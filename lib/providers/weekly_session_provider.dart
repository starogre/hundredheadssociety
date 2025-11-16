import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weekly_session_model.dart';
import '../models/portrait_model.dart';
import '../services/weekly_session_service.dart';
import '../services/user_service.dart';
import '../services/push_notification_service.dart';
import '../services/crashlytics_service.dart';
import '../models/user_model.dart';

// Defines the award categories
enum AwardCategory {
  likeness,
  style,
  fun,
  topHead,
}

const Map<AwardCategory, Map<String, dynamic>> awardDetails = {
  AwardCategory.likeness: {
    'title': 'Sharpened Eye',
    'subtitle': 'Best Likeness',
    'emoji': '👁️',
  },
  AwardCategory.style: {
    'title': 'Style Slayer',
    'subtitle': 'Most Unique Style',
    'emoji': '✨',
  },
  AwardCategory.fun: {
    'title': 'Most Fun To Look At',
    'subtitle': 'Pure Enjoyment',
    'emoji': '😂',
  },
  AwardCategory.topHead: {
    'title': 'All Around',
    'subtitle': 'Top Head of the Week',
    'emoji': '👑',
  },
};

class WeeklySessionProvider extends ChangeNotifier {
  final WeeklySessionService _weeklySessionService = WeeklySessionService();
  final UserService _userService = UserService();
  final PushNotificationService _pushNotificationService = PushNotificationService();

  WeeklySessionModel? _currentSession;
  WeeklySessionModel? _mostRecentCompletedSession; // For winners
  List<UserModel> _rsvpUsers = [];
  List<Map<String, dynamic>> _submissionsWithUsers = [];
  bool _isLoading = false;
  String? _error;

  WeeklySessionModel? get currentSession => _currentSession;
  WeeklySessionModel? get mostRecentCompletedSession => _mostRecentCompletedSession;
  List<UserModel> get rsvpUsers => _rsvpUsers;
  List<Map<String, dynamic>> get submissionsWithUsers => _submissionsWithUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize the provider
  void initialize() {
    _loadCurrentSession();
  }

