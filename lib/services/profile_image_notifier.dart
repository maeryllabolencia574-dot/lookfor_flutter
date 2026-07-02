import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _persistedProfileImagePathKey = 'persisted_profile_image_path';

final ValueNotifier<int> profileImageVersion = ValueNotifier<int>(0);
final ValueNotifier<String?> profileImageUrl = ValueNotifier<String?>(null);

void notifyProfileImageChanged() {
  profileImageVersion.value++;
}

void setProfileImageUrl(String? imageUrl, {bool forceNotify = false}) {
  if (profileImageUrl.value == imageUrl) {
    if (forceNotify) notifyProfileImageChanged();
    return;
  }
  profileImageUrl.value = imageUrl;
  notifyProfileImageChanged();
}

ImageProvider? buildProfileImageProvider({
  String? remoteUrl,
  String? localPath,
}) {
  final resolvedLocalPath = localPath?.trim();
  if (resolvedLocalPath != null && resolvedLocalPath.isNotEmpty) {
    final localFile = File(resolvedLocalPath);
    if (localFile.existsSync()) {
      return FileImage(localFile);
    }
  }

  final resolvedRemoteUrl = remoteUrl?.trim();
  if (resolvedRemoteUrl != null && resolvedRemoteUrl.isNotEmpty) {
    return NetworkImage(resolvedRemoteUrl);
  }

  return null;
}

Future<String?> getPersistedProfileImagePath() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_persistedProfileImagePathKey);
}

Future<String?> persistProfileImageLocally(File imageFile) async {
  final appDir = await getApplicationDocumentsDirectory();
  final imageDir = Directory(path.join(appDir.path, 'profile_images'));
  await imageDir.create(recursive: true);

  final extension = path.extension(imageFile.path);
  final safeExtension = extension.isEmpty ? '.jpg' : extension;
  final fileName = '${DateTime.now().millisecondsSinceEpoch}$safeExtension';
  final savedFile = await imageFile.copy(path.join(imageDir.path, fileName));

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_persistedProfileImagePathKey, savedFile.path);

  return savedFile.path;
}
