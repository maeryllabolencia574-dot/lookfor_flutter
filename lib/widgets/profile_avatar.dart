import 'package:flutter/material.dart';
import 'dart:io';
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
  String? _localPath;

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
    final savedPath = await getPersistedProfileImagePath();
    final resolvedLocalPath = savedPath != null && File(savedPath).existsSync()
        ? savedPath
        : null;

    if (resolvedLocalPath != null) {
      if (!mounted) return;
      setState(() {
        _imageUrl = null;
        _localPath = resolvedLocalPath;
      });
      return;
    }

    final cachedUrl = profileImageUrl.value;
    if (cachedUrl != null) {
      if (!mounted) return;
      setState(() {
        _imageUrl = _withCacheVersion(cachedUrl, version);
        _localPath = null;
      });
      return;
    }

    try {
      final userData = await apiClient.getCurrentUser();
      if (!mounted) return;

      final nextUrl = _withCacheVersion(
        apiClient.getProfileImageUrl(userData['profile_pic']),
        version,
      );

      setState(() {
        _imageUrl = nextUrl;
        _localPath = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _imageUrl = null;
        _localPath = null;
      });
    }
  }

  String? _withCacheVersion(String? url, int version) {
    if (url == null || url.isEmpty) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=$version';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;
    final localPath = _localPath;
    final iconSize = widget.iconSize ?? widget.radius * 1.25;
    final imageProvider = buildProfileImageProvider(
      remoteUrl: imageUrl,
      localPath: localPath,
    );

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: imageProvider,
      onBackgroundImageError: imageProvider == null
          ? null
          : (exception, stackTrace) {},
      child: imageProvider == null
          ? Icon(Icons.person, color: widget.iconColor, size: iconSize)
          : null,
    );
  }
}
