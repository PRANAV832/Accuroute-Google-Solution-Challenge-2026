/// Risk level for a shipment
enum RiskLevel { low, medium, high }

/// Shipment model
/// Designed to be easily replaceable with a backend-fetched model later
class Shipment {
  final String id;
  final String source;
  final String destination;
  final String eta;
  final String distance;
  final RiskLevel risk;
  final double lat;
  final double lng;

  // ── Extended fields ──────────────────────────────────────────────
  final String driverName;
  final String driverPhone;
  final String vehicleType;
  final String vehicleNo;
  final String goodsType;
  final String company;
  final String driverPassword; // Demo-only field for driver login
  final String? optimizedETA;

  const Shipment({
    required this.id,
    required this.source,
    required this.destination,
    required this.eta,
    required this.distance,
    required this.risk,
    this.lat = 0.0,
    this.lng = 0.0,
    this.driverName = '',
    this.driverPhone = '',
    this.vehicleType = '',
    this.vehicleNo = '',
    this.goodsType = '',
    this.company = '',
    this.driverPassword = '',
    this.optimizedETA,
  });

  /// Create a Shipment from JSON (ready for backend integration)
  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'] as String,
      source: json['source'] as String,
      destination: json['destination'] as String,
      eta: json['eta'] as String,
      distance: json['distance'] as String,
      risk: _parseRisk(json['risk'] as String),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      driverName: json['driverName'] as String? ?? '',
      driverPhone: json['driverPhone'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      vehicleNo: json['vehicleNo'] as String? ?? '',
      goodsType: json['goodsType'] as String? ?? '',
      company: json['company'] as String? ?? '',
      driverPassword: json['driverPassword'] as String? ?? '',
      optimizedETA: json['optimizedETA'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'destination': destination,
      'eta': eta,
      'distance': distance,
      'risk': risk.name,
      'lat': lat,
      'lng': lng,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleType': vehicleType,
      'vehicleNo': vehicleNo,
      'goodsType': goodsType,
      'company': company,
      'driverPassword': driverPassword,
      'optimizedETA': optimizedETA,
    };
  }

  /// Parse risk string to enum
  static RiskLevel _parseRisk(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }

  /// Copy with modified fields
  Shipment copyWith({
    String? id,
    String? source,
    String? destination,
    String? eta,
    String? distance,
    RiskLevel? risk,
    double? lat,
    double? lng,
    String? driverName,
    String? driverPhone,
    String? vehicleType,
    String? vehicleNo,
    String? goodsType,
    String? company,
    String? driverPassword,
    String? optimizedETA,
  }) {
    return Shipment(
      id: id ?? this.id,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      eta: eta ?? this.eta,
      distance: distance ?? this.distance,
      risk: risk ?? this.risk,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      goodsType: goodsType ?? this.goodsType,
      company: company ?? this.company,
      driverPassword: driverPassword ?? this.driverPassword,
      optimizedETA: optimizedETA ?? this.optimizedETA,
    );
  }
}
