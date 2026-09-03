/**
 * Tracking Screen - شاشة التتبع
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../utils/widgets/common_widgets.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  List<dynamic> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  Future<void> _loadTracking() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final events = await ApiService.getTrackingEvents();
      if (mounted) {
        setState(() {
          _events = events;
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
    final isRTL = lang == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.get('tracking', lang: lang)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: _isLoading
            ? const LoadingWidget()
            : _error != null
                ? ErrorWidget(message: _error!, onRetry: _loadTracking)
                : _events.isEmpty
                    ? EmptyWidget(message: Localization.get('noData', lang: lang))
                    : RefreshIndicator(
                        onRefresh: _loadTracking,
                        child: ListView.builder(
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return _buildEventCard(event, lang);
                          },
                        ),
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTrackingEvent,
        child: const Icon(Icons.add_location),
      ),
    );
  }

  Widget _buildEventCard(dynamic event, String lang) {
    final eventType = event['event_type'] ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.getStatusColor(eventType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getEventIcon(eventType),
                    color: AppConstants.getStatusColor(eventType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.getStatusName(eventType, lang),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        event['event_date']?.toString().substring(0, 16) ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(event['location'] ?? '-'),
              ],
            ),
            if (event['description'] != null) ...[
              const SizedBox(height: 8),
              Text(event['description'], style: TextStyle(color: Colors.grey[700])),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'departure':
        return Icons.flight_takeoff;
      case 'in_transit':
        return Icons.directions_boat;
      case 'arrival':
        return Icons.flight_land;
      case 'customs':
        return Icons.gavel;
      case 'delivery':
        return Icons.check_circle;
      default:
        return Icons.location_on;
    }
  }

  void _addTrackingEvent() {
    // Show add tracking dialog
  }
}