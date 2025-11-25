import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/block_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import 'report_dialog.dart';

class BlockOrReportDialog extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;
  final bool isCurrentlyBlocked;

  const BlockOrReportDialog({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.isCurrentlyBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final blockService = BlockService();

    return AlertDialog(
      title: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsDuotone.flag,
            color: AppColors.rustyOrange,
          ),
          const SizedBox(width: 12),
          const Text('User Actions'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Block/Unblock Option
          if (isCurrentlyBlocked)
            ElevatedButton.icon(
              onPressed: () async {
                // Don't close dialog yet
                await _unblockUser(context, blockService, authProvider);
              },
              icon: PhosphorIcon(PhosphorIconsDuotone.userCheck, color: Colors.white),
              label: Text('Unblock ${targetUserName}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () async {
                debugPrint('🔴 BLOCK BUTTON PRESSED for $targetUserName');
                // Don't close dialog yet - pass it to the function
                await _confirmBlockUser(context, blockService, authProvider);
                debugPrint('🔴 _confirmBlockUser completed');
              },
              icon: PhosphorIcon(PhosphorIconsDuotone.userMinus, color: Colors.white),
              label: Text('Block ${targetUserName}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Report Option (only if not currently blocked)
          if (!isCurrentlyBlocked)
            OutlinedButton.icon(
              onPressed: () {
                // Close dialog first, then show report dialog
                Navigator.of(context).pop();
                // Need a small delay to ensure dialog is closed
                Future.delayed(const Duration(milliseconds: 100), () {
                  _showReportDialog(context, authProvider);
                });
              },
              icon: PhosphorIcon(PhosphorIconsDuotone.warning, color: AppColors.rustyOrange),
              label: Text('Report ${targetUserName}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rustyOrange,
                side: BorderSide(color: AppColors.rustyOrange),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _confirmBlockUser(
    BuildContext context,
    BlockService blockService,
    AuthProvider authProvider,
  ) async {
    debugPrint('⚠️ CONFIRMATION: Showing confirmation dialog for $targetUserName');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block $targetUserName?'),
        content: Text(
          'You will no longer see their portraits, and they will not be able to see yours. '
          'You can unblock them later from their profile.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('⚠️ CONFIRMATION: User cancelled block');
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('⚠️ CONFIRMATION: User confirmed block');
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    debugPrint('⚠️ CONFIRMATION RESULT: confirmed=$confirmed, mounted=${context.mounted}');
    if (confirmed != true) {
      debugPrint('⚠️ CONFIRMATION: User cancelled - closing dialog');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close the main dialog
      }
      return;
    }

    if (!context.mounted) {
      debugPrint('⚠️ CONFIRMATION: Context unmounted - aborting');
      return;
    }

    debugPrint('🚫 BLOCKING: Starting block process...');
    debugPrint('🚫 Blocker ID: ${authProvider.currentUser!.uid}');
    debugPrint('🚫 Blocked User ID: $targetUserId');

    try {
      debugPrint('🚫 BLOCKING: Calling blockService.blockUser()...');
      await blockService.blockUser(
        blockedBy: authProvider.currentUser!.uid,
        blockedUser: targetUserId,
      );
      debugPrint('🚫 BLOCKING: Block successful!');

      if (context.mounted) {
        // Close the main dialog first
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$targetUserName has been blocked'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
        
        // Pop back to previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('🚫 BLOCKING ERROR: $e');
      debugPrint('🚫 BLOCKING ERROR TYPE: ${e.runtimeType}');
      if (context.mounted) {
        // Close the main dialog first
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unblockUser(
    BuildContext context,
    BlockService blockService,
    AuthProvider authProvider,
  ) async {
    try {
      await blockService.unblockUser(
        blockedBy: authProvider.currentUser!.uid,
        blockedUser: targetUserId,
      );

      if (context.mounted) {
        // Close the dialog first
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$targetUserName has been unblocked'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
        
        // Refresh the profile screen by popping
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        // Close the dialog first
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unblock user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context, AuthProvider authProvider) {
    final reportService = ReportService();
    
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        reportType: 'user',
        onSubmit: (reason, details) async {
          try {
            await reportService.reportUser(
              reporterUserId: authProvider.currentUser!.uid,
              reporterName: authProvider.userData?.name ?? authProvider.currentUser!.displayName ?? 'Unknown',
              reportedUserId: targetUserId,
              reportedUserName: targetUserName,
              reason: reason,
              details: details,
            );

            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted successfully'),
                  backgroundColor: AppColors.forestGreen,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to submit report: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

