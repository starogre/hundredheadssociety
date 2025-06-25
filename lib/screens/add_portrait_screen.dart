import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../providers/portrait_provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/multi_image_picker_gallery.dart';
import '../widgets/bulk_image_grid_picker.dart';

class AddPortraitScreen extends StatefulWidget {
  final String userId;
  final int nextWeekNumber;

  const AddPortraitScreen({
    super.key,
    required this.userId,
    required this.nextWeekNumber,
  });

  @override
  State<AddPortraitScreen> createState() => _AddPortraitScreenState();
}

class _AddPortraitScreenState extends State<AddPortraitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _modelNameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  int _selectedWeek = 1;
  List<int> _availableWeeks = [];
  bool _isBulkMode = false;
  List<File> _bulkImages = [];
  List<TextEditingController> _bulkTitleControllers = [];
  List<TextEditingController> _bulkDescriptionControllers = [];
  List<TextEditingController> _bulkModelNameControllers = [];
  List<int> _bulkWeekNumbers = [];
  List<AssetEntity> _bulkAssets = [];

  @override
  void initState() {
    super.initState();
    _selectedWeek = widget.nextWeekNumber;
    _loadAvailableWeeks();
  }

  Future<void> _loadAvailableWeeks() async {
    // Get user's current portrait count to determine available weeks
    final portraitProvider = Provider.of<PortraitProvider>(context, listen: false);
    final userPortraits = await portraitProvider.getUserPortraits(widget.userId);
    
    // Create list of available weeks (1 to nextWeekNumber)
    setState(() {
      _availableWeeks = List.generate(widget.nextWeekNumber, (index) => index + 1);
    });
  }

  int get _maxBulkCount {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final completed = authProvider.userData?.portraitsCompleted ?? 0;
    return 100 - completed;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickBulkImages() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('DEBUG: _pickBulkImages called')),
    );
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BulkImageGridPicker(
          maxSelection: _maxBulkCount,
        ),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('DEBUG: Navigator returned result type: ${result.runtimeType}')),
    );
    
    if (result != null && result is List<AssetEntity> && result.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DEBUG: Converting ${result.length} assets to files')),
      );
      
      final files = await Future.wait(result.map((a) => a.file).toList());
      final validFiles = files.whereType<File>().toList();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DEBUG: Converted to ${validFiles.length} valid files')),
      );
      
      if (validFiles.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DEBUG: Setting bulk images with ${validFiles.length} files')),
        );
        setState(() {
          _bulkImages = validFiles;
          _bulkTitleControllers = List.generate(_bulkImages.length, (_) => TextEditingController());
          _bulkDescriptionControllers = List.generate(_bulkImages.length, (_) => TextEditingController());
          _bulkModelNameControllers = List.generate(_bulkImages.length, (_) => TextEditingController());
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final completed = authProvider.userData?.portraitsCompleted ?? 0;
          _bulkWeekNumbers = List.generate(_bulkImages.length, (i) => completed + 1 + i);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DEBUG: Bulk mode should now show ${_bulkImages.length} images')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DEBUG: No valid result returned')),
      );
    }
  }

  Future<void> _savePortrait() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final portraitProvider = Provider.of<PortraitProvider>(context, listen: false);
      await portraitProvider.addPortrait(
        userId: widget.userId,
        imageFile: _selectedImage!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        weekNumber: _selectedWeek,
        modelName: _modelNameController.text.trim().isEmpty ? null : _modelNameController.text.trim(),
        context: context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portrait added successfully!'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding portrait: $e'),
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

  Future<void> _bulkUploadPortraits() async {
    if (_bulkImages.isEmpty) return;
    bool hasError = false;
    setState(() {
      _isLoading = true;
    });
    final portraitProvider = Provider.of<PortraitProvider>(context, listen: false);
    for (int i = 0; i < _bulkImages.length; i++) {
      final title = _bulkTitleControllers[i].text.trim();
      if (title.isEmpty) {
        hasError = true;
        continue;
      }
      try {
        await portraitProvider.addPortrait(
          userId: widget.userId,
          imageFile: _bulkImages[i],
          title: title,
          description: _bulkDescriptionControllers[i].text.trim().isEmpty ? null : _bulkDescriptionControllers[i].text.trim(),
          weekNumber: _bulkWeekNumbers[i],
          modelName: _bulkModelNameControllers[i].text.trim().isEmpty ? null : _bulkModelNameControllers[i].text.trim(),
          context: context,
        );
      } catch (e) {
        hasError = true;
      }
    }
    setState(() {
      _isLoading = false;
      _bulkImages.clear();
      _bulkTitleControllers.clear();
      _bulkDescriptionControllers.clear();
      _bulkModelNameControllers.clear();
      _bulkWeekNumbers.clear();
      _isBulkMode = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasError ? 'Some portraits failed to upload.' : 'All portraits uploaded successfully!'),
          backgroundColor: hasError ? Colors.red : Colors.green,
        ),
      );
      if (!hasError) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Portrait'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: _isBulkMode
          ? Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Text(
                        '${_bulkImages.length} of $_maxBulkCount selected',
                        style: TextStyle(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickBulkImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Select Images'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._bulkImages.asMap().entries.map((entry) {
                    final i = entry.key;
                    final file = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.file(file, height: 100, width: double.infinity, fit: BoxFit.cover),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _bulkTitleControllers[i],
                              decoration: const InputDecoration(labelText: 'Title *'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _bulkDescriptionControllers[i],
                              decoration: const InputDecoration(labelText: 'Description (optional)'),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _bulkModelNameControllers[i],
                              decoration: const InputDecoration(labelText: 'Model Name (optional)'),
                            ),
                            const SizedBox(height: 8),
                            Text('Week: ${_bulkWeekNumbers[i]}'),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_bulkImages.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _bulkUploadPortraits,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rustyOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Submit All'),
                      ),
                    ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bulk Upload Toggle
                    Row(
                      children: [
                        Switch(
                          value: _isBulkMode,
                          onChanged: (val) {
                            setState(() {
                              _isBulkMode = val;
                              if (!val) {
                                _bulkImages.clear();
                                _bulkTitleControllers.clear();
                                _bulkDescriptionControllers.clear();
                                _bulkModelNameControllers.clear();
                                _bulkWeekNumbers.clear();
                              }
                            });
                          },
                          activeColor: AppColors.rustyOrange,
                        ),
                        const SizedBox(width: 8),
                        const Text('Add Multiple'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Week Selection
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.rustyOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.rustyOrange.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: AppColors.rustyOrange),
                              const SizedBox(width: 8),
                              Text(
                                'Week $_selectedWeek',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.rustyOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _selectedWeek,
                            decoration: const InputDecoration(
                              labelText: 'Select Week',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _availableWeeks.map((week) {
                              return DropdownMenuItem(
                                value: week,
                                child: Text('Week $week'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedWeek = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Image Selection
                    Text(
                      'Portrait Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedImage != null) ...[
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.forestGreen.withOpacity(0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Model Name Field
                    TextFormField(
                      controller: _modelNameController,
                      decoration: const InputDecoration(
                        labelText: 'Model Name (optional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePortrait,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rustyOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Portrait'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }
} 