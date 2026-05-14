import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class UserOrderStatusScreen extends StatefulWidget {
  final String orderId;
  const UserOrderStatusScreen({super.key, required this.orderId});

  @override
  State<UserOrderStatusScreen> createState() => _UserOrderStatusScreenState();
}

class _UserOrderStatusScreenState extends State<UserOrderStatusScreen> {
  // ── Theme helpers ──────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface =>
      _isDark ? AppTheme.darkBackground : const Color(0xFFF4F7F5);
  Color get _card => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _txtP =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _div => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  // ── Responsive helpers ─────────────────────────────────────────────────
  double get _screenWidth => MediaQuery.of(context).size.width;
  bool get _isTablet => _screenWidth >= 600;
  bool get _isLargeTablet => _screenWidth >= 840;
  double get _horizontalPadding => _isTablet ? 28.0 : 18.0;
  double get _cardRadius => _isTablet ? 24.0 : 20.0;

  static const _steps = [
    _TrackStep('Requested', Icons.send_outlined, 0),
    _TrackStep('Finding Provider', Icons.search_rounded, 1),
    _TrackStep('Provider Assigned', Icons.handshake_outlined, 2),
    _TrackStep('In Progress', Icons.build_outlined, 3),
    _TrackStep('Completed', Icons.check_circle_outline, 4),
  ];

  int _stepFor(BookingModel booking) {
    if (booking.isCompleted) return 4;
    if (booking.isInProgress) return 3;
    if (booking.isAccepted || booking.isProviderAccepted) return 2;
    if (booking.isAssigned || booking.isProviderRejected) return 1;
    return 0;
  }

  /// Cancel is only valid at step 0 (Requested) or step 1 (Finding Provider).
  /// Once a provider has been assigned (step ≥ 2), the button is removed.
  /// Additionally the service itself must allow pre-assignment cancellation.
  bool _canShowCancelButton(BookingModel b) {
    // Gate 1: booking-level cancellability (not already cancelled/completed)
    if (!b.canUserCancel) return false;

    // Gate 2: must be before provider assignment (steps 0 or 1 only)
    final step = _stepFor(b);
    if (step > 1 || b.hasProvider) return false;

    return true;
  }

