/**
 * Home Screen - الشاشة الرئيسية
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../utils/widgets/common_widgets.dart';
import 'shipments/shipments_list_screen.dart';
import 'customers/customers_screen.dart';
import 'containers/containers_screen.dart';
import 'tracking/tracking_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiService.getShipmentStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final authProvider = context.watch<AuthProvider>();
    final lang = localeProvider.locale.languageCode;
    final isRTL = lang == 'ar';

    final screens = [
      _DashboardTab(onRefresh: _loadStats, stats: _stats, isLoading: _isLoadingStats, lang: lang),
      const ShipmentsListScreen(),
      const ContainersScreen(),
      const TrackingScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: Localization.get('home', lang: lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_shipping_outlined),
            selectedIcon: const Icon(Icons.local_shipping),
            label: Localization.get('shipments', lang: lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: Localization.get('containers', lang: lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.location_on_outlined),
            selectedIcon: const Icon(Icons.location_on),
            label: Localization.get('tracking', lang: lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: Localization.get('settings', lang: lang),
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final String lang;

  const _DashboardTab({
    required this.onRefresh,
    this.stats,
    required this.isLoading,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.get('dashboard', lang: lang)),
        centerTitle: true,
      ),
      body: isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        StatCard(
                          title: Localization.get('totalShipments', lang: lang),
                          value: '${stats?['total'] ?? 0}',
                          icon: Icons.local_shipping,
                          color: AppConstants.primaryColor,
                        ),
                        StatCard(
                          title: Localization.get('inTransitShipments', lang: lang),
                          value: '${stats?['in_transit'] ?? 0}',
                          icon: Icons.flight,
                          color: AppConstants.infoColor,
                        ),
                        StatCard(
                          title: Localization.get('deliveredShipments', lang: lang),
                          value: '${stats?['delivered'] ?? 0}',
                          icon: Icons.check_circle,
                          color: AppConstants.secondaryColor,
                        ),
                        StatCard(
                          title: Localization.get('pending', lang: lang),
                          value: '${stats?['pending'] ?? 0}',
                          icon: Icons.pending,
                          color: AppConstants.warningColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Shipments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Localization.get('recentShipments', lang: lang),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to shipments
                          },
                          child: Text(Localization.get('viewAll', lang: lang)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Placeholder for recent shipments
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping),
                        title: const Text('SHIP-CHN-2026-0001'),
                        subtitle: Text(Localization.get('inTransit', lang: lang)),
                        trailing: StatusBadge(status: 'in_transit', lang: lang),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to new shipment
        },
        icon: const Icon(Icons.add),
        label: Text(Localization.get('newShipment', lang: lang)),
      ),
    );
  }
}