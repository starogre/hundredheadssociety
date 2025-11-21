import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final ReportService _reportService = ReportService();
  String _filter = 'pending'; // 'all' or 'pending'

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Reports'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending Only'),
              ),
              const PopupMenuItem(
                value: 'all',
                child: Text('All Reports'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _filter == 'pending' 
            ? _reportService.getPendingReports()
            : _reportService.getAllReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading reports: ${snapshot.error}'),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(
                    PhosphorIconsDuotone.checkCircle,
                    size: 64,
                    color: AppColors.forestGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filter == 'pending' 
                        ? 'No pending reports'
                        : 'No reports yet',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reports from users will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(report, authProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, AuthProvider authProvider) {
    final reportType = report['reportType'] as String;
    final status = report['status'] as String;
    final reason = report['reason'] as String;
    final reportedUserName = report['reportedUserName'] as String;
    final reporterName = report['reporterName'] as String;
    final createdAt = report['createdAt'];
    final details = report['details'] as String?;

    // Format date
    String formattedDate = 'Unknown date';
    if (createdAt != null) {
      try {
        final dateTime = createdAt.toDate();
        formattedDate = DateFormat('MMM d, y - h:mm a').format(dateTime);
      } catch (e) {
        formattedDate = 'Invalid date';
      }
    }

    // Status color
    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'reviewing':
        statusColor = Colors.blue;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'dismissed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Report type icon
    IconData typeIcon;
    String typeLabel;
    switch (reportType) {
      case 'portrait':
        typeIcon = PhosphorIconsDuotone.image;
        typeLabel = 'Portrait';
        break;
      case 'user':
        typeIcon = PhosphorIconsDuotone.user;
        typeLabel = 'User';
        break;
      case 'submission':
        typeIcon = PhosphorIconsDuotone.paperPlane;
        typeLabel = 'Submission';
        break;
      default:
        typeIcon = PhosphorIconsDuotone.flag;
        typeLabel = 'Content';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status == 'pending' ? Colors.orange.withOpacity(0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PhosphorIcon(typeIcon, size: 24, color: AppColors.forestGreen),
                ),
                const SizedBox(width: 12),
                
                // Type and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Reported user
            _buildInfoRow(
              icon: PhosphorIconsDuotone.userCircle,
              label: 'Reported User',
              value: reportedUserName,
            ),
            
            const SizedBox(height: 8),
            
            // Reporter
            _buildInfoRow(
              icon: PhosphorIconsDuotone.flag,
              label: 'Reporter',
              value: reporterName,
            ),
            
            const SizedBox(height: 8),
            
            // Reason
            _buildInfoRow(
              icon: PhosphorIconsDuotone.warning,
              label: 'Reason',
              value: reason,
            ),
            
            if (details != null && details.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: PhosphorIconsDuotone.note,
                label: 'Details',
                value: details,
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Date
            _buildInfoRow(
              icon: PhosphorIconsDuotone.clock,
              label: 'Reported',
              value: formattedDate,
            ),
            
            // Action buttons (only for pending)
            if (status == 'pending') ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _dismissReport(report['id'], authProvider),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Dismiss'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _resolveReport(report['id'], authProvider),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Resolve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Delete button (only for resolved/dismissed)
            if (status != 'pending' && authProvider.userData?.isAdmin == true) ...[
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteReport(report['id']),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhosphorIcon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _dismissReport(String reportId, AuthProvider authProvider) async {
    try {
      await _reportService.updateReportStatus(
        reportId: reportId,
        status: 'dismissed',
        reviewedBy: authProvider.currentUser!.uid,
        resolution: 'Dismissed by moderator',
        actionTaken: 'none',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report dismissed'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error dismissing report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resolveReport(String reportId, AuthProvider authProvider) async {
    try {
      await _reportService.updateReportStatus(
        reportId: reportId,
        status: 'resolved',
        reviewedBy: authProvider.currentUser!.uid,
        resolution: 'Reviewed and action taken',
        actionTaken: 'reviewed',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report resolved'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resolving report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteReport(String reportId) async {
    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text('This will permanently delete this report. This action cannot be undone.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _reportService.deleteReport(reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

