import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/user_data_repair_service.dart';
import '../theme/app_theme.dart';

class UserDataRepairScreen extends StatefulWidget {
  const UserDataRepairScreen({super.key});

  @override
  State<UserDataRepairScreen> createState() => _UserDataRepairScreenState();
}

class _UserDataRepairScreenState extends State<UserDataRepairScreen> {
  final UserDataRepairService _repairService = UserDataRepairService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _restoreAdmin = false;
  bool _restoreModerator = false;
  UserDataConsistencyCheck? _consistencyCheck;
  UserDataRepairResult? _repairResult;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current user's email if available
    final currentUser = Provider.of<AuthProvider>(context, listen: false).userData;
    if (currentUser != null) {
      _emailController.text = currentUser.email;
      _nameController.text = currentUser.name;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkConsistency() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter an email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _consistencyCheck = null;
    });

    try {
      // Find user by email first
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _showError('No user found with that email address');
        return;
      }

      final userId = userQuery.docs.first.id;
      final check = await _repairService.checkUserDataConsistency(userId);
      
      setState(() {
        _consistencyCheck = check;
      });
    } catch (e) {
      _showError('Error checking consistency: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _repairUserData() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter an email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _repairResult = null;
    });

    try {
      final result = await _repairService.repairUserDataByEmail(
        email: _emailController.text.trim(),
        restoreAdmin: _restoreAdmin,
        restoreModerator: _restoreModerator,
        correctName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      );

      setState(() {
        _repairResult = result;
      });

      if (result.success) {
        _showSuccess('User data repair completed successfully!');
        // Refresh consistency check
        await _checkConsistency();
      } else {
        _showError('Repair failed: ${result.message}');
      }
    } catch (e) {
      _showError('Error during repair: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.forestGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Data Repair'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: AppColors.lightCream,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.build, color: AppColors.forestGreen, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'User Data Repair Tool',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This tool can repair user data inconsistencies that may occur when user documents are overwritten or corrupted.',
                      style: TextStyle(color: AppColors.forestGreen.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Input Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        border: OutlineInputBorder(),
                        hintText: 'user@example.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Correct Name (optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Leave empty to keep current name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Restore Privileges:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Restore Admin Privileges'),
                      subtitle: const Text('Grant admin access to the user'),
                      value: _restoreAdmin,
                      onChanged: (value) {
                        setState(() {
                          _restoreAdmin = value ?? false;
                        });
                      },
                      activeColor: AppColors.forestGreen,
                    ),
                    CheckboxListTile(
                      title: const Text('Restore Moderator Privileges'),
                      subtitle: const Text('Grant moderator access to the user'),
                      value: _restoreModerator,
                      onChanged: (value) {
                        setState(() {
                          _restoreModerator = value ?? false;
                        });
                      },
                      activeColor: AppColors.forestGreen,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkConsistency,
                    icon: const Icon(Icons.search),
                    label: const Text('Check Consistency'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _repairUserData,
                    icon: const Icon(Icons.build),
                    label: const Text('Repair Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rustyOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                        ),
                        SizedBox(height: 16),
                        Text('Processing...'),
                      ],
                    ),
                  ),
                ),
              ),

            // Consistency Check Results
            if (_consistencyCheck != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _consistencyCheck!.hasIssues ? Icons.warning : Icons.check_circle,
                            color: _consistencyCheck!.hasIssues ? Colors.orange : AppColors.forestGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Consistency Check Results',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Total Portraits Found', '${_consistencyCheck!.totalPortraits}'),
                      _buildInfoRow('User Portrait Count', '${_consistencyCheck!.userPortraitCount}'),
                      _buildInfoRow('User Portrait IDs', '${_consistencyCheck!.userPortraitIds}'),
                      _buildInfoRow('Portrait Count Match', _consistencyCheck!.portraitCountMismatch ? '❌ No' : '✅ Yes'),
                      _buildInfoRow('Portrait IDs Match', _consistencyCheck!.portraitIdsMismatch ? '❌ No' : '✅ Yes'),
                      if (_consistencyCheck!.issues.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Issues Found:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._consistencyCheck!.issues.map((issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $issue', style: const TextStyle(color: Colors.red)),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Repair Results
            if (_repairResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _repairResult!.success ? Icons.check_circle : Icons.error,
                            color: _repairResult!.success ? AppColors.forestGreen : Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Repair Results',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _repairResult!.message,
                        style: TextStyle(
                          color: _repairResult!.success ? AppColors.forestGreen : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Portraits Found', '${_repairResult!.portraitsFound}'),
                      _buildInfoRow('Portraits Repaired', '${_repairResult!.portraitsRepaired}'),
                      _buildInfoRow('Admin Restored', _repairResult!.adminRestored ? '✅ Yes' : '❌ No'),
                      _buildInfoRow('Moderator Restored', _repairResult!.moderatorRestored ? '✅ Yes' : '❌ No'),
                      _buildInfoRow('Name Updated', _repairResult!.nameUpdated ? '✅ Yes' : '❌ No'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
