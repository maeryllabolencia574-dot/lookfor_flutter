import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String studentId;
  final String email;
  final String course;
  final String section;
  final String phone;
  final String? profileImage;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.studentId,
    required this.email,
    required this.course,
    required this.section,
    required this.phone,
    this.profileImage,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _phoneController;
  File? _newImage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone);
    _phoneController.addListener(() {
      _hasChanges = true;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ---------------- PICK IMAGE ----------------
  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _newImage = File(picked.path);
        _hasChanges = true;
      });
    }
  }

  // ---------------- CONFIRM SAVE ----------------
  void _confirmSave() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Save Changes"),
        content: const Text("Do you want to apply these changes?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                "phone": _phoneController.text,
                "image": _newImage,
              });
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------------- CONFIRM EXIT ----------------
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Discard Changes"),
        content:
            const Text("You have unsaved changes. Discard them?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  
  @override
  
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text("Edit Profile")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ---------------- PROFILE IMAGE ----------------
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: const Color(0xFF005BAB),
                      backgroundImage: _newImage != null
                          ? FileImage(_newImage!)
                          : widget.profileImage != null
                              ? NetworkImage(widget.profileImage!)
                                  as ImageProvider
                              : null,
                      child: _newImage == null &&
                              widget.profileImage == null
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.white)
                          : null,
                    ),
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.camera_alt,
                          size: 18, color: Color(0xFF005BAB)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              

              // ---------------- INFO CARD ----------------
              _infoCard([
                _infoRow("Username", widget.name),
                _infoRow("Student ID", widget.studentId),
                _infoRow("Email", widget.email),
                _editablePhone(),
                _infoRow("Course", widget.course),
                _infoRow("Section", widget.section),
              ]),

              const SizedBox(height: 30),

              // ---------------- SAVE BUTTON ----------------
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _confirmSave,
                  child: const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI HELPERS ----------------
  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFCC00)),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(children: children),
    );
  }
  

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child:
                Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 6,
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
  

  Widget _editablePhone() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: "Phone Number",
          filled: true,
          fillColor: Color(0xFFF2F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}