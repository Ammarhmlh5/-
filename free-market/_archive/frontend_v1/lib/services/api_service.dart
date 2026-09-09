import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  
  final http.Client _client = http.Client();
  
  // Shipments
  Future<List<dynamic>> getShipments() async {
    final response = await _client.get(Uri.parse('$baseUrl/shipments'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('فشل في تحميل الشحنات');
  }
  
  Future<dynamic> getShipment(int id) async {
    final response = await _client.get(Uri.parse('$baseUrl/shipments/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('الشحنة غير موجودة');
  }
  
  Future<dynamic> createShipment(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/shipments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('فشل في إنشاء الشحنة');
  }
  
  Future<dynamic> updateShipment(int id, Map<String, dynamic> data) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/shipments/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('فشل في تحديث الشحنة');
  }
  
  Future<void> deleteShipment(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/shipments/$id'));
    if (response.statusCode != 200) {
      throw Exception('فشل في حذف الشحنة');
    }
  }
  
  // Customers
  Future<List<dynamic>> getCustomers() async {
    final response = await _client.get(Uri.parse('$baseUrl/customers'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('فشل في تحميل العملاء');
  }
  
  Future<dynamic> getCustomer(int id) async {
    final response = await _client.get(Uri.parse('$baseUrl/customers/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('العميل غير موجود');
  }
  
  Future<dynamic> createCustomer(Map<String, dynamic> data) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/customers'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('فشل في إنشاء العميل');
  }
  
  Future<dynamic> updateCustomer(int id, Map<String, dynamic> data) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/customers/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('فشل في تحديث العميل');
  }
  
  Future<void> deleteCustomer(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/customers/$id'));
    if (response.statusCode != 200) {
      throw Exception('فشل في حذف العميل');
    }
  }
  
  // Tracking
  Future<dynamic> getShipmentTracking(int shipmentId) async {
    final response = await _client.get(Uri.parse('$baseUrl/tracking/shipment/$shipmentId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('فشل في تحميل التتبع');
  }
}