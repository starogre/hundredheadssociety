import 'package:flutter/material.dart';
import '../models/model_model.dart';
import '../services/model_service.dart';
import '../theme/app_theme.dart';

class ModelDropdown extends StatefulWidget {
  final String? selectedModelId;
  final Function(String? modelId, String? modelName) onModelSelected;
  final bool showSearch;
  final String? hintText;

  const ModelDropdown({
    super.key,
    this.selectedModelId,
    required this.onModelSelected,
    this.showSearch = true,
    this.hintText,
  });

  @override
  State<ModelDropdown> createState() => _ModelDropdownState();
}

class _ModelDropdownState extends State<ModelDropdown> {
  final ModelService _modelService = ModelService();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedModelId;
  String? _selectedModelName;

  @override
  void initState() {
    super.initState();
    _selectedModelId = widget.selectedModelId;
    _loadSelectedModelName();
  }

  @override
  void didUpdateWidget(ModelDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedModelId != oldWidget.selectedModelId) {
      _selectedModelId = widget.selectedModelId;
      _loadSelectedModelName();
    }
  }

  Future<void> _loadSelectedModelName() async {
    if (_selectedModelId != null) {
      final model = await _modelService.getModelById(_selectedModelId!);
      if (model != null) {
        setState(() {
          _selectedModelName = model.name;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ModelModel>>(
      stream: _modelService.getModelsWithFilter(
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        sortBy: 'date',
        descending: true,
        isActive: true, // Only show active models
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final models = snapshot.data!;
        final validModels = models.where((model) => model.isValidSession).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showSearch) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search models...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
            ],
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedModelId,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Select a model',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('-- Select a model --'),
                  ),
                  ...validModels.map((model) => DropdownMenuItem<String>(
                    value: model.id,
                    child: Row(
                      children: [
                        // Model image or placeholder
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.forestGreen,
                          child: model.imageUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    model.imageUrl!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person, color: Colors.white, size: 16);
                                    },
                                  ),
                                )
                              : const Icon(Icons.person, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        
                        // Model info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                model.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                model.formattedDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
                onChanged: (String? modelId) {
                  setState(() {
                    _selectedModelId = modelId;
                    if (modelId != null) {
                      final model = validModels.firstWhere((m) => m.id == modelId);
                      _selectedModelName = model.name;
                    } else {
                      _selectedModelName = null;
                    }
                  });
                  widget.onModelSelected(modelId, _selectedModelName);
                },
              ),
            ),
            
            if (_selectedModelName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightCream,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.forestGreen, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Selected: $_selectedModelName',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
} 