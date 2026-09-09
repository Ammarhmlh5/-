/**
 * Models - نماذج البيانات
 */

class User {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? fullNameAr;
  final String? phone;
  final String? branchId;
  final String role;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.fullNameAr,
    this.phone,
    this.branchId,
    required this.role,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
      fullNameAr: json['full_name_ar'],
      phone: json['phone'],
      branchId: json['branch_id'],
      role: json['role'] ?? 'operator',
      isActive: json['is_active'] ?? true,
    );
  }
}

class Branch {
  final String id;
  final String name;
  final String code;
  final String country;
  final String? costCenterId;
  final String? warehouseId;
  final bool isActive;

  Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.country,
    this.costCenterId,
    this.warehouseId,
    this.isActive = true,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      country: json['country'] ?? '',
      costCenterId: json['cost_center_id'],
      warehouseId: json['warehouse_id'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String? phone;
  final String? email;
  final String? address;
  final String? country;
  final String? city;
  final String? branchId;
  final double creditLimit;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    this.phone,
    this.email,
    this.address,
    this.country,
    this.city,
    this.branchId,
    this.creditLimit = 0,
    this.isActive = true,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      country: json['country'],
      city: json['city'],
      branchId: json['branch_id'],
      creditLimit: (json['credit_limit'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
    );
  }
}

class Shipment {
  final String id;
  final String shipmentNumber;
  final String branchId;
  final String customerId;
  final String? customerName;
  final String status;
  final String? originPort;
  final String? destinationPort;
  final String? vesselName;
  final String? voyageNumber;
  final String? orderDate;
  final String? departureDate;
  final String? expectedArrival;
  final String? actualArrival;
  final String? deliveryDate;
  final double totalCost;
  final double sellingPrice;
  final String currency;
  final String? description;
  final List<Container> containers;

  Shipment({
    required this.id,
    required this.shipmentNumber,
    required this.branchId,
    required this.customerId,
    this.customerName,
    this.status = 'pending',
    this.originPort,
    this.destinationPort,
    this.vesselName,
    this.voyageNumber,
    this.orderDate,
    this.departureDate,
    this.expectedArrival,
    this.actualArrival,
    this.deliveryDate,
    this.totalCost = 0,
    this.sellingPrice = 0,
    this.currency = 'USD',
    this.description,
    this.containers = const [],
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'] ?? '',
      shipmentNumber: json['shipment_number'] ?? '',
      branchId: json['branch_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      customerName: json['customer']?['name'],
      status: json['status'] ?? 'pending',
      originPort: json['origin_port'],
      destinationPort: json['destination_port'],
      vesselName: json['vessel_name'],
      voyageNumber: json['voyage_number'],
      orderDate: json['order_date'],
      departureDate: json['departure_date'],
      expectedArrival: json['expected_arrival'],
      actualArrival: json['actual_arrival'],
      deliveryDate: json['delivery_date'],
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      sellingPrice: (json['selling_price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      description: json['description'],
      containers: (json['containers'] as List<dynamic>?)
          ?.map((c) => Container.fromJson(c))
          .toList() ?? [],
    );
  }

  double get profit => sellingPrice - totalCost;
}

class Container {
  final String id;
  final String shipmentId;
  final String containerNumber;
  final String containerType;
  final String? sealNumber;
  final double? weight;
  final double? volume;
  final int packageCount;
  final String? description;
  final String status;

  Container({
    required this.id,
    required this.shipmentId,
    required this.containerNumber,
    required this.containerType,
    this.sealNumber,
    this.weight,
    this.volume,
    this.packageCount = 0,
    this.description,
    this.status = 'loading',
  });

  factory Container.fromJson(Map<String, dynamic> json) {
    return Container(
      id: json['id'] ?? '',
      shipmentId: json['shipment_id'] ?? '',
      containerNumber: json['container_number'] ?? '',
      containerType: json['container_type'] ?? '',
      sealNumber: json['seal_number'],
      weight: json['weight']?.toDouble(),
      volume: json['volume']?.toDouble(),
      packageCount: json['package_count'] ?? 0,
      description: json['description'],
      status: json['status'] ?? 'loading',
    );
  }
}

class TrackingEvent {
  final String id;
  final String containerId;
  final String? shipmentId;
  final String eventType;
  final String eventDate;
  final String? location;
  final String? portCode;
  final String? country;
  final String? description;
  final String source;

  TrackingEvent({
    required this.id,
    required this.containerId,
    this.shipmentId,
    required this.eventType,
    required this.eventDate,
    this.location,
    this.portCode,
    this.country,
    this.description,
    this.source = 'manual',
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      id: json['id'] ?? '',
      containerId: json['container_id'] ?? '',
      shipmentId: json['shipment_id'],
      eventType: json['event_type'] ?? '',
      eventDate: json['event_date'] ?? '',
      location: json['location'],
      portCode: json['port_code'],
      country: json['country'],
      description: json['description'],
      source: json['source'] ?? 'manual',
    );
  }
}

class Port {
  final String id;
  final String name;
  final String? nameAr;
  final String? code;
  final String country;
  final String? city;

  Port({
    required this.id,
    required this.name,
    this.nameAr,
    this.code,
    required this.country,
    this.city,
  });

  factory Port.fromJson(Map<String, dynamic> json) {
    return Port(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      code: json['code'],
      country: json['country'] ?? '',
      city: json['city'],
    );
  }
}