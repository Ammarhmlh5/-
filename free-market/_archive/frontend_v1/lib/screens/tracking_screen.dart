import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shipment_provider.dart';
import '../models/shipment.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TextEditingController _trackingController = TextEditingController();
  Shipment? _foundShipment;

  void _searchShipment() {
    final provider = context.read<ShipmentProvider>();
    final shipment = provider.shipments.where(
      (s) => s.trackingNumber.toLowerCase().contains(
            _trackingController.text.toLowerCase()
          )
    ).firstOrNull;
    
    setState(() {
      _foundShipment = shipment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تتبع الشحنة',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _trackingController,
            decoration: InputDecoration(
              hintText: 'أدخل رقم التتبع',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _searchShipment,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _searchShipment(),
          ),
          const SizedBox(height: 24),
          if (_foundShipment != null) _ShipmentTrackingCard(shipment: _foundShipment!)
          else const Center(
            child: Text(
              'أدخل رقم التتبع للبحث',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentTrackingCard extends StatelessWidget {
  final Shipment shipment;
  
  const _ShipmentTrackingCard({required this.shipment});

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'معلومات الشحنة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            const Divider(height: 24),
            _InfoRow(label: 'رقم التتبع', value: shipment.trackingNumber),
            _InfoRow(label: 'من', value: shipment.origin),
            _InfoRow(label: 'إلى', value: shipment.destination),
            if (shipment.weight != null)
              _InfoRow(label: 'الوزن', value: '${shipment.weight} كجم'),
            if (shipment.shippingCost != null)
              _InfoRow(label: 'التكلفة', value: '${shipment.shippingCost} ر.س'),
            const SizedBox(height: 16),
            const Text(
              'خط التتبع:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _TimelineStep(
              status: shipment.statusText,
              location: shipment.destination,
              isCompleted: shipment.status == 'delivered',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String status;
  final String location;
  final bool isCompleted;
  final bool isLast;
  
  const _TimelineStep({
    required this.status,
    required this.location,
    required this.isCompleted,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green : Colors.grey,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
              ),
              Text(
                location,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}