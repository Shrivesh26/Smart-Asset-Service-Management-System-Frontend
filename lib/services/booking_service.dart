import 'package:flutter/foundation.dart';

import '../models/booking_model.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

class BookingService extends ChangeNotifier {
  final ApiService _api;

  List<BookingModel> _bookings = [];
  BookingModel? _selectedBooking;
  bool _isLoading = false;
  String? _error;

  BookingService(this._api);

  List<BookingModel> get bookings => _bookings;
  BookingModel? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<BookingModel> get requestedBookings =>
      _bookings.where((b) => b.status == AppConstants.statusRequested).toList();

  List<BookingModel> get assignedBookings =>
      _bookings.where((b) => b.status == AppConstants.statusAssigned).toList();

  List<BookingModel> get inProgressBookings =>
      _bookings.where((b) => b.status == AppConstants.statusInProgress).toList();

  List<BookingModel> get completedBookings =>
      _bookings
          .where((b) => b.status == AppConstants.statusCompleted)
          .toList();

  List<BookingModel> get pendingBookings =>
      _bookings.where((b) =>
          b.status == AppConstants.statusRequested ||
          b.status == AppConstants.statusAssigned ||
          b.status == AppConstants.statusAccepted).toList();

  List<BookingModel> get cancelledBookings =>
    _bookings.where((b) => b.status == AppConstants.statusCancelled).toList();

  int get totalOrders => _bookings.length;
  int get pendingCount => pendingBookings.length;
  int get inProgressCount => inProgressBookings.length;
  int get completedCount => completedBookings.length;

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

  String _toBackendStatus(String status) {
    switch (status) {
      case AppConstants.statusRequested:
        return 'pending';
      case AppConstants.statusAssigned:
        return 'assigned';
      case AppConstants.statusAccepted:
        return 'accepted';
      case AppConstants.statusInProgress:
        return 'in_progress';
      case AppConstants.statusCompleted:
        return 'completed';
      case AppConstants.statusCancelled:
        return 'cancelled';
      case 'Rejected':
        return 'rejected';
      default:
        return status.toLowerCase().trim();
    }
  }

  String _to24HourTime(String input) {
    final value = input.trim();
    final directMatch = RegExp(r'^([0-1]?\d|2[0-3]):[0-5]\d$');
    if (directMatch.hasMatch(value)) {
      return value.padLeft(5, '0');
    }

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) {
      return value;
    }

    var hours = int.parse(match.group(1)!);
    final minutes = match.group(2)!;
    final period = match.group(3)!.toUpperCase();

    if (period == 'AM') {
      if (hours == 12) hours = 0;
    } else if (hours != 12) {
      hours += 12;
    }

    return '${hours.toString().padLeft(2, '0')}:$minutes';
  }

  Future<void> fetchBookingsForAdmin({String? status}) async {
    _setLoading(true);
    try {
      final response = await _api.getBookingsForAdmin(status: status != null ? _toBackendStatus(status) : null);
      final list = response['data'] as List<dynamic>? ?? [];
      _bookings = list
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Failed to load orders. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> assignProviderToBooking(
    String bookingId, {
    required String providerId,
    List<String> assetIds = const [],
    required String scheduledDate,
    required String scheduledTime,
  }) async {
    _setLoading(true);
    try {
      final response = await _api.assignProviderToBooking(
        bookingId,
        providerId: providerId,
        assetIds: assetIds,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      );

      final updated = BookingModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );
      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) _bookings[idx] = updated;
      if (_selectedBooking?.id == bookingId) _selectedBooking = updated;

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to assign provider. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchBookingsForProvider({String? status}) async {
    _setLoading(true);
    try {
      final response = await _api.getBookingsForProvider(status: status);
      final list = response['data'] as List<dynamic>? ?? [];
      _bookings = list
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
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

  Future<bool> updateBookingStatus(
    String bookingId,
    String newStatus,
  ) async {
    _setLoading(true);
    try {
      final response = await _api.updateBookingStatus(
        bookingId,
        _toBackendStatus(newStatus),
      );
      final updated = BookingModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );

      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) _bookings[idx] = updated;
      if (_selectedBooking?.id == bookingId) _selectedBooking = updated;

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to update status. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateBookingCosts(
    String bookingId, {
    bool? assignedAssetConfirmedUsed,
    List<Map<String, dynamic>>? assignedAssetUsage,
    List<Map<String, dynamic>>? additionalAssets,
  }) async {
    _setLoading(true);
    try {
      final response = await _api.updateBookingCosts(
        bookingId,
        assignedAssetConfirmedUsed: assignedAssetConfirmedUsed,
        assignedAssetUsage: assignedAssetUsage,
        additionalAssets: additionalAssets,
      );
      final updated = BookingModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );

      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) _bookings[idx] = updated;
      if (_selectedBooking?.id == bookingId) _selectedBooking = updated;

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to update cost details. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createBooking({
    required String userId,
    required String userName,
    required String userPhone,
    required String userAddress,
    required String storeId,
    required String storeName,
    required String serviceId,
    required String serviceName,
    required String serviceCategory,
    required String problemDescription,
    required String preferredDate,
    required String preferredTime,
  }) async {
    _setLoading(true);
    try {
      final response = await _api.createBooking({
        'customer': userId,
        'service': serviceId,
        'appointmentDate': preferredDate,
        'startTime': _to24HourTime(preferredTime),
        'customerNotes': problemDescription,
        'contactPhone': userPhone,
        'serviceAddress': userAddress,
      });

      final newBooking = BookingModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );
      _bookings.insert(0, newBooking);

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to submit booking. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchBookingsForUser() async {
    _setLoading(true);
    try {
      final response = await _api.getBookingsForUser();
      final list = response['data'] as List<dynamic>? ?? [];
      _bookings = list
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Failed to load order history. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchBookingById(String id) async {
    _setLoading(true);
    try {
      final response = await _api.getBookingById(id);
      final bookingData = response['data'] as Map<String, dynamic>? ?? {};
      _selectedBooking = BookingModel.fromJson(bookingData);
      _error = null;
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Failed to load booking details. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    _setLoading(true);
    try {
      final response = await _api.cancelBooking(bookingId, reason: reason);
      final updated = BookingModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );

      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) _bookings[idx] = updated;
      if (_selectedBooking?.id == bookingId) _selectedBooking = updated;

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to cancel booking. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitFeedback(
    String bookingId, {
    required int rating,
    String? comment,
  }) async {
    _setLoading(true);
    try {
      final response = await _api.submitBookingFeedback(
        bookingId,
        rating: rating,
        comment: comment,
      );
      final updated = BookingModel.fromJson(
        response['data'] as Map<String, dynamic>? ?? {},
      );

      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) _bookings[idx] = updated;
      if (_selectedBooking?.id == bookingId) _selectedBooking = updated;

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Failed to submit feedback. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectBooking(BookingModel booking) {
    _selectedBooking = booking;
    notifyListeners();
  }

  void clearBookings() {
    _bookings = [];
    _selectedBooking = null;
    notifyListeners();
  }
}
