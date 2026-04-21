import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../utils/app_theme.dart';
import '../widgets/info_row.dart';
import '../widgets/risk_badge.dart';

/// Core shipment detail screen with map placeholder,
/// simulation controls, smart route suggestions, and AI insights.
class ShipmentDetailScreen extends StatefulWidget {
  final Shipment shipment;
  const ShipmentDetailScreen({super.key, required this.shipment});

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  // Disruption simulation state
  bool _trafficOn = false;
  bool _rainOn = false;
  bool _roadblockOn = false;
  bool _isDisrupted = false;

  late String _currentEta;
  late RiskLevel _currentRisk;

  // Route suggestion state
  String _oldEta = '';
  String _newEta = '';
  bool _showRouteSuggestion = false;

  @override
  void initState() {
    super.initState();
    _currentEta = widget.shipment.eta;
    _currentRisk = widget.shipment.risk;
  }

  void _updateDisruption() {
    final disrupted = _trafficOn || _rainOn || _roadblockOn;
    setState(() {
      _isDisrupted = disrupted;
      if (disrupted) {
        _currentRisk = RiskLevel.high;
        _oldEta = widget.shipment.eta;
        // Add delay based on active disruptions
        int extraMin = 0;
        if (_trafficOn) extraMin += 45;
        if (_rainOn) extraMin += 30;
        if (_roadblockOn) extraMin += 60;
        _currentEta = _addMinutes(widget.shipment.eta, extraMin);
        _newEta = _addMinutes(widget.shipment.eta, (extraMin * 0.5).round());
        _showRouteSuggestion = true;
      } else {
        _currentRisk = widget.shipment.risk;
        _currentEta = widget.shipment.eta;
        _showRouteSuggestion = false;
      }
    });
  }

  String _addMinutes(String eta, int minutes) {
    // Parse "4h 20m" format
    final hMatch = RegExp(r'(\d+)h').firstMatch(eta);
    final mMatch = RegExp(r'(\d+)m').firstMatch(eta);
    int h = hMatch != null ? int.parse(hMatch.group(1)!) : 0;
    int m = mMatch != null ? int.parse(mMatch.group(1)!) : 0;
    m += minutes;
    h += m ~/ 60;
    m = m % 60;
    return '${h}h ${m}m';
  }

