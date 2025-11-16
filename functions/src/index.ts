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
  schedule: "0 18 * * 1", // Every Monday at 6:00 PM
  timeZone: "America/New_York",
}, async () => {
  try {
    logger.info("Creating new weekly session...");

    // Calculate this Monday at 6 PM
    const now = new Date();
    const thisMonday = new Date(now);
    thisMonday.setDate(now.getDate() - (now.getDay() - 1) % 7);
    thisMonday.setHours(18, 0, 0, 0); // 6:00 PM

    // Try to find a model with matching date
    let modelName: string | undefined;
    let modelImageUrl: string | undefined;
    
    try {
      // Look for model with date matching this Monday
      const modelSnapshot = await db.collection("models")
          .where("date", "==", thisMonday)
          .where("isActive", "==", true)
          .limit(1)
          .get();

      if (!modelSnapshot.empty) {
        const modelData = modelSnapshot.docs[0].data();
        modelName = modelData.name;
        modelImageUrl = modelData.imageUrl;
        logger.info(`Found model for session: ${modelName}`);
      } else {
        logger.info("No model found for this session date - admin will need to assign manually");
      }
    } catch (error) {
      logger.error("Error finding model:", error);
      // Continue without model - admin can assign later
    }

    // Get all approved users
    const usersSnapshot = await db.collection("users")
        .where("status", "==", "approved")
        .get();

    const approvedUserIds = usersSnapshot.docs.map((doc) => doc.id);

    // Create new session (with or without model)
    const newSession: Partial<WeeklySession> = {
      sessionDate: thisMonday,
      rsvpUserIds: [],
      submissions: [],
      createdAt: new Date(),
      isActive: true,
      modelName: modelName,
      modelImageUrl: modelImageUrl,
    };

    const sessionRef = await db.collection("weeklySessions").add(newSession);

    logger.info(`Created weekly session ${sessionRef.id} for ${
        thisMonday.toDateString()}${modelName ? ` with model ${modelName}` : " (no model assigned)"}`);

    // Send notification to all approved users
    await sendSessionCreationNotification(approvedUserIds, thisMonday, modelName);
  } catch (error) {
    logger.error("Error creating weekly session:", error);
  }
});

/**
 * 2. SESSION REMINDERS
 * Sends reminders 24 hours before session starts
 */
