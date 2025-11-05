class ExpressOrder {
  final String? id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String packageValue;
  final String? packageDescription;
  final String? pickupAddress;
  final String? deliveryAddress;
  final String status;
  final DateTime createdAt;
  final String createdBy;
  final String? livreurId;
  final String? shortCode;

  ExpressOrder({
    this.id,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.packageValue,
    this.packageDescription,
    this.pickupAddress,
    this.deliveryAddress,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.livreurId,
    this.shortCode,
  });

  factory ExpressOrder.fromJson(Map<String, dynamic> json) {
    return ExpressOrder(
      id: json['id'],
      clientId: json['clientId'],
      clientName: json['clientName'],
      clientPhone: json['clientPhone'],
      packageValue: json['packageValue'],
      packageDescription: json['packageDescription'],
      pickupAddress: json['pickupAddress'],
      deliveryAddress: json['deliveryAddress'],
      status: json['status'],
      createdAt: json['createdAt'] is DateTime 
          ? json['createdAt'] 
          : DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      livreurId: json['livreurId'],
      shortCode: json['shortCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'packageValue': packageValue,
      'packageDescription': packageDescription,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'livreurId': livreurId,
      'shortCode': shortCode,
    };
  }
} 