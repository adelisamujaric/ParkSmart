class Drone {
  final String id;
  final int number;
  final String lotId;
  final String lotName;
  final String status;
  final int batteryLevel;
  final String? timeToCharge;
  final DateTime createdAt;

  Drone({
    required this.id,
    required this.number,
    required this.lotId,
    required this.lotName,
    required this.status,
    required this.batteryLevel,
    this.timeToCharge,
    required this.createdAt,
  });

  factory Drone.fromJson(Map<String, dynamic> json) => Drone(
    id: json['id'],
    number: json['number'],
    lotId: json['lotId'],
    lotName: json['lotName'],
    status: json['status'],
    batteryLevel: json['batteryLevel'],
    timeToCharge: json['timeToCharge'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}