  String _statusMessageFor(BookingModel booking) {
    if (booking.isCancelled) return booking.cancellationLabel;
    if (booking.isCompleted) {
      return 'Service completed! Thank you for choosing us.';
    }
    if (booking.isInProgress) {
      return 'Your provider is currently working on the service.';
    }
    if (booking.isAccepted || booking.isProviderAccepted) {
      return 'Your provider has accepted the booking. Provider details are now available.';
    }
    if (booking.isAssigned || booking.isProviderRejected) {
      return 'We are finding the right provider for your service request.';
    }
    return 'Your request is received and awaiting tenant review.';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BookingService>().fetchBookingById(widget.orderId),
    );
  }

  Future<void> _submitRating() async {
    int selectedRating = 5;
    final commentCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (_, ss) => AlertDialog(
          backgroundColor: _card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          title: Text(
            'Rate This Service',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _txtP,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your experience?',
                style: TextStyle(fontSize: 13, color: _txtS),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => ss(() => selectedRating = star),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        star <= selectedRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: star <= selectedRating
                            ? const Color(0xFFFBBF24)
                            : _txtS,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                minLines: 3,
                maxLines: 4,
                style: TextStyle(color: _txtP, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  hintStyle: TextStyle(color: _txtS, fontSize: 13),
                  filled: true,
                  fillColor:
                      _isDark ? AppTheme.darkInput : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text('Cancel', style: TextStyle(color: _txtS)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(d, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.userPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      commentCtrl.dispose();
      return;
    }

    final svc = context.read<BookingService>();
    final success = await svc.submitFeedback(
      widget.orderId,
      rating: selectedRating,
      comment: commentCtrl.text,
    );
    commentCtrl.dispose();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Thanks for your feedback!'
              : (svc.error ?? 'Failed to submit.'),
        ),
        backgroundColor:
            success ? AppTheme.statusCompleted : AppTheme.statusInactive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: _card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Booking',
          style:
              TextStyle(fontWeight: FontWeight.w700, color: _txtP),
        ),
        content: Text(
          'Are you sure you want to cancel this request?',
          style: TextStyle(color: _txtS, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text('Keep it', style: TextStyle(color: _txtS)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.statusInactive,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final svc = context.read<BookingService>();
    final success = await svc.cancelBooking(widget.orderId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Booking cancelled.' : (svc.error ?? 'Could not cancel.'),
        ),
        backgroundColor:
            success ? AppTheme.statusCompleted : AppTheme.statusInactive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BookingService>();
    final b = svc.selectedBooking;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: (svc.isLoading || b == null)
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.userPrimary,
                    ),
                  )
                : RefreshIndicator(
                    color: AppTheme.userPrimary,
                    onRefresh: () => svc.fetchBookingById(widget.orderId),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        // Constrains content width on large tablets
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: _isLargeTablet ? 720 : double.infinity,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(_horizontalPadding),
                            child: _isLargeTablet
                                ? _buildWideContent(b, svc)
                                : _buildNarrowContent(b, svc),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Narrow layout (phone + small tablet) ──────────────────────────────
  Widget _buildNarrowContent(BookingModel b, BookingService svc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusHero(b),
        const SizedBox(height: 18),
        _buildProgressTracker(b),
        const SizedBox(height: 18),
        ..._buildInfoCards(b),
        if (_canShowCancelButton(b)) _buildCancelButton(svc),
        if (b.isCompleted) _buildRatingCard(b, svc),
        const SizedBox(height: 28),
      ],
    );
  }

  // ── Wide layout (large tablet) ─────────────────────────────────────────
  Widget _buildWideContent(BookingModel b, BookingService svc) {
    return Column(
      children: [
        _buildStatusHero(b),
        const SizedBox(height: 18),
        _buildProgressTracker(b),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildInfoCard('Service Details', [
                    _infoRow('Service', b.serviceName),
                    _infoRow('Category', b.serviceCategory),
                    _infoRow('Business', b.storeName),
                    _infoRow('Address',
                        b.userAddress.isEmpty ? '-' : b.userAddress),
                  ]),
                  const SizedBox(height: 14),
                  _buildInfoCard('Schedule', [
                    _infoRow('Preferred Date', b.preferredDate),
                    _infoRow('Preferred Time', b.preferredTime),
                    if (b.scheduledDate != null)
                      _infoRow('Scheduled Date', b.scheduledDate!),
                    if (b.scheduledTime != null)
                      _infoRow('Scheduled Time', b.scheduledTime!),
                  ]),
                  const SizedBox(height: 14),
                  _buildInfoCard('Issue Reported', [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        b.problemDescription.isEmpty
                            ? 'No description provided.'
                            : b.problemDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: _txtP,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  if (b.shouldShowProviderToUser)
                    _buildInfoCard('Assigned Provider', [
                      _infoRow('Name', b.assignedProviderName ?? '-'),
                      _infoRow('Phone', b.assignedProviderPhone ?? '-'),
                      if (b.assignedAssetName != null)
                        _infoRow('Asset', b.assignedAssetName!),
                    ]),
                  if (b.shouldShowProviderToUser) const SizedBox(height: 14),
                  _buildCostBreakdownCard(b),
                  const SizedBox(height: 14),
                  if (_canShowCancelButton(b)) _buildCancelButton(svc),
                  if (b.isCompleted) _buildRatingCard(b, svc),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // ── Info cards for narrow layout ───────────────────────────────────────
  List<Widget> _buildInfoCards(BookingModel b) {
    return [
      _buildInfoCard('Service Details', [
        _infoRow('Service', b.serviceName),
        _infoRow('Category', b.serviceCategory),
        _infoRow('Business', b.storeName),
        _infoRow('Address', b.userAddress.isEmpty ? '-' : b.userAddress),
      ]),
      const SizedBox(height: 14),
      _buildInfoCard('Schedule', [
        _infoRow('Preferred Date', b.preferredDate),
        _infoRow('Preferred Time', b.preferredTime),
        if (b.scheduledDate != null)
          _infoRow('Scheduled Date', b.scheduledDate!),
        if (b.scheduledTime != null)
          _infoRow('Scheduled Time', b.scheduledTime!),
      ]),
      const SizedBox(height: 14),
      if (b.shouldShowProviderToUser) ...[
        _buildInfoCard('Assigned Provider', [
          _infoRow('Name', b.assignedProviderName ?? '-'),
          _infoRow('Phone', b.assignedProviderPhone ?? '-'),
          if (b.assignedAssetName != null)
            _infoRow('Asset', b.assignedAssetName!),
        ]),
        const SizedBox(height: 14),
      ],
      _buildInfoCard('Issue Reported', [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            b.problemDescription.isEmpty
                ? 'No description provided.'
                : b.problemDescription,
            style: TextStyle(fontSize: 13, color: _txtP, height: 1.55),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      _buildCostBreakdownCard(b),
      const SizedBox(height: 14),
    ];
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF0A2E1F), const Color(0xFF145A32)]
              : [const Color(0xFF0A3D2E), AppTheme.userPrimary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Text(
                  'Order Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status hero ────────────────────────────────────────────────────────
  Widget _buildStatusHero(BookingModel b) {
    final isCancelled = b.status == AppConstants.statusCancelled;
    final displayStatus = b.userFacingStatusLabel;

    return Container(
      padding: EdgeInsets.all(_isTablet ? 20 : 18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: _isTablet ? 62 : 56,
            height: _isTablet ? 62 : 56,
            decoration: BoxDecoration(
              color: isCancelled
                  ? AppTheme.statusInactive.withOpacity(0.12)
                  : AppTheme.getStatusBgColor(displayStatus),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isCancelled
                  ? Icons.cancel_outlined
                  : Icons.home_repair_service_outlined,
              color: isCancelled
                  ? AppTheme.statusInactive
                  : AppTheme.getStatusColor(displayStatus),
              size: _isTablet ? 30 : 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.serviceName,
                  style: TextStyle(
                    fontSize: _isTablet ? 17 : 16,
                    fontWeight: FontWeight.w700,
                    color: _txtP,
                  ),
                ),
                const SizedBox(height: 4),
                Text(b.storeName,
                    style: TextStyle(fontSize: 12, color: _txtS)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCancelled
                  ? AppTheme.statusInactive.withOpacity(0.12)
                  : AppTheme.getStatusBgColor(displayStatus),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              displayStatus,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isCancelled
                    ? AppTheme.statusInactive
                    : AppTheme.getStatusColor(displayStatus),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress tracker ───────────────────────────────────────────────────
  Widget _buildProgressTracker(BookingModel booking) {
    final isCancelled = booking.status == AppConstants.statusCancelled;
    final currentStep = isCancelled ? -1 : _stepFor(booking);

    return Container(
      padding: EdgeInsets.all(_isTablet ? 20 : 18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tracking Progress',
                style: TextStyle(
                  fontSize: _isTablet ? 15 : 14,
                  fontWeight: FontWeight.w700,
                  color: _txtP,
                ),
              ),
              if (isCancelled) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.statusInactive.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Cancelled',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.statusInactive,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: _steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              final isLast = idx == _steps.length - 1;
              final isDone = !isCancelled && idx < currentStep;
              final isCurr = !isCancelled && idx == currentStep;

              Color circleColor;
              Color borderColor;
              Color iconColor;

              if (isCancelled) {
                circleColor =
                    _isDark ? AppTheme.darkInput : Colors.grey.shade100;
                borderColor = AppTheme.statusInactive.withOpacity(0.3);
                iconColor = _txtS;
              } else if (isDone) {
                circleColor = AppTheme.userPrimary;
                borderColor = AppTheme.userPrimary;
                iconColor = Colors.white;
              } else if (isCurr) {
                circleColor = AppTheme.userPrimary.withOpacity(0.15);
                borderColor = AppTheme.userPrimary;
                iconColor = AppTheme.userPrimary;
              } else {
                circleColor =
                    _isDark ? AppTheme.darkInput : Colors.grey.shade100;
                borderColor = _div;
                iconColor = _txtS;
              }

              final connectorColor = isCancelled
                  ? AppTheme.statusInactive.withOpacity(0.2)
                  : idx < currentStep
                      ? AppTheme.userPrimary
                      : _div;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _isTablet ? 38 : 34,
                            height: _isTablet ? 38 : 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: circleColor,
                              border: Border.all(
                                color: borderColor,
                                width: isDone ? 0 : 2,
                              ),
                            ),
                            child: Icon(
                              isDone ? Icons.check_rounded : step.icon,
                              size: 16,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isDone || isCurr
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isCancelled
                                  ? _txtS.withOpacity(0.5)
                                  : (isDone || isCurr)
                                      ? AppTheme.userPrimary
                                      : _txtS,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 22),
                          decoration: BoxDecoration(
                            color: connectorColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isCancelled
                  ? AppTheme.statusInactive.withOpacity(0.08)
                  : AppTheme.userPrimary
                      .withOpacity(_isDark ? 0.15 : 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isCancelled
                      ? Icons.cancel_outlined
                      : Icons.info_outline_rounded,
                  color: isCancelled
                      ? AppTheme.statusInactive
                      : AppTheme.userPrimary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessageFor(booking),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isCancelled
                          ? AppTheme.statusInactive
                          : AppTheme.userPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────
  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_isTablet ? 18 : 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.18 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: _isTablet ? 15 : 14,
              fontWeight: FontWeight.w700,
              color: _txtP,
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: _div),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  String _money(double value) => 'Rs ${value.toStringAsFixed(0)}';

  Widget _buildCostBreakdownCard(BookingModel b) {
    final cost = b.costBreakdown;
    return _buildInfoCard(
      cost.isFinal ? 'Final Cost Breakdown' : 'Estimated Cost Breakdown',
      [
        _infoRow('Service', _money(cost.service)),
        if (cost.provider > 0) _infoRow('Provider', _money(cost.provider)),
        if (cost.assignedAsset > 0)
          _infoRow(
            cost.isFinal ? 'Assigned Asset' : 'Asset Estimate',
            _money(cost.assignedAsset),
          ),
        if (cost.additionalAssets > 0)
          _infoRow('Extra Assets', _money(cost.additionalAssets)),
        if (b.additionalAssets.isNotEmpty) ...[
          const SizedBox(height: 6),
          _additionalAssetsList(b.additionalAssets),
        ],
        Divider(height: 18, color: _div),
        _infoRow(
          cost.isFinal ? 'Final Total' : 'Estimated Total',
          _money(cost.total),
        ),
      ],
    );
  }

  Widget _additionalAssetsList(List<Map<String, dynamic>> assets) {
    return Column(
      children: assets.map((asset) {
        final name = asset['name']?.toString().trim();
        final price = (asset['price'] as num?)?.toDouble() ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.userPrimary.withOpacity(_isDark ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.userPrimary.withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.userPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.add_business_outlined,
                  color: AppTheme.userPrimary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name?.isNotEmpty == true ? name! : 'Additional asset',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _txtP,
                      ),
                    ),
                    Text(
                      'Added during service',
                      style: TextStyle(fontSize: 11, color: _txtS),
                    ),
                  ],
                ),
              ),
              Text(
                _money(price),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _txtP,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _isTablet ? 130 : 110,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: _txtS)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _txtP,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cancel button ──────────────────────────────────────────────────────
  // Rules:
  //   1. Booking must not already be cancelled or completed (canUserCancel)
  //   2. Step must be < 2 — i.e., "Requested" or "Finding Provider" only.
  //      Once a provider is assigned (step 2+) the button disappears.
  //   3. The service must have allowCancellationBeforeAssign == true.
  Widget _buildCancelButton(BookingService svc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        height: _isTablet ? 56 : 52,
        child: OutlinedButton.icon(
          onPressed: svc.isLoading ? null : _cancelBooking,
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text(
            'Cancel Booking',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.statusInactive,
            side: const BorderSide(color: AppTheme.statusInactive),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  // ── Rating card ────────────────────────────────────────────────────────
  Widget _buildRatingCard(BookingModel b, BookingService svc) {
    return _buildInfoCard('Your Rating', [
      if (b.feedbackRating != null) ...[
        Row(
          children: [
            ...List.generate(
              5,
              (i) => Icon(
                i < (b.feedbackRating as int)
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: i < (b.feedbackRating as int)
                    ? const Color(0xFFFBBF24)
                    : _txtS,
                size: _isTablet ? 28 : 24,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${b.feedbackRating}/5',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _txtP,
              ),
            ),
          ],
        ),
        if (b.feedbackComment?.isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          Text(
            b.feedbackComment!,
            style: TextStyle(fontSize: 13, color: _txtS, height: 1.4),
          ),
        ],
      ] else
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: svc.isLoading ? null : _submitRating,
            icon: const Icon(Icons.star_rounded, size: 20),
            label: const Text(
              'Rate This Service',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.userPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _TrackStep {
  const _TrackStep(this.label, this.icon, this.index);
  final String label;
  final IconData icon;
  final int index;
}
