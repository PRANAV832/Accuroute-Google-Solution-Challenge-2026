import 'package:flutter/material.dart';
import '../models/shipment.dart';
import '../services/shipment_service.dart';
import '../utils/app_theme.dart';

/// Add Shipment screen — scrollable form to create a new shipment
class AddShipmentScreen extends StatefulWidget {
  const AddShipmentScreen({super.key});

  @override
  State<AddShipmentScreen> createState() => _AddShipmentScreenState();
}

class _AddShipmentScreenState extends State<AddShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ShipmentService();
  bool _isSubmitting = false;

  // Form controllers
  final _idController = TextEditingController();
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleNoController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _goodsTypeController = TextEditingController();
  final _companyController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _sourceController.dispose();
    _destinationController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNoController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _goodsTypeController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final shipment = Shipment(
      id: _idController.text.trim(),
      source: _sourceController.text.trim(),
      destination: _destinationController.text.trim(),
      eta: 'N/A',
      distance: 'N/A',
      risk: RiskLevel.low,
      vehicleType: _vehicleTypeController.text.trim(),
      vehicleNo: _vehicleNoController.text.trim(),
      driverName: _driverNameController.text.trim(),
      driverPhone: _driverPhoneController.text.trim(),
      goodsType: _goodsTypeController.text.trim(),
      company: _companyController.text.trim(),
    );

    await _service.addShipment(shipment);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Shipment added successfully!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add Shipment'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.divider.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section: Shipment Details
                    _sectionTitle('Shipment Details'),
                    const SizedBox(height: 12),
                    _buildField(_idController, 'Shipment ID', Icons.tag_rounded, required: true),
                    const SizedBox(height: 12),
                    _buildField(_sourceController, 'Source', Icons.location_on_outlined, required: true),
                    const SizedBox(height: 12),
                    _buildField(_destinationController, 'Destination', Icons.flag_outlined, required: true),

                    const SizedBox(height: 24),

                    // Section: Vehicle Info
                    _sectionTitle('Vehicle Info'),
                    const SizedBox(height: 12),
                    _buildField(_vehicleTypeController, 'Vehicle Type', Icons.directions_car_rounded),
                    const SizedBox(height: 12),
                    _buildField(_vehicleNoController, 'Vehicle Number', Icons.confirmation_number_outlined),

                    const SizedBox(height: 24),

                    // Section: Driver Info
                    _sectionTitle('Driver Info'),
                    const SizedBox(height: 12),
                    _buildField(_driverNameController, 'Driver Name', Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    _buildField(_driverPhoneController, 'Driver Phone', Icons.phone_outlined,
                        keyboardType: TextInputType.phone),

                    const SizedBox(height: 24),

                    // Section: Goods Info
                    _sectionTitle('Goods Info'),
                    const SizedBox(height: 12),
                    _buildField(_goodsTypeController, 'Goods Type', Icons.inventory_2_outlined),
                    const SizedBox(height: 12),
                    _buildField(_companyController, 'Company Name', Icons.business_outlined),

                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.add_rounded, size: 20),
                        label: Text(_isSubmitting ? 'Adding...' : 'Add Shipment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textMuted),
      ),
      validator: required
          ? (v) {
              if (v == null || v.isEmpty) return '$label is required';
              return null;
            }
          : null,
    );
  }
}
