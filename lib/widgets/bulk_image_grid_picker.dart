import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import 'dart:io';

class BulkImageGridPicker extends StatefulWidget {
  final int maxSelection;

  const BulkImageGridPicker({
    super.key,
    required this.maxSelection,
  });

  @override
  State<BulkImageGridPicker> createState() => _BulkImageGridPickerState();
}

class _BulkImageGridPickerState extends State<BulkImageGridPicker> {
  List<AssetEntity> _images = [];
  late ValueNotifier<List<AssetEntity>> _selectedImages;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedImages = ValueNotifier<List<AssetEntity>>([]);
    _loadImages();
  }

  @override
  void dispose() {
    _selectedImages.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    debugPrint(message);
  }

  Future<void> _loadImages() async {
    final permission = await PhotoManager.requestPermissionExtend();
    _addLog('PhotoManager permission: ${permission.isAuth}');
    _addLog('Android version: ${Platform.isAndroid ? Platform.version : "not Android"}');

    if (!permission.isAuth) {
      _addLog('Permission not granted, opening settings.');
      PhotoManager.openSetting();
      setState(() => _loading = false);
      return;
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    _addLog('Found ${albums.length} albums');
    for (final album in albums) {
      _addLog('Album: ${album.name}, count: ${await album.assetCountAsync}');
    }

    if (albums.isEmpty) {
      setState(() {
        _images = [];
        _loading = false;
      });
      return;
    }
    final recentAlbum = albums.first;
    final List<AssetEntity> images = await recentAlbum.getAssetListPaged(page: 0, size: 200);
    _addLog('Images in recent album: ${images.length}');
    setState(() {
      _images = images;
      _loading = false;
    });
  }

  void _toggleSelection(AssetEntity asset) {
    final current = List<AssetEntity>.from(_selectedImages.value);
    if (current.contains(asset)) {
      current.remove(asset);
    } else if (current.length < widget.maxSelection) {
      current.add(asset);
    }
    _selectedImages.value = current;
  }

  void _finishSelection() {
    Navigator.of(context).pop(_selectedImages.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Images'),
        actions: [
          ValueListenableBuilder<List<AssetEntity>>(
            valueListenable: _selectedImages,
            builder: (context, selected, _) => TextButton(
              onPressed: selected.isNotEmpty ? _finishSelection : null,
              child: Text('Done (${selected.length}/${widget.maxSelection})', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? const Center(child: Text('No images found.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (_, index) {
                    final asset = _images[index];
                    return ValueListenableBuilder<List<AssetEntity>>(
                      valueListenable: _selectedImages,
                      builder: (context, selected, _) {
                        final isSelected = selected.contains(asset);
                        return FutureBuilder<Uint8List?>(
                          future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                          builder: (_, snapshot) {
                            return GestureDetector(
                              onTap: () => _toggleSelection(asset),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (snapshot.hasData && snapshot.data != null)
                                    Image.memory(snapshot.data!, fit: BoxFit.cover)
                                  else
                                    Container(color: Colors.grey.shade200),
                                  if (isSelected)
                                    Container(
                                      color: Colors.black45,
                                      child: const Center(
                                        child: Icon(Icons.check_circle, color: Colors.white, size: 30),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
    );
  }
} 