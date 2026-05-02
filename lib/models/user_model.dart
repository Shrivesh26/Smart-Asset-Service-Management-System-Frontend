import '../utils/app_constants.dart';

class SavedAddressModel {
  final String label;
  final String street;
  final String city;
  final String state;
  final String pinCode;
  final String country;
  final bool isDefault;

  const SavedAddressModel({
    required this.label,
    required this.street,
    this.city = '',
    this.state = '',
    this.pinCode = '',
    this.country = 'India',
    this.isDefault = false,
  });

  factory SavedAddressModel.fromJson(Map<String, dynamic> json) {
    String asString(dynamic value) => value?.toString().trim() ?? '';
    return SavedAddressModel(
      label: asString(json['label']).isEmpty ? 'Address' : asString(json['label']),
      street: asString(json['street'] ?? json['address']),
      city: asString(json['city']),
      state: asString(json['state']),
      pinCode: asString(json['pinCode'] ?? json['pincode']),
      country: asString(json['country']).isEmpty ? 'India' : asString(json['country']),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  String get display {
    final parts = [street, city, state, pinCode, country]
        .where((part) => part.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'street': street,
        'city': city,
        'state': state,
        'pinCode': pinCode,
        'country': country,
        'isDefault': isDefault,
      };
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? profilePhoto;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;
  final List<SavedAddressModel> savedAddresses;
  final String? businessName;
  final String? subdomain;
  final String? businessDescription;
  final String? bio;
  final String? businessType;
  final String? businessWebsite;
  final String? gstNumber;
  final List<String> specializations;
  final String? experience;
  final double rating;
  final int? ratingCount;
  final int? completedJobs;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePhoto,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.country,
    this.savedAddresses = const [],
    this.businessName,
    this.subdomain,
    this.businessDescription,
    this.bio,
    this.businessType,
    this.businessWebsite,
    this.gstNumber,
    this.specializations = const [],
    this.experience,
    this.rating = 0,
    this.completedJobs = 0,
    this.ratingCount,
    this.isActive = true,
  });

  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isTenant => role == AppConstants.roleTenant;
  bool get isProvider => role == AppConstants.roleProvider;
  bool get isUser => role == AppConstants.roleUser;
  String? get storeName => businessName;
  String? get skillCategory =>
      specializations.isNotEmpty ? specializations.first : null;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _normalizeRole(String raw) {
    switch (raw) {
      case 'customer':
        return AppConstants.roleUser;
      case 'service_provider':
        return AppConstants.roleProvider;
      case 'tenant':
        return AppConstants.roleTenant;
      case 'admin':
        return AppConstants.roleAdmin;
      case 'user':
        return AppConstants.roleUser;
      case 'provider':
        return AppConstants.roleProvider;
      default:
        return raw.isEmpty ? AppConstants.roleUser : raw;
    }
  }

  static String? _displayNameFromSubdomain(dynamic value) {
    final subdomain = _asString(value);
    if (subdomain == null) return null;

    final parts = subdomain
        .split('.')
        .first
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .toList();

    return parts.isEmpty ? null : parts.join(' ');
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final firstName = _asString(json['firstName']) ?? '';
    final lastName = _asString(json['lastName']) ?? '';
    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : _asString(json['fullName']) ??
            _asString(json['full_name']) ??
            _asString(json['name']) ??
            '';

    final role = _normalizeRole(_asString(json['role'])?.toLowerCase() ?? '');
    final addressMap = json['address'] is Map
        ? Map<String, dynamic>.from(json['address'] as Map)
        : const <String, dynamic>{};
    final profileMap = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : const <String, dynamic>{};
    final businessMap = json['business'] is Map
        ? Map<String, dynamic>.from(json['business'] as Map)
        : const <String, dynamic>{};
    final ratingMap = profileMap['rating'] is Map
        ? Map<String, dynamic>.from(profileMap['rating'] as Map)
        : const <String, dynamic>{};
    final specializations =
        (json['specializations'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList();
    final savedAddresses =
        (json['savedAddresses'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => SavedAddressModel.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.street.isNotEmpty)
            .toList();

    double _parseRating(dynamic value) {
      if (value == null) return 0;

      if (value is num) return value.toDouble();

      if (value is Map) {
        return (value['average'] as num?)?.toDouble() ?? 0;
      }

      return 0;
    }

    int? _parseRatingCount(dynamic value) {
      if (value == null) return null;

      if (value is num) return value.toInt();

      if (value is Map) {
        return (value['count'] as num?)?.toInt();
      }

      return null;
    }

    return UserModel(
      id: _asString(json['_id']) ?? _asString(json['id']) ?? '',
      fullName: fullName,
      email: _asString(json['email']) ?? '',
      phone: _asString(json['phone']) ?? '',
      role: role,
      profilePhoto: _asString(json['avatarUrl']) ??
          _asString(json['logoUrl']) ??
          _asString(profileMap['avatar']),
      address: _asString(addressMap['street']) ??
          (_asString(json['address']) != null && json['address'] is! Map
              ? _asString(json['address'])
              : null),
      city: _asString(addressMap['city']) ?? _asString(json['city']),
      state: _asString(addressMap['state']) ?? _asString(json['state']),
      pincode: _asString(addressMap['pinCode']) ??
          _asString(addressMap['zipCode']) ??
          _asString(json['pincode']),
      country: _asString(addressMap['country']) ?? _asString(json['country']),
      savedAddresses: savedAddresses,
      businessName: _asString(json['businessName']) ??
          _asString(json['companyName']) ??
          _asString(json['name']) ??
          _displayNameFromSubdomain(json['subdomain']),
      subdomain: _asString(json['subdomain']),
      businessDescription: _asString(businessMap['description']) ??
          _asString(json['businessDescription']) ??
          _asString(json['bio']),
      bio: _asString(json['bio']) ?? _asString(profileMap['bio']),
      businessType:
          _asString(businessMap['type']) ?? _asString(json['businessType']),
      businessWebsite: _asString(businessMap['website']) ??
          _asString(json['businessWebsite']),
      gstNumber: _asString(json['gstNumber']) ?? _asString(json['gst_number']),
      specializations: specializations,
      experience: _asString(json['experience']),
      rating: _parseRating(profileMap['rating'] ?? json['rating']),
      ratingCount: _parseRatingCount(profileMap['rating'] ?? json['rating']),
      completedJobs: int.tryParse(json['completedJobs']?.toString() ?? '') ?? 0,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'avatarUrl': profilePhoto,
        'address': {
          'street': address,
          'city': city,
          'state': state,
          'pinCode': pincode,
          'country': country,
        },
        'savedAddresses': savedAddresses.map((address) => address.toJson()).toList(),
        'businessName': businessName,
        'subdomain': subdomain,
        'businessDescription': businessDescription,
        'bio': bio,
        'businessType': businessType,
        'businessWebsite': businessWebsite,
        'gstNumber': gstNumber,
        'specializations': specializations,
        'experience': experience,
        'rating': rating,
        'completedJobs': completedJobs,
        'isActive': isActive,
      };

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? profilePhoto,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? country,
    String? businessName,
    String? subdomain,
    String? businessDescription,
    String? bio,
    String? businessType,
    String? businessWebsite,
    String? gstNumber,
    List<String>? specializations,
    List<SavedAddressModel>? savedAddresses,
    String? experience,
    double? rating,
    int? completedJobs,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      businessName: businessName ?? this.businessName,
      subdomain: subdomain ?? this.subdomain,
      businessDescription: businessDescription ?? this.businessDescription,
      bio: bio ?? this.bio,
      businessType: businessType ?? this.businessType,
      businessWebsite: businessWebsite ?? this.businessWebsite,
      gstNumber: gstNumber ?? this.gstNumber,
      specializations: specializations ?? this.specializations,
      experience: experience ?? this.experience,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      isActive: isActive ?? this.isActive,
    );
  }
}
