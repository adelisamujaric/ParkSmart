class UserResponse {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? country;
  final String role;
  final DateTime createdAt;
  final bool isActive;

  UserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.address,
    this.city,
    this.postalCode,
    this.country,
    required this.role,
    required this.createdAt,
    required this.isActive,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['id'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    email: json['email'],
    phoneNumber: json['phoneNumber'],
    address: json['address'],
    city: json['city'],
    postalCode: json['postalCode'],
    country: json['country'],
    role: json['role'].toString(),
    createdAt: DateTime.parse(json['createdAt']),
    isActive: json['isActive'],
  );
}

class AuthResponse {
  final String token;
  final UserResponse user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'],
    user: UserResponse.fromJson(json['user']),
  );
}