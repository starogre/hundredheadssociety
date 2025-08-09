/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentUpdated, onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Set global options for cost control
setGlobalOptions({maxInstances: 10});

const db = admin.firestore();

// Types for TypeScript
interface User {
  id: string;
  email: string;
  name: string;
  status: string;
  isAdmin: boolean;
  role?: string; // 'artist', 'art_appreciator', 'admin', 'moderator'
}

interface WeeklySession {
  id: string;
  sessionDate: Date;
  rsvpUserIds: string[];
  submissions: WeeklySubmission[];
  createdAt: Date;
  isActive: boolean;
}

interface WeeklySubmission {
  id: string;
  userId: string;
  portraitId: string;
  portraitTitle: string;
  portraitImageUrl: string;
  submittedAt: Date;
  artistNotes?: string;
  votes: Record<string, string[]>;
}

/**
 * 1. AUTOMATIC WEEKLY SESSION CREATION
 * Runs every Monday at 9:00 AM to create a new weekly session
 */
export const createWeeklySession = onSchedule({
  schedule: "0 9 * * 1", // Every Monday at 9:00 AM
  timeZone: "America/New_York",
}, async () => {
  try {
    logger.info("Creating new weekly session...");

    // Calculate next session date (next Monday)
    const now = new Date();
    const nextMonday = new Date(now);
    nextMonday.setDate(now.getDate() + (8 - now.getDay()) % 7);
    nextMonday.setHours(9, 0, 0, 0); // 9:00 AM

    // Get all approved users
    const usersSnapshot = await db.collection("users")
        .where("status", "==", "approved")
        .get();

    const approvedUserIds = usersSnapshot.docs.map((doc) => doc.id);

    // Create new session
    const newSession: Partial<WeeklySession> = {
      sessionDate: nextMonday,
      rsvpUserIds: [],
      submissions: [],
      createdAt: new Date(),
      isActive: true,
    };

    const sessionRef = await db.collection("weeklySessions").add(newSession);

    logger.info(`Created weekly session ${sessionRef.id} for ${
        nextMonday.toDateString()}`);

    // Send notification to all approved users
    await sendSessionCreationNotification(approvedUserIds, nextMonday);
  } catch (error) {
    logger.error("Error creating weekly session:", error);
  }
});

/**
 * 2. SESSION REMINDERS
 * Sends reminders 24 hours before session starts
 */
export const sendSessionReminders = onSchedule({
  schedule: "0 9 * * 0", // Every Sunday at 9:00 AM
  timeZone: "America/New_York",
}, async () => {
  try {
    logger.info("Sending session reminders...");

    // Find active session for next Monday
    const nextMonday = new Date();
    nextMonday.setDate(nextMonday.getDate() + (8 - nextMonday.getDay()) % 7);
    nextMonday.setHours(9, 0, 0, 0);

    const sessionsSnapshot = await db.collection("weeklySessions")
        .where("sessionDate", "==", nextMonday)
        .where("isActive", "==", true)
        .limit(1)
        .get();

    if (sessionsSnapshot.empty) {
      logger.info("No active session found for next Monday");
      return;
    }

    const session = sessionsSnapshot.docs[0];
    const sessionData = session.data() as WeeklySession;

    // Get users who haven't RSVP'd yet
    const allUsersSnapshot = await db.collection("users")
        .where("status", "==", "approved")
        .get();

    const allApprovedUsers = allUsersSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as User[];

    const usersWithoutRSVP = allApprovedUsers.filter(
        (user) => !sessionData.rsvpUserIds.includes(user.id),
    );

    // Send reminders to users who haven't RSVP'd
    await sendReminderNotifications(usersWithoutRSVP, nextMonday);

    logger.info(`Sent reminders to ${usersWithoutRSVP.length} users`);
  } catch (error) {
    logger.error("Error sending session reminders:", error);
  }
});

/**
 * 3. SESSION CLOSURE
 * Closes session and processes results when session time arrives
 */
