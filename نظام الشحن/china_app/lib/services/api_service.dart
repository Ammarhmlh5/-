/**
 * API Service - خدمة API
 */
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static String? _token;
  
  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }
  
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  static Map<String, String> get _headers async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  static Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _headers);
    return _handleResponse(response);
  }
  
  static Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await http.post(
      uri,
      headers: await _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }
  
  static Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await http.put(
      uri,
      headers: await _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }
  
  static Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await http.delete(uri, headers: await _headers);
    return _handleResponse(response);
  }
  
  static dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else if (response.statusCode == 401) {
      clearToken();
      throw Exception('Unauthorized');
    } else {
      throw Exception(data['error'] ?? 'Unknown error');
    }
  }
  
  // Auth
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await post(ApiConfig.login, body: {
      'username': username,
      'password': password,
    });
    if (data['access_token'] != null) {
      await setToken(data['access_token']);
    }
    return data;
  }
  
  static Future<void> logout() async {
    await clearToken();
  }
  
  // Branches
  static Future<List<dynamic>> getBranches() async {
    final data = await get(ApiConfig.branches);
    return data as List<dynamic>;
  }
  
  // Customers
  static Future<List<dynamic>> getCustomers({String? branchId}) async {
    final params = branchId != null ? {'branch_id': branchId} : null;
    final data = await get(ApiConfig.customers, queryParams: params);
    return data['items'] as List<dynamic>;
  }
  
  static Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> customer) async {
    return await post(ApiConfig.customers, body: customer);
  }
  
  static Future<Map<String, dynamic>> updateCustomer(String id, Map<String, dynamic> customer) async {
    return await put('${ApiConfig.customers}/$id', body: customer);
  }
  
  // Shipments
  static Future<List<dynamic>> getShipments({String? branchId, String? status}) async {
    final params = <String, String>{};
    if (branchId != null) params['branch_id'] = branchId;
    if (status != null) params['status'] = status;
    final data = await get(ApiConfig.shipments, queryParams: params.isNotEmpty ? params : null);
    return data['items'] as List<dynamic>;
  }
  
  static Future<Map<String, dynamic>> getShipment(String id) async {
    return await get('${ApiConfig.shipments}/$id');
  }
  
  static Future<Map<String, dynamic>> createShipment(Map<String, dynamic> shipment) async {
    return await post(ApiConfig.shipments, body: shipment);
  }
  
  static Future<Map<String, dynamic>> updateShipment(String id, Map<String, dynamic> shipment) async {
    return await put('${ApiConfig.shipments}/$id', body: shipment);
  }
  
  static Future<Map<String, dynamic>> updateShipmentStatus(String id, String status) async {
    return await put('${ApiConfig.shipments}/$id/status', body: {'status': status});
  }
  
  static Future<Map<String, dynamic>> linkInvoice(String shipmentId, String invoiceId) async {
    return await post('${ApiConfig.shipments}/$shipmentId/invoice', body: {'erpnext_invoice_id': invoiceId});
  }
  
  // Containers
  static Future<List<dynamic>> getContainers({String? shipmentId}) async {
    final params = shipmentId != null ? {'shipment_id': shipmentId} : null;
    final data = await get(ApiConfig.containers, queryParams: params);
    return data['items'] as List<dynamic>;
  }
  
  static Future<Map<String, dynamic>> createContainer(Map<String, dynamic> container) async {
    return await post(ApiConfig.containers, body: container);
  }
  
  // Tracking
  static Future<List<dynamic>> getTrackingEvents({String? containerId}) async {
    final params = containerId != null ? {'container_id': containerId} : null;
    final data = await get(ApiConfig.tracking, queryParams: params);
    return data['items'] as List<dynamic>;
  }
  
  static Future<Map<String, dynamic>> createTrackingEvent(Map<String, dynamic> event) async {
    return await post(ApiConfig.tracking, body: event);
  }
  
  // Invoices
  static Future<List<dynamic>> getInvoices({String? shipmentId}) async {
    final params = shipmentId != null ? {'shipment_id': shipmentId} : null;
    final data = await get(ApiConfig.invoices, queryParams: params);
    return data['items'] as List<dynamic>;
  }
  
  static Future<Map<String, dynamic>> createInvoice(String shipmentId) async {
    return await post('${ApiConfig.erpnext}/create-sales-invoice', body: {'shipment_id': shipmentId});
  }
  
  // Ports
  static Future<List<dynamic>> getPorts({String? country}) async {
    final params = country != null ? {'country': country} : null;
    final data = await get(ApiConfig.ports, queryParams: params);
    return data as List<dynamic>;
  }
  
  // Shipping Lines
  static Future<List<dynamic>> getShippingLines() async {
    final data = await get(ApiConfig.shippingLines);
    return data as List<dynamic>;
  }
  
  // Stats
  static Future<Map<String, dynamic>> getShipmentStats({String? branchId}) async {
    final params = branchId != null ? {'branch_id': branchId} : null;
    return await get('${ApiConfig.shipments}/stats', queryParams: params);
  }
}