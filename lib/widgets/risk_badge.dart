import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../utils/app_theme.dart';

/// Colored badge indicating the risk level of a shipment
class RiskBadge extends StatelessWidget {
  final RiskLevel risk;

  const RiskBadge({super.key, required this.risk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 14),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String get _label {
    switch (risk) {
      case RiskLevel.low:
        return 'LOW RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.high:
        return 'HIGH RISK';
    }
  }

  Color get _color {
    switch (risk) {
      case RiskLevel.low:
        return AppTheme.riskLow;
      case RiskLevel.medium:
        return AppTheme.riskMedium;
      case RiskLevel.high:
        return AppTheme.riskHigh;
    }
  }

  Color get _backgroundColor {
    switch (risk) {
      case RiskLevel.low:
        return AppTheme.riskLow.withValues(alpha: 0.1);
      case RiskLevel.medium:
        return AppTheme.riskMedium.withValues(alpha: 0.1);
      case RiskLevel.high:
        return AppTheme.riskHigh.withValues(alpha: 0.1);
    }
  }

  IconData get _icon {
    switch (risk) {
      case RiskLevel.low:
        return Icons.check_circle_outline;
      case RiskLevel.medium:
        return Icons.warning_amber_rounded;
      case RiskLevel.high:
        return Icons.error_outline;
    }
  }
}
