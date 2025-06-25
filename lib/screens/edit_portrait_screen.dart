import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/portrait_model.dart';
import '../services/portrait_service.dart';
import '../theme/app_theme.dart';

class EditPortraitScreen extends StatefulWidget {
  final PortraitModel portrait;
  final VoidCallback? onPortraitUpdated;

  const EditPortraitScreen({
    super.key,
    required this.portrait,
    this.onPortraitUpdated,
  });

  @override
  State<EditPortraitScreen> createState() => _EditPortraitScreenState();
}

class _EditPortraitScreenState extends State<EditPortraitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _modelNameController = TextEditingController();
  File? _newImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.portrait.title;
    _descriptionController.text = widget.portrait.description ?? '';
    _modelNameController.text = widget.portrait.modelName ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _newImageFile = File(image.path);
          _imageChanged = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final portraitService = PortraitService();
      String? newImageUrl;

      // Upload new image if changed
      if (_imageChanged && _newImageFile != null) {
        newImageUrl = await portraitService.uploadPortraitImage(_newImageFile!, widget.portrait.userId);
      }

      // Update portrait in Firestore
      await portraitService.updatePortrait(
        portraitId: widget.portrait.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        imageUrl: newImageUrl,
        modelName: _modelNameController.text.trim().isEmpty ? null : _modelNameController.text.trim(),
      );

      if (mounted) {
        // Call the callback first
        widget.onPortraitUpdated?.call();
        // Show success message before navigation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portrait updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Wait a short moment to let the SnackBar show, then pop
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update portrait: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Edit Portrait - Week ${widget.portrait.weekNumber}'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Week Number (at the top)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.rustyOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.rustyOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.rustyOrange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Week ${widget.portrait.weekNumber}',
                      style: TextStyle(
                        color: AppColors.rustyOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Image Selection
              Row(
                children: [
                  Icon(Icons.photo, color: AppColors.forestGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Portrait Image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Change'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.rustyOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _newImageFile != null
                      ? Image.file(
                          _newImageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.portrait.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.error),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title Field
              Row(
                children: [
                  Icon(Icons.title, color: AppColors.forestGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter portrait title',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description Field
              Row(
                children: [
                  Icon(Icons.description, color: AppColors.forestGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Description (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter description (optional)',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Model Name Field
              Row(
                children: [
                  Icon(Icons.person, color: AppColors.rustyOrange, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Model Name (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modelNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter model name (optional)',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.rustyOrange,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...'),
                        ],
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 