class Camera {
  final String id;
  final int number;
  final String lotId;
  final String lotName;
  final String cameraType;
  final String status;
  final DateTime createdAt;

  Camera({
    required this.id,
    required this.number,
    required this.lotId,
    required this.lotName,
    required this.cameraType,
    required this.status,
    required this.createdAt,
  });

  factory Camera.fromJson(Map<String, dynamic> json) => Camera(
    id: json['id'],
    number: json['number'],
    lotId: json['lotId'],
    lotName: json['lotName'],
    cameraType: json['cameraType'],
    status: json['status'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}