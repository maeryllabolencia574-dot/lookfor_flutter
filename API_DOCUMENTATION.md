# LookFor Backend API Documentation
**Base URL:** `http://127.0.0.1:8000` (local) or your deployed server URL

---

## 🔐 Authentication APIs

### 1. Login
**POST** `/token`
```dart
// Request (Form Data)
{
  "username": "admin@novaliches.sti.edu.ph",  // email
  "password": "STI_Admin_2026"
}

// Response (Success)
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "is_admin": true
}

// Response (MFA Required)
{
  "step": "mfa_required",
  "email": "user@example.com",
  "expires_in_minutes": 10
}

// Response (Error)
{
  "detail": "invalid_email" | "wrong_password"
}
```

### 2. Verify MFA Code
**POST** `/auth/verify-mfa`
```dart
// Request (JSON)
{
  "email": "user@example.com",
  "code": "123456"
}

// Response
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "is_admin": false
}
```

### 3. Request Password Reset
**POST** `/auth/request-password-reset`
```dart
// Request (JSON)
{
  "email": "user@example.com"
}

// Response
{
  "status": "reset_code_sent",
  "email": "user@example.com",
  "expires_in_minutes": 10
}
```

### 4. Reset Password with Code
**POST** `/auth/reset-password`
```dart
// Request (JSON)
{
  "email": "user@example.com",
  "code": "123456",
  "new_password": "NewPassword123!"
}

// Response
{
  "status": "password_reset_success"
}
```

### 5. Change Password
**POST** `/auth/change-password`
**Headers:** `Authorization: Bearer {token}`
```dart
// Request (JSON)
{
  "current_password": "OldPassword123",  // optional if must_change_password
  "new_password": "NewPassword123!"
}

// Response
{
  "message": "Password updated successfully"
}
```

### 6. Get Auth Settings
**GET** `/auth/settings`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "two_factor": false,
  "notifications": true,
  "theme": "light",
  "font_size": 16
}
```

### 7. Update Auth Settings
**POST** `/auth/settings`
**Headers:** `Authorization: Bearer {token}`
```dart
// Request (JSON)
{
  "two_factor": true,
  "notifications": true,
  "theme": "dark",
  "font_size": 18
}

// Response
{
  "status": "success",
  "message": "Settings updated successfully"
}
```

### 8. Refresh Access Token
**POST** `/auth/refresh`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "is_admin": false
}
```

---

## 👤 User APIs

### 9. Get Current User Profile
**GET** `/api/current-user`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "id": 1,
  "email": "user@example.com",
  "full_name": "John Doe",
  "student_no": "2024-001",
  "course": "BSIT",
  "section": "4A",
  "level": "G12",
  "department": null,
  "profile_pic": "static/photos/default-student-avatar.jpg",
  "is_admin": false,
  "role_label": "Student",
  "is_student_active": true,
  "must_change_password": false,
  "two_factor_enabled": false,
  "push_notifications": true,
  "theme_mode": "light",
  "font_size": 16
}
```

### 10. Search Users
**GET** `/api/users/search?q={query}`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
[
  {
    "id": 2,
    "email": "student@example.com",
    "full_name": "Jane Smith",
    "role_label": "Student",
    "student_no": "2024-002"
  }
]
```

### 11. Get All Users (Admin Only)
**GET** `/admin/get-all-users`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
[
  {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "student_no": "2024-001",
    "course": "BSIT",
    "section": "4A",
    "department": null,
    "is_admin": false,
    "is_archived": false,
    "permissions": ["Student-Portal-Access"],
    "last_login": "2024-01-15T10:30:00"
  }
]
```

---

## 📦 Items APIs

### 12. Report Found Item (Student)
**POST** `/student/found`
**Headers:** `Authorization: Bearer {token}`
**Content-Type:** `multipart/form-data`
```dart
// Request (Form Data)
{
  "item_name": "Blue Wallet",
  "category": "Wallet",
  "brand": "Nike",
  "color": "Blue",
  "location": "Library",
  "date": "2024-01-15",
  "time_found": "10:30 AM",
  "description": "Found near the entrance",
  "main_image": File,
  "reference_image_1": File (optional),
  "reference_image_2": File (optional)
}

