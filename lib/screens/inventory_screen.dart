import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item_model.dart';
import '../services/api_client.dart';
import '../services/notification_center.dart';
import '../widgets/app_bar_account_menu.dart';
import '../widgets/app_drawer.dart';
import '../widgets/notification_bell_button.dart';
import 'upload_item_screen.dart';
import 'profile_screen.dart';

class InventoryScreen extends StatefulWidget {
  final String type; // "Lost" or "Found"
  final String? initialItemId;

  const InventoryScreen({super.key, required this.type, this.initialItemId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String name = "";
  String role = "";

  /*@override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }
*/

  Future<void> _loadCurrentUser() async {
    try {
      final userData = await apiClient.getCurrentUser();
      if (!mounted) return;

      setState(() {
        final fullName = userData['full_name']?.toString().trim() ?? '';
        name = fullName.isNotEmpty
            ? fullName
            : userData['email']?.toString() ?? "Current User";
        role = userData['role_label']?.toString() ?? "Student";
      });
    } catch (_) {
      // Keep fallback values when profile fetch is unavailable.
    }
  }

  static const int _maxImages = 3;
  static const List<String> _allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  static const String _selectCategoryValue = 'Select category';
  static const String _otherCategoryValue = 'Others';

  final List<ItemReport> _reports = [];
  final List<ItemReport> _pendingSubmittedReports = [];
  final List<File> _draftImages = [];
  final List<String> _categories = [];
  final Set<String> _matchedAlertedReportIds = {};
  final Map<String, int> _categoryIdsByName = {};

  ItemReport? _draftReport;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _handledInitialItem = false;
  bool _isLoadingReports = false; // guard against concurrent _loadReports calls

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadReports();
    _loadCurrentUser();
  }

  Future<void> _loadCategories() async {
    developer.log('[InventoryScreen] _loadCategories START', name: 'LookFor');
    try {
      final rawCategories = await apiClient.getCategories();
      developer.log('[InventoryScreen] _loadCategories got ${rawCategories.length} categories', name: 'LookFor');
      if (!mounted) return;

      setState(() {
        _categoryIdsByName.clear();
        _categories
          ..clear()
          ..addAll(
            rawCategories
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    final name = item['name']?.toString() ?? '';
                    final idValue = item['id'];
                    final id = idValue is int
                        ? idValue
                        : int.tryParse(idValue?.toString() ?? '');
                    if (name.isNotEmpty && id != null) {
                      _categoryIdsByName[name] = id;
                    }
                    return name;
                  }
                  return item.toString();
                })
                .where((name) => name.isNotEmpty),
          );
      });
      developer.log('[InventoryScreen] _loadCategories COMPLETE - ${_categories.length} categories loaded', name: 'LookFor');
    } catch (e, stackTrace) {
      developer.log('[InventoryScreen] _loadCategories FAILED: $e', name: 'LookFor', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _categoryIdsByName.clear();
        if (_categories.isEmpty) {
          _categories.addAll(const [
            'Electronics',
            'Personal Item',
            'ID / Card',
          ]);
        }
      });
    }
  }

  Future<void> _loadReports() async {
    // Prevent concurrent calls (e.g. RefreshIndicator + _submitReport both triggering)
    if (_isLoadingReports) {
      developer.log('[InventoryScreen] _loadReports SKIPPED - already in progress', name: 'LookFor');
      return;
    }
    _isLoadingReports = true;
    
    developer.log('[InventoryScreen] _loadReports START (type=${widget.type})', name: 'LookFor');
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      developer.log('[InventoryScreen] Calling API: ${widget.type == 'Found' ? 'getMyFoundItems' : 'getMyLostReports'}...', name: 'LookFor');
      final rawItems = widget.type == 'Found'
          ? await apiClient.getMyFoundItems()
          : await apiClient.getMyLostReports();

      developer.log('[InventoryScreen] API returned ${rawItems.length} items', name: 'LookFor');

      final reports = rawItems
          .map(
            (item) => ItemReport.fromJson(
              item as Map<String, dynamic>,
              type: widget.type,
            ),
          )
          .toList();
      
      developer.log('[InventoryScreen] Parsed ${reports.length} reports successfully', name: 'LookFor');
      
      _pendingSubmittedReports.removeWhere(
        (pending) =>
            reports.any((report) => _isSameSubmittedReport(report, pending)),
      );

      if (!mounted) return;
      setState(() {
        _reports
          ..clear()
          ..addAll([..._pendingSubmittedReports, ...reports]);
        _isLoading = false;
      });
      developer.log('[InventoryScreen] _loadReports COMPLETE - ${_reports.length} total reports in list', name: 'LookFor');
      _openInitialItemIfNeeded();
      _showMatchedLostItemAlertIfNeeded(reports);
    } catch (e, stackTrace) {
      developer.log('[InventoryScreen] _loadReports FAILED: $e', name: 'LookFor', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _infoDialog('Failed to load ${widget.type.toLowerCase()} items: $e');
    } finally {
      _isLoadingReports = false;
    }
  }

  bool _isSameSubmittedReport(ItemReport report, ItemReport pending) {
    return report.type == pending.type &&
        report.name == pending.name &&
        report.category == pending.category &&
        report.location == pending.location &&
        report.dateTime.year == pending.dateTime.year &&
        report.dateTime.month == pending.dateTime.month &&
        report.dateTime.day == pending.dateTime.day;
  }

  void _openInitialItemIfNeeded() {
    if (_handledInitialItem) return;
    final itemId = widget.initialItemId?.trim();
    if (itemId == null || itemId.isEmpty) return;

    _handledInitialItem = true;
    ItemReport? selected;
    for (final report in _reports) {
      if (report.id == itemId) {
        selected = report;
        break;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (selected == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'The related ${widget.type.toLowerCase()} report could not be found.',
            ),
          ),
        );
        return;
      }
      _openViewItem(selected);
    });
  }

  Future<void> _pickImages(StateSetter setModalState) async {
    final remainingSlots = _maxImages - _draftImages.length;
    if (remainingSlots <= 0) {
      _infoDialog(
        'You can upload only 3 images per item.\nPlease remove one to add another.',
      );
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

    if (picked.length > remainingSlots) {
      _infoDialog(
        'You selected ${picked.length} images.\n'
        'Only $remainingSlots more image(s) can be added.\n'
        'Each item allows a maximum of 3 images.',
      );
    }

    setModalState(() {
      for (final image in picked.take(remainingSlots)) {
        final file = File(image.path);
        if (_isAllowedImageFile(file)) {
          _draftImages.add(file);
        }
      }
    });

    if (_draftImages.isEmpty) {
      _infoDialog(
        'Only JPG, JPEG, PNG, and WEBP images are supported by the backend.',
      );
    }
  }

  Future<void> _captureFoundImage(StateSetter setModalState) async {
    if (widget.type != 'Found') {
      await _pickImages(setModalState);
      return;
    }

    if (_draftImages.length >= _maxImages) {
      _infoDialog(
        'You can upload only 3 images per item.\nPlease remove one to add another.',
      );
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
      _infoDialog(
        'Only JPG, JPEG, PNG, and WEBP images are supported by the backend.',
      );
      return;
    }

    setModalState(() {
      _draftImages.add(file);
    });
  }

  Future<void> _showFoundImageSourceSheet(StateSetter setModalState) async {
    if (widget.type != 'Found') {
      await _pickImages(setModalState);
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
                  _captureFoundImage(setModalState);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(setModalState);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _replaceImage(int index, StateSetter setModalState) async {
    final source = widget.type == 'Found'
        ? await _selectFoundReplacementSource()
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
      _infoDialog(
        'Only JPG, JPEG, PNG, and WEBP images are supported by the backend.',
      );
      return;
    }

    setModalState(() {
      _draftImages[index] = file;
    });
  }

  Future<ImageSource?> _selectFoundReplacementSource() {
    return showModalBottomSheet<ImageSource>(
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
    );
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

  void _openUploadItemModal() async {
    final result = await Navigator.push<UploadResult>(
      context,
      MaterialPageRoute(
        builder: (_) => UploadItemScreen(
          type: widget.type,
          draftReport: _draftReport,
          draftImages: _draftImages,
          categories: _categories,
          categoryIdsByName: _categoryIdsByName,
        ),
      ),
    );

    if (result == null || !mounted) return;

    _draftReport = result.report;
    _draftImages
      ..clear()
      ..addAll(result.images);

    _openReviewModal();
  }

  void _openReviewModal() async {
    final report = _draftReport;
    if (report == null) return;

    final action = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _ReviewItemScreen(
          report: report,
          images: _draftImages,
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'edit') {
      _openUploadItemModal();
    } else if (action == 'submit') {
      _submitReport(report);
    }
  }

  Future<void> _submitReport(ItemReport report) async {
    if (_isSubmitting) return;

    if (_draftImages.isEmpty) {
      _infoDialog('Please upload at least one image.');
      return;
    }

    developer.log('[InventoryScreen] _submitReport START (type=${widget.type}, name=${report.name})', name: 'LookFor');
    setState(() => _isSubmitting = true);

    // Show non-dismissible loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF005BAB),
                ),
                SizedBox(height: 18),
                Text(
                  'Uploading your report...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final submittedImagePaths = _draftImages
        .map((image) => image.path)
        .toList();
    final optimisticReport = report.copyWith(
      imagePaths: submittedImagePaths,
      status: widget.type == 'Lost' ? 'Pending Match' : 'Pending Approval',
    );

    try {
      final date = _formatApiDate(report.dateTime);
      final timeFound = _formatApiTime(report.dateTime);
      final categoryId = _categoryIdsByName[report.category];

      developer.log('[InventoryScreen] Uploading: itemName=${report.name}, category=${report.category}, categoryId=$categoryId, images=${_draftImages.length}', name: 'LookFor');

      Map<String, dynamic> response;
      if (widget.type == 'Found') {
        developer.log('[InventoryScreen] Calling apiClient.reportFoundItem...', name: 'LookFor');
        response = await apiClient.reportFoundItem(
          itemName: report.name,
          category: report.category,
          categoryId: categoryId,
          brand: report.brand,
          color: report.color,
          location: report.location,
          date: date,
          timeFound: timeFound,
          description: report.description,
          mainImage: _draftImages.first,
          referenceImage1: _draftImages.length > 1 ? _draftImages[1] : null,
          referenceImage2: _draftImages.length > 2 ? _draftImages[2] : null,
        );
      } else {
        developer.log('[InventoryScreen] Calling apiClient.reportLostItem...', name: 'LookFor');
        response = await apiClient.reportLostItem(
          itemName: report.name,
          category: report.category,
          categoryId: categoryId,
          brand: report.brand,
          color: report.color,
          location: report.location,
          date: date,
          description: report.description,
          mainImage: _draftImages.first,
          referenceImage1: _draftImages.length > 1 ? _draftImages[1] : null,
          referenceImage2: _draftImages.length > 2 ? _draftImages[2] : null,
        );
      }

      developer.log('[InventoryScreen] Upload API response: $response', name: 'LookFor');

      final savedReportId = _readReportId(response);
      developer.log('[InventoryScreen] Saved report ID: $savedReportId', name: 'LookFor');
      
      final savedReport = savedReportId == null
          ? optimisticReport
          : optimisticReport.copyWith(id: savedReportId);

      if (mounted) {
        setState(() {
          _pendingSubmittedReports.removeWhere(
            (pending) => _isSameSubmittedReport(pending, savedReport),
          );
          _pendingSubmittedReports.insert(0, savedReport);
          _reports
            ..removeWhere(
              (item) => _isSameSubmittedReport(item, savedReport),
            )
            ..insert(0, savedReport);
        });
      }

      _clearDraft();

      // Dismiss loading overlay
      if (mounted) Navigator.pop(context);

      if (!mounted) return;
      if (widget.type == 'Lost') {
        addLocalNotification(
          type: 'lost_report_uploaded',
          title: 'Lost Report Uploaded',
          message:
              'Your lost item report for "${report.name}" was uploaded successfully. We will notify you if a match is found.',
          reportType: 'Lost',
          itemId: savedReportId,
        );
        _showLostReportSubmittedDialog();
      } else {
        addLocalNotification(
          type: 'found_report_uploaded',
          title: 'Found Report Uploaded',
          message:
              'Your found item report for "${report.name}" was uploaded successfully. Surrender the item to the Discipline Office.',
          reportType: 'Found',
          itemId: savedReportId,
        );
        _showFoundReportSubmittedDialog();
      }

      developer.log('[InventoryScreen] Submit complete, reloading reports...', name: 'LookFor');
      await _loadReports();
    } catch (e, stackTrace) {
      developer.log('[InventoryScreen] _submitReport FAILED: $e', name: 'LookFor', error: e, stackTrace: stackTrace);
      // Dismiss loading overlay
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      _infoDialog('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      developer.log('[InventoryScreen] _submitReport END', name: 'LookFor');
    }
  }

  String? _readReportId(Map<String, dynamic> response) {
    dynamic value = response['id'] ??
        response['item_id'] ??
        response['report_id'] ??
        response['lost_item_id'] ??
        response['found_item_id'];
    final data = response['data'];
    if ((value == null || value.toString().trim().isEmpty) &&
        data is Map<String, dynamic>) {
      value = data['id'] ??
          data['item_id'] ??
          data['report_id'] ??
          data['lost_item_id'] ??
          data['found_item_id'];
    }
    final text = value?.toString().trim();
    return text == null || text.isEmpty || text.toLowerCase() == 'null'
        ? null
        : text;
  }

  Widget _imageUploadArea(StateSetter setModalState) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0066CC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _draftImages.isEmpty
          ? InkWell(
              onTap: () => _showFoundImageSourceSheet(setModalState),
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
                      '${_draftImages.length}/$_maxImages photos selected',
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
                      '${_draftImages.length}/$_maxImages photos selected',
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
                    itemCount:
                        _draftImages.length +
                        (_draftImages.length < _maxImages ? 1 : 0),
                    itemBuilder: (_, index) {
                      if (index == _draftImages.length) {
                        return Container(
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFB7C7DA)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Color(0xFF005BAB)),
                            onPressed: () =>
                                _showFoundImageSourceSheet(setModalState),
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
                                _draftImages[index],
                                width: 100,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _imgBtn(
                                      Icons.visibility,
                                      () => _viewImage(_draftImages[index]),
                                    ),
                                    _imgBtn(
                                      Icons.edit,
                                      () => _replaceImage(index, setModalState),
                                    ),
                                    _imgBtn(
                                      Icons.delete,
                                      () => setModalState(
                                        () => _draftImages.removeAt(index),
                                      ),
                                    ),
                                  ],
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
    return IconButton(
      icon: Icon(icon, size: 18, color: Colors.white),
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        currentPage: "${widget.type} Items",
        userName: name,
        userRole: role,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF005BAB)),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Look",
              style: GoogleFonts.greatVibes(
                fontSize: 30,
                color: const Color(0xFF005BAB),
              ),
            ),
            Text(
              "For",
              style: GoogleFonts.greatVibes(
                fontSize: 30,
                color: const Color(0xFFFFE000),
              ),
            ),
          ],
        ),
        actions: [
          const NotificationBellButton(),
          AppBarAccountMenu(
            userName: name,
            userRole: role,
            onProfileSelected: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${widget.type} Item Inventory',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _openUploadItemModal,
                  icon: const Icon(Icons.add),
                  label: Text('Upload ${widget.type} Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadReports,
                      child: _reports.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 120),
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: Color(0xFF94A3B8),
                                ),
                                SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    'No reports yet',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              itemCount: _reports.length,
                              itemBuilder: (_, index) =>
                                  _itemCard(_reports[index]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(ItemReport item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: item.imagePaths.isNotEmpty
                  ? _buildReportImage(item.imagePaths.first, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.isMatched
                            ? const Color(0xFFEAF3FF)
                            : const Color(0xFFFFF3D7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.isMatched ? 'Matched' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          color: item.isMatched
                              ? const Color(0xFF005BAB)
                              : const Color(0xFF9A5B00),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _itemMeta(Icons.palette_outlined, 'Color', item.color),
                _itemMeta(Icons.sell_outlined, 'Brand', item.brand),
                _itemMeta(
                  Icons.place_outlined,
                  widget.type == 'Lost' ? 'Last seen' : 'Found at',
                  item.location,
                ),
                _itemMeta(
                  Icons.schedule_outlined,
                  'Date',
                  item.dateTime.toLocal().toString(),
                  isMuted: true,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Details'),
                        onPressed: () => _openViewItem(item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemMeta(
    IconData icon,
    String label,
    String value, {
    bool isMuted = false,
  }) {
    final displayValue = value.trim().isEmpty ? 'Not specified' : value;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '$label: $displayValue',
              style: TextStyle(
                fontSize: isMuted ? 12 : 13,
                color: isMuted
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
                height: 1.25,
              ),
            ),
          ),
        ],
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

  String _statusLabel(ItemReport item) {
    // Adjust this logic based on how your ItemReport's status is stored
    // This is a common pattern for converting status to display text
    switch (item.status) {
      case 'matched':
        return 'Matched';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case 'approved':
        return 'Approved';
      case 'pending_approval':
        return 'Pending Approval';
      case 'pending_match':
        return 'Pending Match';
      case 'claimed':
        return 'Claimed';
      default:
        return item.status;
    }
  }

  bool _isMatchedLostItem(ItemReport item) {
    return item.type == 'Lost' && _statusLabel(item).toLowerCase() == 'matched';
  }

  void _showMatchedLostItemAlertIfNeeded(List<ItemReport> reports) {
    if (widget.type != 'Lost') return;

    ItemReport? matchedReport;
    for (final report in reports) {
      if (_isMatchedLostItem(report) &&
          !_matchedAlertedReportIds.contains(report.id)) {
        matchedReport = report;
        break;
      }
    }
    if (matchedReport == null) return;

    _matchedAlertedReportIds.add(matchedReport.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showLostItemMatchedDialog(matchedReport);
    });
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

  Widget _modalHeader(String title, VoidCallback onClose) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(icon: const Icon(Icons.close), onPressed: onClose),
      ],
    );
  }

  Widget _requiredLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        '$text *',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    );
  }

  void _openViewItem(ItemReport item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.type} Item Details',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005BAB),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (item.imagePaths.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildReportImage(
                      item.imagePaths.first,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                _viewRow('Item Name', item.name, 'Category', item.category),
                _viewRow('Brand', item.brand, 'Color', item.color),
                const SizedBox(height: 8),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(item.description),
                const SizedBox(height: 12),
                _viewRow(
                  widget.type == 'Lost' ? 'Last Place Located' : 'Found At',
                  item.location,
                  'Date',
                  _formatApiDate(item.dateTime),
                ),
                _viewRow('Time', _formatApiTime(item.dateTime), '', ''),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewRow(String label1, String value1, String label2, String value2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (label2.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label2,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    value2,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDialog(String message, VoidCallback onYes) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
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
              Navigator.pop(context);
              onYes();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _infoDialog(String message) {
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

  void _showLostReportSubmittedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        title: Column(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE680),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF005BAB),
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Lost Item Report Submitted',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF005BAB),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your lost item report has been successfully submitted.\n\n'
          'If no match is currently available, please wait for updates.\n\n'
          'You will be notified once a matching item is found.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFoundReportSubmittedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        title: Column(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFDDF4E7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volunteer_activism_outlined,
                color: Color(0xFF00884A),
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Found Item Report Submitted',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF005BAB),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Thank you for reporting a found item.\n\n'
          'Please surrender the item to the Discipline Office as soon as possible '
          'so it can be safely returned to its owner.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _discardDraft() {
    _clearDraft();
    Navigator.pop(context);
  }

  void _clearDraft() {
    _draftImages.clear();
    _draftReport = null;
  }

  bool _isAllowedImageFile(File file) {
    final parts = file.path.split('.');
    if (parts.length < 2) return false;
    return _allowedImageExtensions.contains(parts.last.toLowerCase());
  }

  Widget _timeButton(TimeOfDay value, ValueChanged<TimeOfDay> onChanged) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.access_time),
      label: Text(value.format(context)),
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }

  Widget _dateButton(DateTime value, ValueChanged<DateTime> onChanged) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_month),
      label: Text('${value.month}/${value.day}/${value.year}'),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }

  void _showLostItemMatchedDialog(ItemReport? matchedReport) {
    final itemName = (matchedReport?.name ?? '').trim();
    final itemLabel = itemName.isEmpty ? 'your lost item' : '"$itemName"';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        title: Column(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFDDF4E7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_outlined,
                color: Color(0xFF198754),
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Item Match Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF005BAB),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Good news! $itemLabel has been successfully matched.\n\n'
          'You may contact the Discipline Officer through message to verify the matched item.\n\n'
          'Or proceed to the Discipline Office to verify and claim your item.\n\n'
          'Kindly bring a valid ID or proof of ownership for verification.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportImage(
    String path, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    final normalizedPath = path.trim();
    final localFile = File(normalizedPath);
    final isLocalFile =
        normalizedPath.contains(':\\') ||
        normalizedPath.startsWith('/') ||
        normalizedPath.startsWith('\\');
    final shouldLoadAsFile = isLocalFile && localFile.existsSync();

    if (shouldLoadAsFile) {
      return Image.file(
        localFile,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    }

    return _ReportImageWithFallback(
      urls: _reportImageUrlCandidates(normalizedPath),
      height: height,
      width: width,
      fit: fit,
    );
  }

  List<String> _reportImageUrlCandidates(String path) {
    final cleanPath = path.replaceAll('\\', '/').trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return [cleanPath];
    }

    final withoutLeadingSlash = cleanPath.startsWith('/')
        ? cleanPath.substring(1)
        : cleanPath;
    final candidates = <String>[apiClient.getImageUrl(withoutLeadingSlash)];

    if (!withoutLeadingSlash.startsWith('static/')) {
      candidates.add(apiClient.getImageUrl('static/$withoutLeadingSlash'));
    }

    if (!withoutLeadingSlash.contains('/')) {
      candidates.add(
        apiClient.getImageUrl('static/uploads/$withoutLeadingSlash'),
      );
    }

    if (withoutLeadingSlash.startsWith('uploads/')) {
      candidates.add(apiClient.getImageUrl('static/$withoutLeadingSlash'));
    }

    return candidates.toSet().toList();
  }

  String _formatApiDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatApiTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _dropdownValueFor(String category) {
    if (category == _selectCategoryValue) return category;
    if (_categories.contains(category)) return category;
    if (category.trim().isNotEmpty) return _otherCategoryValue;
    return _selectCategoryValue;
  }
}

