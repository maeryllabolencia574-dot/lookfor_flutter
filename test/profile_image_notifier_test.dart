import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterlookfor/services/profile_image_notifier.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildProfileImageProvider prefers local file over remote URL', () async {
    final tempDir = await Directory.systemTemp.createTemp();
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final tempFile = File(path.join(tempDir.path, 'profile_test.png'));
    await tempFile.writeAsBytes([1, 2, 3, 4]);

    final provider = buildProfileImageProvider(
      remoteUrl: 'https://example.com/profile.png',
      localPath: tempFile.path,
    );

    expect(provider, isA<FileImage>());
    expect((provider as FileImage).file.path, tempFile.path);
  });
}
