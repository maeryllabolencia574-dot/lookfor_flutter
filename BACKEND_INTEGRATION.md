# Backend Integration Guide

## Overview
The Flutter app is now integrated with the FastAPI backend using the `ApiService` class.

## Configuration

### Base URL
The app automatically detects the platform and uses the appropriate localhost URL:
- **iOS Simulator**: `http://127.0.0.1:8000`
- **Android Emulator**: `http://10.0.2.2:8000`
- **Physical Device**: Update `lib/services/api_service.dart` to use your computer's IP address

### For Physical Devices
If testing on a physical device, update the `baseUrl` getter in `lib/services/api_service.dart`:

```dart
static String get baseUrl {
  return 'http://YOUR_COMPUTER_IP:8000'; // e.g., http://192.168.1.100:8000
}
```

## Features Integrated

### ✅ Authentication
- **Login** with email/password
- **MFA Verification** (2-factor authentication)
- **Password Reset** with OTP
- **Token Management** (automatic header injection)

### 🔄 Ready to Integrate
The following API methods are available in `ApiService` but not yet connected to UI:

#### User Management
- `getCurrentUser()` - Get current user profile
- `searchUsers(query)` - Search for users
- `updateProfile()` - Update student profile

#### Items
- `reportFoundItem()` - Report a found item with images
- `reportLostItem()` - Report a lost item with images
- `getMyFoundItems()` - Get user's found items
- `getMyLostReports()` - Get user's lost reports
- `getItemMatches(itemId)` - Get possible matches for an item

#### Notifications
- `getNotifications()` - Get all notifications
- `getUnreadNotificationCount()` - Get unread count
- `markNotificationAsRead(id)` - Mark as read

#### Messaging
- `getChatHistory(userId)` - Get chat with another user
- `sendMessage(recipientId, content)` - Send a message
- `markChatAsRead(userId)` - Mark conversation as read

#### Categories
- `getCategories()` - Get all item categories

#### Announcements
- `getAnnouncements()` - Get system announcements

## Usage Examples

### Login
```dart
import 'package:flutterlookfor/services/api_client.dart';

try {
  final response = await apiClient.login(email, password);
  
  if (response.containsKey('step') && response['step'] == 'mfa_required') {
    // Show MFA verification screen
  } else {
    // Login successful, navigate to dashboard
  }
} catch (e) {
  // Handle error
  print('Login failed: $e');
}
```

### Report Found Item
```dart
try {
  final result = await apiClient.reportFoundItem(
    itemName: 'Blue Wallet',
    category: 'Wallet',
    brand: 'Nike',
    color: 'Blue',
    location: 'Library',
    date: '2024-01-15',
    timeFound: '10:30 AM',
    description: 'Found near entrance',
    mainImage: File('/path/to/image.jpg'),
  );
  
  print('Item reported with ID: ${result['item_id']}');
} catch (e) {
  print('Failed to report item: $e');
}
```

### Get Current User
```dart
try {
  final user = await apiClient.getCurrentUser();
  print('Welcome ${user['full_name']}');
} catch (e) {
  print('Failed to load user: $e');
}
```

### Load Image from Backend
```dart
import 'package:cached_network_image/cached_network_image.dart';

// Get full image URL
String imageUrl = apiClient.getImageUrl(item['image_path']);

// Display image
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

## Error Handling

All API methods throw `ApiException` on failure:

```dart
try {
  await apiClient.someMethod();
} on ApiException catch (e) {
  // Handle API-specific errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
} catch (e) {
  // Handle other errors
  print('Unexpected error: $e');
}
```

## Token Management

The `ApiService` automatically manages authentication tokens:

```dart
// Check if authenticated
if (apiClient.isAuthenticated) {
  // User is logged in
}

// Check if admin
if (apiClient.isAdmin) {
  // Show admin features
}

// Logout
apiClient.clearToken();
```

## Next Steps

### 1. Update Inventory Screen
Replace the local `ItemRepository` with API calls:

```dart
// In lib/screens/inventory_screen.dart
Future<void> _loadItems() async {
  try {
    final items = widget.type == "Lost" 
        ? await apiClient.getMyLostReports()
        : await apiClient.getMyFoundItems();
    
    setState(() {
      _reports = items.map((json) => ItemReport.fromJson(json)).toList();
    });
  } catch (e) {
    // Handle error
  }
}
```

### 2. Update Dashboard
Load real statistics from the backend:

```dart
Future<void> _loadDashboardStats() async {
  try {
    final foundItems = await apiClient.getMyFoundItems();
    final lostItems = await apiClient.getMyLostReports();
    
    setState(() {
      foundCount = foundItems.length;
      lostCount = lostItems.length;
    });
  } catch (e) {
    // Handle error
  }
}
```

### 3. Implement Notifications
```dart
Future<void> _loadNotifications() async {
  try {
    final notifications = await apiClient.getNotifications();
    final unreadCount = await apiClient.getUnreadNotificationCount();
    
    setState(() {
      _notifications = notifications;
      _unreadCount = unreadCount;
    });
  } catch (e) {
    // Handle error
  }
}
```

### 4. Implement Messaging
```dart
Future<void> _loadChatHistory(int otherUserId) async {
  try {
    final messages = await apiClient.getChatHistory(otherUserId);
    setState(() {
      _chatHistory = messages;
    });
  } catch (e) {
    // Handle error
  }
}

Future<void> _sendMessage(int recipientId, String content) async {
  try {
    await apiClient.sendMessage(recipientId, content);
    await _loadChatHistory(recipientId); // Refresh
  } catch (e) {
    // Handle error
  }
}
```

## Testing

### Start Backend Server
```bash
cd backend
uvicorn main:app --reload
```

### Test Credentials
Use the credentials from your backend's database or create a test account.

### Common Issues

**Connection Refused**
- Ensure backend is running on `http://127.0.0.1:8000`
- For Android emulator, backend must be accessible at `10.0.2.2:8000`
- For physical devices, use your computer's local IP

**401 Unauthorized**
- Token expired - call `apiClient.refreshToken()`
- Invalid credentials - check email/password

**CORS Errors** (Web only)
- Add CORS middleware to FastAPI backend

## Dependencies

Add to `pubspec.yaml` if not already present:

```yaml
dependencies:
  http: ^1.6.0
  cached_network_image: ^3.3.0  # For image caching
```

## Security Notes

- Tokens are stored in memory only (not persisted)
- For production, use `flutter_secure_storage` to persist tokens securely
- Always use HTTPS in production
- Never commit API keys or secrets to version control

## API Documentation

Full API documentation is available in `API_DOCUMENTATION.md`.
