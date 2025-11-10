import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bulk_upload_service.dart';
import '../theme/app_theme.dart';

class UploadProgressBar extends StatelessWidget {
  const UploadProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BulkUploadService>(
      builder: (context, uploadService, child) {
        // Don't show if no active upload
        if (!uploadService.hasItems) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDetailedProgress(context, uploadService),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Icon
                    if (uploadService.isUploading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    const SizedBox(width: 12),
                    
                    // Text and progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            uploadService.isUploading
                                ? 'Uploading ${uploadService.completedCount} of ${uploadService.totalCount} portraits...'
                                : 'Upload complete! ${uploadService.completedCount} portraits uploaded',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: uploadService.progress,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mintGreen),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Chevron or close button
                    if (uploadService.isUploading)
                      const Icon(
                        Icons.expand_less,
                        color: Colors.white,
                        size: 24,
                      )
                    else
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => uploadService.clearQueue(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetailedProgress(BuildContext context, BulkUploadService uploadService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upload Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      if (!uploadService.isUploading)
                        TextButton(
                          onPressed: () {
                            uploadService.clearQueue();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Upload list
                Expanded(
                  child: Consumer<BulkUploadService>(
                    builder: (context, service, child) {
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: service.totalCount,
                        itemBuilder: (context, index) {
                          final item = service.uploadQueue[index];
                          return _buildUploadItem(item, index + 1);
                        },
                      );
                    },
                  ),
                ),
                
                // Actions
                if (uploadService.isUploading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          uploadService.cancelUpload();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel Upload'),
                      ),
                    ),
                  )
                else
                  Consumer<BulkUploadService>(
                    builder: (context, service, child) {
                      final summary = service.getUploadSummary();
                      final hasFailed = (summary['failed'] ?? 0) > 0;
                      
                      if (!hasFailed) {
                        return const SizedBox.shrink();
                      }
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(top: BorderSide(color: Colors.grey[300]!)),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              service.retryFailed();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Retry Failed (${summary['failed']})'),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadItem(PortraitUploadItem item, int number) {
    IconData icon;
    Color iconColor;
    String statusText;

    switch (item.status) {
      case UploadStatus.completed:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        statusText = 'Uploaded';
        break;
      case UploadStatus.uploading:
        icon = Icons.upload;
        iconColor = AppColors.forestGreen;
        statusText = 'Uploading...';
        break;
      case UploadStatus.error:
        icon = Icons.error;
        iconColor = Colors.red;
        statusText = 'Failed';
        break;
      case UploadStatus.idle:
      default:
        icon = Icons.hourglass_empty;
        iconColor = Colors.grey;
        statusText = 'Waiting...';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Image thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              item.imageFile,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portrait #$number - Week ${item.weekNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.description != null && item.description!.isNotEmpty)
                  Text(
                    item.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (item.errorMessage != null)
                  Text(
                    item.errorMessage!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Status icon
          Column(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

