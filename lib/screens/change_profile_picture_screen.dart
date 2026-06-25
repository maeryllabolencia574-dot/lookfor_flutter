import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChangeProfilePictureScreen extends StatefulWidget {
  final String? currentImageUrl;

  const ChangeProfilePictureScreen({super.key, this.currentImageUrl});

  @override
  State<ChangeProfilePictureScreen> createState() =>
      _ChangeProfilePictureScreenState();
}

class _ChangeProfilePictureScreenState
    extends State<ChangeProfilePictureScreen> {
  File? _selectedImage;
  bool _showDefaultPreview = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _showDefaultPreview = false;
      });
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _showDefaultPreview = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Profile Picture")),
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
                  : !_showDefaultPreview && widget.currentImageUrl != null
                  ? NetworkImage(widget.currentImageUrl!) as ImageProvider
                  : null,
              child:
                  _selectedImage == null &&
                      (_showDefaultPreview || widget.currentImageUrl == null)
                  ? const Icon(Icons.person, size: 70, color: Colors.white)
                  : null,
            ),

            const SizedBox(height: 12),
            Text(
              _selectedImage != null
                  ? "New photo selected"
                  : _showDefaultPreview
                  ? "Default avatar preview"
                  : widget.currentImageUrl != null
                  ? "Current profile photo"
                  : "Default avatar",
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 26),

            // PICK BUTTONS
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text("Select from Gallery"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005BAB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
                  foregroundColor: const Color(0xFF005BAB),
                  side: const BorderSide(color: Color(0xFFB7C7DA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.restart_alt),
                  label: const Text("Remove selected photo"),
                  onPressed: _removeSelectedImage,
                ),
              ),
            ],

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
                            Navigator.pop(context, {"image": _selectedImage});
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
