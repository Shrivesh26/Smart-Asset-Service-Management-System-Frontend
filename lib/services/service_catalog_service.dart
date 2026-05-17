import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/service_model.dart';
import 'api_service.dart';

class ServiceCatalogService extends ChangeNotifier {
  final ApiService _api;

  List<ServiceModel> _services = [];
  List<ServiceModel> _storeServices = [];
  ServiceModel? _selectedService;
  bool _isLoading = false;
  String? _error;

  ServiceCatalogService(this._api);

  List<ServiceModel> get services => _services;
  List<ServiceModel> get storeServices => _storeServices;
  ServiceModel? get selectedService => _selectedService;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ServiceModel> get availableServices =>
      _services.where((s) => s.isActive).toList();

  List<String> get categories {
    final cats = _services.map((s) => s.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<ServiceModel> servicesByCategory(String category) =>
      _services.where((s) => s.category == category).toList();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchServicesForAdmin({String? tenantId}) async {
    _setLoading(true);
    try {
      final response = await _api.getServicesForTenant(tenantId ?? '');
      final list = response['data'] as List<dynamic>? ?? [];
      _services = list
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Failed to load services. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMarketplaceServices({
    String? query,
    String? category,
  }) async {
    _setLoading(true);
    try {
      final response = await _api.searchServices(
        query: query,
        category: category,
      );
      final list = response['data'] as List<dynamic>? ?? [];
      _services = list
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .where((s) => s.isActive)
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Failed to load marketplace services. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createService({
    required String tenantId,
    required String name,
    required String category,
    required String description,
    required double pricing,
    required int duration,
    int maxAdvanceDays = 10,
    bool allowCancellation = true,
    bool allowCancellationBeforeAssign = true,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    _setLoading(true);
    try {
      final response = await _api.createService({
        'tenant': tenantId,
        'name': name,
        'category': category,
        'description': description,
        'pricing': pricing,
        'duration': duration,
        'bookingSettings': {
          'maxAdvanceDays': maxAdvanceDays,
          'allowCancellation': allowCancellation,
          'allowCancellationBeforeAssign': allowCancellationBeforeAssign,
        },
      }, imageBytes: imageBytes, imageName: imageName);

      final newService = ServiceModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );
      _services.insert(0, newService);

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to create service. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateService(
  String serviceId,
  Map<String, dynamic> data, {
  Uint8List? imageBytes,
  String? imageName,
}) async {
  _setLoading(true);
  try {
    final response = await _api.updateService(
      serviceId,
      data,
      imageBytesList:
          imageBytes != null ? [imageBytes] : const [],
      imageNames:
          imageName != null ? [imageName] : const [],
    );

    final updated = ServiceModel.fromJson(
      response['data'] as Map<String, dynamic>? ?? {},
    );

    // Update local list
    final idx = _services.indexWhere((s) => s.id == serviceId);
    if (idx != -1) _services[idx] = updated;

    final storeIdx = _storeServices.indexWhere((s) => s.id == serviceId);
    if (storeIdx != -1) _storeServices[storeIdx] = updated;

    if (_selectedService?.id == serviceId) {
      _selectedService = updated;
    }

    _error = null;
    notifyListeners();
    return true;
  } on ApiException catch (e) {
    _setError(e.message);
    return false;
  } catch (_) {

    _setError('Failed to update service. Please try again.');
    return false;
  } finally {
    _setLoading(false);
  }
}

  Future<bool> deleteService(String serviceId) async {
    _setLoading(true);
    try {
      await _api.deleteService(serviceId);
      _services.removeWhere((s) => s.id == serviceId);
      _storeServices.removeWhere((s) => s.id == serviceId);
      if (_selectedService?.id == serviceId) {
        _selectedService = null;
      }

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to delete service. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchServicesForStore(String storeId) async {
    _setLoading(true);
    try {
      final response = await _api.getServicesForTenant(storeId);
      final list = response['data'] as List<dynamic>? ?? [];
      _storeServices = list
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .where((s) => s.isActive)
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Failed to load store services. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  List<ServiceModel> searchServices(String query) {
    final source = _services.where((s) => s.isActive).toList();
    if (query.trim().isEmpty) return source;

    final q = query.toLowerCase();
    return source.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q);
    }).toList();
  }

  void selectService(ServiceModel service) {
    _selectedService = service;
    notifyListeners();
  }

  void clearServices() {
    _services = [];
    _storeServices = [];
    _selectedService = null;
    notifyListeners();
  }
}
