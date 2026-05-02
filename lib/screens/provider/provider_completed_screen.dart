import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_theme.dart';

class ProviderCompletedScreen extends StatefulWidget {
  const ProviderCompletedScreen({super.key});
  @override
  State<ProviderCompletedScreen> createState() =>
      _ProviderCompletedScreenState();
}

class _ProviderCompletedScreenState extends State<ProviderCompletedScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  late final AnimationController _stagger;

  bool  get _isDark  => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg  => _isDark ? AppTheme.darkCard : Colors.white;
  Color get _surface => _isDark ? AppTheme.darkBackground : AppTheme.surface;
  Color get _txtP    => _isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  Color get _txtS    => _isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  Color get _txtH    => _isDark ? AppTheme.darkTextHint : AppTheme.textHint;
  Color get _div     => _isDark ? AppTheme.darkDivider : AppTheme.dividerColor;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BookingService>().fetchBookingsForProvider();
      if (mounted) _stagger.forward();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _stagger.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _stagger.reset();
    await context.read<BookingService>().fetchBookingsForProvider();
    if (mounted) _stagger.forward();
  }

  List<BookingModel> _filtered(List<BookingModel> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((b) =>
        b.serviceName.toLowerCase().contains(q) ||
        b.userName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final svc     = context.watch<BookingService>();
    final done    = svc.completedBookings;
    final filtered = _filtered(done);

    final cancelled  = done.where((b) => b.isCancelled).length;
    final successful = done.length - cancelled;

    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(gradient: LinearGradient(
              colors: _isDark
                  ? [const Color(0xFF451A03), const Color(0xFF92400E)]
                  : [AppTheme.providerDark, AppTheme.providerPrimary])),
          child: SafeArea(bottom: false, child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(18, 8, 16, 12),
              child: Row(children: [
                // IconButton(
                //   icon: const Icon(Icons.arrow_back_ios_new_rounded,
                //       color: Colors.white, size: 20),
                //   onPressed: () => context.pop(),
                // ),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Completed Jobs',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                          fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('${done.length} total  ·  $successful successful',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                          color: Colors.white.withOpacity(0.75))),
                ])),
              ])),
            // Summary chips
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(children: [
                _chip('${done.length}', 'Total',
                    Icons.work_history_outlined),
                const SizedBox(width: 10),
                _chip('$successful', 'Successful',
                    Icons.verified_outlined),
                const SizedBox(width: 10),
                _chip('$cancelled', 'Cancelled',
                    Icons.cancel_outlined),
              ])),
            // Search
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 13, color: _isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search completed jobs...',
                    hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                        color: _isDark ? Colors.white.withOpacity(0.75) : Colors.black.withOpacity(0.75)),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: _isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8), size: 18),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: _isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
                                size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            })
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              )),
          ])),
        ),

        // ── List ────────────────────────────────────────────────────
        Expanded(
          child: svc.isLoading
              ? Center(child: CircularProgressIndicator(
                  color: AppTheme.providerPrimary))
              : filtered.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      color: AppTheme.providerPrimary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _CompletedCard(
                          key: ValueKey(filtered[i].id),
                          booking: filtered[i], index: i,
                          isDark: _isDark, cardBg: _cardBg,
                          txtP: _txtP, txtS: _txtS, txtH: _txtH, div: _div,
                          staggerCtrl: _stagger,
                          onTap: () => context.push(
                              AppRoutes.providerTaskDetail
                                  .replaceAll(':taskId', filtered[i].id)),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _chip(String n, String label, IconData icon) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(icon, color: Colors.white, size: 16),
      const SizedBox(width: 7),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(n, style: const TextStyle(fontFamily: 'Poppins', fontSize: 17,
            fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
            color: Colors.white.withOpacity(0.85))),
      ])),
    ]),
  ));

  Widget _empty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 70, height: 70,
        decoration: BoxDecoration(
            color: _isDark ? AppTheme.darkCard : AppTheme.providerLight,
            shape: BoxShape.circle),
        child: Icon(Icons.check_circle_outline_rounded, size: 34,
            color: AppTheme.providerPrimary.withOpacity(0.6))),
    const SizedBox(height: 16),
    Text(_query.isNotEmpty ? 'No results' : 'No completed jobs yet',
        style: TextStyle(fontFamily: 'Poppins', fontSize: 15,
            fontWeight: FontWeight.w500, color: _txtP)),
    const SizedBox(height: 6),
    Text(_query.isNotEmpty ? 'Try a different search'
        : 'Completed jobs will appear here',
        style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _txtS)),
  ]));
}

