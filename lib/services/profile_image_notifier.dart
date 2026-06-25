import 'package:flutter/foundation.dart';

final ValueNotifier<int> profileImageVersion = ValueNotifier<int>(0);
final ValueNotifier<String?> profileImageUrl = ValueNotifier<String?>(null);

void notifyProfileImageChanged() {
  profileImageVersion.value++;
}

void setProfileImageUrl(String? imageUrl) {
  if (profileImageUrl.value == imageUrl) return;
  profileImageUrl.value = imageUrl;
  notifyProfileImageChanged();
}
