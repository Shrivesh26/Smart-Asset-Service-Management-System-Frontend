import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/service_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/service_catalog_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_media_image.dart';

class BookServiceScreen extends StatefulWidget {
  final String serviceId;
  final String storeId;

  const BookServiceScreen({
    super.key,
    required this.serviceId,
    required this.storeId,
  });

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedDate;
  String _selectedTime = AppConstants.timeSlots.first;
  String _selectedAddressKey = 'new';

  // ── Theme helpers ──────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface =>
      _isDark ? AppTheme.darkBackground : const Color(0xFFF4F7F5);
  Color get _card => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _txtP =>
      _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS =>
      _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _border =>
      _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;
  Color get _fill => _isDark ? AppTheme.darkInput : Colors.grey.shade50;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    _phoneCtrl.text = user?.phone ?? '';
    final saved = user?.savedAddresses ?? const [];
    final defaultIndex = saved.indexWhere((address) => address.isDefault);
    final selectedIndex =
        defaultIndex != -1 ? defaultIndex : (saved.isNotEmpty ? 0 : -1);
    final profileAddress = _profileAddressDisplay(auth);
    if (selectedIndex != -1) {
      _selectedAddressKey = 'saved:$selectedIndex';
      _addressCtrl.text = saved[selectedIndex].display;
    } else if (profileAddress.isNotEmpty) {
      _selectedAddressKey = 'profile';
      _addressCtrl.text = profileAddress;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = widget.storeId;
      if (storeId.isNotEmpty) {
        context.read<ServiceCatalogService>().fetchServicesForStore(storeId);
      } else {
        context.read<ServiceCatalogService>().fetchMarketplaceServices();
      }
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Date picker ────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.userPrimary,
            surface: _card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ── Confirm booking ────────────────────────────────────────────────────
  Future<void> _onConfirmBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      _showSnack('Please select a preferred date.', AppTheme.statusInactive);
      return;
    }

    final auth = context.read<AuthService>();
    final bookingSvc = context.read<BookingService>();
    final service = _selectedServiceModel(context.read<ServiceCatalogService>());
    final user = auth.currentUser!;

    if (service == null) {
      _showSnack('Service details unavailable.', AppTheme.statusInactive);
      return;
    }

    final success = await bookingSvc.createBooking(
      userId: user.id,
      userName: user.fullName,
      userPhone: _phoneCtrl.text.trim(),
      userAddress: _addressCtrl.text.trim(),
      storeId: widget.storeId.isNotEmpty ? widget.storeId : service.tenantId,
      storeName: service.businessName,
      serviceId: service.id,
      serviceName: service.name,
      serviceCategory: service.category,
      problemDescription: _notesCtrl.text.trim(),
      preferredDate: _selectedDate!,
      preferredTime: _selectedTime,
    );

