class RevenueReportDto {
  final double totalRevenue;
  final double ticketRevenue;
  final double reservationRevenue;
  final List<RevenueByLotDto> revenueByLot;
  final List<RevenueByDayDto> revenueByDay;

  RevenueReportDto({
    required this.totalRevenue,
    required this.ticketRevenue,
    required this.reservationRevenue,
    required this.revenueByLot,
    required this.revenueByDay,
  });

  factory RevenueReportDto.fromJson(Map<String, dynamic> json) => RevenueReportDto(
    totalRevenue: (json['totalRevenue'] as num).toDouble(),
    ticketRevenue: (json['ticketRevenue'] as num).toDouble(),
    reservationRevenue: (json['reservationRevenue'] as num).toDouble(),
    revenueByLot: (json['revenueByLot'] as List)
        .map((e) => RevenueByLotDto.fromJson(e)).toList(),
    revenueByDay: (json['revenueByDay'] as List)
        .map((e) => RevenueByDayDto.fromJson(e)).toList(),
  );
}

class RevenueByLotDto {
  final String lotId;
  final String lotName;
  final double ticketRevenue;
  final double reservationRevenue;
  final double totalRevenue;

  RevenueByLotDto({required this.lotId, required this.lotName, required this.ticketRevenue, required this.reservationRevenue, required this.totalRevenue});

  factory RevenueByLotDto.fromJson(Map<String, dynamic> json) => RevenueByLotDto(
    lotId: json['lotId'],
    lotName: json['lotName'],
    ticketRevenue: (json['ticketRevenue'] as num).toDouble(),
    reservationRevenue: (json['reservationRevenue'] as num).toDouble(),
    totalRevenue: (json['totalRevenue'] as num).toDouble(),
  );
}

class RevenueByDayDto {
  final DateTime date;
  final double ticketRevenue;
  final double reservationRevenue;
  final double totalRevenue;

  RevenueByDayDto({required this.date, required this.ticketRevenue, required this.reservationRevenue, required this.totalRevenue});

  factory RevenueByDayDto.fromJson(Map<String, dynamic> json) => RevenueByDayDto(
    date: DateTime.parse(json['date']),
    ticketRevenue: (json['ticketRevenue'] as num).toDouble(),
    reservationRevenue: (json['reservationRevenue'] as num).toDouble(),
    totalRevenue: (json['totalRevenue'] as num).toDouble(),
  );
}