// Response
{
  "message": "Found item reported successfully",
  "item_id": 123
}
```

### 13. Report Lost Item (Student)
**POST** `/student/items/lost/report`
**Headers:** `Authorization: Bearer {token}`
**Content-Type:** `multipart/form-data`
```dart
// Request (Form Data)
{
  "item_name": "Red Backpack",
  "category": "Bag",
  "brand": "Adidas",
  "color": "Red",
  "location": "Cafeteria",
  "date": "2024-01-15",
  "description": "Lost during lunch break",
  "main_image": File,
  "reference_image_1": File (optional),
  "reference_image_2": File (optional)
}

// Response
{
  "message": "Lost item report submitted successfully",
  "item_id": 124,
  "possible_matches": [
    {
      "id": 123,
      "score": 0.85,
      "category": "Bag",
      "location": "Library",
      "image_path": "static/uploads/bag/abc123.jpg"
    }
  ]
}
```

### 14. Get My Found Items (Student)
**GET** `/student/items/found/me`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
[
  {
    "id": 123,
    "category": "Wallet",
    "brand": "Nike",
    "color": "Blue",
    "location": "Library",
    "date": "2024-01-15",
    "time_found": "10:30 AM",
    "description": "Found near the entrance",
    "image_path": "static/uploads/wallet/xyz789.jpg",
    "status": "found",
    "is_matched": false,
    "created_at": "2024-01-15T10:35:00"
  }
]
```

### 15. Get My Lost Reports (Student)
**GET** `/student/api/items/lost/me`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
[
  {
    "id": 124,
    "category": "Bag",
    "brand": "Adidas",
    "color": "Red",
    "location": "Cafeteria",
    "date": "2024-01-15",
    "description": "Lost during lunch break",
    "image_path": "static/uploads/bag/def456.jpg",
    "status": "lost",
    "is_matched": false,
    "possible_matches": [...],
    "created_at": "2024-01-15T12:00:00"
  }
]
```

### 16. Get Found Items (Admin)
**GET** `/admin/items/found`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
[
  {
    "id": 123,
    "category": "Wallet",
    "description": "Blue Nike wallet",
    "location": "Library",
    "date": "2024-01-15",
    "image_path": "static/uploads/wallet/xyz789.jpg",
    "status": "found",
    "archived": false
  }
]
```

### 17. Get Lost Items (Admin)
**GET** `/admin/items/lost`
**Headers:** `Authorization: Bearer {token}`

### 18. Get Archived Found Items (Admin)
**GET** `/admin/items/found/archived`
**Headers:** `Authorization: Bearer {token}`

### 19. Get Archived Lost Items (Admin)
**GET** `/admin/items/lost/archived`
**Headers:** `Authorization: Bearer {token}`

### 20. Get Item Possible Matches
**GET** `/api/items/{item_id}/possible-matches`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "item_id": 124,
  "matches": [
    {
      "id": 123,
      "score": 0.85,
      "category": "Bag",
      "brand": "Adidas",
      "color": "Red",
      "location": "Library",
      "image_path": "static/uploads/bag/abc123.jpg",
      "description": "Red Adidas backpack"
    }
  ]
}
```

### 21. Quick Search (Text-based)
**GET** `/api/quick-search?q={query}&category={category}`
```dart
// Response
{
  "match_found": true,
  "match_percentage": 75.5,
  "total_items": 100,
  "matched_items": 75
}
```

### 22. Quick Compare (Image-based)
**POST** `/api/quick-compare`
**Content-Type:** `multipart/form-data`
```dart
// Request
{
  "file": File
}

