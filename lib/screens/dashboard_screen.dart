import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../services/auth_service.dart';
import '../services/session.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/shipment_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  final _searchController = TextEditingController();
  String _selectedRiskFilter = 'All';

  final List<String> _riskFilters = ['All', 'Low Risk', 'Medium Risk', 'High Risk'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Shipment> _applyFilters(List<Shipment> allShipments) {
    List<Shipment> result = List.from(allShipments);

    // If driver role, filter to only their assigned shipment
    final session = Session();
    if (session.isDriver) {
      result = result
          .where((s) =>
              s.driverName.toLowerCase() ==
                  (session.driverName ?? '').toLowerCase() &&
              s.id.toUpperCase() ==
                  (session.shipmentId ?? '').toUpperCase())
          .toList();
    }

    // Search filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((s) => s.id.toLowerCase().contains(query)).toList();
    }

    // Risk filter
    if (_selectedRiskFilter != 'All') {
      RiskLevel? level;
      switch (_selectedRiskFilter) {
        case 'Low Risk':
          level = RiskLevel.low;
          break;
        case 'Medium Risk':
          level = RiskLevel.medium;
          break;
        case 'High Risk':
          level = RiskLevel.high;
          break;
      }
      if (level != null) {
        result = result.where((s) => s.risk == level).toList();
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.route_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('AcuRoute Dashboard'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await AuthService().logout();
              Session().clear();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(AppConstants.roleSelectRoute);
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),

      // ── FAB: Add Shipment (hidden for drivers) ───────────────────
      floatingActionButton: Session().isDriver
          ? null
          : FloatingActionButton(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: () async {
                await Navigator.of(context).pushNamed(AppConstants.addShipmentRoute);
              },
              child: const Icon(Icons.add),
            ),

      body: StreamBuilder<List<Shipment>>(
        stream: _firestoreService.getShipmentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading shipments', style: TextStyle(color: AppTheme.error)));
          }

          final allShipments = snapshot.data ?? [];
          final filteredShipments = _applyFilters(allShipments);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryHeader(allShipments),
              const SizedBox(height: 16),

              // ── Search + Filter bar (hidden for drivers) ──
              if (!Session().isDriver) ...[
                _buildSearchFilter(),
                const SizedBox(height: 16),
              ],

              const Row(children: [
                Icon(Icons.local_shipping_rounded, size: 18, color: AppTheme.textSecondary),
                SizedBox(width: 8),
                Text('Active Shipments',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ]),
              const SizedBox(height: 12),

              if (filteredShipments.isEmpty)
                _buildEmptyState()
              else
                ...filteredShipments.map((shipment) => ShipmentCard(
                      shipment: shipment,
                      onViewDetails: () => Navigator.of(context)
                          .pushNamed(AppConstants.shipmentDetailRoute, arguments: shipment),
                    )),
            ],
          );
        },
      ),
    );
  }

  // ── Search + Filter ────────────────────────────────────────────
  Widget _buildSearchFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by Shipment ID',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          // Risk filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRiskFilter,
                icon: const Icon(Icons.filter_list_rounded, size: 18, color: AppTheme.textSecondary),
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                items: _riskFilters.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRiskFilter = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'No shipments found',
            style: TextStyle(fontSize: 15, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a different search or filter',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  // ── Summary Header ─────────────────────────────────────────────
  Widget _buildSummaryHeader(List<Shipment> allShipments) {
    final session = Session();
    final source = session.isDriver ? _applyFilters(allShipments) : allShipments;
    final total = source.length;
    final atRisk = source.where((s) => s.risk == RiskLevel.high || s.risk == RiskLevel.medium).length;
    return Row(children: [
      Expanded(child: _tile('Total', '$total', Icons.inventory_2_rounded, AppTheme.primary)),
      const SizedBox(width: 12),
      Expanded(child: _tile('At Risk', '$atRisk', Icons.warning_amber_rounded, AppTheme.riskMedium)),
      const SizedBox(width: 12),
      Expanded(child: _tile('On Track', '${total - atRisk}', Icons.check_circle_outline, AppTheme.riskLow)),
    ]);
  }

  Widget _tile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
