import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MultiImagePickerGallery extends StatefulWidget {
  final int maxSelection;
  final void Function(List<File> files) onSelectionDone;

  const MultiImagePickerGallery({
    super.key,
    required this.maxSelection,
    required this.onSelectionDone,
  });

  @override
  State<MultiImagePickerGallery> createState() => _MultiImagePickerGalleryState();
}

class _MultiImagePickerGalleryState extends State<MultiImagePickerGallery> {
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
  List<AssetEntity> _galleryImages = [];
  List<AssetEntity> _selected = [];
  bool _loading = true;
  bool _showAlbumPicker = true;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    setState(() => _loading = true);
    // Android 13+ uses READ_MEDIA_IMAGES, older uses READ_EXTERNAL_STORAGE
    final status = Platform.isAndroid
        ? (await Permission.photos.request())
        : await Permission.photos.request();
    if (status.isGranted) {
      _fetchAlbums();
    } else {
      setState(() => _loading = false);
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'This app needs access to your photos and media to select images.\n\n'
          'Please grant permission in your device settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAlbums() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) {
      setState(() => _loading = false);
      return;
    }
    
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  Future<void> _selectAlbum(AssetPathEntity album) async {
    setState(() {
      _selectedAlbum = album;
      _showAlbumPicker = false;
      _loading = true;
    });

    final images = await album.getAssetListPaged(page: 0, size: 200);
    setState(() {
      _galleryImages = images;
      _loading = false;
    });
  }

  void _toggleSelect(AssetEntity asset) {
    setState(() {
      if (_selected.contains(asset)) {
        _selected.remove(asset);
      } else if (_selected.length < widget.maxSelection) {
        _selected.add(asset);
      }
    });
  }

  Future<void> _finishSelection() async {
    List<File> files = [];
    for (final asset in _selected) {
      final file = await asset.file;
      if (file != null) files.add(file);
    }
    widget.onSelectionDone(files);
    Navigator.of(context).pop();
  }

  void _backToAlbums() {
    setState(() {
      _showAlbumPicker = true;
      _selectedAlbum = null;
      _galleryImages.clear();
      _selected.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showAlbumPicker ? 'Select Album' : _selectedAlbum?.name ?? 'Select Images'),
        leading: _showAlbumPicker 
            ? null 
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToAlbums,
              ),
        actions: [
          if (!_showAlbumPicker)
            TextButton(
              onPressed: _selected.isNotEmpty ? _finishSelection : null,
              child: Text('Done (${_selected.length}/${widget.maxSelection})', style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _showAlbumPicker
              ? _buildAlbumPicker()
              : _buildImageGrid(),
    );
  }

  Widget _buildAlbumPicker() {
    if (_albums.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No albums found', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Make sure you have images in your device', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return ListTile(
          leading: FutureBuilder<int>(
            future: album.assetCountAsync,
            builder: (context, snapshot) {
              return CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  snapshot.hasData ? '${snapshot.data}' : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          title: Text(album.name),
          subtitle: FutureBuilder<int>(
            future: album.assetCountAsync,
            builder: (context, snapshot) {
              return Text('${snapshot.data ?? 0} images');
            },
          ),
          onTap: () => _selectAlbum(album),
          trailing: const Icon(Icons.arrow_forward_ios),
        );
      },
    );
  }

  Widget _buildImageGrid() {
    if (_galleryImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No images found in ${_selectedAlbum?.name ?? "this album"}', 
                 style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Try selecting a different album', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _galleryImages.length,
      itemBuilder: (context, i) {
        final asset = _galleryImages[i];
        final isSelected = _selected.contains(asset);
        return GestureDetector(
          onTap: () => _toggleSelect(asset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AssetEntityImage(
                asset,
                fit: BoxFit.cover,
              ),
              if (isSelected)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
                ),
            ],
          ),
        );
      },
    );
  }
} 