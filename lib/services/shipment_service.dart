import '../models/shipment.dart';

/// Service layer for shipment data
/// Currently uses dummy data — swap in Firebase / REST API calls later
class ShipmentService {
  /// Singleton instance
  static final ShipmentService _instance = ShipmentService._internal();
  factory ShipmentService() => _instance;
  ShipmentService._internal() {
    // Initialize with dummy data on first creation
    if (_shipments.isEmpty) {
      _shipments = _dummyData.map((json) => Shipment.fromJson(json)).toList();
    }
  }

  // ─── Mutable shipment list ─────────────────────────────────────
  List<Shipment> _shipments = [];

  // ─── Dummy JSON Data ──────────────────────────────────────────
  static const List<Map<String, dynamic>> _dummyData = [
    {
      'id': 'SHP-001',
      'source': 'Mumbai',
      'destination': 'Pune',
      'eta': '4h 20m',
      'distance': '149 km',
      'risk': 'Low',
      'lat': 18.5204,
      'lng': 73.8567,
      'driverName': 'Rajesh Kumar',
      'driverPhone': '+91 98765 43210',
      'vehicleType': 'Truck',
      'vehicleNo': 'MH-12-AB-1234',
      'goodsType': 'Electronics',
      'company': 'TechMove Logistics',
    },
    {
      'id': 'SHP-002',
      'source': 'Delhi',
      'destination': 'Jaipur',
      'eta': '5h 45m',
      'distance': '281 km',
      'risk': 'Medium',
      'lat': 26.9124,
      'lng': 75.7873,
      'driverName': 'Amit Sharma',
      'driverPhone': '+91 91234 56789',
      'vehicleType': 'Container',
      'vehicleNo': 'DL-01-CD-5678',
      'goodsType': 'Pharmaceuticals',
      'company': 'MediShip Express',
    },
    {
      'id': 'SHP-003',
      'source': 'Bangalore',
      'destination': 'Chennai',
      'eta': '6h 10m',
      'distance': '346 km',
      'risk': 'Low',
      'lat': 13.0827,
      'lng': 80.2707,
      'driverName': 'Suresh Reddy',
      'driverPhone': '+91 87654 32109',
      'vehicleType': 'Mini Truck',
      'vehicleNo': 'KA-05-EF-9012',
      'goodsType': 'Textiles',
      'company': 'FabRoute India',
    },
  ];

  /// Fetch all shipments (simulates async API call)
  Future<List<Shipment>> getShipments() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_shipments);
  }

  /// Fetch a single shipment by ID
  Future<Shipment?> getShipmentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final matches = _shipments.where((s) => s.id == id);
    if (matches.isEmpty) return null;
    return matches.first;
  }

  /// Add a shipment to the local list
  /// Returns true on success
  Future<bool> addShipment(Shipment shipment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _shipments.add(shipment);
    return true;
  }
}