export const closeWeeklySession = onSchedule({
  schedule: "0 10 * * 1", // Every Monday at 10:00 AM (1 hour after session starts)
  timeZone: "America/New_York",
}, async () => {
  try {
    logger.info("Closing weekly session...");

    const now = new Date();
    const today9AM = new Date(now);
    today9AM.setHours(9, 0, 0, 0);

    // Find session that started today
    const sessionsSnapshot = await db.collection("weeklySessions")
        .where("sessionDate", "==", today9AM)
        .where("isActive", "==", true)
        .limit(1)
        .get();

    if (sessionsSnapshot.empty) {
      logger.info("No active session found to close");
      return;
    }

    const sessionDoc = sessionsSnapshot.docs[0];
    const sessionData = sessionDoc.data() as WeeklySession;

    // Close the session
    await sessionDoc.ref.update({
      isActive: false,
      closedAt: new Date(),
    });

    // Process session results
    await processSessionResults(sessionDoc.id, sessionData);

    // Send completion notifications
    await sendSessionCompletionNotifications(sessionData);

    logger.info(`Closed session ${sessionDoc.id}`);
  } catch (error) {
    logger.error("Error closing weekly session:", error);
  }
});

/**
 * 4. RSVP TRIGGER
 * When a user RSVPs, send confirmation and update session
 */
export const onUserRSVP = onDocumentUpdated("weeklySessions/{sessionId}", async (event) => {
  try {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    const beforeRSVP = beforeData.rsvpUserIds || [];
    const afterRSVP = afterData.rsvpUserIds || [];

    // Check if someone new RSVP'd
    const newRSVPs = afterRSVP.filter((userId: string) => !beforeRSVP.includes(userId));

    if (newRSVPs.length > 0) {
      logger.info(`New RSVPs detected: ${newRSVPs.join(", ")}`);

      // Send confirmation to new RSVPs
      for (const userId of newRSVPs) {
        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists) {
          const userData = userDoc.data() as User;
          await sendRSVPConfirmation(userData, afterData.sessionDate);
        }
      }
    }
  } catch (error) {
    logger.error("Error processing RSVP:", error);
  }
});

/**
 * 5. SUBMISSION TRIGGER
 * When a submission is added, notify other participants
 */
export const onSubmissionAdded = onDocumentUpdated("weeklySessions/{sessionId}", async (event) => {
  try {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    const beforeSubmissions = beforeData.submissions || [];
    const afterSubmissions = afterData.submissions || [];

    // Check if new submission was added
    if (afterSubmissions.length > beforeSubmissions.length) {
      const newSubmission = afterSubmissions[afterSubmissions.length - 1];
      logger.info(`New submission detected from user ${newSubmission.userId}`);

      // Notify other session participants
      const otherParticipants = afterData.rsvpUserIds.filter(
          (userId: string) => userId !== newSubmission.userId,
      );

      await sendSubmissionNotification(otherParticipants, newSubmission);
    }
  } catch (error) {
    logger.error("Error processing submission:", error);
  }
});

// Helper Functions

/**
 * Send session creation notifications to users
 */
async function sendSessionCreationNotification(userIds: string[], sessionDate: Date): Promise<void> {
  try {
    const batch = db.batch();

    for (const userId of userIds) {
      const notificationRef = db.collection("notifications").doc();
      batch.set(notificationRef, {
        userId: userId,
        type: "session_created",
        title: "New Weekly Session Created!",
        message: `A new weekly session has been scheduled for ${
            sessionDate.toLocaleDateString()}. Don't forget to RSVP!`,
        createdAt: new Date(),
        read: false,
        data: {
          sessionDate: sessionDate,
        },
      });
    }

    await batch.commit();
    logger.info(`Sent session creation notifications to ${userIds.length} users`);
  } catch (error) {
    logger.error("Error sending session creation notifications:", error);
  }
}

/**
 * Send reminder notifications to users
 */
