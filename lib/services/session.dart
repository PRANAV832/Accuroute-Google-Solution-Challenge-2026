/// User role enum
enum UserRole { company, driver }

/// Simple session singleton to hold current user state
/// Designed to be easily replaceable with a proper auth state management later
class Session {
  static final Session _instance = Session._internal();
  factory Session() => _instance;
  Session._internal();

  UserRole? role;
  String? driverName;
  String? shipmentId;

  bool get isDriver => role == UserRole.driver;
  bool get isCompany => role == UserRole.company;

  /// Clear session on logout
  void clear() {
    role = null;
    driverName = null;
    shipmentId = null;
  }
}
