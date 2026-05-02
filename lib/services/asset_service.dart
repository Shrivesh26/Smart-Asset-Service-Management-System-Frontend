import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/asset_model.dart';
import 'api_service.dart';

class AssetService extends ChangeNotifier {
  final ApiService _api;

  List<AssetModel> _assets = [];
  AssetModel? _selectedAsset;
  bool _isLoading = false;
  String? _error;

  AssetService(this._api);

  List<AssetModel> get assets => _assets;
  AssetModel? get selectedAsset => _selectedAsset;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<AssetModel> get availableAssets =>
      _assets.where((a) => a.status.toLowerCase() == 'available').toList();

  List<AssetModel> get assignedAssets =>
      _assets.where((a) => a.status.toLowerCase() == 'assigned').toList();

  List<AssetModel> get maintenanceAssets =>
      _assets.where((a) => a.status.toLowerCase() == 'maintenance').toList();

  int get totalCount => _assets.length;
  int get availableCount => availableAssets.length;
  int get outOfStockCount => assignedAssets.length;

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

  Future<void> fetchAssets({String? adminId}) async {
    _setLoading(true);
    try {
      final response = await _api.getAssets(adminId: adminId);
      final list = response['assets'] as List<dynamic>? ??
          response['data'] as List<dynamic>? ??
          [];
      _assets = list
          .map((e) => AssetModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Failed to load inventory. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createAsset({
    required String adminId,
    required String name,
    required String category,
    required String description,
    required String location,
    required String assetNumber,
    required double price,
    required int quantity,
    required DateTime purchaseDate,
    String status = 'available',
    String condition = 'good',
    List<Uint8List> imageBytesList = const [],
    List<String> imageNames = const [],
  }) async {
    _setLoading(true);
    try {
      final payload = <String, dynamic>{
        'tenant': adminId,
        'name': name,
        'category': category,
        'description': description,
        'location': location,
        'status': status,
        'condition': condition,
        'price': price,
        'quantity': quantity,
        'purchaseDate': purchaseDate.toIso8601String(),
        'assetNumber': assetNumber,
      };

      final response = await _api.createAsset(
        payload,
        imageBytesList: imageBytesList,
        imageNames: imageNames,
      );

      final newAsset = AssetModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );
      _assets.insert(0, newAsset);

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to add asset. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAsset(
    String assetId,
    Map<String, dynamic> data, {
    List<Uint8List> imageBytesList = const [],
    List<String> imageNames = const [],
  }) async {
    _setLoading(true);
    try {
      final response = await _api.updateAsset(
        assetId,
        data,
        imageBytesList: imageBytesList,
        imageNames: imageNames,
      );
      final updated = AssetModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );

      final idx = _assets.indexWhere((a) => a.id == assetId);
      if (idx != -1) _assets[idx] = updated;
      if (_selectedAsset?.id == assetId) _selectedAsset = updated;

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to update asset. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAsset(String assetId) async {
    _setLoading(true);
    try {
      await _api.deleteAsset(assetId);
      _assets.removeWhere((a) => a.id == assetId);
      if (_selectedAsset?.id == assetId) _selectedAsset = null;

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to delete asset. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<AssetModel> searchAssets(String query) {
    if (query.trim().isEmpty) return _assets;
    final q = query.toLowerCase();
    return _assets.where((a) {
      return a.name.toLowerCase().contains(q) ||
          a.category.toLowerCase().contains(q) ||
          a.location.toLowerCase().contains(q);
    }).toList();
  }

  void selectAsset(AssetModel asset) {
    _selectedAsset = asset;
    notifyListeners();
  }

  void clearAssets() {
    _assets = [];
    _selectedAsset = null;
    notifyListeners();
  }
}
