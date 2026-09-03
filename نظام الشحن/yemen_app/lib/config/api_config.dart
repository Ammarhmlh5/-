/**
 * API Configuration - Yemen App
 */
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:5000';  // Android emulator
  static const String apiPrefix = '/api';
  
  // Endpoints
  static const String login = '$apiPrefix/auth/login';
  static const String branches = '$apiPrefix/branches';
  static const String customers = '$apiPrefix/customers';
  static const String shipments = '$apiPrefix/shipments';
  static const String containers = '$apiPrefix/containers';
  static const String tracking = '$apiPrefix/tracking';
  static const String invoices = '$apiPrefix/invoices';
  static const String payments = '$apiPrefix/payments';
  static const String erpnext = '$apiPrefix/erpnext';
  
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
}