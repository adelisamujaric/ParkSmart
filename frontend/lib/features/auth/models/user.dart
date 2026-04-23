class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? country;
  final int role;
  final DateTime createdAt;
  final bool isActive;

  UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    email: json['email'],
    phoneNumber: json['phoneNumber'],
    address: json['address'],
    city: json['city'],
    postalCode: json['postalCode'],
    country: json['country'],
    role: json['role'] is int ? json['role'] : 0,
    createdAt: DateTime.parse(json['createdAt']),
    isActive: json['isActive'] ?? true,
  );

  String get fullName => '$firstName $lastName';
  String get roleLabel => role == 1 ? 'Admin' : 'Korisnik';
}