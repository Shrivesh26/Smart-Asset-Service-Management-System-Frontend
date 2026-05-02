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

  bool get _isDark => false; // resolved via BuildContext below

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final txtP = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final txtS =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final pillBg = isDark
        ? accent.withOpacity(0.15)
        : accent.withOpacity(0.08);
    final catBg = isDark ? AppTheme.darkInput : AppTheme.surface;

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
            color: isDark
                ? accent.withOpacity(0.2)
                : accent.withOpacity(0.14),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon + Category chip ───────────────────────────
              Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      accent.withOpacity(isDark ? 0.25 : 0.18),
                      accent.withOpacity(isDark ? 0.1 : 0.06),
                    ]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: catBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: accent.withOpacity(0.2)),
                  ),
                  child: Text(
                    service.category.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // ── Service name ───────────────────────────────────
              Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: txtP,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),

              // ── Business name ──────────────────────────────────
              Text(
                service.businessName.isEmpty
                    ? 'Independent partner'
                    : service.businessName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: txtS,
                ),
              ),

              // ── Rating ─────────────────────────────────────────
              if (service.averageProviderRating > 0) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.star_rounded, size: 14, color: accent),
                  const SizedBox(width: 4),
                  Text(
                    '${service.averageProviderRating.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'provider rating',
                    style:
                        TextStyle(fontSize: 11, color: txtS),
                  ),
                  if (service.ratedProviderCount > 0) ...[
                    const SizedBox(width: 3),
                    Text(
                      '(${service.ratedProviderCount})',
                      style: TextStyle(
                          fontSize: 10,
                          color: txtS.withOpacity(0.7)),
                    ),
                  ],
                ]),
              ],

              // ── Description ────────────────────────────────────
              const SizedBox(height: 8),
              Text(
                service.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: txtS,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // ── Info pills ─────────────────────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _infoPill(
                    icon: Icons.workspace_premium_rounded,
                    label: providerLabel,
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
              const SizedBox(height: 12),

              // ── Price + duration row ───────────────────────────
              Row(children: [
                Expanded(
                  child: Text(
                    service.priceDisplay,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                Icon(Icons.schedule_rounded, size: 13, color: txtS),
                const SizedBox(width: 4),
                Text(
                  service.durationDisplay,
                  style: TextStyle(fontSize: 11, color: txtS),
                ),
              ]),
              const SizedBox(height: 10),

              // ── Provider assignment row ────────────────────────
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: txtS, height: 1.4),
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              // ── Book button ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.78)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(isDark ? 0.3 : 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Book Service',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
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
  }

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