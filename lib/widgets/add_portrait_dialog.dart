// DEPRECATED: Use AddPortraitScreen instead of AddPortraitDialog for adding portraits.
// This widget is no longer used and will throw if instantiated.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/portrait_provider.dart';

class AddPortraitDialog extends StatefulWidget {
  final String userId;
  final int nextWeekNumber;

  const AddPortraitDialog({
    super.key,
    required this.userId,
    required this.nextWeekNumber,
  });

  @override
  State<AddPortraitDialog> createState() => _AddPortraitDialogState();
}

class _AddPortraitDialogState extends State<AddPortraitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitPortrait() async {
    if (_formKey.currentState!.validate() && _selectedImage != null) {
      setState(() {
        _isSubmitting = true;
      });

      final portraitProvider = Provider.of<PortraitProvider>(context, listen: false);
      
      try {
        final success = await portraitProvider.addPortrait(
          userId: widget.userId,
          imageFile: _selectedImage!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          context: context,
        );

        if (success && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Portrait added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(portraitProvider.error ?? 'Failed to add portrait'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('AddPortraitDialog is deprecated. Use AddPortraitScreen instead.');
  }
} 