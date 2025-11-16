import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/portrait_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/weekly_session_provider.dart';
import '../providers/model_provider.dart';
import '../models/portrait_model.dart';
import '../models/model_model.dart';
import '../theme/app_theme.dart';
import '../screens/add_portrait_screen.dart';

class SubmitPortraitDialog extends StatefulWidget {
  final DateTime sessionDate;

  const SubmitPortraitDialog({
    super.key,
    required this.sessionDate,
  });

  @override
  State<SubmitPortraitDialog> createState() => _SubmitPortraitDialogState();
}

class _SubmitPortraitDialogState extends State<SubmitPortraitDialog> {
  final _artistNotesController = TextEditingController();
  bool _isSubmitting = false;
  PortraitModel? _autoSelectedPortrait;
  ModelModel? _sessionModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _findPortraitForSession();
  }

  @override
  void dispose() {
    _artistNotesController.dispose();
    super.dispose();
  }

  Future<void> _findPortraitForSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final portraitProvider = Provider.of<PortraitProvider>(context, listen: false);
    final modelProvider = Provider.of<ModelProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Get the model for this session date
      final modelsStream = modelProvider.getModels();
      final models = await modelsStream.first;
      
      // Sort models by date
      final sortedModels = models.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      
      // Find the model that is currently active
      // A model is active from its date at 6pm until the next model's date at 6pm
      final now = DateTime.now();
      
      ModelModel? foundModel;
      
      // Start from the end and work backwards to find the most recent model
      // whose 6pm start time has passed
      for (int i = sortedModels.length - 1; i >= 0; i--) {
        final modelStartTime = DateTime(
          sortedModels[i].date.year,
          sortedModels[i].date.month,
          sortedModels[i].date.day,
          18, // 6pm
          0,
        );
        
        // If we've passed this model's start time, this is the active model
        if (now.isAfter(modelStartTime) || now.isAtSameMomentAs(modelStartTime)) {
          foundModel = sortedModels[i];
          break;
        }
      }
      
      // If no model found (current time is before all models), use the first model
      _sessionModel = foundModel ?? sortedModels.first;

      // Get user's portraits
      final portraitsStream = portraitProvider.getUserPortraits(userId);
      final portraits = await portraitsStream.first;

      // Find portrait with matching model name
      if (_sessionModel != null && portraits.isNotEmpty) {
        _autoSelectedPortrait = portraits.cast<PortraitModel?>().firstWhere(
          (portrait) =>
              portrait?.modelName?.toLowerCase() == _sessionModel!.name.toLowerCase(),
          orElse: () => null,
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error finding portrait for session: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final weeklySessionProvider = Provider.of<WeeklySessionProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    return AlertDialog(
      title: const Text('Submit Your Painting'),
      content: SizedBox(
        width: 400,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Model info section
                    if (_sessionModel != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.forestGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.forestGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_sessionModel!.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: _sessionModel!.imageUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    width: 48,
                                    height: 48,
                                    color: AppColors.forestGreen.withOpacity(0.2),
                                    child: PhosphorIcon(
                                      PhosphorIconsDuotone.user,
                                      color: AppColors.forestGreen,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: PhosphorIcon(
                                  PhosphorIconsDuotone.user,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'This Week\'s Model',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _sessionModel!.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.forestGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Portrait preview or add prompt
                    if (_autoSelectedPortrait != null) ...[
                      const Text(
                        'Your Portrait:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: _autoSelectedPortrait!.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Week ${_autoSelectedPortrait!.weekNumber}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.forestGreen,
                                    ),
                                  ),
                                  if (_autoSelectedPortrait!.modelName != null)
                                    Text(
                                      _autoSelectedPortrait!.modelName!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // No portrait found - show prompt to add
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            PhosphorIcon(
                              PhosphorIconsDuotone.paintBrush,
                              size: 40,
                              color: AppColors.rustyOrange,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No portrait found for ${_sessionModel?.name ?? "this week\'s model"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.forestGreen,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please add a portrait for this week before submitting.',
                              style: TextStyle(fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => AddPortraitScreen(
                                      userId: userId!,
                                      nextWeekNumber: authProvider.userData?.portraitsCompleted ?? 0 + 1,
                                    ),
                                  ),
                                );
                              },
                              icon: PhosphorIcon(PhosphorIconsDuotone.plus, size: 18),
                              label: const Text('Add Portrait'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.rustyOrange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_autoSelectedPortrait != null) ...[
                      const SizedBox(height: 16),
                      const Text('Artist Notes (optional):'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _artistNotesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Add any notes about your painting...',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting || _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_autoSelectedPortrait != null)
          ElevatedButton(
            onPressed: _isSubmitting || _isLoading
                ? null
                : () async {
                    setState(() {
                      _isSubmitting = true;
                    });
                    try {
                      await weeklySessionProvider.submitPortraitForCurrentSession(
                        userId!,
                        _autoSelectedPortrait!,
                        _artistNotesController.text.trim().isEmpty
                            ? null
                            : _artistNotesController.text.trim(),
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Submission successful!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to submit: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSubmitting = false;
                        });
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit'),
          ),
      ],
    );
  }
}
