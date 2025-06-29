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

    _weeklySessionService.getNextWeeklySession().listen(
      (session) async {
        _currentSession = session;
        if (session != null) {
          await _loadRsvpUsers(session.rsvpUserIds);
          await _loadSubmissionsWithUsers(session.submissions);
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
        print('Error loading user $userId: $e');
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
        print('Error loading user for submission: $e');
      }
    }
  }

  // RSVP for the current session
  Future<void> rsvpForCurrentSession(String userId) async {
    if (_currentSession == null) return;

    try {
      await _weeklySessionService.rsvpForSession(_currentSession!.id, userId);
      // The stream will automatically update the UI
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
      // The stream will automatically update the UI
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
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get winners for each category
  Map<String, Map<String, dynamic>> get winners {
    if (_currentSession == null || _submissionsWithUsers.isEmpty) return {};

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
      }
    }
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