export const sendSessionReminders = onSchedule({
  schedule: "0 18 * * 0", // Every Sunday at 6:00 PM
  timeZone: "America/New_York",
}, async () => {
  try {
    logger.info("Sending session reminders...");

    // Find active session for next Monday at 6 PM
    const nextMonday = new Date();
    nextMonday.setDate(nextMonday.getDate() + (8 - nextMonday.getDay()) % 7);
    nextMonday.setHours(18, 0, 0, 0);

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

    // Get all approved users
    const allUsersSnapshot = await db.collection("users")
        .where("status", "==", "approved")
        .get();

    const allApprovedUsers = allUsersSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as User[];

    // Send reminders to all approved users (no RSVP needed anymore)
    await sendReminderNotifications(allApprovedUsers, nextMonday, sessionData.modelName);

    logger.info(`Sent reminders to ${allApprovedUsers.length} users`);
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
async function sendSessionCreationNotification(userIds: string[], sessionDate: Date, modelName?: string): Promise<void> {
  try {
    const batch = db.batch();

    const modelInfo = modelName ? ` with model ${modelName}` : "";

    for (const userId of userIds) {
      const notificationRef = db.collection("notifications").doc();
      batch.set(notificationRef, {
        userId: userId,
        type: "session_created",
        title: "New Weekly Session Created!",
        message: `A new weekly session has been scheduled for ${
            sessionDate.toLocaleDateString()} at 6:00 PM${modelInfo}. ` +
            "Don't forget to purchase your session ticket on the website!",
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
async function sendReminderNotifications(users: User[], sessionDate: Date, modelName?: string): Promise<void> {
  try {
    const batch = db.batch();

    const modelInfo = modelName ? ` with model ${modelName}` : "";

    for (const user of users) {
      const notificationRef = db.collection("notifications").doc();
      batch.set(notificationRef, {
        userId: user.id,
        type: "session_reminder",
        title: "Weekly Session Tomorrow!",
        message: `Don't forget! The weekly session starts tomorrow at 6:00 PM${modelInfo}. ` +
            "Remember to purchase your session ticket on the website before attending!",
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

// UPLOAD DEADLINE REMINDER REMOVED - Artists can submit anytime Monday-Friday

/**
 * 9. VOTING REMINDER (Wednesday evening)
 * Sends reminders to artists to vote if they haven't voted yet
 */
export const sendVotingReminders = onSchedule({
  schedule: "0 19 * * 3", // Every Wednesday at 7:00 PM
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

    // Get all approved artists
    const artistsSnapshot = await db.collection("users")
        .where("status", "==", "approved")
        .where("role", "==", "artist")
        .get();

    const artists = artistsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as User[];

    // Check which artists haven't voted yet by looking at submissions
    const artistsWithoutVotes = artists.filter(artist => {
      // Check if this artist has voted in any submission
      const hasVoted = sessionData.submissions.some((submission: WeeklySubmission) => {
        // Check all vote categories
        return Object.values(submission.votes || {}).some((voterIds: string[]) => 
          voterIds.includes(artist.id)
        );
      });
      return !hasVoted; // Only include artists who haven't voted at all
    });

    // Send voting reminders to artists who haven't voted and have this notification enabled
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
            title: "🗳️ Cast Your Votes!",
            message: "Don't forget to vote for your favorite portraits! Voting closes Friday at noon.",
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

    logger.info(`Sent voting reminders to ${artistsWithoutVotes.length} artists who haven't voted`);
  } catch (error) {
    logger.error("Error sending voting reminders:", error);
  }
});

/**
 * Send winner announcement notifications
 * Runs every Friday at 12:00 PM (noon) EST
 */
export const sendWinnerAnnouncements = onSchedule({
  schedule: "0 12 * * 5", // Every Friday at 12:00 PM
  timeZone: "America/New_York",
}, async () => {
  try {
    logger.info("Sending winner announcement notifications...");

    // Get the most recent session (the one that voting just closed for)
    const now = new Date();
    const sessionsSnapshot = await db.collection("weekly_sessions")
      .where("sessionDate", "<", now)
      .orderBy("sessionDate", "desc")
      .limit(1)
      .get();

    if (sessionsSnapshot.empty) {
      logger.info("No sessions found for winner announcements");
      return;
    }

    const sessionDoc = sessionsSnapshot.docs[0];
    const session = sessionDoc.data() as WeeklySession;
    const submissions = session.submissions || [];

    if (submissions.length === 0) {
      logger.info("No submissions for this session");
      return;
    }

    // Calculate winners for each category
    const categories = ["likeness", "style", "fun", "topHead"];
    const categoryNames: {[key: string]: string} = {
      "likeness": "Best Likeness",
      "style": "Best Style",
      "fun": "Most Fun",
      "topHead": "Top Head",
    };

    const winners: {[key: string]: string[]} = {}; // category -> list of winner userIds
    const allWinnerIds = new Set<string>();

    for (const category of categories) {
      let maxVotes = 0;
      const winnersForCategory: string[] = [];

      // Find max votes
      for (const submission of submissions) {
        const votes = (submission.votes && submission.votes[category]) ? submission.votes[category].length : 0;
        if (votes > maxVotes) {
          maxVotes = votes;
        }
      }

      // Collect all submissions with max votes
      if (maxVotes > 0) {
        for (const submission of submissions) {
          const votes = (submission.votes && submission.votes[category]) ? submission.votes[category].length : 0;
          if (votes === maxVotes) {
            winnersForCategory.push(submission.userId);
            allWinnerIds.add(submission.userId);
          }
        }
      }

      if (winnersForCategory.length > 0) {
        winners[category] = winnersForCategory;
      }
    }

    logger.info(`Found winners for ${Object.keys(winners).length} categories`);
    logger.info(`Total unique winners: ${allWinnerIds.size}`);

    // Get all artists (for general announcement)
    const artistsSnapshot = await db.collection("users")
      .where("isArtist", "==", true)
      .where("status", "==", "active")
      .get();

    // Send notifications to winners
    for (const category in winners) {
      const categoryWinners = winners[category];
      const categoryName = categoryNames[category] || category;
      const isTie = categoryWinners.length > 1;

      for (const winnerId of categoryWinners) {
        try {
          const winnerDoc = await db.collection("users").doc(winnerId).get();
          if (!winnerDoc.exists) continue;

          const winner = winnerDoc.data();
          if (!winner || !winner.fcmToken || winner.pushNotificationsEnabled === false) {
            logger.info(`Skipped winner ${winnerId} (no FCM token or disabled)`);
            continue;
          }

          // Send in-app notification
          await db.collection("notifications").add({
            userId: winnerId,
            title: isTie ? "🏆 You're a Co-Winner!" : "🏆 Congratulations, You Won!",
            body: `You won ${categoryName}!${isTie ? ` (${categoryWinners.length}-way tie)` : ""}`,
            type: "winner_announcement",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            read: false,
            link: "/weekly-sessions",
          });

          // Send push notification
          await admin.messaging().send({
            token: winner.fcmToken,
            notification: {
              title: isTie ? "🏆 You're a Co-Winner!" : "🏆 Congratulations, You Won!",
              body: `You won ${categoryName}!${isTie ? ` (${categoryWinners.length}-way tie)` : ""}`,
            },
            data: {
              type: "winner_announcement",
              link: "/weekly-sessions",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
          });

          logger.info(`Sent winner notification to ${winnerId} for ${category}`);
        } catch (error) {
          logger.error(`Error sending winner notification to ${winnerId}:`, error);
        }
      }
    }

    // Send general announcement to all active artists (who didn't win)
    for (const doc of artistsSnapshot.docs) {
      const artist = doc.data();
      const artistId = doc.id;

      // Skip if this artist won an award (they already got personalized notification)
      if (allWinnerIds.has(artistId)) {
        continue;
      }

      try {
        if (!artist.fcmToken || artist.pushNotificationsEnabled === false) {
          logger.info(`Skipped artist ${artistId} (no FCM token or disabled)`);
          continue;
        }

        // Send in-app notification
        await db.collection("notifications").add({
          userId: artistId,
          title: "🏆 This Week's Winners Announced!",
          body: "Check out who won this week's awards",
          type: "winners_announced",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
          link: "/weekly-sessions",
        });

        // Send push notification
        await admin.messaging().send({
          token: artist.fcmToken,
          notification: {
            title: "🏆 This Week's Winners Announced!",
            body: "Check out who won this week's awards",
          },
          data: {
            type: "winners_announced",
            link: "/weekly-sessions",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        });

        logger.info(`Sent general winner announcement to artist ${artistId}`);
      } catch (error) {
        logger.error(`Error sending general announcement to artist ${artistId}:`, error);
      }
    }

    logger.info("Winner announcement notifications sent successfully");
  } catch (error) {
    logger.error("Error sending winner announcement notifications:", error);
  }
});

// RSVP REMINDER REMOVED - Users now pay on website, no RSVP needed
