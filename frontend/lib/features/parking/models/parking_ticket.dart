class ParkingTicket {
  final String id;
  final String userId;
  final String? spotId;
  final String spotNumber;
  final String lotName;
  final String lotAddress;
  final String licensePlate;
  final DateTime entryTime;
  final DateTime? exitTime;
  final DateTime? endTime;
  final double? totalPrice;
  final String status;
  final DateTime createdAt;
  final DateTime? paymentDeadline;
  final double lateFee;

  ParkingTicket({
    required this.id,
    required this.userId,
    required this.spotId,
    required this.spotNumber,
    required this.lotName,
    required this.lotAddress,
    required this.licensePlate,
    required this.entryTime,
    this.exitTime,
    this.endTime,
    this.totalPrice,
    required this.status,
    required this.createdAt,
    this.paymentDeadline,
    this.lateFee = 0,
  });

  factory ParkingTicket.fromJson(Map<String, dynamic> json) => ParkingTicket(

    id: json['id'],
    userId: json['userId'],
    spotId: json['spotId'],  // može biti null
    spotNumber: json['spotNumber'] ?? '',  // default prazan string
    lotName: json['lotName'] ?? '',
    lotAddress: json['lotAddress'] ?? '',
    licensePlate: json['licensePlate'],
    entryTime: DateTime.parse(json['entryTime']),
    exitTime: json['exitTime'] != null ? DateTime.parse(json['exitTime']) : null,
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    totalPrice: json['totalPrice'] != null ? (json['totalPrice'] as num).toDouble() : null,
    //status: json['status'].toString(),
    status: _statusFromInt(json['status']),
    createdAt: DateTime.parse(json['createdAt']),
    paymentDeadline: json['paymentDeadline'] != null ? DateTime.parse(json['paymentDeadline']) : null,
    lateFee: json['lateFee'] != null ? (json['lateFee'] as num).toDouble() : 0,
  );

  static String _statusFromInt(dynamic status) {
    switch (status.toString()) {
      case '0': return 'active';
      case '1': return 'pendingpayment';
      case '2': return 'paid';
      case '3': return 'disputed';
      case '4': return 'closed';
      default: return status.toString();
    }
  }
}