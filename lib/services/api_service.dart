import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl = AppConstants.baseUrl;
  final Dio _dio = Dio();

  // ── Get stored token ─────────────────────────────────────────────────
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyToken);
  }

  // ── Build headers ────────────────────────────────────────────────────
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ── Handle response ──────────────────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] ??
        body['error'] ??
        'Something went wrong. Please try again.';

    throw ApiException(message, statusCode: response.statusCode);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BASE HTTP METHODS
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach server. Please try again.');
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach server. Please try again.');
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach server. Please try again.');
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach server. Please try again.');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach server. Please try again.');
    }
  }

  Future<String> uploadAssetImage({
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    try {
      final token = await _getToken();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(imageBytes, filename: imageName),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/assets/uploads',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );

      final responseData = response.data;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          responseData != null) {
        return responseData['data']?['imageUrl']?.toString() ?? '';
      }

      throw ApiException(
        responseData?['message']?.toString() ??
            'Asset image upload failed. Please try again.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        throw ApiException(
          responseData['message']?.toString() ??
              'Asset image upload failed. Please try again.',
          statusCode: e.response?.statusCode,
        );
      }
      throw const ApiException(
          'Could not upload asset image. Please try again.');
    }
  }

  Future<String> uploadProviderImage({
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    try {
      final token = await _getToken();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(imageBytes, filename: imageName),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/service-providers/uploads',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );

      final responseData = response.data;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          responseData != null) {
        return responseData['data']?['imageUrl']?.toString() ?? '';
      }

      throw ApiException(
        responseData?['message']?.toString() ??
            'Provider image upload failed. Please try again.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        throw ApiException(
          responseData['message']?.toString() ??
              'Provider image upload failed. Please try again.',
          statusCode: e.response?.statusCode,
        );
      }
      throw const ApiException(
          'Could not upload provider image. Please try again.');
    }
  }

  Future<String> uploadTenantImage({
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    try {
      final token = await _getToken();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(imageBytes, filename: imageName),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        // 'http://localhost:3000/uploads',
        '$baseUrl/uploads',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );

      final responseData = response.data;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          responseData != null) {
        return responseData['data']?['imageUrl']?.toString() ?? '';
      }

      throw ApiException(
        responseData?['message']?.toString() ??
            'Tenant image upload failed. Please try again.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        throw ApiException(
          responseData['message']?.toString() ??
              'Tenant image upload failed. Please try again.',
          statusCode: e.response?.statusCode,
        );
      }
      throw const ApiException(
          'Could not upload tenant image. Please try again.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  AUTH ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    return post(
      '/auth/login',
      {'email': email, 'password': password, 'role': role},
      auth: false,
    );
  }

  // Admin & User registration (Provider cannot self-register)
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    final Uint8List? imageBytes = payload.remove('imageBytes') as Uint8List?;
    final String? imageName = payload.remove('imageName') as String?;

    if (imageBytes == null || imageName == null || imageName.isEmpty) {
      return post('/auth/register', payload, auth: false);
    }

    try {
      final formData = FormData.fromMap({
        'data': jsonEncode(payload),
        'avatar': MultipartFile.fromBytes(
          imageBytes,
          filename: imageName,
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/auth/register',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw const ApiException('Empty response from server.');
      }

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return responseData;
      }

      throw ApiException(
        responseData['message']?.toString() ??
            'Registration failed. Please try again.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        throw ApiException(
          responseData['message']?.toString() ??
              'Registration failed. Please try again.',
          statusCode: e.response?.statusCode,
        );
      }
      throw const ApiException('Could not reach server. Please try again.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach server. Please try again.');
    }
  }

  Future<Map<String, dynamic>> _multipartRequest({
    required String method,
    required String endpoint,
    required Map<String, dynamic> payload,
    List<MultipartFile> files = const [],
    String filesField = 'images',
    bool auth = true,
  }) async {
    try {
      final token = auth ? await _getToken() : null;
      final formMap = <String, dynamic>{
        'data': jsonEncode(payload),
      };

      if (files.isNotEmpty) {
        formMap[filesField] = files;
      }

      final response = await _dio.request<Map<String, dynamic>>(
        '$baseUrl$endpoint',
        data: FormData.fromMap(formMap),
        options: Options(
          method: method,
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw const ApiException('Empty response from server.');
      }

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return responseData;
      }

      throw ApiException(
        responseData['message']?.toString() ??
            'Request failed. Please try again.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        throw ApiException(
          responseData['message']?.toString() ??
              'Request failed. Please try again.',
          statusCode: e.response?.statusCode,
        );
      }
      throw const ApiException('Could not reach server. Please try again.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach server. Please try again.');
    }
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    required String role,
  }) async {
    return post(
      '/auth/forgot-password',
      {'email': email, 'role': role},
      auth: false,
    );
  }

  Future<Map<String, dynamic>> logout() async {
    return post('/auth/logout', {});
  }

  Future<Map<String, dynamic>> getProfile() async {
    return get('/auth/me');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return patch('/auth/profile', data);
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return put('/auth/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SERVICES (Admin creates, User browses)
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getServices({bool? isActive}) async {
    final query = isActive != null ? '?isActive=$isActive' : '';
    return get('/services$query');
  }

  Future<Map<String, dynamic>> searchServices({
    String? query,
    String? category,
    String? tenantId,
    double? minPrice,
    double? maxPrice,
  }) async {
    final params = <String>[
      if (query != null && query.trim().isNotEmpty)
        'query=${Uri.encodeQueryComponent(query.trim())}',
      if (category != null && category.trim().isNotEmpty)
        'category=${Uri.encodeQueryComponent(category.trim())}',
      if (tenantId != null && tenantId.trim().isNotEmpty)
        'tenant=${Uri.encodeQueryComponent(tenantId.trim())}',
      if (minPrice != null) 'minPrice=${minPrice.toStringAsFixed(0)}',
      if (maxPrice != null) 'maxPrice=${maxPrice.toStringAsFixed(0)}',
    ];

    final suffix = params.isEmpty ? '' : '?${params.join('&')}';
    return get('/search/services$suffix');
  }

  Future<Map<String, dynamic>> getServicesForTenant(String tenantId) async {
    return get('/services/tenant/$tenantId');
  }

  Future<Map<String, dynamic>> getServicesForCustomer(String customerId) async {
    return get('/services/customer/$customerId');
  }

  Future<Map<String, dynamic>> getServiceById(String id) async {
    return get('/services/$id');
  }

  Future<Map<String, dynamic>> createService(
    Map<String, dynamic> data, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    // ✅ If no image → normal request
    if (imageBytes == null || imageBytes.isEmpty) {
      return post('/services', data);
    }

    // ✅ Single image upload
    final file = MultipartFile.fromBytes(
      imageBytes,
      filename:
          imageName?.isNotEmpty == true ? imageName! : 'service-image.jpg',
    );

    return _multipartRequest(
      method: 'POST',
      endpoint: '/services',
      payload: data,
      files: [file], // ✅ single file list
    );
  }

  Future<Map<String, dynamic>> updateService(
    String id,
    Map<String, dynamic> data, {
    List<Uint8List> imageBytesList = const [],
    List<String> imageNames = const [],
  }) async {
    if (imageBytesList.isEmpty) {
      return put('/services/$id', data);
    }

    final files = <MultipartFile>[];
    for (var i = 0; i < imageBytesList.length; i++) {
      final filename = i < imageNames.length && imageNames[i].isNotEmpty
          ? imageNames[i]
          : 'service-image-${i + 1}.jpg';
      files.add(MultipartFile.fromBytes(imageBytesList[i], filename: filename));
    }

    return _multipartRequest(
      method: 'PUT',
      endpoint: '/services/$id',
      payload: data,
      files: files,
    );
  }

  Future<Map<String, dynamic>> deleteService(String id) async {
    return delete('/services/$id');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ASSETS / INVENTORY (Admin manages)
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getAssets({String? adminId}) async {
    final query = adminId != null ? '?tenant=$adminId' : '';
    return get('/assets$query');
  }

  Future<Map<String, dynamic>> getAssetById(String id) async {
    return get('/assets/$id');
  }

  Future<Map<String, dynamic>> createAsset(
    Map<String, dynamic> data, {
    List<Uint8List> imageBytesList = const [],
    List<String> imageNames = const [],
  }) async {
    if (imageBytesList.isEmpty) {
      return post('/assets', data);
    }

    final files = <MultipartFile>[];
    for (var i = 0; i < imageBytesList.length; i++) {
      final filename = i < imageNames.length && imageNames[i].isNotEmpty
          ? imageNames[i]
          : 'asset-image-${i + 1}.jpg';
      files.add(MultipartFile.fromBytes(imageBytesList[i], filename: filename));
    }

    return _multipartRequest(
      method: 'POST',
      endpoint: '/assets',
      payload: data,
      files: files,
    );
  }

  Future<Map<String, dynamic>> updateAsset(
    String id,
    Map<String, dynamic> data, {
    List<Uint8List> imageBytesList = const [],
    List<String> imageNames = const [],
  }) async {
    if (imageBytesList.isEmpty) {
      return put('/assets/$id', data);
    }

    final files = <MultipartFile>[];
    for (var i = 0; i < imageBytesList.length; i++) {
      final filename = i < imageNames.length && imageNames[i].isNotEmpty
          ? imageNames[i]
          : 'asset-image-${i + 1}.jpg';
      files.add(MultipartFile.fromBytes(imageBytesList[i], filename: filename));
    }

    return _multipartRequest(
      method: 'PUT',
      endpoint: '/assets/$id',
      payload: data,
      files: files,
    );
  }

  Future<Map<String, dynamic>> deleteAsset(String id) async {
    return delete('/assets/$id');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PROVIDERS (Admin creates & manages)
  // ═══════════════════════════════════════════════════════════════════

  // Admin fetches providers under their store
  Future<Map<String, dynamic>> getProviders({String? adminId}) async {
    final query = adminId != null ? '?admin_id=$adminId' : '';
    return get('/service-providers$query');
  }

  Future<Map<String, dynamic>> getProviderById(String id) async {
    return get('/service-providers/$id');
  }

  // Admin creates provider account — provider gets login credentials
  Future<Map<String, dynamic>> createProvider(Map<String, dynamic> data) async {
    return post('/service-providers', data);
  }

  Future<Map<String, dynamic>> updateProvider(
      String id, Map<String, dynamic> data) async {
    return patch('/service-providers/$id', data);
  }

  Future<Map<String, dynamic>> toggleProviderStatus(
      String id, bool isActive) async {
    return put('/service-providers/$id', {'isActive': isActive});
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BOOKINGS / ORDERS
  // ═══════════════════════════════════════════════════════════════════

  // User creates booking
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    return post('/bookings', data);
  }

  // Admin sees all bookings for their store
  Future<Map<String, dynamic>> getBookingsForAdmin({
    String? tenantId,
    String? status,
  }) async {
    final params = <String>[];
    if (tenantId != null) params.add('tenantId=$tenantId');
    if (status != null) params.add('status=$status');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return get('/bookings$query');
  }

  // Admin assigns provider + asset to booking
  Future<Map<String, dynamic>> assignProviderToBooking(
    String bookingId, {
    required String providerId,
    required String assetId,
    required String scheduledDate,
    required String scheduledTime,
  }) async {
    return put('/bookings/$bookingId/assign', {
      'provider': providerId,
      'assigned_asset_id': assetId,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
    });
  }

  // Provider fetches their assigned bookings
  Future<Map<String, dynamic>> getBookingsForProvider({
    String? status,
  }) async {
    final query = status != null ? '?status=$status' : '';
    return get('/bookings$query');
  }

  // Provider updates booking status
  Future<Map<String, dynamic>> updateBookingStatus(
    String bookingId,
    String status,
  ) async {
    return put('/bookings/$bookingId/status', {'status': status});
  }

  Future<Map<String, dynamic>> updateBookingCosts(
    String bookingId, {
    bool? assignedAssetConfirmedUsed,
    List<Map<String, dynamic>>? additionalAssets,
  }) async {
    return put('/bookings/$bookingId/costs', {
      if (assignedAssetConfirmedUsed != null)
        'assignedAssetConfirmedUsed': assignedAssetConfirmedUsed,
      if (additionalAssets != null) 'additionalAssets': additionalAssets,
    });
  }

  Future<Map<String, dynamic>> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    return put('/bookings/$bookingId/cancel', {
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }

  Future<Map<String, dynamic>> submitBookingFeedback(
    String bookingId, {
    required int rating,
    String? comment,
  }) async {
    return post('/bookings/$bookingId/feedback', {
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    });
  }

  // User fetches their own booking history
  Future<Map<String, dynamic>> getBookingsForUser() async {
    return get('/bookings');
  }

  Future<Map<String, dynamic>> getBookingById(String id) async {
    return get('/bookings/$id');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  STORES (User browses admin stores)
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getStores() async {
    final response = await get('/search/tenants');
    final stores = (response['data'] as List<dynamic>? ?? []).map((tenant) {
      final item = tenant as Map<String, dynamic>;
      final address = item['address'] as Map<String, dynamic>? ?? {};
      final businessName = item['businessName']?.toString() ??
          item['business_name']?.toString() ??
          item['name']?.toString() ??
          item['storeName']?.toString() ??
          item['store_name']?.toString() ??
          item['subdomain']?.toString() ??
          '';
      return <String, dynamic>{
        'id': item['_id']?.toString() ?? '',
        'store_name': businessName,
        'business_name': businessName,
        'store_city': address['city']?.toString() ?? '',
        'store_state': address['state']?.toString() ?? '',
        'store_address': address['street']?.toString() ?? '',
        'subdomain': item['subdomain']?.toString() ?? '',
        'business_type':
            (item['business'] as Map<String, dynamic>?)?['type']?.toString(),
        'store_logo': item['avatarUrl']?.toString(),
      };
    }).toList();

    return {
      'success': true,
      'stores': stores,
    };
  }

  Future<Map<String, dynamic>> getStoreById(String id) async {
    return get('/tenants/$id');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getNotifications() async {
    return get('/notifications');
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    return patch('/notifications/$id/read', {});
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    return patch('/notifications/read-all', {});
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DASHBOARD STATS
  // ═══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    return get('/admin/stats');
  }

  Future<Map<String, dynamic>> getProviderDashboardStats() async {
    return get('/dashboard/provider');
  }

  Future<Map<String, dynamic>> getUserDashboardStats() async {
    return get('/dashboard/user');
  }
}
