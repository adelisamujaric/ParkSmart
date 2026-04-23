class ParkingViolation {
  final String id;
  final String licensePlate;
  final String type;
  final String description;
  final double fineAmount;
  final bool isResolved;
  final DateTime createdAt;

  ParkingViolation({
    required this.id,
    required this.licensePlate,
    required this.type,
    required this.description,
    required this.fineAmount,
    required this.isResolved,
    required this.createdAt,
  });

  factory ParkingViolation.fromJson(Map<String, dynamic> json) => ParkingViolation(
    id: json['id'],
    licensePlate: json['licensePlate'],
    type: json['type'].toString(),
    description: json['description'],
    fineAmount: (json['fineAmount'] as num).toDouble(),
    isResolved: json['isResolved'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}