async function sendReminderNotifications(users: User[], sessionDate: Date): Promise<void> {
  try {
    const batch = db.batch();

    for (const user of users) {
      const notificationRef = db.collection("notifications").doc();
      batch.set(notificationRef, {
        userId: user.id,
        type: "session_reminder",
        title: "Weekly Session Tomorrow!",
        message: "Don't forget! The weekly session starts tomorrow at 9:00 AM. " +
            "Please RSVP if you haven't already.",
        createdAt: new Date(),
        read: false,
        data: {
          sessionDate: sessionDate,
        },
      });
    }

    await batch.commit();
    logger.info(`Sent reminder notifications to ${users.length} users`);
  } catch (error) {
    logger.error("Error sending reminder notifications:", error);
  }
}

/**
 * Send RSVP confirmation to user
 */
async function sendRSVPConfirmation(user: User, sessionDate: Date): Promise<void> {
  try {
    const notificationRef = db.collection("notifications").doc();
    await notificationRef.set({
      userId: user.id,
      type: "rsvp_confirmation",
      title: "RSVP Confirmed!",
      message: `You're confirmed for the weekly session on ${
          sessionDate.toLocaleDateString()}. See you there!`,
      createdAt: new Date(),
      read: false,
      data: {
        sessionDate: sessionDate,
      },
    });

    logger.info(`Sent RSVP confirmation to user ${user.id}`);
  } catch (error) {
    logger.error("Error sending RSVP confirmation:", error);
  }
}

/**
 * Send submission notification to participants
 */
async function sendSubmissionNotification(userIds: string[], submission: WeeklySubmission): Promise<void> {
  try {
    const batch = db.batch();

    for (const userId of userIds) {
      const notificationRef = db.collection("notifications").doc();
      batch.set(notificationRef, {
        userId: userId,
        type: "new_submission",
        title: "New Portrait Submission!",
        message: `A new portrait "${submission.portraitTitle}" has been submitted to the weekly session.`,
        createdAt: new Date(),
        read: false,
        data: {
          submissionId: submission.id,
          portraitTitle: submission.portraitTitle,
        },
      });
    }

    await batch.commit();
    logger.info(`Sent submission notifications to ${userIds.length} users`);
  } catch (error) {
    logger.error("Error sending submission notifications:", error);
  }
}

/**
 * Process session results and update statistics
 */
async function processSessionResults(sessionId: string, sessionData: WeeklySession): Promise<void> {
  try {
    // Calculate participation statistics
    const totalParticipants = sessionData.rsvpUserIds.length;
    const totalSubmissions = sessionData.submissions.length;
    const participationRate = totalParticipants > 0 ? 
        (totalSubmissions / totalParticipants) * 100 : 0;

    // Update session with results
    await db.collection("weeklySessions").doc(sessionId).update({
      results: {
        totalParticipants,
        totalSubmissions,
        participationRate: Math.round(participationRate),
        processedAt: new Date(),
      },
    });

    logger.info(`Processed results for session ${sessionId}: ${
        totalSubmissions}/${totalParticipants} submissions`);
  } catch (error) {
    logger.error("Error processing session results:", error);
  }
}

/**
 * Send session completion notifications
 */
async function sendSessionCompletionNotifications(sessionData: WeeklySession): Promise<void> {
  try {
    const batch = db.batch();

    for (const userId of sessionData.rsvpUserIds) {
      const notificationRef = db.collection("notifications").doc();
      batch.set(notificationRef, {
        userId: userId,
        type: "session_completed",
        title: "Weekly Session Completed!",
        message: "The weekly session has ended. Check out all the amazing portraits submitted!",
        createdAt: new Date(),
        read: false,
        data: {
          sessionId: sessionData.id,
          totalSubmissions: sessionData.submissions.length,
        },
      });
    }

    await batch.commit();
    logger.info(`Sent completion notifications to ${sessionData.rsvpUserIds.length} users`);
  } catch (error) {
    logger.error("Error sending completion notifications:", error);
  }
}

