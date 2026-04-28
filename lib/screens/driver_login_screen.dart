import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../services/session.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

/// Driver login screen — validates against dummy shipment data
/// On success, navigates directly to ShipmentDetailScreen (skips dashboard)
class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen>
    with SingleTickerProviderStateMixin {
  final _driverNameController = TextEditingController();
  final _shipmentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _shipmentIdController.dispose();
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final driverName = _driverNameController.text.trim();
    final shipmentId = _shipmentIdController.text.trim().toUpperCase();
    final phone = _phoneController.text.trim();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Validate against Firestore
    final Shipment? shipment =
        await _firestoreService.validateDriverLogin(driverName, shipmentId, phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (shipment != null) {
      // Set session
      final session = Session();
      session.role = UserRole.driver;
      session.driverName = driverName;
      session.shipmentId = shipmentId;

      // Navigate directly to shipment detail (skip dashboard)
      Navigator.of(context).pushReplacementNamed(
        AppConstants.dashboardRoute,
      );

      // Push the shipment detail on top after a short delay
      // so the dashboard is in the stack for back navigation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pushNamed(
            AppConstants.shipmentDetailRoute,
            arguments: shipment,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Invalid credentials. Check Driver Name, Shipment ID & Phone No.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F7FF),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Logo ───────────────────────────────────
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF22C55E),
                              Color(0xFF4ADE80),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E)
                                  .withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Driver Login',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Access your assigned shipment',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Card ──────────────────────────────────
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: AppTheme.divider.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Driver Name field
                                TextFormField(
                                  controller: _driverNameController,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Driver Name',
                                    hintText: 'e.g. Rajesh Kumar',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                      size: 20,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Driver name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Shipment ID field
                                TextFormField(
                                  controller: _shipmentIdController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                    labelText: 'Shipment ID',
                                    hintText: 'e.g. SHP-001',
                                    prefixIcon: Icon(
                                      Icons.tag_rounded,
                                      size: 20,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Shipment ID is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Phone field
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Driver Phone No',
                                    hintText: 'e.g. +91 9876543210',
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      size: 20,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Phone number is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Submit button
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF22C55E),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Log In as Driver'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Demo credentials hint ─────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFF22C55E).withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 18, color: Color(0xFF22C55E)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Demo: Rajesh Kumar · SHP-001 · 9876543210',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Back to role select ───────────────────
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed(
                              AppConstants.roleSelectRoute);
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text(
                          'Back to Role Selection',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
