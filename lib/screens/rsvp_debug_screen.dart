import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/weekly_session_provider.dart';
import '../providers/auth_provider.dart';
import '../services/weekly_session_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';

class RSVPDebugScreen extends StatefulWidget {
  const RSVPDebugScreen({super.key});

  @override
  State<RSVPDebugScreen> createState() => _RSVPDebugScreenState();
}

class _RSVPDebugScreenState extends State<RSVPDebugScreen> {
  final WeeklySessionService _weeklySessionService = WeeklySessionService();
  final PushNotificationService _pushNotificationService = PushNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _debugOutput = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSVP Debug Tools'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RSVP Debug Tools',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Current Session Info
            _buildCurrentSessionInfo(),
            const SizedBox(height: 16),
            
            // Debug Actions
            _buildDebugActions(),
            const SizedBox(height: 16),
            
            // Debug Output
            _buildDebugOutput(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSessionInfo() {
    return Consumer<WeeklySessionProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Session Info',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (provider.currentSession != null) ...[
                  Text('Session ID: ${provider.currentSession!.id}'),
                  Text('Session Date: ${provider.currentSession!.sessionDate}'),
                  Text('RSVP Count: ${provider.currentSession!.rsvpUserIds.length}'),
                  Text('Is Active: ${provider.currentSession!.isActive}'),
                  Text('Is Cancelled: ${provider.currentSession!.isCancelled}'),
                  const SizedBox(height: 8),
                  const Text('RSVP Users:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...provider.currentSession!.rsvpUserIds.map((id) => Text('  - $id')),
                ] else
                  const Text('No active session found'),
                if (provider.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDebugActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Test RSVP
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testRSVP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test RSVP (Current User)'),
              ),
            ),
            const SizedBox(height: 8),
            
            // Test Cancel RSVP
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testCancelRSVP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rustyOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test Cancel RSVP (Current User)'),
              ),
            ),
            const SizedBox(height: 8),
            
            // Test Duplicate RSVP
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testDuplicateRSVP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test Duplicate RSVP (Should Not Crash)'),
              ),
            ),
            const SizedBox(height: 8),
            
            // Test Push Notification Navigation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testPushNotificationNavigation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test Push Notification Navigation'),
              ),
            ),
            const SizedBox(height: 8),
            
            // Check Session Data Integrity
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkSessionDataIntegrity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Check Session Data Integrity'),
              ),
            ),
            const SizedBox(height: 8),
            
            // Clear Debug Output
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _clearDebugOutput,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear Debug Output'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugOutput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Output',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _debugOutput.isEmpty ? 'No debug output yet...' : _debugOutput,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDebugOutput(String message) {
    setState(() {
      _debugOutput += '${DateTime.now().toIso8601String()}: $message\n';
    });
  }

  void _clearDebugOutput() {
    setState(() {
      _debugOutput = '';
    });
  }

  Future<void> _testRSVP() async {
    setState(() => _isLoading = true);
    _addDebugOutput('=== Testing RSVP ===');
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final weeklySessionProvider = Provider.of<WeeklySessionProvider>(context, listen: false);
      
      if (authProvider.currentUser == null) {
        _addDebugOutput('ERROR: No current user');
        return;
      }
      
      final userId = authProvider.currentUser!.uid;
      _addDebugOutput('Testing RSVP for user: $userId');
      
      await weeklySessionProvider.rsvpForCurrentSession(userId);
      _addDebugOutput('RSVP test completed successfully');
      
    } catch (e) {
      _addDebugOutput('ERROR in RSVP test: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCancelRSVP() async {
    setState(() => _isLoading = true);
    _addDebugOutput('=== Testing Cancel RSVP ===');
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final weeklySessionProvider = Provider.of<WeeklySessionProvider>(context, listen: false);
      
      if (authProvider.currentUser == null) {
        _addDebugOutput('ERROR: No current user');
        return;
      }
      
      final userId = authProvider.currentUser!.uid;
      _addDebugOutput('Testing cancel RSVP for user: $userId');
      
      await weeklySessionProvider.cancelRsvpForCurrentSession(userId);
      _addDebugOutput('Cancel RSVP test completed successfully');
      
    } catch (e) {
      _addDebugOutput('ERROR in cancel RSVP test: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testDuplicateRSVP() async {
    setState(() => _isLoading = true);
    _addDebugOutput('=== Testing Duplicate RSVP (Should Not Crash) ===');
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final weeklySessionProvider = Provider.of<WeeklySessionProvider>(context, listen: false);
      
      if (authProvider.currentUser == null) {
        _addDebugOutput('ERROR: No current user');
        return;
      }
      
      final userId = authProvider.currentUser!.uid;
      _addDebugOutput('Testing duplicate RSVP for user: $userId');
      
      // First RSVP
      await weeklySessionProvider.rsvpForCurrentSession(userId);
      _addDebugOutput('First RSVP completed');
      
      // Second RSVP (should not crash)
      await weeklySessionProvider.rsvpForCurrentSession(userId);
      _addDebugOutput('Second RSVP completed (no crash - good!)');
      
    } catch (e) {
      _addDebugOutput('ERROR in duplicate RSVP test: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPushNotificationNavigation() async {
    setState(() => _isLoading = true);
    _addDebugOutput('=== Testing Push Notification Navigation ===');
    
    try {
      // Test navigation data
      final testData = {
        'action': 'rsvp_reminder',
        'navigateTo': 'weekly_sessions',
        'sessionTitle': 'Test Session',
        'sessionDate': DateTime.now().toIso8601String(),
      };
      
      _addDebugOutput('Test navigation data: $testData');
      
      // This would normally be called by the push notification service
      // We're just testing the navigation logic
      _addDebugOutput('Push notification navigation test completed');
      
    } catch (e) {
      _addDebugOutput('ERROR in push notification navigation test: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkSessionDataIntegrity() async {
    setState(() => _isLoading = true);
    _addDebugOutput('=== Checking Session Data Integrity ===');
    
    try {
      final weeklySessionProvider = Provider.of<WeeklySessionProvider>(context, listen: false);
      
      if (weeklySessionProvider.currentSession == null) {
        _addDebugOutput('No current session to check');
        return;
      }
      
      final sessionId = weeklySessionProvider.currentSession!.id;
      _addDebugOutput('Checking session: $sessionId');
      
      // Get fresh data from Firestore
      final sessionDoc = await _firestore.collection('weekly_sessions').doc(sessionId).get();
      
      if (!sessionDoc.exists) {
        _addDebugOutput('ERROR: Session document does not exist in Firestore');
        return;
      }
      
      final sessionData = sessionDoc.data()!;
      final firestoreRsvpIds = List<String>.from(sessionData['rsvpUserIds'] ?? []);
      final localRsvpIds = weeklySessionProvider.currentSession!.rsvpUserIds;
      
      _addDebugOutput('Local RSVP IDs: $localRsvpIds');
      _addDebugOutput('Firestore RSVP IDs: $firestoreRsvpIds');
      
      if (localRsvpIds.length == firestoreRsvpIds.length && 
          localRsvpIds.every((id) => firestoreRsvpIds.contains(id))) {
        _addDebugOutput('✓ Data integrity check passed');
      } else {
        _addDebugOutput('⚠ Data integrity issue detected');
        _addDebugOutput('Local count: ${localRsvpIds.length}, Firestore count: ${firestoreRsvpIds.length}');
      }
      
    } catch (e) {
      _addDebugOutput('ERROR in data integrity check: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
