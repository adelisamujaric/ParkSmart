class ParkingSpot {
  final String id;
  final String lotId;
  final String lotName;
  final String spotNumber;
  final int type;
  final int status;
  final bool isReservable;
  final int? floor;

  ParkingSpot({
    required this.id,
    required this.lotId,
    required this.lotName,
    required this.spotNumber,
    required this.type,
    required this.status,
    required this.isReservable,
    this.floor,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) => ParkingSpot(
    id: json['id'],
    lotId: json['lotId'],
    lotName: json['lotName'],
    spotNumber: json['spotNumber'],
    type: json['type'] is int ? json['type'] : 0,
    status: json['status'] is int ? json['status'] : 0,
    isReservable: json['isReservable'] ?? false,
    floor: json['floor'],
  );
}