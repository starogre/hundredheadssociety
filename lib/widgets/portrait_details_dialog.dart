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

import '../providers/model_provider.dart';
import '../services/award_service.dart';
import '../services/instagram_sharing_service.dart';

class PortraitDetailsDialog extends StatefulWidget {
  final PortraitModel portrait;
  final UserModel? user;
  final String currentUserId;
  final VoidCallback? onPortraitModified;
  final List<PortraitModel>? allPortraits; // For navigation
  final int? initialIndex; // Starting position in allPortraits

  const PortraitDetailsDialog({
    super.key,
    required this.portrait,
    this.user,
    required this.currentUserId,
    this.onPortraitModified,
    this.allPortraits,
    this.initialIndex,
  });

  @override
  State<PortraitDetailsDialog> createState() => _PortraitDetailsDialogState();
}

class _PortraitDetailsDialogState extends State<PortraitDetailsDialog> {
  bool _showDeleteConfirmation = false;
  bool _isDeleting = false;
  final AwardService _awardService = AwardService();
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
  }
  
  PortraitModel get _currentPortrait {
    if (widget.allPortraits != null && widget.allPortraits!.isNotEmpty) {
      return widget.allPortraits![_currentIndex];
    }
    return widget.portrait;
  }
  
  bool get _canNavigatePrevious => widget.allPortraits != null && _currentIndex > 0;
  bool get _canNavigateNext => widget.allPortraits != null && _currentIndex < (widget.allPortraits!.length - 1);
  
  void _navigatePrevious() {
    if (_canNavigatePrevious) {
      setState(() {
        _currentIndex--;
        _showDeleteConfirmation = false;
      });
    }
  }
  
  void _navigateNext() {
    if (_canNavigateNext) {
      setState(() {
        _currentIndex++;
        _showDeleteConfirmation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = widget.user?.id == widget.currentUserId;
    
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showFullImage(context),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 300,
                    child: CachedNetworkImage(
                      imageUrl: _currentPortrait.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
              // Navigation arrows
              if (_canNavigatePrevious)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: _navigatePrevious,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_canNavigateNext)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: _navigateNext,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              // Portrait counter
              if (widget.allPortraits != null && widget.allPortraits!.length > 1)
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.allPortraits!.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _showDeleteConfirmation
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              'Are you sure you want to delete this portrait? This can\'t be undone.',
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
                  )
                : Column(
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
                            ...(widget.user != null ? [
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
                            ] : []),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Model section - below artist
                ...(_currentPortrait.modelName != null && _currentPortrait.modelName!.isNotEmpty ? [
                  Consumer<ModelProvider>(
                    builder: (context, modelProvider, child) {
                      return StreamBuilder<List<ModelModel>>(
                        stream: modelProvider.getModels(),
                        builder: (context, snapshot) {
                          ModelModel? model;
                          if (snapshot.hasData) {
                            model = snapshot.data!.firstWhere(
                              (m) => m.name.toLowerCase() == _currentPortrait.modelName!.toLowerCase(),
                              orElse: () => ModelModel(
                                id: '',
                                name: _currentPortrait.modelName!,
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
                                      _currentPortrait.modelName!,
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
                              ...(model != null ? [
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
                              ] : []),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ] : []),
                // Description section - at the bottom
                ...(_currentPortrait.description != null && _currentPortrait.description!.isNotEmpty ? [
                  Text(
                    _currentPortrait.description!,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.forestGreen.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] : []),
                // Model name section

                // Awards section
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _awardService.getPortraitAwards(_currentPortrait.id),
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
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                      // Action buttons at the bottom
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Share button - available to everyone
                          IconButton(
                            onPressed: () => _sharePortrait(context),
                            icon: const Icon(Icons.share, color: AppColors.rustyOrange),
                            tooltip: 'Share',
                          ),
                          ...(isOwner ? [
                            IconButton(
                              onPressed: () => _editPortrait(context),
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showDeleteConfirmation = true;
                                });
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                            ),
                          ] : []),
                        ],
                      ),
                    ],
                  ),
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
          portrait: _currentPortrait,
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
      await portraitService.deletePortrait(_currentPortrait.id, widget.currentUserId);
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
                  imageUrl: _currentPortrait.imageUrl,
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

  Future<void> _sharePortrait(BuildContext context) async {
    if (widget.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to share: Artist information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get awards for this portrait
      final List<Map<String, dynamic>> awards = await _awardService.getPortraitAwards(_currentPortrait.id);
      final List<String> awardCategories = awards.map((award) => award['category'] as String).toList();
      
      // Get artist's Instagram handle
      final String? artistInstagram = widget.user!.instagram;
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Share to Instagram
      await InstagramSharingService.sharePortraitToInstagram(
        portrait: _currentPortrait,
        artist: widget.user!,
        awards: awardCategories.isNotEmpty ? awardCategories : null,
        artistInstagram: artistInstagram,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portrait shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share portrait: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 