    if (!mounted) return;
    if (success) {
      final shouldTrack = await _showSuccessDialog();
      if (!mounted) return;
      if (shouldTrack == true) {
        context.go(AppRoutes.userOrderHistory);
      } else {
        context.go(AppRoutes.userMarketplace);
      }
    } else {
      _showSnack(
          bookingSvc.error ?? 'Failed to submit booking.', AppTheme.statusInactive);
    }
  }

  Future<bool?> _showSuccessDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (d) => AlertDialog(
        backgroundColor: _card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.statusCompleted.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.statusCompleted, size: 46),
          ),
          const SizedBox(height: 20),
          Text('Booking Submitted!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _txtP,
              )),
          const SizedBox(height: 10),
          Text(
            'Your request has been sent. A provider will be assigned shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _txtS, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(d, rootNavigator: true).pop(true),
              icon: const Icon(Icons.track_changes_rounded),
              label: const Text('Track My Order'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.userPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(d, rootNavigator: true).pop(false),
            child: Text('Back to Home',
                style: TextStyle(color: _txtS, fontSize: 13)),
          ),
        ]),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  ServiceModel? _selectedServiceModel(ServiceCatalogService svc) {
    final services =
        svc.storeServices.isNotEmpty ? svc.storeServices : svc.services;
    if (services.isEmpty) return null;
    try {
      return services.firstWhere((s) => s.id == widget.serviceId);
    } catch (_) {
      return services.first;
    }
  }

  String _profileAddressDisplay(AuthService auth) {
    final user = auth.currentUser;
    final parts = [
      user?.address,
      user?.city,
      user?.state,
      user?.pincode,
      user?.country,
    ]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ServiceCatalogService>();
    final service = _selectedServiceModel(catalog);

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: catalog.isLoading && service == null
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.userPrimary,
                  ),
                )
              : catalog.error != null && service == null
                  ? _buildLoadError(catalog.error!)
                  : SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Service summary ──────────────────────────────
                  _buildServiceCard(service),
                  const SizedBox(height: 18),

                  // ── Policy banner ────────────────────────────────
                  if (service != null && service.allowCancellation)
                    _buildPolicyBanner(service),
                  if (service != null && service.allowCancellation)
                    const SizedBox(height: 18),

                  // ── Steps ────────────────────────────────────────
                  _buildStepTracker(),
                  const SizedBox(height: 18),

                  // ── Address ──────────────────────────────────────
                  _buildSectionCard(
                    title: 'Service Address',
                    icon: Icons.location_on_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _savedAddressPicker(),
                        if (((context
                                    .watch<AuthService>()
                                    .currentUser
                                    ?.savedAddresses
                                    .isNotEmpty ??
                                false) ||
                            _profileAddressDisplay(context.read<AuthService>())
                                .isNotEmpty))
                          const SizedBox(height: 12),
                        _addressModeHint(),
                        _buildTextField(
                          controller: _addressCtrl,
                          hint: 'Enter your full address',
                          icon: Icons.map_outlined,
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Address is required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Contact ──────────────────────────────────────
                  _buildSectionCard(
                    title: 'Contact Details',
                    icon: Icons.call_outlined,
                    child: _buildTextField(
                      controller: _phoneCtrl,
                      hint: 'Your phone number',
                      icon: Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Phone is required'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Schedule ─────────────────────────────────────
                  _buildSectionCard(
                    title: 'Preferred Schedule',
                    icon: Icons.schedule_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Date'),
                        const SizedBox(height: 8),
                        _buildDatePicker(),
                        const SizedBox(height: 14),
                        _fieldLabel('Time Slot'),
                        const SizedBox(height: 8),
                        _buildTimePicker(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Notes ────────────────────────────────────────
                  _buildSectionCard(
                    title: 'Describe the Issue',
                    icon: Icons.edit_note_rounded,
                    child: _buildTextField(
                      controller: _notesCtrl,
                      hint:
                          'Describe the problem or any special requirements...',
                      icon: Icons.notes_rounded,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Confirm button ───────────────────────────────
                  _buildConfirmButton(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildLoadError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppTheme.statusInactive,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _txtP,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                if (widget.storeId.isNotEmpty) {
                  context
                      .read<ServiceCatalogService>()
                      .fetchServicesForStore(widget.storeId);
                } else {
                  context
                      .read<ServiceCatalogService>()
                      .fetchMarketplaceServices();
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

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
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => context.go(AppRoutes.userMarketplace),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Book a Service',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      )),
                  Text('Fill in the details to confirm',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.75))),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Service card ───────────────────────────────────────────────────────
  Widget _buildServiceCard(ServiceModel? service) {
    if (service == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.userPrimary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.userPrimary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(children: [
        AppMediaImage(
          imageUrl: service.imageUrl,
          fallbackIcon: Icons.home_repair_service_outlined,
          accent: AppTheme.userPrimary,
          width: double.infinity,
          height: 150,
          radius: 16,
        ),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.userPrimary.withOpacity(0.2),
                  AppTheme.userPrimary.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.home_repair_service_outlined,
                color: AppTheme.userPrimary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(service.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _txtP,
                  )),
              const SizedBox(height: 3),
              Text(
                service.businessName.isEmpty
                    ? 'Independent team'
                    : service.businessName,
                style: TextStyle(fontSize: 12, color: _txtS),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(Icons.currency_rupee_rounded, service.priceDisplay),
            _chip(Icons.schedule_rounded, service.durationDisplay),
            _chip(Icons.calendar_month_outlined,
                'Up to ${service.maxAdvanceDays}d'),
            if (service.averageProviderRating > 0)
              _chip(Icons.star_rounded,
                  '${service.averageProviderRating.toStringAsFixed(1)} ★'),
          ],
        ),
      ]),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.userPrimary.withOpacity(_isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppTheme.userPrimary),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.userPrimary,
            )),
      ]),
    );
  }

  Widget _savedAddressPicker() {
    final user = context.watch<AuthService>().currentUser;
    final addresses = user?.savedAddresses ?? const [];
    final profileAddress = [
      user?.address,
      user?.city,
      user?.state,
      user?.pincode,
      user?.country,
    ]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .join(', ');

    final options = <Map<String, String>>[
      if (profileAddress.isNotEmpty)
        {
          'key': 'profile',
          'label': 'Present address',
          'value': profileAddress,
        },
      ...addresses.asMap().entries.map((entry) => {
            'key': 'saved:${entry.key}',
            'label': entry.value.label,
            'value': entry.value.display,
          }),
      {
        'key': 'new',
        'label': 'New address',
        'value': '',
      },
    ];

    if (options.length <= 1) return const SizedBox.shrink();

    final selectedKey = options.any((item) => item['key'] == _selectedAddressKey)
        ? _selectedAddressKey
        : options.first['key']!;

    return DropdownButtonFormField<String>(
      value: selectedKey,
      dropdownColor: _card,
      style: TextStyle(color: _txtP, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: _fill,
        prefixIcon: const Icon(Icons.bookmark_outline_rounded,
            color: AppTheme.userPrimary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.userPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: options.map((option) {
        final isNew = option['key'] == 'new';
        final display = isNew
            ? 'Add a new address below'
            : '${option['label']} - ${option['value']}';
        return DropdownMenuItem(
          value: option['key'],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNew
                    ? Icons.add_location_alt_outlined
                    : Icons.location_on_outlined,
                color: AppTheme.userPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  display,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: _txtP),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        final selected = options.firstWhere((item) => item['key'] == value);
        setState(() {
          _selectedAddressKey = value;
          if (value == 'new') {
            _addressCtrl.clear();
          } else {
            _addressCtrl.text = selected['value'] ?? '';
          }
        });
      },
    );
  }

  Widget _addressModeHint() {
    if (_selectedAddressKey != 'new') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.userPrimary.withOpacity(_isDark ? 0.14 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.userPrimary.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_location_alt_outlined,
                color: AppTheme.userPrimary, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enter the address where the service should be completed.',
                style: TextStyle(fontSize: 12, color: _txtS, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Policy banner ──────────────────────────────────────────────────────
  Widget _buildPolicyBanner(ServiceModel service) {
    final allowed = service.allowCancellation;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: allowed
            ? AppTheme.statusCompleted.withOpacity(0.08)
            : AppTheme.statusInactive.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: allowed
              ? AppTheme.statusCompleted.withOpacity(0.2)
              : AppTheme.statusInactive.withOpacity(0.2),
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
          allowed ? Icons.check_circle_outline : Icons.info_outline_rounded,
          color: allowed ? AppTheme.statusCompleted : AppTheme.statusInactive,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Booking Policy',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: allowed
                      ? AppTheme.statusCompleted
                      : AppTheme.statusInactive,
                )),
            const SizedBox(height: 3),
            Text(
              service.allowCancellationBeforeAssign
                  ? 'You can cancel this booking before a provider is assigned.'
                  : 'You can cancel this booking according to this service cancellation policy.',
              style: TextStyle(
                  fontSize: 12,
                  color: _txtS,
                  height: 1.4),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Step tracker ───────────────────────────────────────────────────────
  Widget _buildStepTracker() {
    const steps = [
      _Step('Service', Icons.home_repair_service_outlined),
      _Step('Schedule', Icons.calendar_today_outlined),
      _Step('Confirm', Icons.check_circle_outline),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value;
          final isDone = idx < 2;
          final isCurrent = idx == 2;

          return Expanded(
            child: Row(children: [
              Expanded(
                child: Column(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? AppTheme.userPrimary
                          : isCurrent
                              ? AppTheme.userPrimary.withOpacity(0.1)
                              : _isDark
                                  ? AppTheme.darkInput
                                  : Colors.grey.shade100,
                      border: Border.all(
                        color: isDone || isCurrent
                            ? AppTheme.userPrimary
                            : _border,
                        width: isDone ? 0 : 2,
                      ),
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : step.icon,
                      size: 17,
                      color: isDone
                          ? Colors.white
                          : isCurrent
                              ? AppTheme.userPrimary
                              : _txtS,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(step.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isDone || isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isDone || isCurrent ? AppTheme.userPrimary : _txtS,
                      )),
                ]),
              ),
              if (idx < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.userPrimary,
                          idx < 1
                              ? AppTheme.userPrimary
                              : AppTheme.userPrimary.withOpacity(0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ── Section card ───────────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.userPrimary.withOpacity(_isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.userPrimary, size: 17),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _txtP,
              )),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  // ── Text field ─────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: _txtP, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _txtS, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.userPrimary, size: 20),
        filled: true,
        fillColor: _fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.userPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.statusInactive, width: 1.2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedDate != null
                ? AppTheme.userPrimary
                : _border,
            width: _selectedDate != null ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined,
              color: _selectedDate != null ? AppTheme.userPrimary : _txtS,
              size: 20),
          const SizedBox(width: 12),
          Text(
            _selectedDate ?? 'Select preferred date',
            style: TextStyle(
              fontSize: 14,
              color: _selectedDate != null ? _txtP : _txtS,
            ),
          ),
          const Spacer(),
          if (_selectedDate != null)
            Icon(Icons.check_circle_rounded,
                color: AppTheme.userPrimary, size: 18),
        ]),
      ),
    );
  }

  Widget _buildTimePicker() {
    return DropdownButtonFormField<String>(
      value: _selectedTime,
      dropdownColor: _card,
      style: TextStyle(color: _txtP, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: _fill,
        prefixIcon: const Icon(Icons.access_time_rounded,
            color: AppTheme.userPrimary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.userPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: AppConstants.timeSlots.map((t) {
        return DropdownMenuItem(
            value: t, child: Text(t, style: TextStyle(color: _txtP)));
      }).toList(),
      onChanged: (v) => setState(() => _selectedTime = v!),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _txtP,
        ));
  }

  // ── Confirm button ─────────────────────────────────────────────────────
  Widget _buildConfirmButton() {
    return Consumer<BookingService>(
      builder: (_, svc, __) => Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDark
                ? [const Color(0xFF145A32), AppTheme.userPrimary]
                : [const Color(0xFF0A3D2E), AppTheme.userPrimary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.userPrimary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: svc.isLoading ? null : _onConfirmBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          icon: svc.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 22),
          label: Text(
            svc.isLoading ? 'Submitting...' : 'Confirm Booking',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Step {
  const _Step(this.label, this.icon);
  final String label;
  final IconData icon;
}
