class Recommendation {
  final String lotId;
  final String lotName;
  final double ratePerMinute;
  final int availableSpots;
  final int totalSpots;
  final double occupancyRate;
  final double score;
  final String reason;
  final int type;

  Recommendation({
    required this.lotId,
    required this.lotName,
    required this.ratePerMinute,
    required this.availableSpots,
    required this.totalSpots,
    required this.occupancyRate,
    required this.score,
    required this.reason,
    required this.type,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
    lotId: json['lot_id'],
    lotName: json['lot_name'],
    ratePerMinute: (json['rate_per_minute'] as num).toDouble(),
    availableSpots: json['available_spots'],
    totalSpots: json['total_spots'],
    occupancyRate: (json['occupancy_rate'] as num).toDouble(),
    score: (json['score'] as num).toDouble(),
    reason: json['reason'],
    type: (json['type'] as int?) ?? 0,
  );
}