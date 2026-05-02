import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

class ProviderService extends ChangeNotifier {
  final ApiService _api;

  List<UserModel> _providers = [];
  UserModel? _selectedProvider;
  bool _isLoading = false;
  String? _error;

  ProviderService(this._api);

  List<UserModel> get providers => _providers;
  UserModel? get selectedProvider => _selectedProvider;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<UserModel> get activeProviders =>
      _providers.where((p) => p.isActive).toList();

  List<UserModel> get inactiveProviders =>
      _providers.where((p) => !p.isActive).toList();

  int get totalCount => _providers.length;
  int get activeCount => activeProviders.length;
  int get inactiveCount => inactiveProviders.length;

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

  Future<void> fetchProviders({String? adminId}) async {
    _setLoading(true);
    try {
      final response = await _api.getProviders(adminId: adminId);
      final list = response['data'] as List<dynamic>? ?? [];
      _providers = list
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Failed to load providers. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  int _experienceToYears(String value) {
    if (value == AppConstants.experienceOptions[0]) return 0;
    if (value == AppConstants.experienceOptions[1]) return 1;
    if (value == AppConstants.experienceOptions[2]) return 2;
    if (value == AppConstants.experienceOptions[3]) return 5;
    if (value == AppConstants.experienceOptions[4]) return 10;
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
    return 0;
  }

  Future<bool> createProvider({
    required String adminId,
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String skillCategory,
    required String experience,
    required String password,
    List<String> assignedServiceIds = const [],
    String? idProof,
    String? certifications,
    String? profilePhoto,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    _setLoading(true);
    try {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      final firstName = parts.isNotEmpty ? parts.first : fullName.trim();
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'Provider';
      String? uploadedProfilePhoto = profilePhoto;

      if (imageBytes != null && imageName != null && imageName.isNotEmpty) {
        uploadedProfilePhoto = await _api.uploadProviderImage(
          imageBytes: imageBytes,
          imageName: imageName,
        );
      }

      final response = await _api.createProvider({
        'tenant': adminId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': 'service_provider',
        'specializations': [skillCategory],
        'experience': _experienceToYears(experience),
        'address': {
          'street': address,
          'city': '',
          'state': '',
          'pinCode': '',
          'country': 'India',
        },
        'profile': {
          'avatar': uploadedProfilePhoto,
        },
        'bio': certifications,
      });

      final newProvider = UserModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );
      _providers.insert(0, newProvider);

      // Assign services after provider is confirmed created
      for (final serviceId in assignedServiceIds) {
        try {
          await _api.post('/services/assign_provider', {
            'serviceId': serviceId,
            'providerId': newProvider.id,
          });
        } catch (_) {
          // Non-fatal: service assignment failed, provider was still created
        }
      }

      _error = null;
      notifyListeners();
      return newProvider.id.isNotEmpty;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to create provider. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProvider(
    String providerId,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    try {
      final response = await _api.updateProvider(providerId, data);
      final updated = UserModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );

      final idx = _providers.indexWhere((p) => p.id == providerId);
      if (idx != -1) _providers[idx] = updated;
      if (_selectedProvider?.id == providerId) _selectedProvider = updated;

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to update provider. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleProviderStatus(
    String providerId,
    bool isActive,
  ) async {
    _setLoading(true);
    try {
      final response = await _api.toggleProviderStatus(providerId, isActive);
      if (response['success'] == false) {
        _setError(response['message'] as String? ?? 'Failed to update status');
        return false;
      }
      final updated = UserModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );

      final idx = _providers.indexWhere((p) => p.id == providerId);
      if (idx != -1) _providers[idx] = updated;
      if (_selectedProvider?.id == providerId) _selectedProvider = updated;

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to update provider status. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<UserModel> searchProviders(String query) {
    if (query.trim().isEmpty) return _providers;
    final q = query.toLowerCase();
    return _providers.where((p) {
      return p.fullName.toLowerCase().contains(q) ||
          (p.skillCategory?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void selectProvider(UserModel provider) {
    _selectedProvider = provider;
    notifyListeners();
  }

  void clearProviders() {
    _providers = [];
    _selectedProvider = null;
    notifyListeners();
  }
}