// Response
{
  "highest_score": 0.87,
  "matched_item": {
    "id": 123,
    "category": "Wallet",
    "description": "Blue Nike wallet",
    "image_path": "static/uploads/wallet/xyz789.jpg"
  }
}
```

### 23. Compare Text Details
**POST** `/api/compare-text-details`
**Content-Type:** `multipart/form-data`
```dart
// Request
{
  "category": "Wallet",
  "location": "Library",
  "date": "2024-01-15",
  "description": "Blue wallet",
  "brand": "Nike",
  "color": "Blue"
}

// Response
{
  "highest_score": 0.82,
  "matched_items": [...]
}
```

---

## 🔔 Notifications APIs

### 24. Get Student Notifications
**GET** `/student/notifications`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
[
  {
    "id": 1,
    "message": "A potential match was found for your lost item",
    "type": "student_match",
    "target_url": "/student/Lost-report",
    "is_read": false,
    "created_at": "2024-01-15T10:00:00"
  }
]
```

### 25. Get Unread Notification Count
**GET** `/student/notifications/unread-count`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "unread_count": 3
}
```

### 26. Mark Notification as Read
**POST** `/student/notifications/{notif_id}/read`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "status": "success"
}
```

---

## 💬 Messaging APIs

### 27. Get Chat History
**GET** `/api/messages/history/{other_user_id}`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
[
  {
    "id": 1,
    "sender_id": 1,
    "recipient_id": 2,
    "content": "Hello, I found your wallet",
    "created_at": "2024-01-15T10:00:00",
    "status": "read"
  }
]
```

### 28. Send Message
**POST** `/api/messages/send`
**Headers:** `Authorization: Bearer {token}`
**Content-Type:** `multipart/form-data`
```dart
// Request
{
  "recipient_id": 2,
  "content": "Hello, I found your wallet"
}

// Response
{
  "status": "success"
}
```

### 29. Mark Chat as Read
**POST** `/api/messages/read/{other_user_id}`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "success": true,
  "updated": 3
}
```

### 30. Delete Conversation
**DELETE** `/api/messages/conversation/{other_user_id}`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "success": true,
  "deleted": 5
}
```

### 31. Get Unread Message Count
**GET** `/admin/api/messages/unread-count`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "unread_count": 5
}
```

---

## 🎯 Claims APIs

### 32. Get Claims (Admin)
**GET** `/api/admin/claims`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
[
  {
    "id": 1,
    "lost_item_id": 124,
    "found_item_id": 123,
    "claimant_id": 2,
    "similarity_score": "0.85",
    "status": "pending",
    "created_at": "2024-01-15T10:00:00",
    "lost_item": {...},
    "found_item": {...},
    "claimant": {...}
  }
]
```

### 33. Approve Claim (Admin)
**POST** `/api/admin/claims/{claim_id}/approve`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "message": "Claim approved successfully"
}
```

### 34. Reject Claim (Admin)
**POST** `/api/admin/claims/{claim_id}/reject`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "message": "Claim rejected successfully"
}
```

### 35. Create Manual Claim (Admin)
**POST** `/api/admin/manual-claim`
**Headers:** `Authorization: Bearer {token}`
**Content-Type:** `multipart/form-data`
```dart
// Request
{
  "found_item_id": 123,
  "claimant_user_id": 2,
  "claim_id_image": File (optional)
}

// Response
{
  "message": "Manual claim created successfully",
  "claim_id": 1
}
```

---

## 📊 Categories & Departments APIs

### 36. Get Categories
**GET** `/api/categories`
```dart
// Response
[
  {
    "id": 1,
    "name": "Wallet"
  },
  {
    "id": 2,
    "name": "Bag"
  }
]
```

### 37. Get Departments (Admin)
**GET** `/admin/departments`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
[
  {
    "id": 1,
    "name": "Library"
  },
  {
    "id": 2,
    "name": "IT Department"
  }
]
```

