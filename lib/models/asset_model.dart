class AssetModel {
  final String id;
  final String tenantId;
  final String name;
  final String category;
  final String description;
  final String location;
  final String status;
  final String condition;
  final double value;
  final int quantity;
  final int assignedQuantity;
  final int availableQuantity;
  final double? currentValue;
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiryDate;
  final String assetNumber;
  final String? assetTag;
  final List<String> imageUrls;
  final DateTime createdAt;

  const AssetModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.status,
    required this.condition,
    required this.value,
    this.quantity = 1,
    this.assignedQuantity = 0,
    this.availableQuantity = 1,
    this.currentValue,
    this.purchaseDate,
    this.warrantyExpiryDate,
    required this.assetNumber,
    this.assetTag,
    this.imageUrls = const [],
    required this.createdAt,
  });

  bool get isAvailable {
    final normalized = status.toLowerCase();
    return normalized == 'available' && availableQuantity > 0;
  }

  // Compatibility getters for the current UI.
  String get adminId => tenantId;
  int get quantityAvailable => availableQuantity;
  double get cost => value;
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    final tenantRaw = json['tenant'];
    final tenantId = tenantRaw is Map<String, dynamic>
        ? tenantRaw['_id']?.toString() ?? ''
        : tenantRaw?.toString() ?? '';

    final imagesRaw = json['images'] as List<dynamic>? ?? const [];
    final imageUrls = imagesRaw
        .map((item) {
          if (item is Map<String, dynamic>) {
            return item['url']?.toString() ?? '';
          }
          return item?.toString() ?? '';
        })
        .where((url) => url.isNotEmpty)
        .toList();

    final fallbackImageUrl = json['imageUrl']?.toString();
    if (fallbackImageUrl != null && fallbackImageUrl.isNotEmpty) {
      imageUrls.insert(0, fallbackImageUrl);
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return AssetModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      tenantId: tenantId,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      status: json['status']?.toString() ?? 'available',
      quantity: _asInt(json['quantity'], fallback: 1),
      assignedQuantity: _asInt(json['assignedQuantity']),
      availableQuantity: _asInt(
        json['availableQuantity'],
        fallback: _asInt(json['quantity'], fallback: 1),
      ),
      condition: json['condition']?.toString() ?? 'good',
      value: _asDouble(json['value'] ?? json['cost']),
      currentValue: json['currentValue'] == null
          ? null
          : _asDouble(json['currentValue']),
      purchaseDate: parseDate(json['purchaseDate']),
      warrantyExpiryDate: parseDate(json['warrantyExpiryDate']),
      assetNumber: json['assetNumber']?.toString() ?? '',
      assetTag: json['assetTag']?.toString(),
      imageUrls: imageUrls,
      createdAt: parseDate(json['createdAt']) ??
          parseDate(json['created_at']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant': tenantId,
        'name': name,
        'category': category,
        'description': description,
        'location': location,
        'status': status,
        'condition': condition,
        'value': value,
        'quantity': quantity,
        'assignedQuantity': assignedQuantity,
        'availableQuantity': availableQuantity,
        'currentValue': currentValue,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'warrantyExpiryDate': warrantyExpiryDate?.toIso8601String(),
        'assetNumber': assetNumber,
        'assetTag': assetTag,
        'images': imageUrls.map((url) => {'url': url}).toList(),
      };

  AssetModel copyWith({
    String? name,
    String? category,
    String? description,
    String? location,
    String? status,
    String? condition,
    double? value,
    int? quantity,
    int? assignedQuantity,
    int? availableQuantity,
    double? currentValue,
    DateTime? purchaseDate,
    DateTime? warrantyExpiryDate,
    String? assetNumber,
    String? assetTag,
    List<String>? imageUrls,
  }) {
    return AssetModel(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      value: value ?? this.value,
      quantity: quantity ?? this.quantity,
      assignedQuantity: assignedQuantity ?? this.assignedQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      currentValue: currentValue ?? this.currentValue,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiryDate: warrantyExpiryDate ?? this.warrantyExpiryDate,
      assetNumber: assetNumber ?? this.assetNumber,
      assetTag: assetTag ?? this.assetTag,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt,
    );
  }
}
