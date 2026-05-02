class ServiceModel {
  final String id;
  final String tenantId;
  final String businessName;
  final String name;
  final String category;
  final String description;
  final double pricing;
  final int duration;
  final String? imageUrl;
  final List<String> providerIds;
  final List<String> providerNames;
  final double averageProviderRating;
  final int ratedProviderCount;
  final bool isActive;
  final int maxAdvanceDays;
  final bool allowCancellation;
  final bool allowCancellationBeforeAssign;
  final DateTime createdAt;

  const ServiceModel({
    required this.id,
    required this.tenantId,
    required this.businessName,
    required this.name,
    required this.category,
    required this.description,
    required this.pricing,
    required this.duration,
    this.imageUrl,
    this.providerIds = const [],
    this.providerNames = const [],
    this.averageProviderRating = 0,
    this.ratedProviderCount = 0,
    this.isActive = true,
    this.maxAdvanceDays = 30,
    this.allowCancellation = true,
    this.allowCancellationBeforeAssign = true,
    required this.createdAt,
  });

  String get storeName => businessName;
  String? get serviceImage => imageUrl;
  String get priceDisplay => 'Rs ${pricing.toStringAsFixed(0)}';

  String get durationDisplay {
    if (duration < 60) return '$duration mins';
    final hrs = duration ~/ 60;
    final mins = duration % 60;
    return mins == 0 ? '$hrs hr${hrs > 1 ? 's' : ''}' : '$hrs hr ${mins} mins';
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _displayNameFromSubdomain(dynamic value) {
    final subdomain = _asString(value);
    if (subdomain == null) return null;

    final words = subdomain
        .split('.')
        .first
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .toList();

    return words.isEmpty ? null : words.join(' ');
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final tenantRaw = json['tenant'];
    final tenantMap =
        tenantRaw is Map ? Map<String, dynamic>.from(tenantRaw) : null;
    final providersRaw = json['providers'] as List<dynamic>? ?? const [];
    final imagesRaw = json['images'];
    final singleImage = json['image']?.toString();
    final bookingSettings = json['bookingSettings'] is Map
        ? Map<String, dynamic>.from(json['bookingSettings'] as Map)
        : const <String, dynamic>{};
    final providerRatings = providersRaw
        .map((item) {
          if (item is Map) {
            final profile = item['profile'];
            if (profile is Map && profile['rating'] is Map) {
              final ratingMap = profile['rating'] as Map;
              final average = ratingMap['average'];
              if (average is num) return average.toDouble();
            }
            final directRating = item['rating'];
            if (directRating is num) return directRating.toDouble();
          }
          return null;
        })
        .whereType<double>()
        .where((rating) => rating > 0)
        .toList();

    final durationValue = json['duration'];
    final pricingValue = json['pricing'];

    return ServiceModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      tenantId: tenantMap?['_id']?.toString() ?? tenantRaw?.toString() ?? '',
      businessName: _asString(tenantMap?['businessName']) ??
          _asString(tenantMap?['name']) ??
          _asString(json['businessName']) ??
          _displayNameFromSubdomain(tenantMap?['subdomain']) ??
          _displayNameFromSubdomain(json['subdomain']) ??
          '',
      name: _asString(json['name']) ?? '',
      category: _asString(json['category']) ?? '',
      description: _asString(json['description']) ?? '',
      pricing: pricingValue is num
          ? pricingValue.toDouble()
          : double.tryParse(pricingValue?.toString() ?? '') ?? 0,
      duration: durationValue is num
          ? durationValue.toInt()
          : int.tryParse(durationValue?.toString() ?? '') ?? 0,
      imageUrl: _asString(json['imageUrl']) ??
          _asString(json['image']) ??
          (json['images'] is List && json['images'].isNotEmpty
              ? json['images'][0].toString()
              : null),
      providerIds: providersRaw
          .map((item) =>
              item is Map ? item['_id']?.toString() ?? '' : item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      providerNames: providersRaw
          .map((item) {
            if (item is Map) {
              final firstName = _asString(item['firstName']) ?? '';
              final lastName = _asString(item['lastName']) ?? '';
              return '$firstName $lastName'.trim();
            }
            return '';
          })
          .where((item) => item.isNotEmpty)
          .toList(),
      averageProviderRating: providerRatings.isEmpty
          ? 0
          : providerRatings.reduce((a, b) => a + b) / providerRatings.length,
      ratedProviderCount: providerRatings.length,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      maxAdvanceDays:
          (bookingSettings['maxAdvanceDays'] as num?)?.toInt() ?? 30,
      allowCancellation: bookingSettings['allowCancellation'] as bool? ?? true,
      allowCancellationBeforeAssign:
          bookingSettings['allowCancellationBeforeAssign'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant': tenantId,
        'name': name,
        'category': category,
        'description': description,
        'pricing': pricing,
        'duration': duration,
        'imageUrl': imageUrl,
        'providerNames': providerNames,
        'averageProviderRating': averageProviderRating,
        'ratedProviderCount': ratedProviderCount,
        'isActive': isActive,
        'bookingSettings': {
          'maxAdvanceDays': maxAdvanceDays,
          'allowCancellation': allowCancellation,
          'allowCancellationBeforeAssign': allowCancellationBeforeAssign,
        },
      };

  ServiceModel copyWith({
    String? name,
    String? category,
    String? description,
    double? pricing,
    int? duration,
    String? imageUrl,
    List<String>? providerIds,
    List<String>? providerNames,
    double? averageProviderRating,
    int? ratedProviderCount,
    bool? isActive,
    int? maxAdvanceDays,
    bool? allowCancellation,
    bool? allowCancellationBeforeAssign,
  }) {
    return ServiceModel(
      id: id,
      tenantId: tenantId,
      businessName: businessName,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      pricing: pricing ?? this.pricing,
      duration: duration ?? this.duration,
      imageUrl: imageUrl ?? this.imageUrl,
      providerIds: providerIds ?? this.providerIds,
      providerNames: providerNames ?? this.providerNames,
      averageProviderRating:
          averageProviderRating ?? this.averageProviderRating,
      ratedProviderCount: ratedProviderCount ?? this.ratedProviderCount,
      isActive: isActive ?? this.isActive,
      maxAdvanceDays: maxAdvanceDays ?? this.maxAdvanceDays,
      allowCancellation: allowCancellation ?? this.allowCancellation,
      allowCancellationBeforeAssign:
          allowCancellationBeforeAssign ?? this.allowCancellationBeforeAssign,
      createdAt: createdAt,
    );
  }
}
