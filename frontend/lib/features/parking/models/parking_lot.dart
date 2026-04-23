class ParkingLot {
  final String id;
  final String name;
  final int totalSpots;
  final double ratePerMinute;
  final double? reservationRatePerMinute;
  final String openTime;
  final String address;
  final String closeTime;
  final bool isActive;
  final int type;

  bool get isOpen => type == 0;

  ParkingLot({
    required this.id,
    required this.name,
    required this.totalSpots,
    required this.ratePerMinute,
    this.reservationRatePerMinute,
    required this.openTime,
    required this.address,
    required this.closeTime,
    required this.isActive,
    required this.type,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> json) => ParkingLot(
    id: json['id'],
    name: json['name'],
    address: json['address'] ?? '',
    totalSpots: json['totalSpots'] ?? 0,
    ratePerMinute: (json['ratePerMinute'] as num?)?.toDouble() ?? 0.0,
    reservationRatePerMinute: (json['reservationRatePerMinute'] as num?)?.toDouble(),
    openTime: json['openTime'] ?? '00:00:00',
    closeTime: json['closeTime'] ?? '00:00:00',
    isActive: json['isActive'] ?? true,
    type: (json['type'] as int?) ?? 0,
  );
}