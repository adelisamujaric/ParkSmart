class ParkingReservation {
  final String id;
  final String spotNumber;
  final String lotName;
  final String lotAddress;
  final String licensePlate;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final int status;

  ParkingReservation({
    required this.id,
    required this.spotNumber,
    required this.lotName,
    required this.lotAddress,
    required this.licensePlate,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
  });

  factory ParkingReservation.fromJson(Map<String, dynamic> json) => ParkingReservation(
    id: json['id'],
    spotNumber: json['spotNumber'],
    lotName: json['lotName'],
    lotAddress: json['lotAddress'] ?? '',
    licensePlate: json['licensePlate'],
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    totalPrice: (json['totalPrice'] as num).toDouble(),
    status: json['status'],
  );
}