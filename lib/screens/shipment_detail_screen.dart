import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/shipment.dart';
import '../services/firestore_service.dart';
import '../services/maps_service.dart';
import '../services/ai_service.dart';
import '../services/simulation_service.dart';
import '../utils/app_theme.dart';
import '../widgets/info_row.dart';
import '../widgets/risk_badge.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final Shipment shipment;
  const ShipmentDetailScreen({super.key, required this.shipment});

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  bool _trafficOn = false;
  bool _rainOn = false;
  bool _roadblockOn = false;

  final FirestoreService _firestoreService = FirestoreService();
  final MapsService _mapsService = MapsService();
  final AiService _aiService = AiService();
  final SimulationService _simulationService = SimulationService();

  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  String _aiInsight = "Fetching AI Insights...";
  bool _isLoadingInsight = true;

  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatting = false;

  RiskLevel _lastProcessedRisk = RiskLevel.low;

  // ── New state for enhanced logic ───────────────────────────────
  bool _isMapLoading = true;
  bool _mapLoadFailed = false;
  RouteData? _cachedRouteData; // Cache the primary route for ETA base

  @override
  void initState() {
    super.initState();
    _lastProcessedRisk = widget.shipment.risk;
    _loadMapRoute(widget.shipment);
    _fetchInsight(widget.shipment);
  }

  Future<void> _loadMapRoute(Shipment shipment, {bool isAlternate = false}) async {
    if (!isAlternate) {
      setState(() {
        _isMapLoading = true;
        _mapLoadFailed = false;
      });
    }

    RouteData? routeData;
    if (isAlternate) {
      routeData = await _mapsService.getAlternateRoute(shipment.source, shipment.destination);
    } else {
      routeData = await _mapsService.getRoute(shipment.source, shipment.destination);
    }

    if (!mounted) return;

    if (routeData == null) {
      if (!isAlternate) {
        setState(() {
          _isMapLoading = false;
          _mapLoadFailed = true;
        });
      }
      return;
    }

    setState(() {
      if (!isAlternate) {
        // Cache the primary route data for ETA calculations
        _cachedRouteData = routeData;
        _isMapLoading = false;
        _mapLoadFailed = false;

        _markers.clear();
        _markers.add(Marker(markerId: const MarkerId('source'), position: routeData!.startLocation, infoWindow: InfoWindow(title: shipment.source)));
        _markers.add(Marker(markerId: const MarkerId('destination'), position: routeData.endLocation, infoWindow: InfoWindow(title: shipment.destination)));

        // Remove old primary polyline, keep alternate if present
        _polylines.removeWhere((p) => p.polylineId.value == 'route');
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: routeData.polylinePoints,
            color: AppTheme.primary,
            width: 4,
          ),
        );
      } else {
        // Add alternate route as a second polyline with different style
        _polylines.removeWhere((p) => p.polylineId.value == 'alternate_route');
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('alternate_route'),
            points: routeData!.polylinePoints,
            color: AppTheme.riskLow,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    });

    if (_mapController != null && !isAlternate && mounted) {
      // Build map bounds
      double minLat = routeData.startLocation.latitude;
      double maxLat = routeData.startLocation.latitude;
      double minLng = routeData.startLocation.longitude;
      double maxLng = routeData.startLocation.longitude;

      for (var point in routeData.polylinePoints) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      try {
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
          50,
        ));
      } catch (_) {
        // Controller may have been disposed if user navigated away
      }
    }
  }

  Future<void> _fetchInsight(Shipment shipment, {int? delayMinutes, List<String>? activeConditions}) async {
    setState(() => _isLoadingInsight = true);

    // Use traffic-aware ETA from cached route if available
    final actualEta = _cachedRouteData?.durationInTrafficText;

    final insight = await _aiService.getAIInsight(
      shipment.source,
      shipment.destination,
      shipment.risk,
      delayMinutes: delayMinutes,
      activeConditions: activeConditions,
      actualEta: actualEta,
    );

    if (mounted) {
      setState(() {
        _aiInsight = insight;
        _isLoadingInsight = false;
        _lastProcessedRisk = shipment.risk;
      });
    }
  }

  void _updateDisruption(Shipment currentShipment) async {
    // ── Use the cached route's traffic-aware ETA as the base ────
    final baseEtaText = _cachedRouteData?.durationInTrafficText ?? currentShipment.eta;
    final baseEtaSeconds = _cachedRouteData?.durationInTrafficSeconds;

    // ── Run the simulation engine ───────────────────────────────
    final result = _simulationService.run(
      baseEtaText: baseEtaText,
      baseEtaSeconds: baseEtaSeconds,
      trafficOn: _trafficOn,
      rainOn: _rainOn,
      roadblockOn: _roadblockOn,
    );

    // ── Update Firestore with simulation results ────────────────
    await _firestoreService.updateShipmentRisk(
      currentShipment.id,
      result.riskLevel,
      result.adjustedEta,
      optimizedEta: result.riskLevel != RiskLevel.low ? result.optimizedEta : null,
    );

    // ── Handle alternate route for roadblock ────────────────────
    if (result.shouldFetchAlternateRoute) {
      // Draw the primary route in red and fetch an alternate green route
      setState(() {
        _polylines.removeWhere((p) => p.polylineId.value == 'route');
        if (_cachedRouteData != null) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: _cachedRouteData!.polylinePoints,
              color: AppTheme.riskHigh,
              width: 4,
            ),
          );
        }
      });
      _loadMapRoute(currentShipment, isAlternate: true);
    } else {
      // Remove alternate route and restore primary color
      setState(() {
        _polylines.removeWhere((p) => p.polylineId.value == 'alternate_route');
        _polylines.removeWhere((p) => p.polylineId.value == 'route');
        if (_cachedRouteData != null) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: _cachedRouteData!.polylinePoints,
              color: result.riskLevel == RiskLevel.low ? AppTheme.primary : AppTheme.riskHigh,
              width: 4,
            ),
          );
        }
      });
    }

    // ── Build list of active conditions for AI enrichment ────────
    final List<String> conditions = [];
    if (_trafficOn) conditions.add('heavy traffic');
    if (_rainOn) conditions.add('rain/bad weather');
    if (_roadblockOn) conditions.add('roadblock');

    // ── Refresh AI insight with dynamic context ─────────────────
    if (result.riskLevel != RiskLevel.low) {
      _fetchInsight(
        currentShipment,
        delayMinutes: result.totalDelayMinutes,
        activeConditions: conditions,
      );
    }
  }

  void _sendMessage(Shipment shipment) async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({"role": "user", "text": text});
      _isChatting = true;
    });
    _chatController.clear();

    final response = await _aiService.chatWithBot(text, shipment, shipment.risk);
    
    if (mounted) {
      setState(() {
        _chatMessages.add({"role": "bot", "text": response});
        _isChatting = false;
      });
    }
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
      body: StreamBuilder<Shipment?>(
        stream: _firestoreService.getShipmentStream(widget.shipment.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading shipment: ${snapshot.error}'));
          }

          final shipment = snapshot.data ?? widget.shipment;

          // Check if risk level changed externally
          if (shipment.risk != _lastProcessedRisk) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadMapRoute(shipment);
                _fetchInsight(shipment);
             });
          }

          bool isDisrupted = shipment.risk == RiskLevel.high;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isDisrupted) _warningBanner(),

              _buildMap(),
              const SizedBox(height: 16),

              _shipmentInfoCard(shipment),
              const SizedBox(height: 16),

              _simulationControls(shipment),
              const SizedBox(height: 16),

              if (isDisrupted && shipment.optimizedETA != null) ...[
                _routeSuggestion(shipment),
                const SizedBox(height: 16),
              ],

              _aiInsightCard(),
              const SizedBox(height: 24),

              _buildChatSection(shipment),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

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
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.riskHigh, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '⚠️ Delay Detected — Disruption affecting this route',
              style: TextStyle(color: AppTheme.riskHigh, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(target: LatLng(20.5937, 78.9629), zoom: 4.5), // India default
              polylines: _polylines,
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
            ),
            // ── Loading overlay ─────────────────────────────
            if (_isMapLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
                      SizedBox(height: 10),
                      Text('Loading route...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            // ── Error overlay ───────────────────────────────
            if (_mapLoadFailed && !_isMapLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, color: AppTheme.textMuted.withValues(alpha: 0.5), size: 40),
                      const SizedBox(height: 10),
                      const Text('Route unavailable', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      const Text('Could not fetch route from Google Maps', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => _loadMapRoute(widget.shipment),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _shipmentInfoCard(Shipment shipment) {
    return _card(
      title: 'Shipment Info',
      icon: Icons.info_outline_rounded,
      child: Column(children: [
        InfoRow(icon: Icons.tag_rounded, label: 'Shipment ID', value: shipment.id),
        InfoRow(icon: Icons.location_on_outlined, label: 'Source', value: shipment.source),
        InfoRow(icon: Icons.flag_outlined, label: 'Destination', value: shipment.destination),
        InfoRow(icon: Icons.straighten_rounded, label: 'Distance', value: shipment.distance),
        InfoRow(icon: Icons.access_time_rounded, label: 'Current ETA', value: shipment.eta,
            iconColor: shipment.risk == RiskLevel.high ? AppTheme.riskHigh : null),
        if (shipment.vehicleType.isNotEmpty)
          InfoRow(icon: Icons.directions_car_rounded, label: 'Vehicle Type', value: shipment.vehicleType),
        if (shipment.vehicleNo.isNotEmpty)
          InfoRow(icon: Icons.confirmation_number_outlined, label: 'Vehicle No', value: shipment.vehicleNo),
        if (shipment.driverName.isNotEmpty)
          InfoRow(icon: Icons.person_outline_rounded, label: 'Driver Name', value: shipment.driverName),
        if (shipment.driverPhone.isNotEmpty)
          InfoRow(icon: Icons.phone_outlined, label: 'Driver Phone', value: shipment.driverPhone),
        if (shipment.goodsType.isNotEmpty)
          InfoRow(icon: Icons.inventory_2_outlined, label: 'Goods Type', value: shipment.goodsType),
        if (shipment.company.isNotEmpty)
          InfoRow(icon: Icons.business_outlined, label: 'Company', value: shipment.company),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            const Text('Risk Level', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            RiskBadge(risk: shipment.risk),
          ]),
        ),
      ]),
    );
  }

  Widget _simulationControls(Shipment currentShipment) {
    return _card(
      title: 'Simulation Controls',
      icon: Icons.tune_rounded,
      child: Column(children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _trafficOn = true;
                _rainOn = true;
                _roadblockOn = false;
              });
              _updateDisruption(currentShipment);
            },
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
          _updateDisruption(currentShipment);
        }),
        _toggleRow('Rain', Icons.water_drop_outlined, _rainOn, (v) {
          setState(() => _rainOn = v);
          _updateDisruption(currentShipment);
        }),
        _toggleRow('Roadblock', Icons.block_rounded, _roadblockOn, (v) {
          setState(() => _roadblockOn = v);
          _updateDisruption(currentShipment);
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

  Widget _routeSuggestion(Shipment shipment) {
    return _card(
      title: 'Smart Route Suggestion',
      icon: Icons.alt_route_rounded,
      headerColor: AppTheme.riskLow,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _etaBox('Current ETA', shipment.eta, AppTheme.riskHigh)),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_rounded, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(child: _etaBox('New ETA', shipment.optimizedETA ?? '', AppTheme.riskLow)),
        ]),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.riskLow.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.riskLow, size: 18),
            SizedBox(width: 8),
            Expanded(
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

  Widget _aiInsightCard() {
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
            const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: _isLoadingInsight 
                ? const SizedBox(
                    height: 20, width: 20, 
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
                  )
                : Text(_aiInsight,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w400)),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        const Text(
          'Powered by Gemini AI',
          style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
        ),
      ]),
    );
  }

  Widget _buildChatSection(Shipment shipment) {
    return _card(
      title: 'AI Assistant',
      icon: Icons.chat_bubble_outline_rounded,
      headerColor: AppTheme.primary,
      child: Column(
        children: [
          if (_chatMessages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Ask me about nearby hotels, petrol pumps, or delay reasons!',
                style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ..._chatMessages.map((msg) {
            bool isUser = msg["role"] == "user";
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12).copyWith(
                    bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(12),
                    bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(12),
                  ),
                ),
                child: Text(
                  msg["text"]!,
                  style: TextStyle(color: isUser ? AppTheme.primary : AppTheme.textPrimary, fontSize: 13),
                ),
              ),
            );
          }),
          if (_isChatting)
             const Align(
               alignment: Alignment.centerLeft,
               child: Padding(
                 padding: EdgeInsets.all(8.0),
                 child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
               ),
             ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Type your question...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                onPressed: () => _sendMessage(shipment),
              )
            ],
          )
        ],
      ),
    );
  }

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
        Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ]),
    );
  }
}
