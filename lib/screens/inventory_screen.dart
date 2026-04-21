import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/item_model.dart';
import '../data/item_repository.dart';
import '../widgets/app_drawer.dart';



class InventoryScreen extends StatefulWidget {
  final String type; // "Lost" or "Found"
  const InventoryScreen({super.key, required this.type});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<ItemReport> get _reports =>
      ItemRepository.getByType(widget.type);

  ItemReport? _draftReport;
  final List<File> _draftImages = [];
  static const int _maxImages = 3;

  // ==================================================
  // IMAGE PICKING
  // ==================================================
  Future<void> _pickImages(StateSetter setModalState) async {
  final remainingSlots = _maxImages - _draftImages.length;

  if (remainingSlots <= 0) {
    _infoDialog(
      "You can upload only 3 images per item.\nPlease remove one to add another.",
    );
    return;
  }

  final picker = ImagePicker();
  final picked = await picker.pickMultiImage();

  if (picked.isEmpty) return;

  if (picked.length > remainingSlots) {
    _infoDialog(
      "You selected ${picked.length} images.\n"
      "Only $remainingSlots more image(s) can be added.\n"
      "Each item allows a maximum of 3 images.",
    );
  }

  setModalState(() {
    for (final img in picked.take(remainingSlots)) {
      _draftImages.add(File(img.path));
    }
  });
}

  Future<void> _replaceImage(
      int index, StateSetter setModalState) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    setModalState(() {
      _draftImages[index] = File(img.path);
    });
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

