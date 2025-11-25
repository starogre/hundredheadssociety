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
                Navigator.of(context).pop();
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
                Navigator.of(context).pop();
                await _confirmBlockUser(context, blockService, authProvider);
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
                Navigator.of(context).pop();
                _showReportDialog(context, authProvider);
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await blockService.blockUser(
        blockedBy: authProvider.currentUser!.uid,
        blockedUser: targetUserId,
      );

      if (context.mounted) {
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
      if (context.mounted) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$targetUserName has been unblocked'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
        
        // Refresh the profile screen by popping and showing success
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
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
              reporterId: authProvider.currentUser!.uid,
              reporterName: authProvider.currentUser!.name,
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

