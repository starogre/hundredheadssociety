import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/portrait_service.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userData;
  final String userId;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.userData,
    required this.userId,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final PortraitService _portraitService = PortraitService();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      if (widget.userData.profileImageUrl != null)
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: CachedNetworkImageProvider(widget.userData.profileImageUrl!),
                        )
                      else
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.forestGreen.withOpacity(0.1),
                          child: Text(
                            widget.userData.name.isNotEmpty ? widget.userData.name[0].toUpperCase() : 'A',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadProfileImage,
                    icon: PhosphorIcon(PhosphorIconsDuotone.camera),
                    label: const Text('Change Picture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name Section
            _buildSectionHeader('Name'),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: PhosphorIconsDuotone.user,
              value: widget.userData.name.isNotEmpty ? widget.userData.name : 'No name set',
              isEmpty: widget.userData.name.isEmpty,
            ),
            const SizedBox(height: 12),
            _buildEditButton(
              label: 'Edit Name',
              icon: PhosphorIconsDuotone.pencil,
              onPressed: () => _editName(),
            ),
            const SizedBox(height: 24),

            // Instagram Section
            _buildSectionHeader('Instagram Handle'),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: PhosphorIconsDuotone.instagramLogo,
              value: widget.userData.instagram?.isNotEmpty == true
                  ? '@${widget.userData.instagram!.replaceAll('@', '')}'
                  : 'No Instagram handle set',
              isEmpty: widget.userData.instagram?.isEmpty ?? true,
            ),
            const SizedBox(height: 12),
            _buildEditButton(
              label: 'Edit Instagram',
              icon: PhosphorIconsDuotone.pencil,
              onPressed: () => _editInstagram(),
            ),
            const SizedBox(height: 24),

            // Email Section
            _buildSectionHeader('Contact Email'),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: PhosphorIconsDuotone.envelope,
              value: widget.userData.contactEmail?.isNotEmpty == true
                  ? widget.userData.contactEmail!
                  : widget.userData.email,
              isEmpty: false,
            ),
            const SizedBox(height: 12),
            _buildEditButton(
              label: 'Edit Email',
              icon: PhosphorIconsDuotone.pencil,
              onPressed: () => _editEmail(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: AppColors.forestGreen,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String value,
    required bool isEmpty,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          PhosphorIcon(icon, color: AppColors.forestGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: isEmpty ? Colors.grey[600] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: PhosphorIcon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forestGreen,
          side: BorderSide(color: AppColors.forestGreen),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        final imageUrl = await _portraitService.uploadPortraitImage(
          File(pickedFile.path),
          widget.userId,
        );

        await _userService.updateUserProfile(
          userId: widget.userId,
          profileImageUrl: imageUrl,
        );

        widget.onProfileUpdated();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: AppColors.forestGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  Future<void> _editName() async {
    final newName = await _showEditDialog(
      title: 'Edit Name',
      initialValue: widget.userData.name,
      hintText: 'Enter your name',
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        await _userService.updateUserProfile(
          userId: widget.userId,
          name: newName,
        );

        widget.onProfileUpdated();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name updated!'),
              backgroundColor: AppColors.forestGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update name: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editInstagram() async {
    final newHandle = await _showEditDialog(
      title: 'Edit Instagram',
      initialValue: widget.userData.instagram ?? '',
      hintText: 'Enter Instagram handle',
      prefixText: '@',
    );

    if (newHandle != null) {
      try {
        await _userService.updateUserProfile(
          userId: widget.userId,
          instagram: newHandle,
        );

        widget.onProfileUpdated();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Instagram handle updated!'),
              backgroundColor: AppColors.forestGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update Instagram: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editEmail() async {
    final newEmail = await _showEditDialog(
      title: 'Edit Contact Email',
      initialValue: widget.userData.contactEmail ?? widget.userData.email,
      hintText: 'Enter contact email',
    );

    if (newEmail != null && newEmail.isNotEmpty) {
      try {
        await _userService.updateUserProfile(
          userId: widget.userId,
          contactEmail: newEmail,
        );

        widget.onProfileUpdated();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact email updated!'),
              backgroundColor: AppColors.forestGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update email: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<String?> _showEditDialog({
    required String title,
    required String initialValue,
    required String hintText,
    String? prefixText,
  }) async {
    final controller = TextEditingController(text: initialValue);
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              String value = controller.text.trim();
              if (prefixText != null) {
                value = value.replaceAll(prefixText, '');
              }
              Navigator.of(context).pop(value);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

