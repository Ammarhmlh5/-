class Shipment {
  final int id;
  final String trackingNumber;
  final int customerId;
  final String status;
  final String origin;
  final String destination;
  final double? weight;
  final String? dimensions;
  final double? shippingCost;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? customer;

  Shipment({
    required this.id,
    required this.trackingNumber,
    required this.customerId,
    required this.status,
    required this.origin,
    required this.destination,
    this.weight,
    this.dimensions,
    this.shippingCost,
    this.createdAt,
    this.updatedAt,
    this.customer,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'],
      trackingNumber: json['tracking_number'] ?? '',
      customerId: json['customer_id'],
      status: json['status'] ?? 'pending',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      weight: json['weight']?.toDouble(),
      dimensions: json['dimensions'],
      shippingCost: json['shipping_cost']?.toDouble(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      customer: json['customer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracking_number': trackingNumber,
      'customer_id': customerId,
      'status': status,
      'origin': origin,
      'destination': destination,
      'weight': weight,
      'dimensions': dimensions,
      'shipping_cost': shippingCost,
    };
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'picked_up':
        return 'تم الاستلام';
      case 'in_transit':
        return 'في الطريق';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغى';
      default:
        return status;
    }
  }
}