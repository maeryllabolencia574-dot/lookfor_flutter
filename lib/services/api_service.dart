import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'https://lookfor-app-aafd5427.azurewebsites.net';

  String? _accessToken;
  bool? _isAdmin;

  String? get accessToken => _accessToken;
  bool get isAdmin => _isAdmin ?? false;
  bool get isAuthenticated => _accessToken != null;

  void setToken(String token, {bool isAdmin = false}) {
    _accessToken = token;
    _isAdmin = isAdmin;
  }

  void clearToken() {
    _accessToken = null;
    _isAdmin = null;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.containsKey('step') && data['step'] == 'mfa_required') {
        return data;
      }

      _accessToken = data['access_token'];
      _isAdmin = data['is_admin'] ?? false;
      return data;
    } else {
      final error = json.decode(response.body);
      throw ApiException(error['detail'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> verifyMfa(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-mfa'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
      _isAdmin = data['is_admin'] ?? false;
      return data;
    } else {
      throw ApiException('Invalid MFA code');
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/request-password-reset'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to send reset code');
    }
  }

  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException('Failed to reset password');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _authHeaders(),
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException('Failed to change password');
    }
  }

  Future<void> refreshToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
    } else {
      throw ApiException('Token refresh failed');
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/current-user'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to load user profile');
    }
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/search?q=$query'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to search users');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String studentNo,
    required String course,
    required String section,
    File? profilePic,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/student/update-profile'),
    );

    request.headers['Authorization'] = 'Bearer $_accessToken';
    request.fields['full_name'] = fullName;
    request.fields['student_no'] = studentNo;
    request.fields['course'] = course;
    request.fields['section'] = section;

    if (profilePic != null) {
      request.files.add(await _buildImagePart('profile_pic', profilePic));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) return <String, dynamic>{};
      final decoded = json.decode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }

    dynamic error;
    try {
      error = json.decode(response.body);
    } catch (_) {}
    throw ApiException(
      _extractErrorMessage(error) ??
          'Failed to update profile (${response.statusCode})',
    );
  }

  Future<Map<String, dynamic>> reportFoundItem({
    required String itemName,
    required String category,
    int? categoryId,
    required String brand,
    required String color,
    required String location,
    required String date,
    required String timeFound,
    required String description,
    required File mainImage,
    File? referenceImage1,
    File? referenceImage2,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/student/found'),
    );

    request.headers['Authorization'] = 'Bearer $_accessToken';
    request.fields['item_name'] = itemName;
    request.fields['category'] = category;
    if (categoryId != null) {
      request.fields['category_id'] = categoryId.toString();
    }
    request.fields['brand'] = brand;
    request.fields['color'] = color;
    request.fields['location'] = location;
    request.fields['date'] = date;
    request.fields['time_found'] = timeFound;
    request.fields['description'] = description;

    request.files.add(await _buildImagePart('image', mainImage));

    if (referenceImage1 != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'reference_image_1',
          referenceImage1.path,
        ),
      );
    }

    if (referenceImage2 != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'reference_image_2',
          referenceImage2.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      dynamic error;
      try {
        error = json.decode(response.body);
      } catch (_) {}
      throw ApiException(
        _extractErrorMessage(error) ??
            'Failed to report found item (${response.statusCode})',
      );
    }
  }

  Future<Map<String, dynamic>> reportLostItem({
    required String itemName,
    required String category,
    int? categoryId,
    required String brand,
    required String color,
    required String location,
    required String date,
    required String description,
    required File mainImage,
    File? referenceImage1,
    File? referenceImage2,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/student/items/lost/report'),
    );

    request.headers['Authorization'] = 'Bearer $_accessToken';
    request.fields['item_name'] = itemName;
    request.fields['category'] = category;
    if (categoryId != null) {
      request.fields['category_id'] = categoryId.toString();
    }
    request.fields['brand'] = brand;
    request.fields['color'] = color;
    request.fields['location'] = location;
    request.fields['date'] = date;
    request.fields['description'] = description;

    request.files.add(await _buildImagePart('image', mainImage));

    if (referenceImage1 != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'reference_image_1',
          referenceImage1.path,
        ),
      );
    }

    if (referenceImage2 != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'reference_image_2',
          referenceImage2.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      dynamic error;
      try {
        error = json.decode(response.body);
      } catch (_) {}
      throw ApiException(
        _extractErrorMessage(error) ??
            'Failed to report lost item (${response.statusCode})',
      );
    }
  }

  Future<List<dynamic>> getMyFoundItems() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/items/found/me'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to load found items');
    }
  }

  Future<List<dynamic>> getMyLostReports() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/api/items/lost/me'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to load lost reports');
    }
  }

  Future<Map<String, dynamic>> getItemMatches(int itemId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/items/$itemId/possible-matches'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to load matches');
    }
  }

  Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/categories'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to load categories');
    }
  }

  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/notifications'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to load notifications');
    }
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/notifications/unread-count'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['unread_count'];
    } else {
      throw ApiException('Failed to load notification count');
    }
  }

  Future<void> markNotificationAsRead(int notif_id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/notifications/$notif_id/read'),
      headers: _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw ApiException('Failed to mark notification as read');
    }
  }
  Future<void> markAllNotificationsAsRead() async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/notifications/mark-all-read'),
      headers: _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw ApiException('Failed to mark all notifications as read');
    }
  }

  Future<List<dynamic>> getChatHistory(int otherUserId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/messages/history/$otherUserId'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to load chat history');
    }
  }

  Future<void> sendMessage(int recipientId, String content) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/messages/send'),
    );

    request.headers['Authorization'] = 'Bearer $_accessToken';
    request.fields['recipient_id'] = recipientId.toString();
    request.fields['content'] = content;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw ApiException('Failed to send message');
    }
  }

  Future<void> markChatAsRead(int otherUserId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/messages/read/$otherUserId'),
      headers: _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw ApiException('Failed to mark chat as read');
    }
  }

  Future<List<dynamic>> getAnnouncements() async {
    final response = await http.get(Uri.parse('$baseUrl/api/announcements'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to load announcements');
    }
  }

  Map<String, String> _authHeaders() {
    if (_accessToken == null) {
      throw ApiException('Not authenticated');
    }
    return {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
    };
  }

  String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return '';
    }
    final value = imagePath.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;

    final path = value.startsWith('/') ? value.substring(1) : value;
    return '$baseUrl/$path';
  }

  String? getProfileImageUrl(dynamic profilePic) {
    final rawPath = profilePic?.toString().trim();
    if (rawPath == null || rawPath.isEmpty || _isDefaultProfilePath(rawPath)) {
      return null;
    }
    return getImageUrl(rawPath);
  }

  Future<http.MultipartFile> _buildImagePart(String fieldName, File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      _ => throw ApiException(
        'Unsupported image type "$extension". Please upload JPG, JPEG, PNG, or WEBP.',
      ),
    };

    return http.MultipartFile.fromPath(
      fieldName,
      file.path,
      contentType: mediaType,
    );
  }

  String? _extractErrorMessage(dynamic error) {
    if (error is Map<String, dynamic>) {
      final detail = error['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) {
        return detail
            .map((entry) {
              if (entry is Map<String, dynamic>) {
                final location = entry['loc'];
                final message = entry['msg'];
                final images = entry['images'];
                if (images is List && images.isNotEmpty) {
                  return 'Image upload error: ${images.join(', ')}';
                }
                if (message is String) {
                  if (location is List && location.isNotEmpty) {
                    return '${location.join('.')} $message';
                  }
                  return message;
                }
              }
              return entry.toString();
            })
            .join('\n');
      }

      final message = error['message'];
      if (message is String && message.isNotEmpty) return message;
    }

    return null;
  }

  bool _isDefaultProfilePath(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('default-student-avatar') ||
        normalized.contains('default-profile') ||
        normalized.contains('default-avatar');
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
