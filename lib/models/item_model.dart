class ItemReport {
  final String id;
  final String type;
  final String name;
  final String brand;
  final String color;
  final String category;
  final String description;
  final String location;
  final DateTime dateTime;
  final List<String> imagePaths;
  final String status;
  final bool isMatched;

  ItemReport({
    required this.id,
    required this.type,
    required this.name,
    required this.brand,
    required this.color,
    required this.category,
    required this.description,
    required this.location,
    required this.dateTime,
    required this.imagePaths,
    this.status = '',
    this.isMatched = false,
  });

  ItemReport copyWith({
    String? id,
    String? type,
    String? name,
    String? brand,
    String? color,
    String? category,
    String? description,
    String? location,
    DateTime? dateTime,
    List<String>? imagePaths,
    String? status,
    bool? isMatched,
  }) {
    return ItemReport(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      dateTime: dateTime ?? this.dateTime,
      imagePaths: imagePaths ?? this.imagePaths,
      status: status ?? this.status,
      isMatched: isMatched ?? this.isMatched,
    );
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  static String _categoryName(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _stringValue(value['name']);
    }
    return _stringValue(value);
  }

  static String _imageValue(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return _imageValue(value.first);
    }
    if (value is Map<String, dynamic>) {
      return _stringValue(
        value['image_path'] ??
            value['file_path'] ??
            value['path'] ??
            value['url'] ??
            value['image_url'] ??
            value['photo_url'],
      );
    }
    return _stringValue(value);
  }

  static String _normalizeStatus(
    String type,
    String rawStatus,
    bool isMatched,
  ) {
    final text = rawStatus.trim().toLowerCase().replaceAll('_', ' ');

    if (type == 'Lost') {
      if (text.contains('claimed')) return 'Claimed';
      if (text.contains('match') || isMatched) return 'Matched';
      return 'Pending Match';
    }

    if (text.contains('claimed')) return 'Claimed';
    if (text.contains('match') || isMatched) return 'Match Found';
    if (text.contains('approved') || text == 'approved') return 'Approved';
    return 'Pending Approval';
  }

  factory ItemReport.fromJson(
    Map<String, dynamic> json, {
    required String type,
  }) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final displayStatus = _stringValue(json['display_status']);

    final rawDate = payload['created_at'] ?? payload['date'];
    final parsedDate = rawDate is String && rawDate.isNotEmpty
        ? DateTime.tryParse(rawDate)
        : null;

    final imagePath = _imageValue(
      payload['image_path'] ??
          payload['main_image_path'] ??
          payload['image_url'] ??
          payload['main_image_url'] ??
          payload['main_image'] ??
          payload['image'] ??
          payload['images'] ??
          payload['photos'] ??
          payload['attachments'] ??
          payload['reference_images'] ??
          payload['photo_url'] ??
          payload['photo'],
    );

    final categoryName = _categoryName(
      payload['category_relationship'] ??
          payload['category_name'] ??
          payload['category'] ??
          payload['item_category'] ??
          payload['item_type'],
    );

    final itemName = _stringValue(
      payload['item_name'] ??
          payload['name'] ??
          payload['title'] ??
          payload['item'] ??
          payload['found_item_name'] ??
          payload['reported_item_name'],
    );

    final description = _stringValue(
      payload['description'] ??
          payload['details'] ??
          payload['item_description'] ??
          payload['notes'],
    );

    final brand = _stringValue(payload['brand'] ?? payload['item_brand']);

    final color = _stringValue(payload['color'] ?? payload['item_color']);

    final location = _stringValue(
      payload['location'] ??
          payload['found_at'] ??
          payload['place_found'] ??
          payload['found_location'] ??
          payload['last_seen_location'],
    );

    final rawStatus = _stringValue(
      payload['status'] ??
          payload['item_status'] ??
          payload['report_status'] ??
          payload['approval_status'] ??
          payload['display_status'] ??
          displayStatus,
    );
    final isMatched =
        payload['is_matched'] == true ||
        displayStatus.toLowerCase() == 'matched' ||
        rawStatus.toLowerCase().contains('match');

    return ItemReport(
      id: payload['id'].toString(),
      type: type,
      name: itemName.isNotEmpty
          ? itemName
          : categoryName.isNotEmpty
          ? categoryName
          : description.isNotEmpty
          ? description
          : 'Unknown Item',
      brand: brand,
      color: color,
      category: categoryName,
      description: description,
      location: location,
      dateTime: parsedDate ?? DateTime.now(),
      imagePaths: imagePath.isNotEmpty ? [imagePath] : [],
      status: _normalizeStatus(type, rawStatus, isMatched),
      isMatched: isMatched,
    );
  }
}
