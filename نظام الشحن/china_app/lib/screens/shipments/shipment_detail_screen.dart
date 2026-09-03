/**
 * Shipment Detail Screen - تفاصيل الشحنة
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/widgets/common_widgets.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final String shipmentId;
  
  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  Map<String, dynamic>? _shipment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShipment();
  }

  Future<void> _loadShipment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shipment = await ApiService.getShipment(widget.shipmentId);
      if (mounted) {
        setState(() {
          _shipment = shipment;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final lang = localeProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.get('shipmentDetails', lang: lang)),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget(message: _error!, onRetry: _loadShipment)
              : _buildContent(lang),
    );
  }

  Widget _buildContent(String lang) {
    final shipment = _shipment!;
    final isRTL = lang == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          shipment['shipment_number'] ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        StatusBadge(
                          status: shipment['status'] ?? 'pending',
                          lang: lang,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.person,
                      Localization.get('customer', lang: lang),
                      shipment['customer']?['name'] ?? '-',
                      lang,
                    ),
                    _buildInfoRow(
                      Icons.flight_takeoff,
                      Localization.get('origin', lang: lang),
                      shipment['origin_port'] ?? '-',
                      lang,
                    ),
                    _buildInfoRow(
                      Icons.flight_land,
                      Localization.get('destination', lang: lang),
                      shipment['destination_port'] ?? '-',
                      lang,
                    ),
                    _buildInfoRow(
                      Icons.directions_boat,
                      Localization.get('vessel', lang: lang),
                      shipment['vessel_name'] ?? '-',
                      lang,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التواريخ / Dates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDateRow(
                      Localization.get('departureDate', lang: lang),
                      shipment['departure_date'],
                      lang,
                    ),
                    _buildDateRow(
                      Localization.get('expectedArrival', lang: lang),
                      shipment['expected_arrival'],
                      lang,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Financial
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المعلومات المالية / Financial',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.money_off,
                      Localization.get('totalCost', lang: lang),
                      '${shipment['total_cost'] ?? 0} ${shipment['currency'] ?? 'USD'}',
                      lang,
                    ),
                    _buildInfoRow(
                      Icons.attach_money,
                      Localization.get('sellingPrice', lang: lang),
                      '${shipment['selling_price'] ?? 0} ${shipment['currency'] ?? 'USD'}',
                      lang,
                    ),
                    _buildInfoRow(
                      Icons.trending_up,
                      Localization.get('profit', lang: lang),
                      '${((shipment['selling_price'] ?? 0) - (shipment['total_cost'] ?? 0)).toStringAsFixed(2)} ${shipment['currency'] ?? 'USD'}',
                      lang,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Containers
            if (shipment['containers'] != null && (shipment['containers'] as List).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Localization.get('containers', lang: lang),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(shipment['containers'] as List).map<Widget>((container) => 
                        ListTile(
                          leading: const Icon(Icons.inventory_2),
                          title: Text(container['container_number'] ?? ''),
                          subtitle: Text(container['container_type'] ?? ''),
                          trailing: StatusBadge(
                            status: container['status'] ?? 'loading',
                            lang: lang,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _createInvoice(),
                    icon: const Icon(Icons.receipt),
                    label: Text(Localization.get('createInvoice', lang: lang)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, String? date, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Text(
            date?.substring(0, 10) ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _createInvoice() async {
    try {
      final result = await ApiService.createInvoice(widget.shipmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice created: ${result['erpnext_invoice_id']}'),
            backgroundColor: AppConstants.secondaryColor,
          ),
        );
        _loadShipment();
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
    }
  }
}