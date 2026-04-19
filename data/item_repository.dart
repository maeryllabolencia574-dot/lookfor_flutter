import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/item_model.dart';

class ItemRepository {
  // ==================================================
  // LOCAL IN-MEMORY STORAGE (TEMPORARY)
  // ==================================================
  static final List<ItemReport> _items = [];

  /// Get items by type (Lost / Found)
  static List<ItemReport> getByType(String type) {
    return _items.where((item) => item.type == type).toList();
  }

  /// Add new item
  static void add(ItemReport item) {
    _items.add(item);
  }

  /// Update existing item
  static void update(ItemReport item) {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
  }

  /// Delete item by id
  static void delete(String id) {
    _items.removeWhere((e) => e.id == id);
  }

  // ==================================================
  // API CONFIG
  // ==================================================
  static const String baseUrl = 'http://YOUR_API_URL/api';

  // ==================================================
  // IMAGE UPLOAD
  // ==================================================
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/upload');

      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final responseBody =
          await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final json = jsonDecode(responseBody);
        return json['imageUrl'] as String?;
      } else {
        throw Exception(
          'Upload failed: ${streamedResponse.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Image upload error: $e');
    }
  }
  
static Future<String?> uploadPreviewImage(List<File> images) async {
    if (images.isEmpty) return null;

    // ✅ Upload only the FIRST image
    return await uploadImage(images.first);
  }

}
