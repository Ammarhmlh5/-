import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/api_service.dart';

class CustomerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;
  
  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _apiService.getCustomers();
      _customers = data.map((json) => Customer.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> addCustomer(Map<String, dynamic> data) async {
    try {
      final result = await _apiService.createCustomer(data);
      _customers.add(Customer.fromJson(result));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> updateCustomer(int id, Map<String, dynamic> data) async {
    try {
      final result = await _apiService.updateCustomer(id, data);
      final index = _customers.indexWhere((c) => c.id == id);
      if (index != -1) {
        _customers[index] = Customer.fromJson(result);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> deleteCustomer(int id) async {
    try {
      await _apiService.deleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}