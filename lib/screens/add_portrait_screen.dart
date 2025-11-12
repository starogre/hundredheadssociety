import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../providers/portrait_provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/model_dropdown.dart';
import '../services/portrait_service.dart';
import '../services/bulk_upload_service.dart';

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

  final _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  int _selectedWeek = 1;
  List<int> _availableWeeks = [];
  bool _isBulkMode = false;
  List<File> _bulkImages = [];

  List<TextEditingController> _bulkDescriptionControllers = [];
  List<int> _bulkWeekNumbers = [];
  
  // Model selection
  String? _selectedModelId;
  String? _selectedModelName;
  
  // Bulk upload model selection
  List<String?> _bulkModelIds = [];
  List<String?> _bulkModelNames = [];

  @override
  void initState() {
    super.initState();
    _selectedWeek = widget.nextWeekNumber;
    _loadAvailableWeeks();
  }

  Future<void> _loadAvailableWeeks() async {
    // Create list of available weeks (1 to nextWeekNumber)
    setState(() {
      _availableWeeks = List.generate(widget.nextWeekNumber, (index) => index + 1);
    });
  }

  int get _maxBulkCount {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final completed = authProvider.userData?.portraitsCompleted ?? 0;
    // Calculate remaining portraits in current set of 100
    // e.g., if completed = 97, can select 3 more to reach 100
    // if completed = 100, can select 100 more to reach 200
    // if completed = 157, can select 43 more to reach 200
    final nextMilestone = ((completed ~/ 100) + 1) * 100;
    final remaining = nextMilestone - completed;
    // Ensure at least 1 (in case of any calculation issues)
    return remaining > 0 ? remaining : 100;
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
    try {
      // Get max count for current milestone
      final maxCount = _maxBulkCount;
      
      // Request permission with proper options for limited access
      final PermissionState permission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          iosAccessLevel: IosAccessLevel.readWrite,
        ),
      );
      
      // Handle different permission states
      if (permission == PermissionState.authorized) {
        // Full access - proceed normally
        print('Photo permission: AUTHORIZED (full access)');
      } else if (permission == PermissionState.limited) {
        // Limited access - show helpful message but still allow picking
        print('Photo permission: LIMITED (selected photos only)');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You\'ve granted access to selected photos. Tap to add more photos in Settings.'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => PhotoManager.openSetting(),
              ),
            ),
          );
        }
        // Continue to picker - it will show the limited photo set
      } else {
        // Denied - show settings dialog
        print('Photo permission: DENIED');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Photo access permission denied. Please enable it in settings.'),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Open Settings',
                textColor: Colors.white,
                onPressed: () => PhotoManager.openSetting(),
              ),
            ),
          );
        }
        return; // Don't open picker if permission denied
      }
      
      // Use wechat_assets_picker for better UX
      // This works with both full and limited access
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: maxCount,
          requestType: RequestType.image,
          selectedAssets: [],
          themeColor: AppColors.forestGreen,
          textDelegate: const EnglishAssetPickerTextDelegate(),
          sortPathsByModifiedDate: true,
          // Allow access to all albums (or limited set if permission is limited)
          pathNameBuilder: (AssetPathEntity path) {
            return path.name;
          },
        ),
      );
      
      if (result != null && result.isNotEmpty) {
        // Convert AssetEntity to File
        final files = await Future.wait(
          result.map((asset) async {
            final file = await asset.file;
            return file;
          }),
        );
        final validFiles = files.whereType<File>().toList();
        
        if (validFiles.isNotEmpty) {
          // Find the next available week numbers without gaps
          final portraitService = PortraitService();
          final existingPortraits = await portraitService.getUserPortraits(widget.userId).first;
          final existingWeeks = existingPortraits.map((p) => p.weekNumber).toSet();
          
          // Find the next available week numbers
          final nextWeeks = <int>[];
          int weekToCheck = 1;
          while (nextWeeks.length < validFiles.length) {
            if (!existingWeeks.contains(weekToCheck)) {
              nextWeeks.add(weekToCheck);
            }
            weekToCheck++;
          }
          
          setState(() {
            _isBulkMode = true;
            _bulkImages = validFiles;
            _bulkDescriptionControllers = List.generate(_bulkImages.length, (_) => TextEditingController());
            _bulkModelIds = List.generate(_bulkImages.length, (_) => null);
            _bulkModelNames = List.generate(_bulkImages.length, (_) => null);
            _bulkWeekNumbers = nextWeeks;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_bulkImages.length} images selected'),
                backgroundColor: AppColors.forestGreen,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showLimitedAccessInfo() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limited Photo Access'),
        content: const Text(
          'You\'ve granted access to selected photos only.\n\n'
          'You can:\n'
          '• Select from your chosen photos now\n'
          '• Add more photos in Settings > Privacy > Photos\n\n'
          'For the best experience, consider granting full access to your photo library.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              PhotoManager.openSetting();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: AppColors.forestGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Continue',
              style: TextStyle(color: AppColors.forestGreen),
            ),
          ),
        ],
      ),
    );
  }

  // Remove image at specific index
  void _removeImageAtIndex(int index) {
    setState(() {
      _bulkImages.removeAt(index);
      _bulkDescriptionControllers[index].dispose();
      _bulkDescriptionControllers.removeAt(index);
      _bulkModelIds.removeAt(index);
      _bulkModelNames.removeAt(index);
      _bulkWeekNumbers.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image removed. ${_bulkImages.length} remaining.'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.forestGreen,
      ),
    );
  }

  // Edit image at specific index
  Future<void> _editImageAtIndex(int index) async {
    final descriptionController = TextEditingController(
      text: _bulkDescriptionControllers[index].text,
    );
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Portrait #${index + 1}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _bulkImages[index],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              // Week display
              Text(
                'Week: ${_bulkWeekNumbers[index]}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 16),
              // Description field
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Model dropdown
              ModelDropdown(
                selectedModelId: _bulkModelIds[index],
                selectedModelName: _bulkModelNames[index],
                onModelSelected: (modelId, modelName) {
                  setState(() {
                    _bulkModelIds[index] = modelId;
                    _bulkModelNames[index] = modelName;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              descriptionController.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _bulkDescriptionControllers[index].dispose();
              _bulkDescriptionControllers[index] = descriptionController;
              Navigator.of(context).pop();
            },
            child: Text(
              'Save',
              style: TextStyle(color: AppColors.forestGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _selectModelAtIndex(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Model',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.forestGreen,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ModelDropdown(
            selectedModelId: _bulkModelIds[index],
            selectedModelName: _bulkModelNames[index],
            onModelSelected: (modelId, modelName) {
              setState(() {
                _bulkModelIds[index] = modelId;
                _bulkModelNames[index] = modelName;
              });
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
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
        title: '', // Title deprecated
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        weekNumber: _selectedWeek,
        modelName: _selectedModelName,
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

  void _bulkUploadPortraits() {
    if (_bulkImages.isEmpty) return;
    
    final bulkUploadService = Provider.of<BulkUploadService>(context, listen: false);
    
    try {
      // Start the bulk upload in the background (fire and forget)
      bulkUploadService.startBulkUpload(
        userId: widget.userId,
        images: _bulkImages,
        descriptions: _bulkDescriptionControllers.map((c) => c.text.trim().isEmpty ? null : c.text.trim()).toList(),
        modelNames: _bulkModelNames,
        weekNumbers: _bulkWeekNumbers,
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Upload started! Check the progress bar at the top.'),
            backgroundColor: AppColors.forestGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Clear local state
      setState(() {
        _bulkImages.clear();
        for (var controller in _bulkDescriptionControllers) {
          controller.dispose();
        }
        _bulkDescriptionControllers.clear();
        _bulkModelIds.clear();
        _bulkModelNames.clear();
        _bulkWeekNumbers.clear();
        _isBulkMode = false;
      });
      
      // Navigate back immediately
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start upload: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
          ? _buildBulkUploadView()
          : _buildSingleUploadView(),
    );
  }

  // Build the improved bulk upload view with grid preview
  Widget _buildBulkUploadView() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Header with count and action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.forestGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_bulkImages.length} ${_bulkImages.length == 1 ? 'portrait' : 'portraits'} selected',
                      style: TextStyle(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_bulkImages.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _bulkImages.clear();
                            _bulkDescriptionControllers.clear();
                            _bulkModelIds.clear();
                            _bulkModelNames.clear();
                            _bulkWeekNumbers.clear();
                          });
                        },
                        child: Text(
                          'Clear All',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickBulkImages,
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: Text(_bulkImages.isEmpty ? 'Select Images' : 'Select More'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Preview Grid or Empty State
          Expanded(
            child: _bulkImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No images selected',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Select Images" to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bulkImages.length,
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final animValue = Curves.easeInOut.transform(animation.value);
                          final elevation = lerpDouble(4, 16, animValue)!;
                          final scale = lerpDouble(1.0, 1.05, animValue)!;
                          return Transform.scale(
                            scale: scale,
                            child: Material(
                              elevation: elevation,
                              borderRadius: BorderRadius.circular(12),
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      return ReorderableDragStartListener(
                        key: ValueKey('drag_$index'),
                        index: index,
                        child: _buildHorizontalImageCard(index),
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        // Adjust index if moving down
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        
                        // Reorder all arrays to keep data synchronized
                        final image = _bulkImages.removeAt(oldIndex);
                        _bulkImages.insert(newIndex, image);
                        
                        final desc = _bulkDescriptionControllers.removeAt(oldIndex);
                        _bulkDescriptionControllers.insert(newIndex, desc);
                        
                        final modelId = _bulkModelIds.removeAt(oldIndex);
                        _bulkModelIds.insert(newIndex, modelId);
                        
                        final modelName = _bulkModelNames.removeAt(oldIndex);
                        _bulkModelNames.insert(newIndex, modelName);
                        
                        final week = _bulkWeekNumbers.removeAt(oldIndex);
                        _bulkWeekNumbers.insert(newIndex, week);
                        
                        // Recalculate all week numbers based on new order
                        // Start from the next available week and count down for each portrait
                        final startWeek = widget.nextWeekNumber;
                        for (int i = 0; i < _bulkWeekNumbers.length; i++) {
                          _bulkWeekNumbers[i] = startWeek + i;
                        }
                      });
                    },
                  ),
          ),
          
          // Submit Button
          if (_bulkImages.isNotEmpty)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _bulkUploadPortraits,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rustyOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Upload ${_bulkImages.length} ${_bulkImages.length == 1 ? 'Portrait' : 'Portraits'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build horizontal image card with model selector (new layout)
  Widget _buildHorizontalImageCard(int index) {
    return Container(
      key: ValueKey('portrait_$index'),
      height: 160,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Container(
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
              ),
              
              // Left: Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Image.file(
                  _bulkImages[index],
                  width: 110,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
          
              // Right: Info section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top: Week badge and remove button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.rustyOrange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Week ${_bulkWeekNumbers[index]}',
                              style: TextStyle(
                                color: AppColors.rustyOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Remove button
                          GestureDetector(
                            onTap: () => _removeImageAtIndex(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red[700],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Middle: Model selector button
                      GestureDetector(
                        onTap: () => _selectModelAtIndex(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: _bulkModelNames[index] != null 
                                    ? AppColors.forestGreen 
                                    : Colors.grey[400],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _bulkModelNames[index] ?? 'Select Model',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _bulkModelNames[index] != null 
                                        ? AppColors.forestGreen 
                                        : Colors.grey[600],
                                    fontWeight: _bulkModelNames[index] != null 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Bottom: Description button
                      GestureDetector(
                        onTap: () => _editImageAtIndex(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: _bulkDescriptionControllers[index].text.isNotEmpty
                                    ? AppColors.forestGreen
                                    : Colors.grey[400],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _bulkDescriptionControllers[index].text.isNotEmpty
                                      ? _bulkDescriptionControllers[index].text
                                      : 'Add Description',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _bulkDescriptionControllers[index].text.isNotEmpty
                                        ? AppColors.forestGreen
                                        : Colors.grey[600],
                                    fontWeight: _bulkDescriptionControllers[index].text.isNotEmpty
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Number badge - positioned at top left
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.forestGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build the single upload view (existing functionality)
  Widget _buildSingleUploadView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    // Bulk Upload Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isBulkMode = true;
                          });
                        },
                        icon: const Icon(Icons.photo_library, size: 20),
                        label: const Text('Add Multiple'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rustyOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Week Selection
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.rustyOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.rustyOrange.withValues(alpha: 0.3)),
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
                          border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.3)),
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
                    // Model Selection
                    ModelDropdown(
                      selectedModelId: _selectedModelId,
                      selectedModelName: _selectedModelName,
                      onModelSelected: (modelId, modelName) {
                        setState(() {
                          _selectedModelId = modelId;
                          _selectedModelName = modelName;
                        });
                      },
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
            );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
} 