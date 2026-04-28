import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shipment.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Collection reference
  CollectionReference get _shipmentsRef => _firestore.collection('shipments');

  /// Stream all shipments
  Stream<List<Shipment>> getShipmentsStream() {
    return _shipmentsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure ID is passed if not in document body
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }
        return Shipment.fromJson(data);
      }).toList();
    });
  }

  /// Stream a single shipment
  Stream<Shipment?> getShipmentStream(String id) {
    return _shipmentsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('id')) {
        data['id'] = doc.id;
      }
      return Shipment.fromJson(data);
    });
  }

  /// Add a shipment
  Future<void> addShipment(Shipment shipment) async {
    // If ID is not empty, use it as the document ID
    if (shipment.id.isNotEmpty) {
      await _shipmentsRef.doc(shipment.id).set(shipment.toJson());
    } else {
      await _shipmentsRef.add(shipment.toJson());
    }
  }

  /// Update shipment risk and ETAs
  Future<void> updateShipmentRisk(String id, RiskLevel risk, String newEta, {String? optimizedEta}) async {
    final Map<String, dynamic> updates = {
      'risk': risk.name,
      'eta': newEta,
    };
    if (optimizedEta != null) {
      updates['optimizedETA'] = optimizedEta;
    }
    await _shipmentsRef.doc(id).update(updates);
  }

  /// Validate driver login
  Future<Shipment?> validateDriverLogin(String driverName, String shipmentId, String driverPhone) async {
    try {
      final doc = await _shipmentsRef.doc(shipmentId).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      final shipment = Shipment.fromJson(data..['id'] = doc.id);
      
      if (shipment.driverName.toLowerCase() == driverName.toLowerCase() && 
          shipment.driverPhone == driverPhone) {
        return shipment;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