  // Load the current weekly session
  void _loadCurrentSession() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Load the upcoming session for RSVP and submissions
    _weeklySessionService.getNextWeeklySession().listen(
      (session) async {
        final oldSession = _currentSession;
        _currentSession = session;
        
        // Reload users and submissions whenever session data changes
        if (session != null) {
          // Check if we need to reload (session changed OR submissions/rsvps changed OR votes changed)
          final sessionChanged = oldSession?.id != session.id || oldSession == null;
          final submissionsChanged = oldSession?.submissions.length != session.submissions.length;
          final rsvpsChanged = oldSession?.rsvpUserIds.length != session.rsvpUserIds.length;
          
          // Check if votes changed by comparing submission vote counts
          bool votesChanged = false;
          if (oldSession != null && oldSession.submissions.length == session.submissions.length) {
            // Same number of submissions, check if votes changed
            // Create a map of old submissions by ID for efficient lookup
            final oldSubmissionsMap = {
              for (var s in oldSession.submissions) s.id: s
            };
            
            for (final newSubmission in session.submissions) {
              final oldSubmission = oldSubmissionsMap[newSubmission.id];
              if (oldSubmission != null) {
                // Compare vote counts
                final oldTotalVotes = oldSubmission.votes.values.fold(0, (sum, list) => sum + list.length);
                final newTotalVotes = newSubmission.votes.values.fold(0, (sum, list) => sum + list.length);
                if (oldTotalVotes != newTotalVotes) {
                  votesChanged = true;
                  break;
                }
              } else {
                // New submission found, treat as changed
                votesChanged = true;
                break;
              }
            }
          }
          
          if (sessionChanged || submissionsChanged || rsvpsChanged || votesChanged) {
            await _loadRsvpUsers(session.rsvpUserIds);
            await _loadSubmissionsWithUsers(session.submissions);
          }
        } else {
          _rsvpUsers = [];
          _submissionsWithUsers = [];
        }
        
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    // Load the most recent completed session for winners
    _weeklySessionService.getMostRecentCompletedSession().listen(
      (session) {
        _mostRecentCompletedSession = session;
        notifyListeners();
      },
      onError: (error) {
        print('DEBUG: Error loading most recent completed session: $error');
      },
    );
  }

  // Load users who have RSVP'd
  Future<void> _loadRsvpUsers(List<String> userIds) async {
    _rsvpUsers = [];
    for (String userId in userIds) {
      try {
        final user = await _userService.getUserById(userId);
        if (user != null) {
          _rsvpUsers.add(user);
        }
      } catch (e) {
        // Error loading user - silent fail
      }
    }
  }

  // Load submissions with user information
  Future<void> _loadSubmissionsWithUsers(List<WeeklySubmissionModel> submissions) async {
    _submissionsWithUsers = [];
    final Set<String> seenSubmissionIds = {}; // Track seen submission IDs to prevent duplicates
    final Set<String> seenUserPortraitPairs = {}; // Track userId+portraitId pairs to prevent duplicates
    
    for (WeeklySubmissionModel submission in submissions) {
      // Create a unique key for userId+portraitId combination
      final userPortraitKey = '${submission.userId}_${submission.portraitId}';
      
      // Skip if we've already seen this submission ID
      if (submission.id.isNotEmpty && seenSubmissionIds.contains(submission.id)) {
        debugPrint('WARNING: Duplicate submission found with ID: ${submission.id}');
        continue;
      }
      
      // Skip if same user+portrait combination already seen (user can only submit once per session)
      if (seenUserPortraitPairs.contains(userPortraitKey)) {
        debugPrint('WARNING: Duplicate submission found for user ${submission.userId} with portrait ${submission.portraitId}');
        continue;
      }
      
      if (submission.id.isNotEmpty) {
        seenSubmissionIds.add(submission.id);
      }
      seenUserPortraitPairs.add(userPortraitKey);
      
      try {
        final user = await _userService.getUserById(submission.userId);
        if (user != null) {
          _submissionsWithUsers.add({
            'submission': submission,
            'user': user,
          });
        }
      } catch (e) {
        // Error loading user for submission - silent fail
      }
    }
  }

  // RSVP for the current session
  Future<void> rsvpForCurrentSession(String userId) async {
    if (_currentSession == null) {
      _error = 'No active session found';
      notifyListeners();
      return;
    }

    try {
      print('Attempting to RSVP user $userId for session ${_currentSession!.id}');
      
      // Check if user is already RSVP'd locally
      if (_currentSession!.rsvpUserIds.contains(userId)) {
        print('User $userId is already RSVP\'d locally');
        return;
      }
      
      await _weeklySessionService.rsvpForSession(_currentSession!.id, userId);
      
      // Update locally for immediate UI feedback
      _currentSession = _currentSession!.copyWith(
        rsvpUserIds: [..._currentSession!.rsvpUserIds, userId],
      );
      
      // Load the user data immediately
      final user = await _userService.getUserById(userId);
      if (user != null && !_rsvpUsers.any((u) => u.id == userId)) {
        _rsvpUsers.add(user);
        notifyListeners();
      }
      
      print('Successfully RSVP\'d user $userId for session ${_currentSession!.id}');
      
      // Send RSVP confirmation push notification
      try {
        await _pushNotificationService.sendRSVPConfirmation(
          userId,
          'Weekly Session',
          _currentSession!.sessionDate,
        );
        print('RSVP confirmation notification sent successfully');
      } catch (e) {
        // Don't fail the RSVP if push notification fails
        print('Error sending RSVP confirmation notification: $e');
      }
      
      // Clear any previous errors
      _error = null;
      notifyListeners();
    } catch (e) {
      print('Error in rsvpForCurrentSession: $e');
      
      // Log to Crashlytics
      CrashlyticsService.recordRsvpError(
        e,
        StackTrace.current,
        userId: userId,
        action: 'rsvp_for_current_session',
      );
      
      _error = 'Failed to RSVP: ${e.toString()}';
      notifyListeners();
    }
  }

  // Cancel RSVP for the current session
  Future<void> cancelRsvpForCurrentSession(String userId) async {
    if (_currentSession == null) return;

    try {
      await _weeklySessionService.cancelRsvp(_currentSession!.id, userId);
      // Update locally for immediate UI feedback
      if (_currentSession!.rsvpUserIds.contains(userId)) {
        _currentSession = _currentSession!.copyWith(
          rsvpUserIds: _currentSession!.rsvpUserIds.where((id) => id != userId).toList(),
        );
        // Remove from local list immediately
        _rsvpUsers.removeWhere((user) => user.id == userId);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Submit a portrait for the current session
  Future<void> submitPortraitForCurrentSession(
    String userId,
    PortraitModel portrait,
    String? artistNotes,
  ) async {
    if (_currentSession == null) return;

    try {
      await _weeklySessionService.submitPortrait(
        _currentSession!.id,
        userId,
        portrait,
        artistNotes,
      );
      // The stream will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Remove submission for the current session
  Future<void> removeSubmissionForCurrentSession(String userId) async {
    if (_currentSession == null) return;

    try {
      await _weeklySessionService.removeSubmission(_currentSession!.id, userId);
      // The stream will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Vote for a submission
  Future<void> voteForSubmission(
    String submissionId,
    String awardCategory,
    String userId,
  ) async {
    if (_currentSession == null) return;
    
    // First, optimistically update local state for immediate UI feedback
    final submissionIndex = _submissionsWithUsers.indexWhere(
      (data) => (data['submission'] as WeeklySubmissionModel).id == submissionId,
    );
    
    if (submissionIndex != -1) {
      final submission = _submissionsWithUsers[submissionIndex]['submission'] as WeeklySubmissionModel;
      final updatedVotes = Map<String, List<String>>.from(submission.votes);
      updatedVotes.putIfAbsent(awardCategory, () => []);
      
      // Only update if not already voted
      if (!updatedVotes[awardCategory]!.contains(userId)) {
        updatedVotes[awardCategory]!.add(userId);
        
        final updatedSubmission = submission.copyWith(votes: updatedVotes);
        _submissionsWithUsers[submissionIndex] = {
          ..._submissionsWithUsers[submissionIndex],
          'submission': updatedSubmission,
        };
        notifyListeners();
      }
    }
    
    // Then update backend
    try {
      await _weeklySessionService.voteForSubmission(
        _currentSession!.id,
        submissionId,
        awardCategory,
        userId,
      );
      // Stream will eventually sync, but we already updated UI
    } catch (e) {
      debugPrint('Error voting for submission: $e');
      _error = e.toString();
      // Revert local change on error - reload from current session
      if (_currentSession != null) {
        await _loadSubmissionsWithUsers(_currentSession!.submissions);
      }
      notifyListeners();
      rethrow; // Let the UI handle the error message
    }
  }

  // Remove vote for a submission
  Future<void> removeVoteForSubmission(
    String submissionId,
    String awardCategory,
    String userId,
  ) async {
    if (_currentSession == null) return;
    
    // First, optimistically update local state for immediate UI feedback
    final submissionIndex = _submissionsWithUsers.indexWhere(
      (data) => (data['submission'] as WeeklySubmissionModel).id == submissionId,
    );
    
    if (submissionIndex != -1) {
      final submission = _submissionsWithUsers[submissionIndex]['submission'] as WeeklySubmissionModel;
      final updatedVotes = Map<String, List<String>>.from(submission.votes);
      updatedVotes.putIfAbsent(awardCategory, () => []);
      updatedVotes[awardCategory]!.remove(userId);
      
      final updatedSubmission = submission.copyWith(votes: updatedVotes);
      _submissionsWithUsers[submissionIndex] = {
        ..._submissionsWithUsers[submissionIndex],
        'submission': updatedSubmission,
      };
      notifyListeners();
    }
    
    // Then update backend
    try {
      await _weeklySessionService.removeVoteForSubmission(
        _currentSession!.id,
        submissionId,
        awardCategory,
        userId,
      );
      // Stream will eventually sync, but we already updated UI
    } catch (e) {
      _error = e.toString();
      // Revert local change on error
      await _loadSubmissionsWithUsers(_currentSession!.submissions);
      notifyListeners();
    }
  }

  // Get winners for each category (supports ties - multiple winners per category)
  Map<String, List<Map<String, dynamic>>> get winners {
    if (_mostRecentCompletedSession == null) {
      print('DEBUG: No most recent completed session for winners');
      return {};
    }

    // We need to load submissions for the most recent completed session
    // For now, let's use the current session's submissions if they exist
    if (_submissionsWithUsers.isEmpty) {
      print('DEBUG: No submissions for winners');
      return {};
    }

    final Map<String, List<Map<String, dynamic>>> categoryWinners = {};

    // Use award categories from the nomination dialog
    final awardCategories = ['likeness', 'style', 'fun', 'topHead'];

    for (var category in awardCategories) {
      List<Map<String, dynamic>> winners = [];
      int maxVotes = 0;

      // First pass: find the maximum number of votes
      for (var submissionData in _submissionsWithUsers) {
        final submission = submissionData['submission'] as WeeklySubmissionModel;
        final votes = submission.votes[category]?.length ?? 0;
        if (votes > maxVotes) {
          maxVotes = votes;
        }
      }

      // Second pass: collect all submissions with the maximum votes (handles ties)
      if (maxVotes > 0) {
        for (var submissionData in _submissionsWithUsers) {
          final submission = submissionData['submission'] as WeeklySubmissionModel;
          final votes = submission.votes[category]?.length ?? 0;
          if (votes == maxVotes) {
            winners.add(submissionData);
          }
        }
      }

      if (winners.isNotEmpty) {
        categoryWinners[category] = winners;
        if (winners.length > 1) {
          print('DEBUG: TIE for $category - ${winners.length} co-winners with $maxVotes votes each');
        } else {
          print('DEBUG: Winner for $category - ${winners[0]['user'].name} with $maxVotes votes');
        }
      } else {
        print('DEBUG: No winner for $category - max votes: $maxVotes');
      }
    }
    
    print('DEBUG: Total categories with winners: ${categoryWinners.length}');
    return categoryWinners;
  }

  // Check if user has RSVP'd for current session
  bool hasUserRsvpd(String userId) {
    return _currentSession?.rsvpUserIds.contains(userId) ?? false;
  }

  // Check if user has submitted for current session
  bool hasUserSubmitted(String userId) {
    return _currentSession?.submissions.any((s) => s.userId == userId) ?? false;
  }

  // Check if user has already voted for a specific award category
  bool hasUserVotedForCategory(String userId, String awardCategory) {
    for (var submissionData in _submissionsWithUsers) {
      final submission = submissionData['submission'] as WeeklySubmissionModel;
      final votes = submission.votes[awardCategory] ?? [];
      if (votes.contains(userId)) {
        return true;
      }
    }
    return false;
  }

  // Check if voting is closed (after Friday noon)
  bool isVotingClosed() {
    if (_currentSession == null) return false;
    
    final now = DateTime.now();
    final sessionDate = _currentSession!.sessionDate;
    
    // Calculate Friday noon (4 days after Monday session)
    final friday = sessionDate.add(const Duration(days: 4));
    final fridayNoon = DateTime(friday.year, friday.month, friday.day, 12, 0);
    
    final isClosed = now.isAfter(fridayNoon);
    print('DEBUG: Voting closed check - Now: $now, Session: $sessionDate, Friday noon: $fridayNoon, Is closed: $isClosed');
    
    return isClosed;
  }

  // Update user's award count when they win an award
  Future<void> _updateUserAwardCount(String userId, int awardCount) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'portraitAwardCount': FieldValue.increment(awardCount),
      });
    } catch (e) {
      print('Error updating user award count: $e');
    }
  }

  // Process winners and update award counts
  Future<void> processWinnersAndUpdateAwards() async {
    if (_mostRecentCompletedSession == null) return;
    
    try {
      // Get the winners for the most recent completed session
      final winners = this.winners;
      
      // Track how many awards each user won
      Map<String, int> userAwardCounts = {};
      
      for (var winner in winners.values) {
        final userId = winner['user'].id;
        userAwardCounts[userId] = (userAwardCounts[userId] ?? 0) + 1;
      }
      
      // Update each user's award count
      for (var entry in userAwardCounts.entries) {
        await _updateUserAwardCount(entry.key, entry.value);
        print('Updated award count for user ${entry.key}: +${entry.value}');
      }
    } catch (e) {
      print('Error processing winners and updating awards: $e');
    }
  }

  // Check if winners should be shown (from Friday noon until Monday 9am)
  bool shouldShowWinners() {
    if (_mostRecentCompletedSession == null) {
      print('DEBUG: No most recent completed session for winners check');
      return false;
    }
    
    final now = DateTime.now();
    final sessionDate = _mostRecentCompletedSession!.sessionDate;
    
    print('DEBUG: Most recent completed session date: $sessionDate');
    
    // Calculate Friday noon (4 days after Monday session)
    final friday = sessionDate.add(const Duration(days: 4));
    final fridayNoon = DateTime(friday.year, friday.month, friday.day, 12, 0);
    
    // Calculate next Monday 9am (7 days after session)
    final nextMonday = sessionDate.add(const Duration(days: 7));
    final nextMonday9am = DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 9, 0);
    
    final shouldShow = now.isAfter(fridayNoon) && now.isBefore(nextMonday9am);
    print('DEBUG: Show winners check - Now: $now, Session: $sessionDate, Friday noon: $fridayNoon, Next Monday 9am: $nextMonday9am, Should show: $shouldShow');
    
    return shouldShow;
  }

  // Get user's submission for current session
  WeeklySubmissionModel? getUserSubmission(String userId) {
    try {
      return _currentSession?.submissions.firstWhere((s) => s.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Create a new weekly session (admin function)
  Future<void> createWeeklySession() async {
    try {
      await _weeklySessionService.createWeeklySession();
      // The stream will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Cancel a weekly session (admin/moderator function)
  Future<void> cancelWeeklySession(String notes) async {
    if (_currentSession == null) return;
    
    try {
      await _weeklySessionService.cancelWeeklySession(_currentSession!.id, notes);
      // The stream will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Un-cancel a weekly session (admin/moderator function)
  Future<void> uncancelWeeklySession() async {
    if (_currentSession == null) return;
    
    try {
      await _weeklySessionService.uncancelWeeklySession(_currentSession!.id);
      // The stream will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update session notes (admin/moderator function)
  Future<void> updateSessionNotes(String notes) async {
    if (_currentSession == null) return;
    
    try {
      await _weeklySessionService.updateSessionNotes(_currentSession!.id, notes);
      // The stream will automatically update the UI
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get next Monday date
  DateTime getNextMonday() {
    return _weeklySessionService.getNextMonday();
  }

  // Format session date
  String formatSessionDate(DateTime date) {
    return _weeklySessionService.formatSessionDate(date);
  }

  // Check if session is today
  bool isSessionToday(DateTime sessionDate) {
    return _weeklySessionService.isSessionToday(sessionDate);
  }
} 