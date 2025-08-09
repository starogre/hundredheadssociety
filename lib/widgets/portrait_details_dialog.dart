import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/portrait_model.dart';
import '../models/user_model.dart';
import '../models/model_model.dart';
import '../theme/app_theme.dart';
import '../screens/edit_portrait_screen.dart';
import '../screens/profile_screen.dart';
import '../services/portrait_service.dart';
import '../services/award_service.dart';
import '../providers/model_provider.dart';

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
  final AwardService _awardService = AwardService();
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
          GestureDetector(
            onTap: () => _showFullImage(context),
            child: Container(
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
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artist section - most prominent at top
                GestureDetector(
                  onTap: () => _navigateToProfile(context),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.forestGreen,
                        backgroundImage: widget.user?.profileImageUrl != null 
                            ? NetworkImage(widget.user!.profileImageUrl!)
                            : null,
                        child: widget.user?.profileImageUrl == null
                            ? Text(
                                widget.user?.name.isNotEmpty == true ? widget.user!.name[0].toUpperCase() : 'A',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user?.name ?? 'Anonymous',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.forestGreen,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (widget.user != null) ...[
                            const SizedBox(height: 2),
                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.user!.isArtist 
                                    ? Colors.blue.shade100 
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.user!.isArtist 
                                      ? Colors.blue.shade300 
                                      : Colors.green.shade300,
                                ),
                              ),
                              child: Text(
                                widget.user!.isArtist ? 'Artist' : 'Appreciator',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: widget.user!.isArtist 
                                      ? Colors.blue.shade700 
                                      : Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                ),
                const SizedBox(height: 16),
                // Model section - below artist
                if (widget.portrait.modelName != null && widget.portrait.modelName!.isNotEmpty) ...[
                  Consumer<ModelProvider>(
                    builder: (context, modelProvider, child) {
                      return StreamBuilder<List<ModelModel>>(
                        stream: modelProvider.getModels(),
                        builder: (context, snapshot) {
                          ModelModel? model;
                          if (snapshot.hasData) {
                            model = snapshot.data!.firstWhere(
                              (m) => m.name.toLowerCase() == widget.portrait.modelName!.toLowerCase(),
                              orElse: () => ModelModel(
                                id: '',
                                name: widget.portrait.modelName!,
                                date: DateTime.now(),
                                isActive: true,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            );
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Model image
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: AppColors.forestGreen, width: 1.5),
                                    ),
                                    child: model?.imageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(16.5),
                                            child: Image.network(
                                              model!.imageUrl!,
                                              width: 36,
                                              height: 36,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: AppColors.forestGreen,
                                                    borderRadius: BorderRadius.circular(16.5),
                                                  ),
                                                  child: const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.forestGreen,
                                              borderRadius: BorderRadius.circular(16.5),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Model name
                                  Expanded(
                                    child: Text(
                                      widget.portrait.modelName!,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.forestGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Model date - smaller and below
                              if (model != null) ...[
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 48),
                                                                     child: Text(
                                     'Modeled ${_formatDate(model.date)}',
                                     style: TextStyle(
                                       fontSize: 14,
                                       color: AppColors.forestGreen.withValues(alpha: 0.6),
                                       fontStyle: FontStyle.italic,
                                     ),
                                   ),
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Awards section
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _awardService.getPortraitAwards(widget.portrait.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      final awardDetails = _awardService.getAwardDetails();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color: AppColors.rustyOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Awards Won',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.rustyOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...snapshot.data!.map((award) {
                            final category = award['category'] as String;
                            final details = awardDetails[category];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.rustyOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.rustyOrange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    details?['emoji'] ?? '🏆',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          details?['title'] ?? category,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.rustyOrange,
                                          ),
                                        ),
                                        Text(
                                          '${award['votes']} votes',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.rustyOrange.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Description section - at the bottom
                if (widget.portrait.description != null && widget.portrait.description!.isNotEmpty) ...[
                  Text(
                    widget.portrait.description!,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.forestGreen.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Model name section

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

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Full size image
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: widget.portrait.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    if (widget.user != null) {
      Navigator.of(context).pop(); // Close the portrait details dialog
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: widget.user!.id),
        ),
      );
    }
  }
} 