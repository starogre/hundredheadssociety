import 'package:flutter/foundation.dart';
import '../models/weekly_session_model.dart';
import '../models/portrait_model.dart';
import '../services/weekly_session_service.dart';
import '../services/user_service.dart';
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

  WeeklySessionModel? _currentSession;
  WeeklySessionModel? _mostRecentCompletedSession; // For winners
  List<UserModel> _rsvpUsers = [];
  List<Map<String, dynamic>> _submissionsWithUsers = [];
  bool _isLoading = false;
  String? _error;

  WeeklySessionModel? get currentSession => _currentSession;
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
        
        // Only reload users if session changed
        if (session != null && (oldSession?.id != session.id || oldSession == null)) {
          await _loadRsvpUsers(session.rsvpUserIds);
          await _loadSubmissionsWithUsers(session.submissions);
        } else if (session == null) {
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
    for (WeeklySubmissionModel submission in submissions) {
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
    if (_currentSession == null) return;

    try {
      await _weeklySessionService.rsvpForSession(_currentSession!.id, userId);
      // Update locally for immediate UI feedback
      if (!_currentSession!.rsvpUserIds.contains(userId)) {
        _currentSession = _currentSession!.copyWith(
          rsvpUserIds: [..._currentSession!.rsvpUserIds, userId],
        );
        // Load the user data immediately
        final user = await _userService.getUserById(userId);
        if (user != null && !_rsvpUsers.any((u) => u.id == userId)) {
          _rsvpUsers.add(user);
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
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
    try {
      await _weeklySessionService.voteForSubmission(
        _currentSession!.id,
        submissionId,
        awardCategory,
        userId,
      );
      
      // Update locally for immediate UI feedback
      final submissionIndex = _submissionsWithUsers.indexWhere(
        (data) => (data['submission'] as WeeklySubmissionModel).id == submissionId,
      );
      
      if (submissionIndex != -1) {
        final submission = _submissionsWithUsers[submissionIndex]['submission'] as WeeklySubmissionModel;
        final updatedVotes = Map<String, List<String>>.from(submission.votes);
        updatedVotes.putIfAbsent(awardCategory, () => []);
        if (!updatedVotes[awardCategory]!.contains(userId)) {
          updatedVotes[awardCategory]!.add(userId);
        }
        
        final updatedSubmission = submission.copyWith(votes: updatedVotes);
        _submissionsWithUsers[submissionIndex] = {
          ..._submissionsWithUsers[submissionIndex],
          'submission': updatedSubmission,
        };
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Remove vote for a submission
  Future<void> removeVoteForSubmission(
    String submissionId,
    String awardCategory,
    String userId,
  ) async {
    if (_currentSession == null) return;
    try {
      await _weeklySessionService.removeVoteForSubmission(
        _currentSession!.id,
        submissionId,
        awardCategory,
        userId,
      );
      
      // Update locally for immediate UI feedback
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
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get winners for each category
  Map<String, Map<String, dynamic>> get winners {
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

    final Map<String, Map<String, dynamic>> categoryWinners = {};

    // Use award categories from the nomination dialog
    final awardCategories = ['likeness', 'style', 'fun', 'topHead'];

    for (var category in awardCategories) {
      Map<String, dynamic>? topSubmission;
      int maxVotes = 0;

      for (var submissionData in _submissionsWithUsers) {
        final submission = submissionData['submission'] as WeeklySubmissionModel;
        final votes = submission.votes[category]?.length ?? 0;
        if (votes > maxVotes) {
          maxVotes = votes;
          topSubmission = submissionData;
        }
      }

      if (topSubmission != null && maxVotes > 0) {
        categoryWinners[category] = topSubmission;
        print('DEBUG: Winner for $category - ${topSubmission['user'].name} with $maxVotes votes');
      } else {
        print('DEBUG: No winner for $category - max votes: $maxVotes');
      }
    }
    
    print('DEBUG: Total winners found: ${categoryWinners.length}');
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

  // Check if voting is closed (after Wednesday noon)
  bool isVotingClosed() {
    if (_currentSession == null) return false;
    
    final now = DateTime.now();
    final sessionDate = _currentSession!.sessionDate;
    
    // Calculate Wednesday noon (2 days after Monday session)
    final wednesday = sessionDate.add(const Duration(days: 2));
    final wednesdayNoon = DateTime(wednesday.year, wednesday.month, wednesday.day, 12, 0);
    
    final isClosed = now.isAfter(wednesdayNoon);
    print('DEBUG: Voting closed check - Now: $now, Session: $sessionDate, Wednesday noon: $wednesdayNoon, Is closed: $isClosed');
    
    return isClosed;
  }

  // Check if winners should be shown (from Wednesday noon until Monday 9am)
  bool shouldShowWinners() {
    if (_mostRecentCompletedSession == null) {
      print('DEBUG: No most recent completed session for winners check');
      return false;
    }
    
    final now = DateTime.now();
    final sessionDate = _mostRecentCompletedSession!.sessionDate;
    
    print('DEBUG: Most recent completed session date: $sessionDate');
    
    // Calculate Wednesday noon (2 days after Monday session)
    final wednesday = sessionDate.add(const Duration(days: 2));
    final wednesdayNoon = DateTime(wednesday.year, wednesday.month, wednesday.day, 12, 0);
    
    // Calculate next Monday 9am (7 days after session)
    final nextMonday = sessionDate.add(const Duration(days: 7));
    final nextMonday9am = DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 9, 0);
    
    final shouldShow = now.isAfter(wednesdayNoon) && now.isBefore(nextMonday9am);
    print('DEBUG: Show winners check - Now: $now, Session: $sessionDate, Wednesday noon: $wednesdayNoon, Next Monday 9am: $nextMonday9am, Should show: $shouldShow');
    
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