// ══════════════════════════════════════════════════════════════════════
//  COMPLETED CARD
// ══════════════════════════════════════════════════════════════════════
class _CompletedCard extends StatefulWidget {
  final BookingModel booking;
  final int index;
  final bool isDark;
  final Color cardBg, txtP, txtS, txtH, div;
  final AnimationController staggerCtrl;
  final VoidCallback onTap;

  const _CompletedCard({super.key, required this.booking, required this.index,
    required this.isDark, required this.cardBg, required this.txtP,
    required this.txtS, required this.txtH, required this.div,
    required this.staggerCtrl, required this.onTap});

  @override State<_CompletedCard> createState() => _CompletedCardState();
}

class _CompletedCardState extends State<_CompletedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 380));
    widget.staggerCtrl.addListener(_sync);
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    final delay  = widget.index * 0.07;
    final rawVal = ((widget.staggerCtrl.value - delay) / 0.4).clamp(0.0, 1.0);
    _ctrl.value  = rawVal;
  }

  @override
  void dispose() {
    widget.staggerCtrl.removeListener(_sync);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b           = widget.booking;
    final isCancelled = b.isCancelled;
    final borderColor = isCancelled
        ? AppTheme.statusCancelled : AppTheme.statusCompleted;

    Widget card = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isCancelled && !widget.isDark
              ? const Color(0xFFFFF8F8) : widget.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.25 : 0.05),
            blurRadius: 10, offset: const Offset(0, 3),
          )],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: borderColor, width: 4),
                top:  BorderSide(color: widget.div),
                right: BorderSide(color: widget.div),
                bottom: BorderSide(color: widget.div),
              ),
            ),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(widget.isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(11)),
                  child: Icon(
                      isCancelled ? Icons.cancel_outlined
                          : Icons.check_circle_outline_rounded,
                      size: 20, color: borderColor)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.serviceName, style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: widget.txtP),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('#${b.id.length > 6 ? b.id.substring(0, 6).toUpperCase() : b.id}',
                      style: TextStyle(fontFamily: 'Poppins',
                          fontSize: 10, color: widget.txtH)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusBgColor(b.status)
                        .withOpacity(widget.isDark ? 0.5 : 1),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(b.status, style: TextStyle(fontFamily: 'Poppins',
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppTheme.getStatusColor(b.status))),
                ),
              ]),
              const SizedBox(height: 10),
              _row(Icons.person_outline_rounded, b.userName),
              const SizedBox(height: 4),
              _row(Icons.calendar_today_outlined,
                  (b.scheduledDate?.isNotEmpty == true)
                      ? '${b.scheduledDate}  ·  ${b.scheduledTime ?? ''}'
                      : '${b.preferredDate}  ·  ${b.preferredTime}'),
              if (b.assignedAssetName != null) ...[
                const SizedBox(height: 4),
                _row(Icons.inventory_2_outlined, b.assignedAssetName!),
              ],
              if (isCancelled) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.statusCancelled.withOpacity(
                        widget.isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.statusCancelled, size: 14),
                    SizedBox(width: 6),
                    Text('Booking was cancelled',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.statusCancelled)),
                  ]),
                ),
              ],
            ])),
          ),
        ),
      ),
    );

    return FadeTransition(
      opacity: _ctrl,
      child: SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
        child: card),
    );
  }
  Widget _row(IconData icon, String text) => Row(children: [
    Icon(icon, size: 13, color: widget.txtH),
    const SizedBox(width: 5),
    Expanded(child: Text(text, style: TextStyle(fontFamily: 'Poppins',
        fontSize: 12, color: widget.txtS),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
  ]);
}
