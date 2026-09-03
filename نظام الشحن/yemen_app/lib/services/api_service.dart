/**
 * API Service - Yemen App
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
  
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await post(ApiConfig.login, body: {'username': username, 'password': password});
    if (data['access_token'] != null) {
      await setToken(data['access_token']);
    }
    return data;
  }
  
  static Future<void> logout() async {
    await clearToken();
  }
  
  static Future<List<dynamic>> getShipments({String? status, String? branchId}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (branchId != null) params['branch_id'] = branchId;
    final data = await get(ApiConfig.shipments, queryParams: params.isNotEmpty ? params : null);
    return data['items'] as List<dynamic>;
  }
  
  static Future<Map<String, dynamic>> getShipment(String id) async {
    return await get('${ApiConfig.shipments}/$id');
  }
  
  static Future<Map<String, dynamic>> updateShipmentStatus(String id, String status) async {
    return await put('${ApiConfig.shipments}/$id/status', body: {'status': status});
  }
  
  static Future<Map<String, dynamic>> createPayment(Map<String, dynamic> payment) async {
    return await post(ApiConfig.payments, body: payment);
  }
  
  static Future<List<dynamic>> getPayments({String? customerId}) async {
    final params = customerId != null ? {'customer_id': customerId} : null;
    final data = await get(ApiConfig.payments, queryParams: params);
    return data['items'] as List<dynamic>;
  }
}