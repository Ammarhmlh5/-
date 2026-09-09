import 'package:flutter/foundation.dart';
import '../models/shipment.dart';
import '../services/api_service.dart';

class ShipmentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Shipment> _shipments = [];
  bool _isLoading = false;
  String? _error;
  
  List<Shipment> get shipments => _shipments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadShipments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _apiService.getShipments();
      _shipments = data.map((json) => Shipment.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> addShipment(Map<String, dynamic> data) async {
    try {
      final result = await _apiService.createShipment(data);
      _shipments.add(Shipment.fromJson(result));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> updateShipment(int id, Map<String, dynamic> data) async {
    try {
      final result = await _apiService.updateShipment(id, data);
      final index = _shipments.indexWhere((s) => s.id == id);
      if (index != -1) {
        _shipments[index] = Shipment.fromJson(result);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> deleteShipment(int id) async {
    try {
      await _apiService.deleteShipment(id);
      _shipments.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}