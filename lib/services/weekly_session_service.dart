import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weekly_session_model.dart';
import '../models/portrait_model.dart';

class WeeklySessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the current active weekly session
  Stream<WeeklySessionModel?> getCurrentWeeklySession() {
    return _firestore
        .collection('weekly_sessions')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return WeeklySessionModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    });
  }

  // Create a new weekly session for the upcoming Monday
  Future<void> createWeeklySession() async {
    final now = DateTime.now();
    final upcomingMonday = _getUpcomingMonday(now);
    
    final session = WeeklySessionModel(
      id: '',
      sessionDate: upcomingMonday,
      rsvpUserIds: [],
      submissions: [],
      createdAt: now,
      isActive: true,
    );

    await _firestore.collection('weekly_sessions').add(session.toMap());
  }

  // RSVP for a weekly session
  Future<void> rsvpForSession(String sessionId, String userId) async {
    await _firestore.collection('weekly_sessions').doc(sessionId).update({
      'rsvpUserIds': FieldValue.arrayUnion([userId]),
    });
  }

  // Cancel RSVP for a weekly session
  Future<void> cancelRsvp(String sessionId, String userId) async {
    await _firestore.collection('weekly_sessions').doc(sessionId).update({
      'rsvpUserIds': FieldValue.arrayRemove([userId]),
    });
  }

  // Submit a portrait for the weekly session
  Future<void> submitPortrait(
    String sessionId,
    String userId,
    PortraitModel portrait,
    String? artistNotes,
  ) async {
    final submission = WeeklySubmissionModel(
      id: '',
      userId: userId,
      portraitId: portrait.id,
      portraitTitle: portrait.title,
      portraitImageUrl: portrait.imageUrl,
      submittedAt: DateTime.now(),
      artistNotes: artistNotes,
    );

    await _firestore.collection('weekly_sessions').doc(sessionId).update({
      'submissions': FieldValue.arrayUnion([submission.toMap()]),
    });
  }

  // Remove a submission
  Future<void> removeSubmission(String sessionId, String userId) async {
    final sessionDoc = await _firestore.collection('weekly_sessions').doc(sessionId).get();
    if (!sessionDoc.exists) return;

    final session = WeeklySessionModel.fromMap(sessionDoc.data()!, sessionDoc.id);
    final updatedSubmissions = session.submissions.where((s) => s.userId != userId).toList();

    await _firestore.collection('weekly_sessions').doc(sessionId).update({
      'submissions': updatedSubmissions.map((s) => s.toMap()).toList(),
    });
  }

  // Get all weekly sessions (for admin purposes)
  Stream<List<WeeklySessionModel>> getAllWeeklySessions() {
    return _firestore
        .collection('weekly_sessions')
        .orderBy('sessionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeeklySessionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Check if user has already submitted for this session
  Future<bool> hasUserSubmitted(String sessionId, String userId) async {
    final sessionDoc = await _firestore.collection('weekly_sessions').doc(sessionId).get();
    if (!sessionDoc.exists) return false;

    final session = WeeklySessionModel.fromMap(sessionDoc.data()!, sessionDoc.id);
    return session.submissions.any((submission) => submission.userId == userId);
  }

  // Get user's submission for current session
  Future<WeeklySubmissionModel?> getUserSubmission(String sessionId, String userId) async {
    final sessionDoc = await _firestore.collection('weekly_sessions').doc(sessionId).get();
    if (!sessionDoc.exists) return null;

    final session = WeeklySessionModel.fromMap(sessionDoc.data()!, sessionDoc.id);
    try {
      return session.submissions.firstWhere((submission) => submission.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Vote for a submission in a specific award category
  Future<void> voteForSubmission(
    String sessionId,
    String submissionId,
    String awardCategory,
    String userId,
  ) async {
    final sessionRef = _firestore.collection('weekly_sessions').doc(sessionId);
    final sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) return;

    final session = WeeklySessionModel.fromMap(sessionDoc.data()!, sessionDoc.id);
    final submissions = session.submissions.toList();
    final submissionIndex = submissions.indexWhere((s) => s.id == submissionId);
    if (submissionIndex == -1) return;

    final submission = submissions[submissionIndex];
    final votes = Map<String, List<String>>.from(submission.votes);
    
    // Ensure the category exists
    votes.putIfAbsent(awardCategory, () => []);

    // Add the user's vote, ensuring no duplicates
    if (!votes[awardCategory]!.contains(userId)) {
      votes[awardCategory]!.add(userId);
    }

    // Update the submission with new votes
    submissions[submissionIndex] = submission.copyWith(votes: votes);
    await sessionRef.update({
      'submissions': submissions.map((s) => s.toMap()).toList(),
    });
  }

  // Remove a vote from a submission
  Future<void> removeVoteForSubmission(
    String sessionId,
    String submissionId,
    String awardCategory,
    String userId,
  ) async {
    final sessionRef = _firestore.collection('weekly_sessions').doc(sessionId);
    final sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) return;

    final session = WeeklySessionModel.fromMap(sessionDoc.data()!, sessionDoc.id);
    final submissions = session.submissions.toList();
    final submissionIndex = submissions.indexWhere((s) => s.id == submissionId);
    if (submissionIndex == -1) return;
    
    final submission = submissions[submissionIndex];
    final votes = Map<String, List<String>>.from(submission.votes);

    if (votes.containsKey(awardCategory)) {
      votes[awardCategory]!.remove(userId);
    }
    
    submissions[submissionIndex] = submission.copyWith(votes: votes);
    await sessionRef.update({
      'submissions': submissions.map((s) => s.toMap()).toList(),
    });
  }

  // Helper method to get next Monday
  DateTime _getNextMonday(DateTime from) {
    final daysUntilMonday = (DateTime.monday - from.weekday) % 7;
    if (daysUntilMonday == 0) {
      // If today is Monday, get next Monday
      return from.add(const Duration(days: 7));
    }
    return from.add(Duration(days: daysUntilMonday));
  }

  // Helper method to get the upcoming Monday (for session creation after Monday night)
  DateTime _getUpcomingMonday(DateTime from) {
    // If it's Tuesday or later, get next Monday
    // If it's Monday, get the Monday after next
    if (from.weekday == DateTime.monday) {
      return from.add(const Duration(days: 7));
    } else {
      final daysUntilMonday = (DateTime.monday - from.weekday) % 7;
      return from.add(Duration(days: daysUntilMonday));
    }
  }

  // Get the next Monday date for display
  DateTime getNextMonday() {
    return _getNextMonday(DateTime.now());
  }

  // Format date for display
  String formatSessionDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Check if session is today
  bool isSessionToday(DateTime sessionDate) {
    final now = DateTime.now();
    return sessionDate.year == now.year &&
           sessionDate.month == now.month &&
           sessionDate.day == now.day;
  }

  // Get the next upcoming weekly session (by date)
  Stream<WeeklySessionModel?> getNextWeeklySession() {
    final now = DateTime.now();
    return _firestore
        .collection('weekly_sessions')
        .where('sessionDate', isGreaterThanOrEqualTo: now)
        .orderBy('sessionDate')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return WeeklySessionModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    });
  }

  // Get the most recent completed weekly session (for winners)
  Stream<WeeklySessionModel?> getMostRecentCompletedSession() {
    final now = DateTime.now();
    return _firestore
        .collection('weekly_sessions')
        .where('sessionDate', isLessThan: now)
        .orderBy('sessionDate', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return WeeklySessionModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    });
  }

  // Cancel a weekly session
  Future<void> cancelWeeklySession(String sessionId, String notes) async {
    await _firestore.collection('weekly_sessions').doc(sessionId).update({
      'isCancelled': true,
      'notes': notes,
    });
  }

  // Un-cancel a weekly session
  Future<void> uncancelWeeklySession(String sessionId) async {
    await _firestore.collection('weekly_sessions').doc(sessionId).update({
      'isCancelled': false,
    });
  }

  // Add or update notes for a weekly session
  Future<void> updateSessionNotes(String sessionId, String notes) async {
    await _firestore.collection('weekly_sessions').doc(sessionId).update({
      'notes': notes,
    });
  }
} 