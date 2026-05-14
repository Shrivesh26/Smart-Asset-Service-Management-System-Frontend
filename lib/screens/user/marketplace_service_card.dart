import 'package:flutter/material.dart';

import '../../models/service_model.dart';
import '../../utils/app_theme.dart';

class MarketplaceServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;
  final IconData icon;
  final Color accent;

  const MarketplaceServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder so the card adapts whether it lives in a 1-, 2-, or
    // 3-column grid without needing MediaQuery on the parent.
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Breakpoints based on the card's own rendered width
        final isCompact = availableWidth < 200; // narrow grid column
        final isMedium = availableWidth < 300;  // medium column / phone full-width
        // wide = >= 300  (tablet full-width or 2-col tablet grid)

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? AppTheme.darkCard : Colors.white;
        final txtP = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
        final txtS = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
        final pillBg = isDark ? accent.withOpacity(0.15) : accent.withOpacity(0.08);
        final catBg = isDark ? AppTheme.darkInput : AppTheme.surface;

        // ── Responsive sizing tokens ────────────────────────────────────
        final cardPadding = isCompact ? 12.0 : (isMedium ? 14.0 : 16.0);
        final iconBoxSize = isCompact ? 40.0 : (isMedium ? 46.0 : 52.0);
        final iconSize   = isCompact ? 20.0 : (isMedium ? 23.0 : 26.0);
        final iconRadius = isCompact ? 12.0 : (isMedium ? 14.0 : 16.0);
        final nameSize   = isCompact ? 13.0 : (isMedium ? 14.0 : 15.0);
        final bizSize    = isCompact ? 11.0 : 12.0;
        final descSize   = isCompact ? 11.0 : 12.0;
        final priceSize  = isCompact ? 15.0 : (isMedium ? 16.0 : 18.0);
        final btnRadius  = isCompact ? 12.0 : (isMedium ? 14.0 : 16.0);
        final btnVPad    = isCompact ? 10.0 : (isMedium ? 11.0 : 13.0);
        final catFontSize = isCompact ? 9.0 : 10.0;
        final catHPad    = isCompact ? 7.0 : 10.0;
        final catVPad    = isCompact ? 4.0 : 5.0;
        final descMaxLines = isCompact ? 1 : 2;
        final nameMaxLines = isCompact ? 1 : 2;

        final providerLabel = service.providerNames.isEmpty
            ? 'Verified service team'
            : service.providerNames.length == 1
                ? service.providerNames.first
                : '${service.providerNames.first} +${service.providerNames.length - 1} more';

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? accent.withOpacity(0.2) : accent.withOpacity(0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(isDark ? 0.12 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Icon + Category chip ─────────────────────────────
                  Row(children: [
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          accent.withOpacity(isDark ? 0.25 : 0.18),
                          accent.withOpacity(isDark ? 0.1 : 0.06),
                        ]),
                        borderRadius: BorderRadius.circular(iconRadius),
                      ),
                      child: Icon(icon, color: accent, size: iconSize),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: catHPad, vertical: catVPad),
                      decoration: BoxDecoration(
                        color: catBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: accent.withOpacity(0.2)),
                      ),
                      child: Text(
                        service.category.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: catFontSize,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ]),
                  SizedBox(height: isCompact ? 8 : 12),

                  // ── Service name ─────────────────────────────────────
                  Text(
                    service.name,
                    maxLines: nameMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: nameSize,
                      fontWeight: FontWeight.w700,
                      color: txtP,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: isCompact ? 2 : 4),

                  // ── Business name ────────────────────────────────────
                  Text(
                    service.businessName.isEmpty
                        ? 'Independent partner'
                        : service.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: bizSize,
                      fontWeight: FontWeight.w600,
                      color: txtS,
                    ),
                  ),

                  // ── Rating ───────────────────────────────────────────
                  if (service.averageProviderRating > 0) ...[
                    SizedBox(height: isCompact ? 5 : 8),
                    Row(children: [
                      Icon(Icons.star_rounded,
                          size: isCompact ? 12 : 14, color: accent),
                      const SizedBox(width: 3),
                      Text(
                        service.averageProviderRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: isCompact ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 4),
                        Text('provider rating',
                            style: TextStyle(fontSize: 11, color: txtS)),
                        if (service.ratedProviderCount > 0) ...[
                          const SizedBox(width: 3),
                          Text(
                            '(${service.ratedProviderCount})',
                            style: TextStyle(
                                fontSize: 10,
                                color: txtS.withOpacity(0.7)),
                          ),
                        ],
                      ],
                    ]),
                  ],

                  // ── Description ──────────────────────────────────────
                  SizedBox(height: isCompact ? 5 : 8),
                  Text(
                    service.description,
                    maxLines: descMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: descSize,
                      color: txtS,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: isCompact ? 8 : 12),

                  // ── Info pills (hidden on very compact cards) ─────────
                  if (!isCompact)
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _infoPill(
                          icon: Icons.workspace_premium_rounded,
                          label: isMedium
                              ? _truncate(providerLabel, 14)
                              : providerLabel,
                          accent: accent,
                          pillBg: pillBg,
                        ),
                        _infoPill(
                          icon: Icons.event_available_rounded,
                          label: service.maxAdvanceDays > 0
                              ? 'Up to ${service.maxAdvanceDays}d ahead'
                              : 'Same-day',
                          accent: accent,
                          pillBg: pillBg,
                        ),
                        _infoPill(
                          icon: service.allowCancellationBeforeAssign
                              ? Icons.rule_rounded
                              : Icons.assignment_late_outlined,
                          label: service.allowCancellationBeforeAssign
                              ? 'Cancellable'
                              : 'Non-refundable',
                          accent: accent,
                          pillBg: pillBg,
                        ),
                      ],
                    ),

                  const Spacer(),
                  SizedBox(height: isCompact ? 8 : 12),

                  // ── Price + duration row ─────────────────────────────
                  Row(children: [
                    Expanded(
                      child: Text(
                        service.priceDisplay,
                        style: TextStyle(
                          fontSize: priceSize,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                    Icon(Icons.schedule_rounded,
                        size: isCompact ? 11 : 13, color: txtS),
                    const SizedBox(width: 3),
                    Text(
                      service.durationDisplay,
                      style: TextStyle(
                          fontSize: isCompact ? 10 : 11, color: txtS),
                    ),
                  ]),

                  // ── Provider assignment row (hidden on compact) ───────
                  if (!isCompact) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: accent.withOpacity(0.12),
                        child: Icon(Icons.person_outline_rounded,
                            size: 15, color: accent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service.providerNames.isNotEmpty
                              ? 'by ${service.providerNames.join(', ')}'
                              : 'Assigned after approval',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: txtS, height: 1.4),
                        ),
                      ),
                    ]),
                  ],
                  SizedBox(height: isCompact ? 8 : 14),

                  // ── Book button ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: btnVPad),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.78)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(btnRadius),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(isDark ? 0.3 : 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded,
                            color: Colors.white,
                            size: isCompact ? 13 : 16),
                        SizedBox(width: isCompact ? 4 : 6),
                        Text(
                          isCompact ? 'Book' : 'Book Service',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _truncate(String text, int maxChars) =>
      text.length > maxChars ? '${text.substring(0, maxChars)}…' : text;

  Widget _infoPill({
    required IconData icon,
    required String label,
    required Color accent,
    required Color pillBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: accent),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: accent,
          ),
        ),
      ]),
    );
  }
}