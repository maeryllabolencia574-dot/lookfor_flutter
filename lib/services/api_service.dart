import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (Platform.isIOS) {
      return 'http://127.0.0.1:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

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

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
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

  Future<void> updateProfile({
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
      request.files.add(
        await http.MultipartFile.fromPath('profile_pic', profilePic.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw ApiException('Failed to update profile');
    }
  }

  Future<Map<String, dynamic>> reportFoundItem({
    required String itemName,
    required String category,
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
    request.fields['brand'] = brand;
    request.fields['color'] = color;
    request.fields['location'] = location;
    request.fields['date'] = date;
    request.fields['time_found'] = timeFound;
    request.fields['description'] = description;

    request.files.add(
      await http.MultipartFile.fromPath('main_image', mainImage.path),
    );

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

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to report found item');
    }
  }

  Future<Map<String, dynamic>> reportLostItem({
    required String itemName,
    required String category,
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
    request.fields['brand'] = brand;
    request.fields['color'] = color;
    request.fields['location'] = location;
    request.fields['date'] = date;
    request.fields['description'] = description;

    request.files.add(
      await http.MultipartFile.fromPath('main_image', mainImage.path),
    );

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

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException('Failed to report lost item');
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

  Future<void> markNotificationAsRead(int notificationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/notifications/$notificationId/read'),
      headers: _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw ApiException('Failed to mark notification as read');
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

  String getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    final path = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    return '$baseUrl/$path';
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
