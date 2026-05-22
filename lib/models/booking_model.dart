import '../utils/app_constants.dart';
import '../utils/url_utils.dart';

class BookingAssetModel {
  final String id;
  final String name;
  final String assetNumber;
  final double price;
  final String? imageUrl;
  final bool? confirmedUsed;

  const BookingAssetModel({
    required this.id,
    required this.name,
    this.assetNumber = '',
    this.price = 0,
    this.imageUrl,
    this.confirmedUsed,
  });

  String get displayName => name.isNotEmpty ? name : assetNumber;

  factory BookingAssetModel.fromJson(dynamic value) {
    if (value is! Map) {
      return BookingAssetModel(
        id: value?.toString() ?? '',
        name: '',
      );
    }

    final json = Map<String, dynamic>.from(value);
    final images = json['images'] as List<dynamic>? ?? const [];
    String? firstImage;
    if (images.isNotEmpty) {
      final first = images.first;
      if (first is Map) {
        firstImage = first['url']?.toString() ?? first['imageUrl']?.toString();
      } else {
        firstImage = first?.toString();
      }
    }

    return BookingAssetModel(
      id: json['asset']?.toString() ??
          json['assetId']?.toString() ??
          json['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
      assetNumber: json['assetNumber']?.toString() ?? '',
      price: (json['value'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0,
      imageUrl: UrlUtils.normalizeMediaUrl(
        json['imageUrl']?.toString() ?? firstImage,
      ),
      confirmedUsed: json['confirmedUsed'] as bool?,
    );
  }

  BookingAssetModel copyWith({
    double? price,
    String? imageUrl,
    bool? confirmedUsed,
  }) {
    return BookingAssetModel(
      id: id,
      name: name,
      assetNumber: assetNumber,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      confirmedUsed: confirmedUsed ?? this.confirmedUsed,
    );
  }
}

class CostBreakdownModel {
  final double service;
  final double provider;
  final double assignedAsset;
  final double additionalAssets;
  final double total;
  final bool isFinal;

  const CostBreakdownModel({
    this.service = 0,
    this.provider = 0,
    this.assignedAsset = 0,
    this.additionalAssets = 0,
    this.total = 0,
    this.isFinal = false,
  });

  factory CostBreakdownModel.fromJson(Map<String, dynamic>? json) {
    double numValue(String key) => (json?[key] as num?)?.toDouble() ?? 0;
    return CostBreakdownModel(
      service: numValue('service'),
      provider: numValue('provider'),
      assignedAsset: numValue('assignedAsset'),
      additionalAssets: numValue('additionalAssets'),
      total: numValue('total'),
      isFinal: json?['isFinal'] as bool? ?? false,
    );
  }
}

class BookingModel {
  final String id;
  final String tenantId;
  final String userId;
  final String userName;
  final String userPhone;
  final String userAddress;
  final String storeId;
  final String storeName;
  final String serviceId;
  final String serviceName;
  final String serviceCategory;
  final String? serviceImageUrl;
  final String problemDescription;
  final String preferredDate;
  final String preferredTime;
  final String? assignedProviderId;
  final String? assignedProviderName;
  final String? assignedProviderPhone;
  final String? assignedProviderImageUrl;
  final String? assignedAssetId;
  final String? assignedAssetName;
  final double assignedAssetPrice;
  final List<BookingAssetModel> assignedAssets;
  final bool? assignedAssetConfirmedUsed;
  final List<Map<String, dynamic>> additionalAssets;
  final CostBreakdownModel costBreakdown;
  final String? providerStatus;
  final String? cancelledByRole;
  final bool allowCancellation;
  final bool allowCancellationBeforeAssign;
  final String? cancellationPolicy;
  final String? scheduledDate;
  final String? scheduledTime;
  final int duration;
  final double pricing;
  final String? endTime;
  final int? feedbackRating;
  final String? feedbackComment;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userAddress,
    required this.storeId,
    required this.storeName,
    required this.serviceId,
    required this.serviceName,
    required this.serviceCategory,
    this.serviceImageUrl,
    required this.problemDescription,
    required this.preferredDate,
    required this.preferredTime,
    this.assignedProviderId,
    this.assignedProviderName,
    this.assignedProviderPhone,
    this.assignedProviderImageUrl,
    this.assignedAssetId,
    this.assignedAssetName,
    this.assignedAssetPrice = 0,
    this.assignedAssets = const [],
    this.assignedAssetConfirmedUsed,
    this.additionalAssets = const [],
    this.costBreakdown = const CostBreakdownModel(),
    this.providerStatus,
    this.cancelledByRole,
    this.allowCancellation = false,
    this.allowCancellationBeforeAssign = true,
    this.cancellationPolicy,
    this.scheduledDate,
    this.scheduledTime,
    this.duration = 0,
    this.pricing = 0,
    this.endTime,
    this.feedbackRating,
    this.feedbackComment,
    this.status = AppConstants.statusRequested,
    required this.createdAt,
    this.updatedAt,
  });

  static String _normalizeStatus(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'pending':
      case 'requested':
        return AppConstants.statusRequested;
      case 'assigned':
        return AppConstants.statusAssigned;
      case 'accepted':
        return AppConstants.statusAccepted;
      case 'in_progress':
      case 'in progress':
        return AppConstants.statusInProgress;
      case 'completed':
        return AppConstants.statusCompleted;
      case 'cancelled':
        return AppConstants.statusCancelled;
      default:
        return AppConstants.statusRequested;
    }
  }

