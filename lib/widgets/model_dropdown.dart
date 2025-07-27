import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/model_provider.dart';
import '../models/model_model.dart';

class ModelDropdown extends StatefulWidget {
  final String? selectedModelId;
  final String? selectedModelName;
  final Function(String? modelId, String? modelName)? onModelSelected;
  final bool showOnlyActive;

  const ModelDropdown({
    super.key,
    this.selectedModelId,
    this.selectedModelName,
    this.onModelSelected,
    this.showOnlyActive = true,
  });

  @override
  State<ModelDropdown> createState() => _ModelDropdownState();
}

class _ModelDropdownState extends State<ModelDropdown> {
  ModelModel? _selectedModel;

  @override
  void initState() {
    super.initState();
    // If we have a selected model name but no ID, we'll need to find the model
    if (widget.selectedModelName != null && widget.selectedModelId == null) {
      _findModelByName(widget.selectedModelName!);
    }
  }

  Future<void> _findModelByName(String modelName) async {
    final modelProvider = Provider.of<ModelProvider>(context, listen: false);
    final models = await modelProvider.getModels().first;
         final model = models.firstWhere(
       (m) => m.name.toLowerCase() == modelName.toLowerCase(),
       orElse: () => ModelModel(
         id: '',
         name: modelName,
         date: DateTime.now(),
         isActive: true,
         createdAt: DateTime.now(),
         updatedAt: DateTime.now(),
       ),
     );
    if (mounted) {
      setState(() {
        _selectedModel = model;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelProvider>(
      builder: (context, modelProvider, child) {
        return StreamBuilder<List<ModelModel>>(
          stream: widget.showOnlyActive 
              ? modelProvider.getActiveModels()
              : modelProvider.getModels(),
          builder: (context, snapshot) {
                         if (snapshot.connectionState == ConnectionState.waiting) {
               return DropdownButtonFormField<String>(
                 value: null,
                 items: const [],
                 decoration: const InputDecoration(
                   labelText: 'Model',
                   border: OutlineInputBorder(),
                 ),
                 hint: const Text('Loading models...'),
                 onChanged: (value) {},
               );
             }

                         if (snapshot.hasError) {
               return DropdownButtonFormField<String>(
                 value: null,
                 items: const [],
                 decoration: const InputDecoration(
                   labelText: 'Model',
                   border: OutlineInputBorder(),
                 ),
                 hint: Text('Error: ${snapshot.error}'),
                 onChanged: (value) {},
               );
             }

            final models = snapshot.data ?? [];
            
                         // If we have a selected model name but no model object, try to find it
             if (_selectedModel == null && widget.selectedModelName != null) {
               final foundModel = models.firstWhere(
                 (m) => m.name.toLowerCase() == widget.selectedModelName!.toLowerCase(),
                 orElse: () => ModelModel(
                   id: '',
                   name: widget.selectedModelName!,
                   date: DateTime.now(),
                   isActive: true,
                   createdAt: DateTime.now(),
                   updatedAt: DateTime.now(),
                 ),
               );
               _selectedModel = foundModel;
             }

            // Create dropdown items
            final items = <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No model selected'),
              ),
              ...models.map((model) => DropdownMenuItem<String>(
                value: model.id,
                child: Row(
                  children: [
                    // Model image or placeholder
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: model.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                model.imageUrl!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Model name and date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            model.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDate(model.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Active indicator
                    if (model.isActive)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              )),
            ];

            return DropdownButtonFormField<String>(
              value: _selectedModel?.id,
              items: items,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              hint: const Text('Select a model'),
              selectedItemBuilder: (BuildContext context) {
                return items.map<Widget>((DropdownMenuItem<String> item) {
                  if (item.value == null) {
                    return const Text('No model selected');
                  }
                  final model = models.firstWhere(
                    (m) => m.id == item.value,
                    orElse: () => ModelModel(
                      id: '',
                      name: 'Unknown',
                      date: DateTime.now(),
                      isActive: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                  return Text(
                    model.name,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
              onChanged: (String? modelId) {
                                 final selectedModel = models.firstWhere(
                   (m) => m.id == modelId,
                   orElse: () => ModelModel(
                     id: '',
                     name: '',
                     date: DateTime.now(),
                     isActive: true,
                     createdAt: DateTime.now(),
                     updatedAt: DateTime.now(),
                   ),
                 );
                
                setState(() {
                  _selectedModel = modelId != null ? selectedModel : null;
                });
                
                widget.onModelSelected?.call(
                  modelId,
                  selectedModel.name.isNotEmpty ? selectedModel.name : null,
                );
              },
              validator: (value) {
                // Optional validation - you can make this required if needed
                return null;
              },
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
} 