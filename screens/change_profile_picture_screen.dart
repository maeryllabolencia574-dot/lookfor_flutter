import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChangeProfilePictureScreen extends StatefulWidget {
  final String? currentImageUrl;

  const ChangeProfilePictureScreen({
    super.key,
    this.currentImageUrl,
  });

  @override
  State<ChangeProfilePictureScreen> createState() =>
      _ChangeProfilePictureScreenState();
}

class _ChangeProfilePictureScreenState
    extends State<ChangeProfilePictureScreen> {
  File? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Change Profile Picture",
          style: TextStyle(color: Color(0xFF0066CC)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0066CC)),
        elevation: 1,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // PROFILE PREVIEW
            CircleAvatar(
              radius: 70,
              backgroundColor: const Color(0xFF005BAB),
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : widget.currentImageUrl != null
                      ? NetworkImage(widget.currentImageUrl!)
                          as ImageProvider
                      : null,
              child: _selectedImage == null &&
                      widget.currentImageUrl == null
                  ? const Icon(Icons.person,
                      size: 70, color: Colors.white)
                  : null,
            ),

            const SizedBox(height: 30),

            // PICK BUTTONS
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text("Select from Gallery"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Take a Photo"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0066CC),
                  side: const BorderSide(color: Color(0xFF0066CC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
            ),

            const Spacer(),

            // ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE000),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _selectedImage == null
                        ? null
                        : () {
                            Navigator.pop(context, {
                              "image": _selectedImage,
                            });
                          },
                    child: const Text("Save"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}