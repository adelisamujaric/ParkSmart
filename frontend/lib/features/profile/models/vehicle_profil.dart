class Vehicle {
  final String id;
  final String licensePlate;
  final String brand;
  final String model;
  final String userId;
  final DateTime createdAt;
  final bool isActive;

  Vehicle({
    required this.id,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.userId,
    required this.createdAt,
    required this.isActive,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'],
    licensePlate: json['licensePlate'],
    brand: json['brand'],
    model: json['model'],
    userId: json['userId'],
    createdAt: DateTime.parse(json['createdAt']),
    isActive: json['isActive'],
  );
}