  // ==================================================
  // CREATE / EDIT MODAL
  // ==================================================
  void _openUploadItemModal() {
    final name = TextEditingController(text: _draftReport?.name);
    final brand = TextEditingController(text: _draftReport?.brand);
    final color = TextEditingController(text: _draftReport?.color);
    final desc =
        TextEditingController(text: _draftReport?.description);
    final loc =
        TextEditingController(text: _draftReport?.location);

    String category =
        _draftReport?.category ?? "Select category";
    TimeOfDay timeLocated = TimeOfDay.now();
    DateTime dateLocated = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: StatefulBuilder(
          builder: (_, setModalState) =>
              SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _modalHeader(
                  "Create ${widget.type} Item Report",
                  () => _confirmDialog(
                    "Exit without uploading this item?",
                    _discardDraft,
                  ),
                ),

                _imageUploadArea(setModalState),

                _requiredLabel("Item Name"),
                _roundedField(name),

                Row(
                        children: [
                          Expanded(child: _roundedField(brand, label: "Brand")),
                          const SizedBox(width: 8),
                          Expanded(child: _roundedField(color, label: "Color")),
                        ],
                      ),

                _requiredLabel("Category"),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: _inputDecoration(),
                  items: const [
                    DropdownMenuItem(
                        value: "Select category",
                        child: Text("Select category")),
                    DropdownMenuItem(
                        value: "Electronics",
                        child: Text("Electronics")),
                    DropdownMenuItem(
                        value: "Personal Item",
                        child: Text("Personal Item")),
                    DropdownMenuItem(
                        value: "ID / Card",
                        child: Text("ID / Card")),
                  ],
                  onChanged: (v) =>
                      setModalState(() => category = v!),
                ),

                _requiredLabel("Additional Description"),
                _roundedField(desc, maxLines: 3),

                _requiredLabel(
                  widget.type == "Lost"
                      ? "Last place located"
                      : "Found at",
                ),
                _roundedField(loc),

                Row(
                        children: [
                          Expanded(
                              child: _timeButton(
                                  timeLocated,
                                  (t) =>
                                      setModalState(() => timeLocated = t))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _dateButton(
                                  dateLocated,
                                  (d) =>
                                      setModalState(() => dateLocated = d))),
                        ],
                      ),
                      const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _confirmDialog(
                          "Cancel and discard this item?",
                          _discardDraft,
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE000),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () async{
                          
  // ✅ Validation FIRST
  if (name.text.trim().isEmpty ||
      category == "Select category" ||
      desc.text.trim().isEmpty ||
      loc.text.trim().isEmpty) {
    _infoDialog("Please fill in all required fields.");
    return;
  }

  // ✅ NO IMAGE UPLOAD HERE
  _draftReport = ItemReport(
   id: _draftReport?.id ?? DateTime.now().toString(),
    type: widget.type,
    name: name.text.trim(),
    brand: brand.text.trim(),
    color: color.text.trim(),
    category: category,
    description: desc.text.trim(),
    location: loc.text.trim(),
    dateTime: DateTime.now(),
    imagePaths: _draftImages.map((e) => e.path).toList(),
// temporary
  );

  Navigator.pop(context);

  // ✅ Review modal ALWAYS opens correctly
  _openReviewModal();

                        },
                        child: const Text("Next"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ==================================================
  // REVIEW MODAL
  // ==================================================
  void _openReviewModal() {
    final report = _draftReport!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modalHeader(
                "Review Your ${report.type} Item Report",
                () => _confirmDialog(
                  "Exit without submitting this report?",
                  _discardDraft,
                ),
              ),

              if (_draftImages.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _draftImages.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _draftImages[i],
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              _reviewRow("Item Name", report.name),
              _reviewRow("Category", report.category),
              _reviewRow("Brand", report.brand),
              _reviewRow("Color", report.color),
              _reviewRow(
                  "Description", report.description),
              _reviewRow("Location", report.location),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openUploadItemModal();
                      },
                      child: const Text("Edit Details"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFFE000),
                        foregroundColor: Colors.black,
                      ),
                      
               
onPressed: () => _confirmDialog(
                    "Confirm and submit this item?",
                    () {
                      
final isEditing = _reports.any((i) => i.id == report.id);

  /*  final finalReport = report.copyWith(
      imagePaths: report.imagePaths,
    );
*/
                      
setState(() {
      if (isEditing) {
        ItemRepository.update(report); // ✅ UPDATE
      } else {
        ItemRepository.add(report);    // ✅ CREATE
      }
_clearDraft();
                      });
                      Navigator.pop(context);
                    },
                  ),

                      child:
                          const Text("Confirm & Submit"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================
  // IMAGE PREVIEW AREA
  // ==================================================
  Widget _imageUploadArea(StateSetter setModalState) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF0066CC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _draftImages.isEmpty
          ? InkWell(
              onTap: () => _pickImages(setModalState),
              child: const Center(
                  child: Text("Click to upload image")),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: _draftImages.length +
                  (_draftImages.length < _maxImages
                      ? 1
                      : 0),
              itemBuilder: (_, i) {
                if (i == _draftImages.length) {
                  return IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () =>
                        _pickImages(setModalState),
                  );
                }
                return Stack(
                  children: [
                    Image.file(
                      _draftImages[i],
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 0,
                      child: Column(
                        children: [
                          _imgBtn(
                            Icons.visibility,
                            () => _viewImage(
                                _draftImages[i]),
                          ),
                          _imgBtn(
                            Icons.edit,
                            () => _replaceImage(
                                i, setModalState),
                          ),
                          _imgBtn(
                            Icons.delete,
                            () => setModalState(() =>
                                _draftImages.removeAt(i)),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _imgBtn(
      IconData icon, VoidCallback onTap) {
    return IconButton(
      icon:
          Icon(icon, size: 18, color: Colors.white),
      onPressed: onTap,
    );
  }

  // ==================================================
  // MAIN UI
  // ==================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:
          AppDrawer(currentPage: "${widget.type} Items"),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Look",
              style: GoogleFonts.greatVibes(
                fontSize: 28,
                color: const Color(0xFF005BAB),
              ),
            ),
            Text(
              "For",
              style: GoogleFonts.greatVibes(
                fontSize: 28,
                color: const Color(0xFFFFCC00),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${widget.type} Item Inventory",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _openUploadItemModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFFFE000),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.add),
                  label:
                      Text("Upload ${widget.type} Item"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _reports.isEmpty
                  ? const Center(
                      child: Text("No reports yet"),
                    )
                  : ListView.builder(
                      itemCount: _reports.length,
                      itemBuilder: (_, i) =>
                          _itemCard(_reports[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // ITEM CARD
  // ==================================================
  Widget _itemCard(ItemReport item) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFFCC00), width: 2),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= IMAGE =================
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(14),
          ),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: item.imagePaths.isNotEmpty
                ? Image.file(
  File(item.imagePaths.first),
  fit: BoxFit.cover,
)
                : const Center(
                    child: Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
          ),
        ),

        // ================= CONTENT =================
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Unpaired",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Details
              Text("Color: ${item.color}",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              Text("Brand: ${item.brand}",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              Text("Last seen: ${item.location}",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              Text(
                "${item.dateTime.toLocal()}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),

              const SizedBox(height: 14),

              // ================= ACTION BUTTONS =================
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text("View"),
                      onPressed: () => _openViewItem(item),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text("Edit"),
                      onPressed: () => _openEditItem(item),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(item),
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
  // ==================================================
  // HELPERS
  // ==================================================
  InputDecoration _inputDecoration([String? label]) {
   const blueBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(
        color: Color(0xFF0066CC),
        width: 1,
      ),
    );

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFE9ECEF),
      enabledBorder: blueBorder,
      focusedBorder: blueBorder.copyWith(
        borderSide: const BorderSide(
            color: Color(0xFF0066CC), width: 1.5),
      ),
      border: blueBorder,
    );
  }

  Widget _field(
    TextEditingController c, {
    int maxLines = 1,
    String? label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: _inputDecoration(label),
      ),
    );
  }

  Widget _modalHeader(
      String title, VoidCallback onClose) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }

  Widget _requiredLabel(String text) =>
      Padding(
        padding:
            const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          "$text *",
          style:
              const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  Widget _reviewRow(String a, String b) =>
      Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [Text(a), Text(b)],
      );

  void _confirmDialog(
      String msg, VoidCallback onYes) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
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
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  void _infoDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
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
  Widget _roundedField(TextEditingController c,
          {int maxLines = 1, String? label}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: _roundedDecoration(label),
        ),
      );

  InputDecoration _roundedDecoration([String? label]) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF2F6FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),       enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFF0066CC),
            width: 1,
          ),
        ),        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFF0066CC),
            width: 1.5,
          ),
        ),
      );


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
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Lost Item Details",
                    style: TextStyle(
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

              // IMAGE
              if (item.imagePaths.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
  File(item.imagePaths.first),
  height: 220,
  width: double.infinity,
  fit: BoxFit.cover,
)
                ),

              const SizedBox(height: 16),

              _viewRow("Item Name", item.name, "Category", item.category),
              _viewRow("Brand", item.brand, "Color", item.color),

              const SizedBox(height: 8),
              const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(item.description),

              const SizedBox(height: 12),
              _viewRow(
                "Last Place Located",
                item.location,
                "Date",
                "${item.dateTime.year}-${item.dateTime.month}-${item.dateTime.day}",
              ),
              _viewRow(
                "Time",
                "${item.dateTime.hour}:${item.dateTime.minute.toString().padLeft(2, '0')}",
                "",
                "",
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _viewRow(String l1, String v1, String l2, String v2) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l1, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(v1, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (l2.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l2, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(v2, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    ),
  );
}


void _confirmDelete(ItemReport item) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Confirm Deletion"),
      content: const Text(
          "Are you sure you want to delete this item report? This action cannot be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () {
            setState(() => ItemRepository.delete(item.id));
            Navigator.pop(context);
          },
          child: const Text("Delete"),
        ),
      ],
    ),
  );
}


void _openEditItem(ItemReport item) {
  _draftReport = item;

  _draftImages
    ..clear()
    ..addAll(item.imagePaths.map((p) => File(p)));

  _openUploadItemModal();
}


  Widget _timeButton(TimeOfDay v, ValueChanged<TimeOfDay> f) =>
      OutlinedButton.icon(
        icon: const Icon(Icons.access_time),
        label: Text(v.format(context)),
        onPressed: () async {
          final t = await showTimePicker(context: context, initialTime: v);
          if (t != null) f(t);
        },
      );

  Widget _dateButton(DateTime v, ValueChanged<DateTime> f) =>
      OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month),
        label: Text("${v.month}/${v.day}/${v.year}"),
        onPressed: () async {
          final d = await showDatePicker(
              context: context,
              initialDate: v,
              firstDate: DateTime(2020),
              lastDate: DateTime.now());
          if (d != null) f(d);
        },
      );
}