class _ReportImageWithFallback extends StatefulWidget {
  final List<String> urls;
  final double? height;
  final double? width;
  final BoxFit fit;

  const _ReportImageWithFallback({
    required this.urls,
    this.height,
    this.width,
    required this.fit,
  });

  @override
  State<_ReportImageWithFallback> createState() =>
      _ReportImageWithFallbackState();
}

class _ReportImageWithFallbackState extends State<_ReportImageWithFallback> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _ReportImageWithFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls.join('|') != widget.urls.join('|')) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return _brokenImagePlaceholder();
    }

    final url = widget.urls[_index.clamp(0, widget.urls.length - 1)];
    return Image.network(
      url,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        if (_index < widget.urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _index++);
            }
          });
          return _imageLoadingPlaceholder();
        }

        return _brokenImagePlaceholder();
      },
    );
  }

  Widget _imageLoadingPlaceholder() {
    return const Center(
      child: SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _brokenImagePlaceholder() {
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8)),
    );
  }
}

class _ReviewItemScreen extends StatelessWidget {
  final ItemReport report;
  final List<File> images;

  const _ReviewItemScreen({
    required this.report,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Review Your ${report.type} Item Report'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmExit(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              if (images.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        images[index],
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              _detailRow('Item Name', report.name),
              _detailRow('Category', report.category),
              _detailRow('Brand', report.brand.isEmpty ? 'Not specified' : report.brand),
              _detailRow('Color', report.color.isEmpty ? 'Not specified' : report.color),
              _detailRow('Description', report.description.isEmpty ? 'None' : report.description),
              _detailRow('Location', report.location),
              _detailRow('Date & Time', _formatDateTime(report.dateTime)),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, 'edit'),
                      child: const Text('Edit Details'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE000),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => _confirmSubmit(context),
                      child: const Text('Submit'),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.month}/${dt.day}/${dt.year} at $hour:$minute $period';
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Exit without submitting this report?'),
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

  void _confirmSubmit(BuildContext context) {
    Navigator.pop(context, 'submit');
  }
}
