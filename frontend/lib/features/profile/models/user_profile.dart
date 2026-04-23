class UserProfile {
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
  final bool isActive;
  final bool isDisabled;

  UserProfile({
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
    required this.isActive,
    required this.isDisabled,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    email: json['email'],
    phoneNumber: json['phoneNumber'],
    address: json['address'],
    city: json['city'],
    postalCode: json['postalCode'],
    country: json['country'],
    role: json['role'],
    isActive: json['isActive'],
    isDisabled: json['isDisabled'] ?? false,
  );
}