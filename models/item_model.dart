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
  final List<String> imagePaths; // ✅ FIXED

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
    required this.imagePaths, // ✅ REQUIRED
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
    );
  }
}