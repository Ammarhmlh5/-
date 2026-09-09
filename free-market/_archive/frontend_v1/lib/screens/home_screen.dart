import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shipment_provider.dart';
import '../providers/customer_provider.dart';
import 'shipments_screen.dart';
import 'customers_screen.dart';
import 'tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ShipmentsScreen(),
    const CustomersScreen(),
    const TrackingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShipmentProvider>().loadShipments();
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام الشحن'),
        centerTitle: true,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping),
            label: 'الشحنات',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'العملاء',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on),
            label: 'تتبع',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لوحة التحكم',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Consumer<ShipmentProvider>(
                  builder: (context, provider, child) {
                    return _StatCard(
                      title: 'إجمالي الشحنات',
                      value: '${provider.shipments.length}',
                      icon: Icons.local_shipping,
                      color: Colors.blue,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Consumer<CustomerProvider>(
                  builder: (context, provider, child) {
                    return _StatCard(
                      title: 'إجمالي العملاء',
                      value: '${provider.customers.length}',
                      icon: Icons.people,
                      color: Colors.green,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Consumer<ShipmentProvider>(
                  builder: (context, provider, child) {
                    final inTransit = provider.shipments
                        .where((s) => s.status == 'in_transit')
                        .length;
                    return _StatCard(
                      title: 'في الطريق',
                      value: '$inTransit',
                      icon: Icons.directions_car,
                      color: Colors.orange,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Consumer<ShipmentProvider>(
                  builder: (context, provider, child) {
                    final delivered = provider.shipments
                        .where((s) => s.status == 'delivered')
                        .length;
                    return _StatCard(
                      title: 'تم التسليم',
                      value: '$delivered',
                      icon: Icons.check_circle,
                      color: Colors.teal,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}