### 38. Create Category (Admin)
**POST** `/admin/categories`
**Headers:** `Authorization: Bearer {token}`
```dart
// Request (JSON)
{
  "name": "Electronics"
}

// Response
{
  "message": "Category created successfully",
  "category_id": 3
}
```

### 39. Delete Category (Admin)
**DELETE** `/admin/categories/{category_id}`
**Headers:** `Authorization: Bearer {token}`

---

## 📢 Announcements APIs

### 40. Get Announcements
**GET** `/api/announcements`
```dart
// Response
[
  {
    "id": 1,
    "title": "New Lost and Found System",
    "content": "We've launched a new AI-powered system...",
    "image_url": "/static/photos/announcement.jpg",
    "created_at": "2024-01-15T10:00:00"
  }
]
```

---

## 👥 Admin User Management APIs

### 41. Create Admin
**POST** `/admin/create-new-admin`
**Headers:** `Authorization: Bearer {token}`
```dart
// Request (JSON)
{
  "full_name": "Admin User",
  "email": "admin@example.com",
  "permissions": ["User-Management", "User-Management-Edit"],
  "department": "IT Department",
  "section": null
}

// Response
{
  "message": "Admin created successfully",
  "user_id": 5,
  "temp_password": "TempPass123"
}
```

### 42. Update User Permissions (Admin)
**POST** `/admin/update-permissions/{user_id}`
**Headers:** `Authorization: Bearer {token}`
```dart
// Request (JSON)
{
  "permissions": ["User-Management", "User-Management-Edit"]
}

// Response
{
  "message": "Permissions updated successfully"
}
```

### 43. Activate Students (Admin)
**POST** `/admin/activate-students`
**Headers:** `Authorization: Bearer {token}`
```dart
// Request (JSON)
{
  "user_ids": [1, 2, 3]
}

// Response
{
  "message": "3 user account(s) activated successfully.",
  "count": 3,
  "requested_count": 3
}
```

### 44. Deactivate Students (Admin)
**POST** `/admin/deactivate-students`
**Headers:** `Authorization: Bearer {token}`
```dart
// Request (JSON)
{
  "user_ids": [1, 2, 3]
}
```

### 45. Bulk Register Students (Admin)
**POST** `/admin/bulk-register-students`
**Headers:** `Authorization: Bearer {token}`
```dart
// Request (JSON)
{
  "students": [
    {
      "student_id": "2024-001",
      "last_name": "Doe",
      "first_name": "John",
      "middle_name": "M",
      "program": "BSIT",
      "level": "G12"
    }
  ],
  "duplicate_action": "skip" // or "replace"
}

// Response
{
  "job_id": "abc123",
  "message": "Bulk registration started"
}
```

### 46. Get Bulk Registration Status (Admin)
**GET** `/admin/bulk-register-students/status/{job_id}`
**Headers:** `Authorization: Bearer {token}`
```dart
// Response
{
  "status": "completed",
  "progress": 100,
  "processed": 50,
  "summary": {
    "total": 50,
    "created": 45,
    "replaced": 0,
    "ignored": 5
  }
}
```

### 47. Archive User (Admin)
**POST** `/admin/toggle-archive/{user_id}`
**Headers:** `Authorization: Bearer {token}`

### 48. Bulk Archive Users (Admin)
**POST** `/admin/bulk-toggle-archive`
**Headers:** `Authorization: Bearer {token}`

### 49. Delete User (Admin)
**DELETE** `/admin/permanent-delete/{user_id}`
**Headers:** `Authorization: Bearer {token}`

---

## 📱 Student Profile APIs

### 50. Update Student Profile
**POST** `/student/update-profile`
**Headers:** `Authorization: Bearer {token}`
**Content-Type:** `multipart/form-data`
```dart
// Request
{
  "full_name": "John Doe",
  "student_no": "2024-001",
  "course": "BSIT",
  "section": "4A",
  "profile_pic": File (optional)
}

// Response
{
  "message": "Student profile updated successfully"
}
```

