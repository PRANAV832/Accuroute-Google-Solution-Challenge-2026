import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../utils/app_theme.dart';
import 'risk_badge.dart';

/// Shipment summary card shown on the Dashboard
/// Structured display: ID → Route → Driver → ETA/Distance → Risk → Details
class ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback onViewDetails;

  const ShipmentCard({
    super.key,
    required this.shipment,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onViewDetails,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Shipment ID (bold, top priority) ─────────
                Text(
                  shipment.id,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),

                // ── Route ────────────────────────────────────
                Row(
                  children: [
                    _routeIcon(),
                    const SizedBox(width: 10),
                    Text(
                      '${shipment.source} → ${shipment.destination}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Driver Name ──────────────────────────────
                if (shipment.driverName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 16, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          shipment.driverName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── ETA + Distance row ───────────────────────
                Row(
                  children: [
                    _infoChip(Icons.access_time_rounded, 'ETA: ${shipment.eta}'),
                    const SizedBox(width: 12),
                    _infoChip(Icons.straighten_rounded, shipment.distance),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Risk Badge + Details button ──────────────
                Row(
                  children: [
                    RiskBadge(risk: shipment.risk),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The circular route icon
  Widget _routeIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.local_shipping_rounded,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  /// Small chip showing an icon + text
  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
