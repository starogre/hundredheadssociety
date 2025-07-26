import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../models/model_model.dart';
import '../services/model_service.dart';
import '../utils/csv_parser.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class ModelManagementScreen extends StatefulWidget {
  const ModelManagementScreen({super.key});

  @override
  State<ModelManagementScreen> createState() => _ModelManagementScreenState();
}

class _ModelManagementScreenState extends State<ModelManagementScreen> {
  final ModelService _modelService = ModelService();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();
  String _sortBy = 'date';
  bool _sortDescending = true;
  bool _showOnlyActive = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<AuthProvider>(context, listen: false).userData?.isAdmin ?? false;
    final isModerator = Provider.of<AuthProvider>(context, listen: false).userData?.isModerator ?? false;

    if (!isAdmin && !isModerator) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Model Management'),
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.white,
        ),
        body: const Center(
          child: Text('Access denied. Admin or moderator privileges required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Management'),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditModelDialog(context),
            tooltip: 'Add New Model',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'import_csv':
                  _showImportDialog(context);
                  break;
                case 'export_csv':
                  _exportToCSV();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_csv',
                child: Row(
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 8),
                    Text('Import CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.lightCream,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search models...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                
                // Filter and Sort Controls
                Row(
                  children: [
                    // Sort Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: const InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'date', child: Text('Date')),
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Sort Direction
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _sortDescending = !_sortDescending;
                        });
                      },
                      icon: Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward),
                      tooltip: 'Sort Direction',
                    ),
                    
                    // Active Filter
                    FilterChip(
                      label: const Text('Active Only'),
                      selected: _showOnlyActive,
                      onSelected: (value) {
                        setState(() {
                          _showOnlyActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Models List
          Expanded(
            child: StreamBuilder<List<ModelModel>>(
              stream: _modelService.getModelsWithFilter(
                searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
                sortBy: _sortBy,
                descending: _sortDescending,
                isActive: _showOnlyActive ? true : null,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final models = snapshot.data!;

                if (models.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No models found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first model using the + button',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final model = models[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: model.isActive ? AppColors.forestGreen : Colors.grey,
                          child: model.imageUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    model.imageUrl!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person, color: Colors.white, size: 20);
                                    },
                                  ),
                                )
                              : const Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          model.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: model.isActive ? Colors.black : Colors.grey,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date: ${model.formattedDate}',
                              style: TextStyle(
                                color: model.isActive ? Colors.grey[600] : Colors.grey,
                              ),
                            ),
                            if (model.notes != null && model.notes!.isNotEmpty)
                              Text(
                                'Notes: ${model.notes}',
                                style: TextStyle(
                                  color: model.isActive ? Colors.grey[600] : Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!model.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'INACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditModelDialog(context, model: model),
                              tooltip: 'Edit Model',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(context, model),
                              tooltip: 'Delete Model',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditModelDialog(BuildContext context, {ModelModel? model}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditModelDialog(model: model),
    );
  }
}

class _AddEditModelDialog extends StatefulWidget {
  final ModelModel? model;
  
  const _AddEditModelDialog({this.model});
  
  @override
  State<_AddEditModelDialog> createState() => _AddEditModelDialogState();
}

class _AddEditModelDialogState extends State<_AddEditModelDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();
  
  DateTime _selectedDate = DateTime.now();
  bool _isActive = true;
  String? _imageUrl;
  File? _selectedImageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.model != null) {
      _nameController.text = widget.model!.name;
      _notesController.text = widget.model!.notes ?? '';
      _selectedDate = widget.model!.date;
      _isActive = widget.model!.isActive;
      _imageUrl = widget.model!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.model != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'Edit Model' : 'Add New Model'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Model Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Date Picker
            ListTile(
              title: const Text('Date'),
              subtitle: Text(_selectedDate.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Image picker
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Model Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Current image or placeholder
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageUrl != null || _selectedImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _selectedImageFile != null
                                    ? Image.file(
                                        _selectedImageFile!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        _imageUrl!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Image picker buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? image = await _imagePicker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 800,
                              maxHeight: 800,
                              imageQuality: 80,
                            );
                            if (image != null) {
                              setState(() {
                                _selectedImageFile = File(image.path);
                                _imageUrl = null; // Clear existing URL
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? image = await _imagePicker.pickImage(
                              source: ImageSource.camera,
                              maxWidth: 800,
                              maxHeight: 800,
                              imageQuality: 80,
                            );
                            if (image != null) {
                              setState(() {
                                _selectedImageFile = File(image.path);
                                _imageUrl = null; // Clear existing URL
                              });
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                        if (_imageUrl != null || _selectedImageFile != null)
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImageFile = null;
                                _imageUrl = null;
                              });
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Remove'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Active toggle
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Whether this model session happened'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveModel,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _saveModel() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model name is required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final modelService = ModelService();
      
      // Upload image if a new one was selected
      String? finalImageUrl = _imageUrl;
      if (_selectedImageFile != null) {
        final uploadedUrl = await _uploadModelImage(
          _selectedImageFile!,
          _nameController.text.trim(),
        );
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (widget.model != null) {
        await modelService.updateModel(widget.model!.id, {
          'name': _nameController.text.trim(),
          'date': _selectedDate,
          'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          'imageUrl': finalImageUrl,
          'isActive': _isActive,
        });
      } else {
        await modelService.addModel(
          name: _nameController.text.trim(),
          date: _selectedDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          imageUrl: finalImageUrl,
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.model != null ? 'Model updated successfully' : 'Model added successfully'),
            backgroundColor: AppColors.forestGreen,
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
          _isLoading = false;
        });
      }
    }
  }

  // Upload model image to Firebase Storage
  Future<String?> _uploadModelImage(File imageFile, String modelName) async {
    try {
      print('Starting model image upload to Firebase Storage');
      String fileName = 'models/${_uuid.v4()}.jpg';
      print('Generated filename: $fileName');
      Reference ref = _storage.ref().child(fileName);
      
      print('Starting upload task');
      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'modelName': modelName},
        ),
      );

      print('Waiting for upload to complete');
      TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          print('Upload timed out after 2 minutes');
          throw TimeoutException('Upload timed out after 2 minutes');
        },
      );
      
      if (snapshot.state == TaskState.error) {
        print('Upload failed with error state');
        throw Exception('Upload failed: ${snapshot.state}');
      }

      print('Upload complete, getting download URL');
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Got download URL: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase error in uploadModelImage: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error in uploadModelImage: $e');
      rethrow;
    }
  }
  }

  void _showDeleteConfirmation(BuildContext context, ModelModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text('Are you sure you want to delete "${model.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _modelService.deleteModel(model.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Model "${model.name}" deleted successfully'),
                      backgroundColor: AppColors.forestGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting model: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Models'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This will import model data from CSV files.'),
            SizedBox(height: 16),
            Text('Note: This will add new models but won\'t overwrite existing ones.'),
            SizedBox(height: 8),
            Text('Supported formats:'),
            Text('• 2024: "January 9,TRUE,Kristine"'),
            Text('• 2025: "1/6/2025 21:00:00,Geoffrey Barber"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _importCSVData();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importCSVData() async {
    try {
      // For now, we'll use a simple approach where you can paste CSV data
      // In the future, we can add file picker functionality
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import CSV Data'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paste your CSV data below:'),
              SizedBox(height: 8),
              Text('Format: "Date,TRUE/FALSE,Model Name" or "Date,Model Name"'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement CSV paste functionality
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV import functionality coming soon!'),
                  ),
                );
              },
              child: const Text('Import'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing models: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportToCSV() {
    // TODO: Implement CSV export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV export functionality coming soon!'),
      ),
    );
  }

} 