  static String? _normalizeProviderStatus(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase().trim()) {
      case 'pending':
        return 'pending';
      case 'accepted':
        return 'accepted';
      case 'rejected':
        return 'rejected';
      default:
        return null;
    }
  }

  static String? _normalizeCancelledByRole(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase().trim()) {
      case 'customer':
      case 'user':
        return 'user';
      case 'tenant':
        return 'tenant';
      case 'service_provider':
      case 'provider':
        return 'provider';
      default:
        return null;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _toAmPm(String input) {
    final parts = input.split(':');
    if (parts.length != 2) return input;
    final hour = int.tryParse(parts[0]);
    final minute = parts[1];
    if (hour == null) return input;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${displayHour.toString().padLeft(2, '0')}:$minute $suffix';
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

  bool get isRequested => status == AppConstants.statusRequested;
  bool get isAssigned => status == AppConstants.statusAssigned;
  bool get isAccepted => status == AppConstants.statusAccepted;
  bool get isInProgress => status == AppConstants.statusInProgress;
  bool get isCompleted => status == AppConstants.statusCompleted;
  bool get isCancelled => status == AppConstants.statusCancelled;
  bool get isResolved => isCancelled;
  bool get isProviderPending => providerStatus == 'pending';
  bool get isProviderAccepted => providerStatus == 'accepted';
  bool get isProviderRejected => providerStatus == 'rejected';
  bool get shouldShowProviderToUser =>
      hasProvider &&
      (isAccepted || isInProgress || isCompleted || isCancelled);
  bool get canTenantCancel =>
      !isCompleted && !isCancelled;
  bool get canUserCancel =>
      allowCancellation &&
      allowCancellationBeforeAssign &&
      !hasProvider &&
      !isCompleted &&
      !isCancelled;
  bool get shouldShowCancellationPolicy => allowCancellation;

  bool get hasProvider =>
      assignedProviderId != null && assignedProviderId!.isNotEmpty;

  String get assignedAssetsLabel {
    if (assignedAssets.isNotEmpty) {
      return assignedAssets
          .map((asset) => asset.displayName)
          .where((name) => name.trim().isNotEmpty)
          .join(', ');
    }
    return assignedAssetName ?? '';
  }

  String get cancellationLabel {
    final role = cancelledByRole ?? 'tenant';
    return 'Cancelled by ${role[0].toUpperCase()}${role.substring(1)}';
  }

  String get userFacingStatusLabel {
    if (isCancelled) return cancellationLabel;
    if (isCompleted) return AppConstants.statusCompleted;
    if (isInProgress) return AppConstants.statusInProgress;
    if (isAccepted || isProviderAccepted) return 'Provider Assigned';
    if (isAssigned || isProviderRejected) return 'Finding a provider...';
    return AppConstants.statusRequested;
  }

  String get tenantFacingStatusLabel {
    if (isCancelled) return cancellationLabel;
    if (isCompleted) return AppConstants.statusCompleted;
    if (isInProgress) return AppConstants.statusInProgress;
    if (isAccepted || isProviderAccepted) return AppConstants.statusAccepted;
    if (isAssigned || isProviderPending) return AppConstants.statusAssigned;
    if (isProviderRejected) return 'Rejected -> Reassign required';
    return 'New Request';
  }

  String get providerFacingStatusLabel {
    if (isCancelled) return cancellationLabel;
    if (isCompleted) return AppConstants.statusCompleted;
    if (isInProgress) return AppConstants.statusInProgress;
    if (isAccepted || isProviderAccepted) return AppConstants.statusAccepted;
    if (isAssigned || isProviderPending) return 'New Job Assigned';
    return status;
  }

  int get statusStep {
    switch (status) {
      case AppConstants.statusRequested:
        return 0;
      case AppConstants.statusAssigned:
      case AppConstants.statusAccepted:
        return 1;
      case AppConstants.statusInProgress:
        return 2;
      case AppConstants.statusCompleted:
      case AppConstants.statusCancelled:
        return 3;
      default:
        return 0;
    }
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // ── Parse populated references safely ─────────────────────────────
    final customer = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'] as Map)
        : null;
    final service = json['service'] is Map
        ? Map<String, dynamic>.from(json['service'] as Map)
        : null;
    final provider = json['provider'] is Map
        ? Map<String, dynamic>.from(json['provider'] as Map)
        : null;
    final tenant = json['tenant'] is Map
        ? Map<String, dynamic>.from(json['tenant'] as Map)
        : null;
    final customerAddress = customer?['address'] is Map
        ? Map<String, dynamic>.from(customer?['address'] as Map)
        : null;
    final assignedAssetsRaw = json['assignedAssets'] as List<dynamic>? ??
        json['assigned_assets'] as List<dynamic>? ??
        const [];
    final assignedAssets = assignedAssetsRaw
        .map(BookingAssetModel.fromJson)
        .where((asset) => asset.id.isNotEmpty || asset.displayName.isNotEmpty)
        .toList();
    final assetUsageRaw = json['assignedAssetUsage'] as List<dynamic>? ?? const [];
    final usageById = <String, BookingAssetModel>{
      for (final usage in assetUsageRaw.map(BookingAssetModel.fromJson))
        if (usage.id.isNotEmpty) usage.id: usage,
    };
    final enrichedAssignedAssets = assignedAssets.map((asset) {
      final usage = usageById[asset.id];
      if (usage == null) return asset;
      return asset.copyWith(
        price: usage.price > 0 ? usage.price : asset.price,
        imageUrl: usage.imageUrl ?? asset.imageUrl,
        confirmedUsed: usage.confirmedUsed,
      );
    }).toList();
    final feedback = json['feedback'] is Map
        ? Map<String, dynamic>.from(json['feedback'] as Map)
        : null;
    final cancellation = json['cancellation'] is Map
        ? Map<String, dynamic>.from(json['cancellation'] as Map)
        : null;
    final firstAssignedAsset = assignedAssetsRaw.isNotEmpty
        ? assignedAssetsRaw.first
        : null;
    final assignedAssetMap = firstAssignedAsset is Map
        ? Map<String, dynamic>.from(firstAssignedAsset)
        : null;
    final assignedAssetSnapshot = json['assignedAsset'] is Map
        ? Map<String, dynamic>.from(json['assignedAsset'] as Map)
        : null;
    final costBreakdownMap = json['costBreakdown'] is Map
        ? Map<String, dynamic>.from(json['costBreakdown'] as Map)
        : null;
    final bookingSettings = service?['bookingSettings'] is Map
        ? Map<String, dynamic>.from(service?['bookingSettings'] as Map)
        : const <String, dynamic>{};
    final additionalAssets = (json['additionalAssets'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    // ── Build name from firstName/lastName ─────────────────────────────
    String customerName = '';
    if (customer != null) {
      final first = _asString(customer['firstName']) ?? '';
      final last  = _asString(customer['lastName'])  ?? '';
      customerName = '$first $last'.trim();
    }

    String? providerName;
    if (provider != null) {
      final first = _asString(provider['firstName']) ?? '';
      final last  = _asString(provider['lastName'])  ?? '';
      final name  = '$first $last'.trim();
      providerName = name.isNotEmpty ? name : null;
    }

    // ── appointmentDate → preferredDate ───────────────────────────────
    final apptRaw = json['appointmentDate']?.toString();
    String preferredDate = '';
    if (apptRaw != null && apptRaw.isNotEmpty) {
      preferredDate = apptRaw.split('T').first;
    } else {
      preferredDate = _asString(json['preferred_date'])
          ?? _asString(json['preferredDate'])
          ?? '';
    }

    final startTime = json['startTime']?.toString();

    // ── scheduled fields (only when provider is assigned) ─────────────
    final providerRef = json['provider'];
    final hasProvider = providerRef != null &&
        (providerRef is Map || providerRef is String && providerRef.isNotEmpty);

    String? scheduledDate;
    if (hasProvider && preferredDate.isNotEmpty) {
      scheduledDate = _asString(json['scheduled_date'])
          ?? _asString(json['scheduledDate'])
          ?? preferredDate;
    }

    String? scheduledTime;
    if (hasProvider && startTime != null && startTime.isNotEmpty) {
      scheduledTime = _asString(json['scheduled_time'])
          ?? _asString(json['scheduledTime'])
          ?? _toAmPm(startTime);
    }

    // ── Fallbacks ─────────────────────────────────────────────────────
    final duration = (json['duration'] as num?)?.toInt() ??
        (service?['duration'] as num?)?.toInt() ?? 0;
    final pricing = (json['pricing'] as num?)?.toDouble() ??
        (service?['pricing'] as num?)?.toDouble() ?? 0.0;

    // ── ID helpers ────────────────────────────────────────────────────
    String? str(dynamic v) {
      if (v == null) return null;
      if (v is Map) return v['_id']?.toString();
      return v.toString();
    }

    return BookingModel(
      id: str(json['_id']) ?? str(json['id']) ?? '',
      tenantId: str(tenant?['_id']) ?? str(json['tenant']) ?? '',
      userId: str(customer?['_id']) ?? str(json['customer']) ?? str(json['user_id']) ?? '',
      userName: customerName.isNotEmpty
          ? customerName
          : _asString(json['user_name'])
              ?? _asString(json['userName'])
              ?? '',
      userPhone: customer?['phone']?.toString()
          ?? json['contactPhone']?.toString()
          ?? json['user_phone']?.toString()
          ?? json['userPhone']?.toString()
          ?? '',
      userAddress: _asString(json['serviceAddress'])
          ?? _asString(json['user_address'])
          ?? _asString(json['userAddress'])
          ?? _address(customerAddress)
          ?? '',
      storeId: str(tenant?['_id']) ?? str(json['tenant']) ?? str(json['store_id']) ?? str(json['storeId']) ?? '',
      storeName: _asString(tenant?['businessName'])
          ?? _asString(tenant?['business_name'])
          ?? _asString(tenant?['name'])
          ?? _asString(json['businessName'])
          ?? _asString(json['business_name'])
          ?? _asString(json['store_name'])
          ?? _asString(json['storeName'])
          ?? _displayNameFromSubdomain(tenant?['subdomain'])
          ?? _displayNameFromSubdomain(json['subdomain'])
          ?? '',
      serviceId: str(service?['_id'])
          ?? str(json['service'])
          ?? str(json['service_id'])
          ?? str(json['serviceId'])
          ?? '',
      serviceName: _asString(service?['name'])
          ?? _asString(json['service_name'])
          ?? _asString(json['serviceName'])
          ?? '',
      serviceCategory: _asString(service?['category'])
          ?? _asString(json['service_category'])
          ?? _asString(json['serviceCategory'])
          ?? '',
      serviceImageUrl: UrlUtils.normalizeMediaUrl(
        _asString(service?['imageUrl']) ??
            _asString(service?['image']) ??
            _asString(json['serviceImageUrl']) ??
            _asString(json['service_image']),
      ),
      problemDescription: _asString(json['customerNotes'])
          ?? _asString(json['problem_description'])
          ?? _asString(json['problemDescription'])
          ?? '',
      preferredDate: preferredDate,
      preferredTime: startTime != null && startTime.isNotEmpty
          ? _toAmPm(startTime)
          : _asString(json['preferred_time'])
              ?? _asString(json['preferredTime'])
              ?? '',
      assignedProviderId: str(provider?['_id'])
          ?? str(json['provider'])
          ?? str(json['assigned_provider_id'])
          ?? str(json['assignedProviderId']),
      assignedProviderName: providerName
          ?? _asString(json['assigned_provider_name'])
          ?? _asString(json['assignedProviderName']),
      assignedProviderPhone: _asString(provider?['phone'])
          ?? _asString(json['assigned_provider_phone'])
          ?? _asString(json['assignedProviderPhone']),
      assignedProviderImageUrl: UrlUtils.normalizeMediaUrl(
        _asString((provider?['profile'] is Map)
                ? (provider?['profile'] as Map)['avatar']
                : null) ??
            _asString(json['assignedProviderImageUrl']) ??
            _asString(json['providerImageUrl']),
      ),
      assignedAssetId: str(assignedAssetMap?['_id'])
          ?? str(firstAssignedAsset)
          ?? str(json['assigned_asset_id'])
          ?? str(json['assignedAssetId']),
      assignedAssetName: _asString(assignedAssetSnapshot?['name'])
          ?? _asString(assignedAssetMap?['name'])
          ?? _asString(assignedAssetMap?['assetNumber'])
          ?? _asString(json['assigned_asset_name'])
          ?? _asString(json['assignedAssetName']),
      assignedAssetPrice: (assignedAssetSnapshot?['price'] as num?)?.toDouble()
          ?? (assignedAssetMap?['value'] as num?)?.toDouble()
          ?? 0,
      assignedAssets: enrichedAssignedAssets,
      assignedAssetConfirmedUsed: assignedAssetSnapshot?['confirmedUsed'] as bool?,
      additionalAssets: additionalAssets,
      costBreakdown: CostBreakdownModel.fromJson(costBreakdownMap),
      providerStatus: _normalizeProviderStatus(
        _asString(json['providerStatus']) ?? _asString(json['provider_status']),
      ),
      cancelledByRole: _normalizeCancelledByRole(
        _asString(cancellation?['cancelledRole']) ??
            _asString(json['cancelledRole']) ??
            _asString(json['cancelled_by_role']),
      ),
      allowCancellation: bookingSettings['allowCancellation'] as bool? ?? false,
      allowCancellationBeforeAssign:
          bookingSettings['allowCancellationBeforeAssign'] as bool? ?? true,
      cancellationPolicy: _asString(bookingSettings['cancellationPolicy']) ??
          _asString(bookingSettings['policy']) ??
          ((bookingSettings['allowCancellation'] as bool? ?? false)
              ? 'This booking can be cancelled by the tenant before it is completed.'
              : null),
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      duration: duration,
      pricing: pricing,
      endTime: _asString(json['endTime']),
      feedbackRating: (feedback?['rating'] as num?)?.toInt(),
      feedbackComment: _asString(feedback?['comment']),
      status: _normalizeStatus(json['status']?.toString() ?? ''),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  static String? _address(Map<String, dynamic>? addr) {
    if (addr == null) return null;
    final parts = [
      addr['street'],
      addr['city'],
      addr['state'],
      addr['pinCode'],
      addr['zipCode'],
    ]
        .map((p) => p?.toString().trim())
        .where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  BookingModel copyWith({
    String? assignedProviderId,
    String? assignedProviderName,
    String? assignedProviderPhone,
    String? assignedAssetId,
    String? assignedAssetName,
    String? providerStatus,
    String? cancelledByRole,
    String? scheduledDate,
    String? scheduledTime,
    String? status,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id,
      tenantId: tenantId,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      userAddress: userAddress,
      storeId: storeId,
      storeName: storeName,
      serviceId: serviceId,
      serviceName: serviceName,
      serviceCategory: serviceCategory,
      serviceImageUrl: serviceImageUrl,
      problemDescription: problemDescription,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      assignedProviderId: assignedProviderId ?? this.assignedProviderId,
      assignedProviderName: assignedProviderName ?? this.assignedProviderName,
      assignedProviderPhone: assignedProviderPhone ?? this.assignedProviderPhone,
      assignedProviderImageUrl: assignedProviderImageUrl,
      assignedAssetId: assignedAssetId ?? this.assignedAssetId,
      assignedAssetName: assignedAssetName ?? this.assignedAssetName,
      assignedAssetPrice: assignedAssetPrice,
      assignedAssets: assignedAssets,
      assignedAssetConfirmedUsed: assignedAssetConfirmedUsed,
      additionalAssets: additionalAssets,
      costBreakdown: costBreakdown,
      providerStatus: providerStatus ?? this.providerStatus,
      cancelledByRole: cancelledByRole ?? this.cancelledByRole,
      allowCancellation: allowCancellation,
      allowCancellationBeforeAssign: allowCancellationBeforeAssign,
      cancellationPolicy: cancellationPolicy,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration,
      pricing: pricing,
      endTime: endTime,
      feedbackRating: feedbackRating,
      feedbackComment: feedbackComment,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
