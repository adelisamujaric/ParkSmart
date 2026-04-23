class ViolationsReportDto {
  final int totalViolations;
  final double totalFinesAmount;
  final double collectedFinesAmount;
  final List<ViolationsByTypeDto> violationsByType;
  final List<ViolationsByDayDto> violationsByDay;

  ViolationsReportDto({
    required this.totalViolations,
    required this.totalFinesAmount,
    required this.collectedFinesAmount,
    required this.violationsByType,
    required this.violationsByDay,
  });

  factory ViolationsReportDto.fromJson(Map<String, dynamic> json) => ViolationsReportDto(
    totalViolations: json['totalViolations'],
    totalFinesAmount: (json['totalFinesAmount'] as num).toDouble(),
    collectedFinesAmount: (json['collectedFinesAmount'] as num).toDouble(),
    violationsByType: (json['violationsByType'] as List)
        .map((e) => ViolationsByTypeDto.fromJson(e)).toList(),
    violationsByDay: (json['violationsByDay'] as List)
        .map((e) => ViolationsByDayDto.fromJson(e)).toList(),
  );
}

class ViolationsByTypeDto {
  final String violationType;
  final int count;
  final double totalFineAmount;

  ViolationsByTypeDto({required this.violationType, required this.count, required this.totalFineAmount});

  factory ViolationsByTypeDto.fromJson(Map<String, dynamic> json) => ViolationsByTypeDto(
    violationType: json['violationType'],
    count: json['count'],
    totalFineAmount: (json['totalFineAmount'] as num).toDouble(),
  );
}

class ViolationsByDayDto {
  final DateTime date;
  final int count;
  final double totalFineAmount;

  ViolationsByDayDto({required this.date, required this.count, required this.totalFineAmount});

  factory ViolationsByDayDto.fromJson(Map<String, dynamic> json) => ViolationsByDayDto(
    date: DateTime.parse(json['date']),
    count: json['count'],
    totalFineAmount: (json['totalFineAmount'] as num).toDouble(),
  );
}