### 51. Update Student Settings
**POST** `/student/update-settings`
**Headers:** `Authorization: Bearer {token}`
```dart
// Request (JSON)
{
  "two_factor": true,
  "notifications": true,
  "theme": "dark",
  "font_size": 18
}

// Response
{
  "status": "success",
  "message": "Settings updated successfully"
}
```

---

## 📈 Reports APIs (Admin)

### 52. Get Report Module Data
**GET** `/api/admin/report-module?report_type={type}&date_range={range}&start_date={start}&end_date={end}&category={cat}&location={loc}`
**Headers:** `Authorization: Bearer {token}`
```dart
// Query Parameters:
// - report_type: "all" | "lost" | "found"
// - date_range: "today" | "week" | "month" | "custom"
// - start_date: "2024-01-01" (for custom range)
// - end_date: "2024-01-31" (for custom range)
// - category: "Wallet" (optional filter)
// - location: "Library" (optional filter)

// Response
{
  "rows": [
    {
      "id": 123,
      "category": "Wallet",
      "description": "Blue Nike wallet",
      "location": "Library",
      "date": "2024-01-15",
      "status": "found",
      "reporter_name": "John Doe",
      "reporter_email": "john@example.com"
    }
  ]
}
```

---

## 🔧 Content Management APIs (Admin)

### 53. Get Landing Content
**GET** `/api/content/landing`
```dart
// Response
{
  "hero": {
    "title": "Welcome to LookFor",
    "description": "AI-powered lost and found system",
    "image_path": "/static/images/hero.jpg"
  },
  "features": [...],
  "about": {...}
}
```

### 54. Update Bulk Content (Admin)
**POST** `/admin/api/update-content/bulk`
**Headers:** `Authorization: Bearer {token}`
**Content-Type:** `multipart/form-data`
```dart
// Request
{
  "hero_title": "New Title",
  "hero_description": "New Description",
  "hero_image": File (optional),
  // ... other fields
}

// Response
{
  "message": "Content updated successfully"
}
```

---

## 🔑 Important Notes for Flutter Integration

### Authentication Header
All authenticated endpoints require:
```dart
headers: {
  'Authorization': 'Bearer $accessToken',
}
```

### File Upload
Use `multipart/form-data` for file uploads:
```dart
var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/student/found'));
request.headers['Authorization'] = 'Bearer $accessToken';
request.files.add(await http.MultipartFile.fromPath('main_image', imagePath));
request.fields['item_name'] = 'Blue Wallet';
```

### Error Handling
```dart
// Common error responses:
{
  "detail": "error_message"
}

// HTTP Status Codes:
// 200: Success
// 400: Bad Request
// 401: Unauthorized (invalid/expired token)
// 403: Forbidden (insufficient permissions)
// 404: Not Found
// 500: Internal Server Error
```

### Token Refresh
Tokens expire after 30 minutes. Use `/auth/refresh` to get a new token before expiry.

### Image URLs
All image paths are relative. Prepend base URL:
```dart
String imageUrl = '$baseUrl/${item.image_path}';
```

---

## 📝 Example Flutter HTTP Service

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  String? _accessToken;

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
      return data;
    } else {
      throw Exception(json.decode(response.body)['detail']);
    }
  }

  // Get Current User
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/current-user'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user');
    }
  }

  // Report Found Item
  Future<Map<String, dynamic>> reportFoundItem({
    required String itemName,
    required String category,
    required String location,
    required String date,
    required String imagePath,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/student/found'),
    );

    request.headers['Authorization'] = 'Bearer $_accessToken';
    request.fields['item_name'] = itemName;
    request.fields['category'] = category;
    request.fields['location'] = location;
    request.fields['date'] = date;
    request.files.add(
      await http.MultipartFile.fromPath('main_image', imagePath),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to report item');
    }
  }
}
```

---

**Generated:** 2024-01-15  
**Version:** 1.0  
**Backend:** FastAPI + Python 3.9+
