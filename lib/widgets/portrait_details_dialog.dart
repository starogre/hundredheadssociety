import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/portrait_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../screens/edit_portrait_screen.dart';
import '../services/portrait_service.dart';
import 'dart:io';

class PortraitDetailsDialog extends StatefulWidget {
  final PortraitModel portrait;
  final UserModel? user;
  final String currentUserId;
  final VoidCallback? onPortraitModified;

  const PortraitDetailsDialog({
    super.key,
    required this.portrait,
    this.user,
    required this.currentUserId,
    this.onPortraitModified,
  });

  @override
  State<PortraitDetailsDialog> createState() => _PortraitDetailsDialogState();
}

class _PortraitDetailsDialogState extends State<PortraitDetailsDialog> {
  bool _showDeleteConfirmation = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final bool isOwner = widget.user?.id == widget.currentUserId;
    
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              image: DecorationImage(
                image: CachedNetworkImageProvider(widget.portrait.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.portrait.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isOwner && !_showDeleteConfirmation) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editPortrait(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _showDeleteConfirmation = true;
                          });
                        },
                      ),
                    ],
                  ],
                ),
                if (widget.portrait.description != null && widget.portrait.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.portrait.description!,
                    style: TextStyle(
                      color: AppColors.forestGreen.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.forestGreen,
                      backgroundImage: widget.user?.profileImageUrl != null 
                          ? NetworkImage(widget.user!.profileImageUrl!)
                          : null,
                      child: widget.user?.profileImageUrl == null
                          ? Text(
                              widget.user?.name.isNotEmpty == true ? widget.user!.name[0].toUpperCase() : 'A',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.user?.name ?? 'Anonymous',
                        style: TextStyle(
                          color: AppColors.forestGreen.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Week ${widget.portrait.weekNumber}',
                      style: TextStyle(
                        color: AppColors.rustyOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Delete confirmation section
                if (_showDeleteConfirmation) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Delete Portrait',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Are you sure you want to delete "${widget.portrait.title}"? This action cannot be undone.',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isDeleting ? null : () {
                                setState(() {
                                  _showDeleteConfirmation = false;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isDeleting ? null : _deletePortrait,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: _isDeleting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editPortrait(BuildContext context) {
    Navigator.of(context).pop(); // Close the details dialog
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditPortraitScreen(
          portrait: widget.portrait,
          onPortraitUpdated: () {
            widget.onPortraitModified?.call();
            // Show success message after returning from edit screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Portrait updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _deletePortrait() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final portraitService = PortraitService();
      await portraitService.deletePortrait(widget.portrait.id, widget.currentUserId);
      widget.onPortraitModified?.call();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close details dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portrait deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete portrait: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _showDeleteConfirmation = false;
        });
      }
    }
  }
} 