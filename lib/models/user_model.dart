class UserModel {
  final String? id;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String role;

  UserModel({
    this.id,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
    };
  }
}
