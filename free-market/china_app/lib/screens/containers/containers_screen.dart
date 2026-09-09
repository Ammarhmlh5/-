/**
 * Containers Screen - شاشة الحاويات
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../../utils/localization.dart';
import '../../utils/widgets/common_widgets.dart';

class ContainersScreen extends StatefulWidget {
  const ContainersScreen({super.key});

  @override
  State<ContainersScreen> createState() => _ContainersScreenState();
}

class _ContainersScreenState extends State<ContainersScreen> {
  List<dynamic> _containers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  Future<void> _loadContainers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final containers = await ApiService.getContainers();
      if (mounted) {
        setState(() {
          _containers = containers;
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
        title: Text(Localization.get('containers', lang: lang)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget(message: _error!, onRetry: _loadContainers)
              : _containers.isEmpty
                  ? EmptyWidget(message: Localization.get('noData', lang: lang))
                  : RefreshIndicator(
                      onRefresh: _loadContainers,
                      child: ListView.builder(
                        itemCount: _containers.length,
                        itemBuilder: (context, index) {
                          final container = _containers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.inventory_2),
                              title: Text(container['container_number'] ?? ''),
                              subtitle: Text(container['container_type'] ?? ''),
                              trailing: StatusBadge(status: container['status'] ?? 'loading', lang: lang),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}