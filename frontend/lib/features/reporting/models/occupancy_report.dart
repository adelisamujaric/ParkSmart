class OccupancyReportDto {
  final double averageOccupancyRate;
  final List<OccupancyByHourDto> occupancyByHour;
  final List<OccupancyByLotDto> occupancyByLot;

  OccupancyReportDto({
    required this.averageOccupancyRate,
    required this.occupancyByHour,
    required this.occupancyByLot,
  });

  factory OccupancyReportDto.fromJson(Map<String, dynamic> json) => OccupancyReportDto(
    averageOccupancyRate: (json['averageOccupancyRate'] as num).toDouble(),
    occupancyByHour: (json['occupancyByHour'] as List)
        .map((e) => OccupancyByHourDto.fromJson(e)).toList(),
    occupancyByLot: (json['occupancyByLot'] as List)
        .map((e) => OccupancyByLotDto.fromJson(e)).toList(),
  );
}

class OccupancyByHourDto {
  final int hour;
  final int activeTickets;
  final double occupancyRate;

  OccupancyByHourDto({required this.hour, required this.activeTickets, required this.occupancyRate});

  factory OccupancyByHourDto.fromJson(Map<String, dynamic> json) => OccupancyByHourDto(
    hour: json['hour'],
    activeTickets: json['activeTickets'],
    occupancyRate: (json['occupancyRate'] as num).toDouble(),
  );
}

class OccupancyByLotDto {
  final String lotId;
  final String lotName;
  final int totalSpots;
  final double averageOccupancyRate;

  OccupancyByLotDto({required this.lotId, required this.lotName, required this.totalSpots, required this.averageOccupancyRate});

  factory OccupancyByLotDto.fromJson(Map<String, dynamic> json) => OccupancyByLotDto(
    lotId: json['lotId'],
    lotName: json['lotName'],
    totalSpots: json['totalSpots'],
    averageOccupancyRate: (json['averageOccupancyRate'] as num).toDouble(),
  );
}