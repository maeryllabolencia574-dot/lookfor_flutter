import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/profile_image_notifier.dart';

class ProfileAvatar extends StatefulWidget {
  final double radius;
  final Color backgroundColor;
  final Color iconColor;
  final double? iconSize;

  const ProfileAvatar({
    super.key,
    this.radius = 16,
    this.backgroundColor = const Color(0xFFDDDDDD),
    this.iconColor = const Color(0xFF003366),
    this.iconSize,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    profileImageVersion.addListener(_loadProfileImage);
    _loadProfileImage();
  }

  @override
  void dispose() {
    profileImageVersion.removeListener(_loadProfileImage);
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    final version = profileImageVersion.value;
    final cachedUrl = profileImageUrl.value;
    if (cachedUrl != null) {
      setState(() {
        _imageUrl = _withCacheVersion(cachedUrl, version);
      });
      return;
    }

    try {
      final userData = await apiClient.getCurrentUser();
      if (!mounted) return;

      final rawPath = userData['profile_pic']?.toString().trim();
      final nextUrl =
          rawPath == null || rawPath.isEmpty || _isDefaultProfilePath(rawPath)
          ? null
          : _withCacheVersion(apiClient.getImageUrl(rawPath), version);

      setState(() {
        _imageUrl = nextUrl;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _imageUrl = null;
      });
    }
  }

  String _withCacheVersion(String url, int version) {
    if (url.isEmpty) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=$version';
  }

  bool _isDefaultProfilePath(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('default-student-avatar') ||
        normalized.contains('default-profile') ||
        normalized.contains('default-avatar');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;
    final iconSize = widget.iconSize ?? widget.radius * 1.25;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
      onBackgroundImageError: imageUrl == null
          ? null
          : (exception, stackTrace) {},
      child: imageUrl == null
          ? Icon(Icons.person, color: widget.iconColor, size: iconSize)
          : null,
    );
  }
}
