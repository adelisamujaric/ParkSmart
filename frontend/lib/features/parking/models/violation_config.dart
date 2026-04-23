class ViolationConfig {
  final String id;
  final String typeName;
  final String description;
  final double fineAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ViolationConfig({
    required this.id,
    required this.typeName,
    required this.description,
    required this.fineAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ViolationConfig.fromJson(Map<String, dynamic> json) {
    return ViolationConfig(
      id: json['id'],
      typeName: json['typeName'],
      description: json['description'],
      fineAmount: (json['fineAmount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}