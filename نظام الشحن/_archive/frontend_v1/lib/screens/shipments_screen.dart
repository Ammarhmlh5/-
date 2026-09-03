import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shipment_provider.dart';
import '../models/shipment.dart';

class ShipmentsScreen extends StatelessWidget {
  const ShipmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ShipmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.shipments.isEmpty) {
            return const Center(
              child: Text('لا توجد شحنات', style: TextStyle(fontSize: 18)),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.shipments.length,
            itemBuilder: (context, index) {
              final shipment = provider.shipments[index];
              return _ShipmentCard(shipment: shipment);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showAddDialog(BuildContext context) {
    final originController = TextEditingController();
    final destinationController = TextEditingController();
    final weightController = TextEditingController();
    int? selectedCustomerId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة شحنة جديدة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: originController,
                decoration: const InputDecoration(labelText: 'الم'origine),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(labelText: 'الوجهة'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الوزن (كجم)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (originController.text.isNotEmpty && 
                  destinationController.text.isNotEmpty) {
                context.read<ShipmentProvider>().addShipment({
                  'customer_id': 1,
                  'origin': originController.text,
                  'destination': destinationController.text,
                  'weight': double.tryParse(weightController.text),
                  'status': 'pending',
                });
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  
  const _ShipmentCard({required this.shipment});

  Color _getStatusColor() {
    switch (shipment.status) {
      case 'pending': return Colors.orange;
      case 'picked_up': return Colors.blue;
      case 'in_transit': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shipment.trackingNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    shipment.statusText,
                    style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('من: ${shipment.origin}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.flag, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('إلى: ${shipment.destination}'),
              ],
            ),
            if (shipment.weight != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.scale, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('الوزن: ${shipment.weight} كجم'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}