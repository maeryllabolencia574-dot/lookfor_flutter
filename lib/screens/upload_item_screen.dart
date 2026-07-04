import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item_model.dart';

class UploadItemScreen extends StatefulWidget {
  final String type; // "Lost" or "Found"
  final ItemReport? draftReport;
  final List<File> draftImages;
  final List<String> categories;
  final Map<String, int> categoryIdsByName;

  const UploadItemScreen({
    super.key,
    required this.type,
    this.draftReport,
    required this.draftImages,
    required this.categories,
    required this.categoryIdsByName,
  });

  @override
  State<UploadItemScreen> createState() => _UploadItemScreenState();
}

class _UploadItemScreenState extends State<UploadItemScreen> {
  static const int _maxImages = 3;
  static const List<String> _allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  static const String _selectCategoryValue = 'Select category';
  static const String _otherCategoryValue = 'Others';

  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _color;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _otherCategory;

  late String _category;
  late TimeOfDay _timeLocated;
  late DateTime _dateLocated;
  late List<File> _images;

  @override
  void initState() {
    super.initState();
    final draft = widget.draftReport;
    _name = TextEditingController(text: draft?.name);
    _brand = TextEditingController(text: draft?.brand);
    _color = TextEditingController(text: draft?.color);
    _description = TextEditingController(text: draft?.description);
    _location = TextEditingController(text: draft?.location);
    _otherCategory = TextEditingController();

    final draftCategory = draft?.category ?? _selectCategoryValue;
    _category = _dropdownValueFor(draftCategory);
    if (_category == _otherCategoryValue &&
        draftCategory != _otherCategoryValue) {
      _otherCategory.text = draftCategory;
    }

    _timeLocated = draft != null
        ? TimeOfDay.fromDateTime(draft.dateTime)
        : TimeOfDay.now();
    _dateLocated = draft?.dateTime ?? DateTime.now();
    _images = List<File>.from(widget.draftImages);
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _color.dispose();
    _description.dispose();
    _location.dispose();
    _otherCategory.dispose();
    super.dispose();
  }

  String _dropdownValueFor(String category) {
    if (category == _selectCategoryValue) return category;
    if (widget.categories.contains(category)) return category;
    if (category.trim().isNotEmpty) return _otherCategoryValue;
    return _selectCategoryValue;
  }

  bool _isAllowedImageFile(File file) {
    final parts = file.path.split('.');
    if (parts.length < 2) return false;
    return _allowedImageExtensions.contains(parts.last.toLowerCase());
  }

  Future<void> _pickImages() async {
    final remainingSlots = _maxImages - _images.length;
    if (remainingSlots <= 0) {
      _showInfo('You can upload only 3 images per item.\nPlease remove one to add another.');
      return;
    }

    final picker = ImagePicker();
    final List<XFile> picked;
    if (remainingSlots == 1) {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      picked = image == null ? <XFile>[] : <XFile>[image];
    } else {
      picked = await picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
        limit: remainingSlots,
      );
    }
    if (picked.isEmpty) return;

