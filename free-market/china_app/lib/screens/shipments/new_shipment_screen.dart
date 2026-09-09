/**
 * New Shipment Screen - إنشاء شحنة جديدة
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';

class NewShipmentScreen extends StatefulWidget {
  const NewShipmentScreen({super.key});

  @override
  State<NewShipmentScreen> createState() => _NewShipmentScreenState();
}

class _NewShipmentScreenState extends State<NewShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _vesselController = TextEditingController();
  final _voyageController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();
  
  String? _selectedCustomerId;
  List<dynamic> _customers = [];
  List<dynamic> _ports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final customers = await ApiService.getCustomers();
      final ports = await ApiService.getPorts();
      if (mounted) {
        setState(() {
          _customers = customers;
          _ports = ports;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _vesselController.dispose();
    _voyageController.dispose();
    _costController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveShipment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final shipment = {
        'customer_id': _selectedCustomerId,
        'branch_id': 'china_branch_id', // Get from auth
        'origin_port': _originController.text,
        'destination_port': _destinationController.text,
        'vessel_name': _vesselController.text,
        'voyage_number': _voyageController.text,
        'total_cost': double.tryParse(_costController.text) ?? 0,
        'selling_price': double.tryParse(_priceController.text) ?? 0,
        'currency': 'USD',
      };

      await ApiService.createShipment(shipment);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment created successfully'),
            backgroundColor: AppConstants.secondaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final lang = localeProvider.locale.languageCode;
    final isRTL = lang == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.get('newShipment', lang: lang)),
      ),
      body: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Customer
              DropdownButtonFormField<String>(
                value: _selectedCustomerId,
                decoration: InputDecoration(
                  labelText: Localization.get('customer', lang: lang),
                  prefixIcon: const Icon(Icons.person),
                ),
                items: _customers.map((c) => DropdownMenuItem(
                  value: c['id'],
                  child: Text(c['name'] ?? ''),
                )).toList(),
                onChanged: (value) => setState(() => _selectedCustomerId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Origin Port
              DropdownButtonFormField<String>(
                value: _originController.text.isNotEmpty ? _originController.text : null,
                decoration: InputDecoration(
                  labelText: Localization.get('origin', lang: lang),
                  prefixIcon: const Icon(Icons.flight_takeoff),
                ),
                items: _ports.where((p) => p['country'] == 'الصين' || p['country'] == 'China').map((p) => DropdownMenuItem(
                  value: p['name'],
                  child: Text(p['name'] ?? ''),
                )).toList(),
                onChanged: (value) => _originController.text = value ?? '',
              ),
              const SizedBox(height: 16),

              // Destination Port
              DropdownButtonFormField<String>(
                value: _destinationController.text.isNotEmpty ? _destinationController.text : null,
                decoration: InputDecoration(
                  labelText: Localization.get('destination', lang: lang),
                  prefixIcon: const Icon(Icons.flight_land),
                ),
                items: _ports.where((p) => p['country'] == 'اليمن' || p['country'] == 'Yemen').map((p) => DropdownMenuItem(
                  value: p['name'],
                  child: Text(p['name'] ?? ''),
                )).toList(),
                onChanged: (value) => _destinationController.text = value ?? '',
              ),
              const SizedBox(height: 16),

              // Vessel
              TextFormField(
                controller: _vesselController,
                decoration: InputDecoration(
                  labelText: Localization.get('vessel', lang: lang),
                  prefixIcon: const Icon(Icons.directions_boat),
                ),
              ),
              const SizedBox(height: 16),

              // Voyage
              TextFormField(
                controller: _voyageController,
                decoration: const InputDecoration(
                  labelText: 'Voyage Number',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 24),

              // Financial
              Text(
                'المعلومات المالية / Financial Info',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),

              // Cost & Price
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Localization.get('totalCost', lang: lang),
                        prefixIcon: const Icon(Icons.money_off),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Localization.get('sellingPrice', lang: lang),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveShipment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(Localization.get('save', lang: lang)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}