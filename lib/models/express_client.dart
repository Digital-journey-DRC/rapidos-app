class ExpressClient {
  final String? id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? address;
  final DateTime createdAt;
  final String createdBy;

  ExpressClient({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.address,
    required this.createdAt,
    required this.createdBy,
  });

  factory ExpressClient.fromJson(Map<String, dynamic> json) {
    return ExpressClient(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      createdAt: json['createdAt'] is DateTime 
          ? json['createdAt'] 
          : DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  String get fullName => '$firstName $lastName';
} 