// Manual trigger function for testing
export const testWeeklySessionFunctions = onRequest(async (req, res) => {
  try {
    logger.info("Testing weekly session functions...");

    // Test session creation
    const nextMonday = new Date();
    nextMonday.setDate(nextMonday.getDate() + (8 - nextMonday.getDay()) % 7);
    nextMonday.setHours(9, 0, 0, 0);

    const testSession = {
      sessionDate: nextMonday,
      rsvpUserIds: [],
      submissions: [],
      createdAt: new Date(),
      isActive: true,
    };

    const sessionRef = await db.collection("weeklySessions").add(testSession);

    res.json({
      success: true,
      message: "Test session created successfully",
      sessionId: sessionRef.id,
      sessionDate: nextMonday.toISOString(),
    });
  } catch (error) {
    logger.error("Error in test function:", error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

/**
 * 6. PUSH NOTIFICATION TRIGGER
 * When a notification is created in Firestore, send push notification via FCM
 */
export const sendPushNotification = onDocumentCreated("users/{userId}/notifications/{notificationId}", async (event) => {
  try {
    const notificationData = event.data?.data();
    if (!notificationData) {
      logger.error("No notification data found");
      return;
    }

    const userId = event.params.userId;
    const notificationId = event.params.notificationId;

    logger.info(`Processing push notification for user ${userId}, notification ${notificationId}`);

    // Get user's FCM token
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      logger.error(`User ${userId} not found`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      logger.warn(`No FCM token found for user ${userId}`);
      return;
    }

    // Check user's notification preferences
    const notificationType = notificationData.type;
    const notificationPreferences = userData?.notificationPreferences || {};
    
    // If user has disabled this notification type, don't send push notification
    if (notificationPreferences[notificationType] === false) {
      logger.info(`Push notification disabled for user ${userId}, type: ${notificationType}`);
      return;
    }

    // Prepare notification message
    const message = {
      token: fcmToken,
      notification: {
        title: notificationData.title || "100 Heads Society",
        body: notificationData.message || "You have a new notification",
      },
      data: {
        notificationId: notificationId,
        type: notificationData.type || "general",
        userId: userId,
        ...notificationData.data,
      },
      android: {
        priority: "high" as const,
        notification: {
          channelId: "hundred_heads_channel",
          priority: "high" as const,
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    // Send push notification
    const response = await admin.messaging().send(message);
    logger.info(`Push notification sent successfully to user ${userId}: ${response}`);

    // Update notification with sent status
    await event.data?.ref.update({
      pushSent: true,
      pushSentAt: new Date(),
      fcmMessageId: response,
    });

  } catch (error) {
    logger.error("Error sending push notification:", error);
    
    // Update notification with error status
    try {
      await event.data?.ref.update({
        pushError: error instanceof Error ? error.message : "Unknown error",
        pushErrorAt: new Date(),
      });
    } catch (updateError) {
      logger.error("Error updating notification with error status:", updateError);
    }
  }
});

/**
 * 7. TEST PUSH NOTIFICATION FUNCTION
 * Manual trigger for testing push notifications
 */
export const testPushNotification = onRequest(async (req, res) => {
  try {
    const { userId, title, body } = req.body;

    if (!userId || !title || !body) {
      res.status(400).json({
        success: false,
        error: "Missing required parameters: userId, title, body",
      });
      return;
    }

    logger.info(`Testing push notification for user ${userId}`);

    // Get user's FCM token
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      res.status(404).json({
        success: false,
        error: "User not found",
      });
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      res.status(400).json({
        success: false,
        error: "No FCM token found for user",
      });
      return;
    }

    // Send test push notification
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "test",
        userId: userId,
        timestamp: new Date().toISOString(),
      },
      android: {
        priority: "high" as const,
        notification: {
          channelId: "hundred_heads_channel",
          priority: "high" as const,
          defaultSound: true,
        },
      },
    };

    const response = await admin.messaging().send(message);
    logger.info(`Test push notification sent successfully: ${response}`);

    res.json({
      success: true,
      message: "Test push notification sent successfully",
      fcmMessageId: response,
    });

  } catch (error) {
    logger.error("Error in test push notification function:", error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

/**
 * 8. UPLOAD DEADLINE REMINDER (Tuesday noon)
 * Sends reminders to artists to upload their portraits
 */
export const sendUploadDeadlineReminders = onSchedule({
  schedule: "0 12 * * 2", // Every Tuesday at 12:00 PM (noon)
  timeZone: "America/New_York",
}, async () => {
  try {
    logger.info("Sending upload deadline reminders...");

    // Find active session for next Monday
    const nextMonday = new Date();
    nextMonday.setDate(nextMonday.getDate() + (8 - nextMonday.getDay()) % 7);
    nextMonday.setHours(9, 0, 0, 0);

    const sessionsSnapshot = await db.collection("weeklySessions")
        .where("sessionDate", "==", nextMonday)
        .where("isActive", "==", true)
        .limit(1)
        .get();

    if (sessionsSnapshot.empty) {
      logger.info("No active session found for next Monday");
      return;
    }

    const session = sessionsSnapshot.docs[0];
    const sessionData = session.data() as WeeklySession;

    // Get all approved artists (users with role 'artist')
    const artistsSnapshot = await db.collection("users")
        .where("status", "==", "approved")
        .where("role", "==", "artist")
        .get();

    const artists = artistsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as User[];

    // Send upload deadline reminders to artists who have this notification enabled
    for (const artist of artists) {
      try {
        // Check if artist has this notification type enabled
        const userDoc = await db.collection("users").doc(artist.id).get();
        const userData = userDoc.data();
        const notificationPreferences = userData?.notificationPreferences || {};
        const isUploadDeadlineEnabled = notificationPreferences.upload_deadline !== false; // Default to true

        if (isUploadDeadlineEnabled) {
          await db.collection("users").doc(artist.id).collection("notifications").add({
            userId: artist.id,
            type: "upload_deadline",
            title: "📤 Upload Your Portrait!",
            message: "Don't forget to upload your portrait for this week's session!",
            createdAt: new Date(),
            read: false,
            data: {
              sessionTitle: `Weekly Session - ${nextMonday.toLocaleDateString()}`,
              action: "upload_reminder"
            }
          });
          logger.info(`Sent upload deadline reminder to artist ${artist.id}`);
        } else {
          logger.info(`Skipped upload deadline reminder for artist ${artist.id} (disabled)`);
        }
      } catch (error) {
        logger.error(`Error sending upload deadline reminder to artist ${artist.id}:`, error);
      }
    }

    logger.info(`Sent upload deadline reminders to ${artists.length} artists`);
  } catch (error) {
    logger.error("Error sending upload deadline reminders:", error);
  }
});

/**
 * 9. VOTING REMINDER (Wednesday 1 hour before close)
 * Sends reminders to artists to vote before voting closes
 */
export const sendVotingReminders = onSchedule({
  schedule: "0 11 * * 3", // Every Wednesday at 11:00 AM (1 hour before 12 PM close)
  timeZone: "America/New_York",
}, async () => {
  try {
    logger.info("Sending voting reminders...");

    // Find active session for this week (Monday)
    const thisMonday = new Date();
    thisMonday.setDate(thisMonday.getDate() - (thisMonday.getDay() - 1) % 7);
    thisMonday.setHours(9, 0, 0, 0);

    const sessionsSnapshot = await db.collection("weeklySessions")
        .where("sessionDate", "==", thisMonday)
        .where("isActive", "==", true)
        .limit(1)
        .get();

    if (sessionsSnapshot.empty) {
      logger.info("No active session found for this Monday");
      return;
    }

    const session = sessionsSnapshot.docs[0];
    const sessionData = session.data() as WeeklySession;

    // Get all approved artists who haven't voted yet
    const artistsSnapshot = await db.collection("users")
        .where("status", "==", "approved")
        .where("role", "==", "artist")
        .get();

    const artists = artistsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as User[];

    // Check which artists haven't voted (simplified check)
    const artistsWithoutVotes = artists.filter(artist => {
      // This is a simplified check - in a real implementation, you'd check actual votes
      return true; // For now, send to all artists
    });

    // Send voting reminders to artists who have this notification enabled
    for (const artist of artistsWithoutVotes) {
      try {
        // Check if artist has this notification type enabled
        const userDoc = await db.collection("users").doc(artist.id).get();
        const userData = userDoc.data();
        const notificationPreferences = userData?.notificationPreferences || {};
        const isVotingReminderEnabled = notificationPreferences.voting_reminder !== false; // Default to true

        if (isVotingReminderEnabled) {
          await db.collection("users").doc(artist.id).collection("notifications").add({
            userId: artist.id,
            type: "voting_reminder",
            title: "🗳️ Vote Now!",
            message: "Voting closes in 1 hour! Don't forget to vote for your favorite portraits!",
            createdAt: new Date(),
            read: false,
            data: {
              sessionTitle: `Weekly Session - ${thisMonday.toLocaleDateString()}`,
              action: "voting_reminder"
            }
          });
          logger.info(`Sent voting reminder to artist ${artist.id}`);
        } else {
          logger.info(`Skipped voting reminder for artist ${artist.id} (disabled)`);
        }
      } catch (error) {
        logger.error(`Error sending voting reminder to artist ${artist.id}:`, error);
      }
    }

    logger.info(`Sent voting reminders to ${artistsWithoutVotes.length} artists`);
  } catch (error) {
    logger.error("Error sending voting reminders:", error);
  }
});

/**
 * 10. RSVP REMINDER (Saturday noon)
 * Sends reminders to artists to RSVP for next Monday's session
 */
export const sendRSVPReminders = onSchedule({
  schedule: "0 12 * * 6", // Every Saturday at 12:00 PM (noon)
  timeZone: "America/New_York",
}, async () => {
  try {
    logger.info("Sending RSVP reminders...");

    // Find active session for next Monday
    const nextMonday = new Date();
    nextMonday.setDate(nextMonday.getDate() + (8 - nextMonday.getDay()) % 7);
    nextMonday.setHours(9, 0, 0, 0);

    const sessionsSnapshot = await db.collection("weeklySessions")
        .where("sessionDate", "==", nextMonday)
        .where("isActive", "==", true)
        .limit(1)
        .get();

    if (sessionsSnapshot.empty) {
      logger.info("No active session found for next Monday");
      return;
    }

    const session = sessionsSnapshot.docs[0];
    const sessionData = session.data() as WeeklySession;

    // Get all approved artists who haven't RSVP'd yet
    const artistsSnapshot = await db.collection("users")
        .where("status", "==", "approved")
        .where("role", "==", "artist")
        .get();

    const artists = artistsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as User[];

    // Filter artists who haven't RSVP'd
    const artistsWithoutRSVP = artists.filter(artist => 
      !sessionData.rsvpUserIds.includes(artist.id)
    );

    // Send RSVP reminders to artists who have this notification enabled
    for (const artist of artistsWithoutRSVP) {
      try {
        // Check if artist has this notification type enabled
        const userDoc = await db.collection("users").doc(artist.id).get();
        const userData = userDoc.data();
        const notificationPreferences = userData?.notificationPreferences || {};
        const isRSVPReminderEnabled = notificationPreferences.rsvp_reminder !== false; // Default to true

        if (isRSVPReminderEnabled) {
          await db.collection("users").doc(artist.id).collection("notifications").add({
            userId: artist.id,
            type: "rsvp_reminder",
            title: "📅 RSVP for Monday's Session",
            message: "Will you be joining us for this week's session? Please RSVP!",
            createdAt: new Date(),
            read: false,
            data: {
              sessionTitle: `Weekly Session - ${nextMonday.toLocaleDateString()}`,
              sessionDate: nextMonday,
              action: "rsvp_reminder",
              navigateTo: "weekly_sessions"
            }
          });
          logger.info(`Sent RSVP reminder to artist ${artist.id}`);
        } else {
          logger.info(`Skipped RSVP reminder for artist ${artist.id} (disabled)`);
        }
      } catch (error) {
        logger.error(`Error sending RSVP reminder to artist ${artist.id}:`, error);
      }
    }

    logger.info(`Sent RSVP reminders to ${artistsWithoutRSVP.length} artists`);
  } catch (error) {
    logger.error("Error sending RSVP reminders:", error);
  }
});
