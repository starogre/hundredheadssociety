import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload image and return the download URL
  Future<String?> uploadImage(File imageFile, String folder, String fileName) async {
    try {
      // Create a unique filename
      final extension = path.extension(imageFile.path);
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName$extension';
      
      // Create reference to the file location
      final storageRef = _storage.ref().child('$folder/$uniqueFileName');
      
      // Upload the file
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('Image deleted successfully: $imageUrl');
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
} 