  void _simulateDisruption() {
    setState(() {
      _trafficOn = true;
      _rainOn = true;
      _roadblockOn = false;
    });
    _updateDisruption();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('${widget.shipment.source} → ${widget.shipment.destination}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Warning banner
          if (_isDisrupted) _warningBanner(),

          // Map placeholder
          _mapPlaceholder(),
          const SizedBox(height: 16),

          // Shipment info card
          _shipmentInfoCard(),
          const SizedBox(height: 16),

          // Simulation controls
          _simulationControls(),
          const SizedBox(height: 16),

          // Smart route suggestion
          if (_showRouteSuggestion) ...[
            _routeSuggestion(),
            const SizedBox(height: 16),
          ],

          // AI Insight
          _aiInsightCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Warning Banner ──────────────────────────────────────────────
  Widget _warningBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.riskHigh.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.riskHigh.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.riskHigh, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '⚠️ Delay Detected — Disruption affecting this route',
              style: TextStyle(color: AppTheme.riskHigh, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map Placeholder ─────────────────────────────────────────────
  Widget _mapPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Stack(
        children: [
          // Background grid to simulate map
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _MapGridPainter(),
            ),
          ),
          // Route line
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              height: 3,
              decoration: BoxDecoration(
                color: _isDisrupted ? AppTheme.riskHigh : AppTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Source dot
          Positioned(
            left: 32, top: 90,
            child: _mapDot(widget.shipment.source, AppTheme.primary),
          ),
          // Destination dot
          Positioned(
            right: 32, top: 90,
            child: _mapDot(widget.shipment.destination, AppTheme.riskLow),
          ),
          // Overlay label
          Positioned(
            bottom: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 14, color: AppTheme.textMuted),
                  SizedBox(width: 4),
                  Text('Map integration coming soon', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapDot(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }

  // ── Shipment Info Card ──────────────────────────────────────────
  Widget _shipmentInfoCard() {
    return _card(
      title: 'Shipment Info',
      icon: Icons.info_outline_rounded,
      child: Column(children: [
        InfoRow(icon: Icons.tag_rounded, label: 'Shipment ID', value: widget.shipment.id),
        InfoRow(icon: Icons.location_on_outlined, label: 'Source', value: widget.shipment.source),
        InfoRow(icon: Icons.flag_outlined, label: 'Destination', value: widget.shipment.destination),
        InfoRow(icon: Icons.straighten_rounded, label: 'Distance', value: widget.shipment.distance),
        InfoRow(icon: Icons.access_time_rounded, label: 'Current ETA', value: _currentEta,
            iconColor: _isDisrupted ? AppTheme.riskHigh : null),
        if (widget.shipment.vehicleType.isNotEmpty)
          InfoRow(icon: Icons.directions_car_rounded, label: 'Vehicle Type', value: widget.shipment.vehicleType),
        if (widget.shipment.vehicleNo.isNotEmpty)
          InfoRow(icon: Icons.confirmation_number_outlined, label: 'Vehicle No', value: widget.shipment.vehicleNo),
        if (widget.shipment.driverName.isNotEmpty)
          InfoRow(icon: Icons.person_outline_rounded, label: 'Driver Name', value: widget.shipment.driverName),
        if (widget.shipment.driverPhone.isNotEmpty)
          InfoRow(icon: Icons.phone_outlined, label: 'Driver Phone', value: widget.shipment.driverPhone),
        if (widget.shipment.goodsType.isNotEmpty)
          InfoRow(icon: Icons.inventory_2_outlined, label: 'Goods Type', value: widget.shipment.goodsType),
        if (widget.shipment.company.isNotEmpty)
          InfoRow(icon: Icons.business_outlined, label: 'Company', value: widget.shipment.company),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            const Text('Risk Level', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            RiskBadge(risk: _currentRisk),
          ]),
        ),
      ]),
    );
  }

  // ── Simulation Controls ─────────────────────────────────────────
  Widget _simulationControls() {
    return _card(
      title: 'Simulation Controls',
      icon: Icons.tune_rounded,
      child: Column(children: [
        // Simulate Disruption button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _simulateDisruption,
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Simulate Disruption'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.riskMedium,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _toggleRow('Traffic', Icons.traffic_rounded, _trafficOn, (v) {
          setState(() => _trafficOn = v);
          _updateDisruption();
        }),
        _toggleRow('Rain', Icons.water_drop_outlined, _rainOn, (v) {
          setState(() => _rainOn = v);
          _updateDisruption();
        }),
        _toggleRow('Roadblock', Icons.block_rounded, _roadblockOn, (v) {
          setState(() => _roadblockOn = v);
          _updateDisruption();
        }),
      ]),
    );
  }

  Widget _toggleRow(String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }

  // ── Smart Route Suggestion ──────────────────────────────────────
  Widget _routeSuggestion() {
    return _card(
      title: 'Smart Route Suggestion',
      icon: Icons.alt_route_rounded,
      headerColor: AppTheme.riskLow,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _etaBox('Old ETA', _oldEta, AppTheme.riskHigh)),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_rounded, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(child: _etaBox('New ETA', _newEta, AppTheme.riskLow)),
        ]),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.riskLow.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.riskLow, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Better route available — switch to save time',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _etaBox(String label, String eta, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(eta, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // ── AI Insight Card ─────────────────────────────────────────────
  Widget _aiInsightCard() {
    String insight = _isDisrupted
        ? 'Heavy traffic and rain detected on the ${widget.shipment.source}–${widget.shipment.destination} corridor. '
          'Alternate route via expressway reduces delay by ~30 minutes. '
          'Recommend rerouting to maintain delivery SLA.'
        : 'All conditions nominal on this route. No disruptions detected. '
          'Current ETA is within expected range. Continue on planned route.';

    return _card(
      title: 'AI Insight',
      icon: Icons.auto_awesome_rounded,
      headerColor: AppTheme.accent,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lightbulb_outline_rounded, color: AppTheme.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(insight,
                style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w400)),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        const Text(
          'Powered by AcuRoute AI Engine',
          style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
        ),
      ]),
    );
  }

  // ── Generic card wrapper ────────────────────────────────────────
  Widget _card({required String title, required IconData icon, required Widget child, Color? headerColor}) {
    final color = headerColor ?? AppTheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ]),
        ),
        const Divider(height: 1),
        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ]),
    );
  }
}

/// Paints a subtle grid to simulate a map background
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.divider.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Vertical lines
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
