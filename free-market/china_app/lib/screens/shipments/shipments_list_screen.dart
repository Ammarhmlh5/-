/**
 * Shipments List Screen - قائمة الشحنات
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/widgets/common_widgets.dart';
import 'shipment_detail_screen.dart';
import 'new_shipment_screen.dart';

class ShipmentsListScreen extends StatefulWidget {
  const ShipmentsListScreen({super.key});

  @override
  State<ShipmentsListScreen> createState() => _ShipmentsListScreenState();
}

class _ShipmentsListScreenState extends State<ShipmentsListScreen> {
  List<dynamic> _shipments = [];
  bool _isLoading = true;
  String? _error;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shipments = await ApiService.getShipments(status: _statusFilter);
      if (mounted) {
        setState(() {
          _shipments = shipments;
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
        title: Text(Localization.get('shipments', lang: lang)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget(message: _error!, onRetry: _loadShipments)
              : _shipments.isEmpty
                  ? EmptyWidget(message: Localization.get('noData', lang: lang))
                  : RefreshIndicator(
                      onRefresh: _loadShipments,
                      child: ListView.builder(
                        itemCount: _shipments.length,
                        itemBuilder: (context, index) {
                          final shipment = _shipments[index];
                          return ShipmentCard(
                            shipment: shipment,
                            lang: lang,
                            onTap: () => _openShipmentDetail(shipment['id']),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewShipment,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog() {
    final localeProvider = context.read<LocaleProvider>();
    final lang = localeProvider.locale.languageCode;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('All'),
            leading: Radio<String?>(
              value: null,
              groupValue: _statusFilter,
              onChanged: (value) {
                setState(() => _statusFilter = value);
                Navigator.pop(context);
                _loadShipments();
              },
            ),
          ),
          ...AppConstants.shipmentStatuses.map((status) => ListTile(
            title: Text(AppConstants.getStatusName(status, lang)),
            leading: Radio<String?>(
              value: status,
              groupValue: _statusFilter,
              onChanged: (value) {
                setState(() => _statusFilter = value);
                Navigator.pop(context);
                _loadShipments();
              },
            ),
          )),
        ],
      ),
    );
  }

  void _openShipmentDetail(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShipmentDetailScreen(shipmentId: id),
      ),
    );
  }

  void _createNewShipment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewShipmentScreen(),
      ),
    ).then((_) => _loadShipments());
  }
}