    setState(() {
      for (final image in picked.take(remainingSlots)) {
        final file = File(image.path);
        if (_isAllowedImageFile(file)) {
          _images.add(file);
        }
      }
    });
  }

  Future<void> _captureImage() async {
    if (_images.length >= _maxImages) {
      _showInfo('You can upload only 3 images per item.\nPlease remove one to add another.');
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image == null) return;

    final file = File(image.path);
    if (!_isAllowedImageFile(file)) {
      _showInfo('Only JPG, JPEG, PNG, and WEBP images are supported.');
      return;
    }

    setState(() => _images.add(file));
  }

  Future<void> _showImageSourceSheet() async {
    if (widget.type != 'Found') {
      await _pickImages();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo now'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _replaceImage(int index) async {
    final source = widget.type == 'Found'
        ? await showModalBottomSheet<ImageSource>(
            context: context,
            showDragHandle: true,
            builder: (_) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_camera_outlined),
                      title: const Text('Retake photo'),
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: const Text('Replace from gallery'),
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ],
                ),
              ),
            ),
          )
        : ImageSource.gallery;
    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image == null) return;

    final file = File(image.path);
    if (!_isAllowedImageFile(file)) {
      _showInfo('Only JPG, JPEG, PNG, and WEBP images are supported.');
      return;
    }

    setState(() => _images[index] = file);
  }

  void _viewImage(File image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(child: Image.file(image)),
            Positioned(
              top: 30,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfo(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Exit without uploading this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back, return null
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    final manualCategory = _otherCategory.text.trim();
    final selectedCategory = _category == _otherCategoryValue
        ? manualCategory
        : _category;

    if (_name.text.trim().isEmpty ||
        _category == _selectCategoryValue ||
        selectedCategory.isEmpty ||
        _location.text.trim().isEmpty) {
      _showInfo('Please fill in all required fields.');
      return;
    }

    final selectedDateTime = DateTime(
      _dateLocated.year,
      _dateLocated.month,
      _dateLocated.day,
      _timeLocated.hour,
      _timeLocated.minute,
    );

    final report = ItemReport(
      id: widget.draftReport?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: widget.type,
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      color: _color.text.trim(),
      category: selectedCategory,
      description: _description.text.trim(),
      location: _location.text.trim(),
      dateTime: selectedDateTime,
      imagePaths: _images.map((e) => e.path).toList(),
    );

    // Return the report and images to the caller
    Navigator.pop(context, UploadResult(report: report, images: _images));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Create ${widget.type} Item Report'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmExit,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image upload area
              _buildImageArea(),
              const SizedBox(height: 16),

              _requiredLabel('Item Name'),
              _roundedField(_name),

              Row(
                children: [
                  Expanded(child: _roundedField(_brand, label: 'Brand')),
                  const SizedBox(width: 8),
                  Expanded(child: _roundedField(_color, label: 'Color')),
                ],
              ),

              _requiredLabel('Category'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _inputDecoration(),
                items: [
                  const DropdownMenuItem(
                    value: _selectCategoryValue,
                    child: Text('Select category'),
                  ),
                  ...widget.categories
                      .where((c) => c != _otherCategoryValue)
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item))),
                  const DropdownMenuItem(
                    value: _otherCategoryValue,
                    child: Text('Others'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _category = value;
                    if (value != _otherCategoryValue) {
                      _otherCategory.clear();
                    }
                  });
                },
              ),

              if (_category == _otherCategoryValue) ...[
                _requiredLabel('Specify Category'),
                _roundedField(_otherCategory, label: 'Category name'),
              ],

              _fieldLabel('Additional Description'),
              _roundedField(_description, maxLines: 3),

              _requiredLabel(
                widget.type == 'Lost' ? 'Last place located' : 'Found at',
              ),
              _roundedField(_location),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(_timeLocated.format(context)),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _timeLocated,
                        );
                        if (picked != null) {
                          setState(() => _timeLocated = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        '${_dateLocated.month}/${_dateLocated.day}/${_dateLocated.year}',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateLocated,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _dateLocated = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _confirmExit,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE000),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _submitForm,
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0066CC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _images.isEmpty
          ? InkWell(
              onTap: _showImageSourceSheet,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.type == 'Found'
                          ? Icons.photo_camera_outlined
                          : Icons.upload_file,
                      color: const Color(0xFF0066CC),
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.type == 'Found'
                          ? 'Take photo or upload image'
                          : 'Click to upload image',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_images.length}/$_maxImages photos selected',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_images.length}/$_maxImages photos selected',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: _images.length + (_images.length < _maxImages ? 1 : 0),
                    itemBuilder: (_, index) {
                      if (index == _images.length) {
                        return Container(
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFB7C7DA)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Color(0xFF005BAB)),
                            onPressed: _showImageSourceSheet,
                          ),
                        );
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 100,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                _images[index],
                                width: 100,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(10),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      _imgBtn(Icons.visibility, () => _viewImage(_images[index])),
                                      _imgBtn(Icons.edit, () => _replaceImage(index)),
                                      _imgBtn(Icons.delete, () => setState(() => _images.removeAt(index))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _imgBtn(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  Widget _requiredLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        '$text *',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _roundedField(
    TextEditingController controller, {
    int maxLines = 1,
    String? label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: _roundedDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration([String? label]) {
    const blueBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF0066CC), width: 1),
    );

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFE9ECEF),
      enabledBorder: blueBorder,
      focusedBorder: blueBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF0066CC), width: 1.5),
      ),
      border: blueBorder,
    );
  }

  InputDecoration _roundedDecoration([String? label]) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF2F6FF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF0066CC), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF0066CC), width: 1.5),
      ),
    );
  }
}

/// Result returned when the user completes the form
class UploadResult {
  final ItemReport report;
  final List<File> images;

  UploadResult({required this.report, required this.images});
}
