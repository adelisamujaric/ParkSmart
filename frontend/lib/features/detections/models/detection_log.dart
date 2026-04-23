class DetectionLog {
  final String id;
  final String lotId;
  final String lotName;
  final String? spotId;
  final String detectionCameraType;
  final String licensePlate;
  final String result;
  final String status;
  final String? imageUrl;
  final String? reviewNote;
  final DateTime? reviewedAt;
  final DateTime detectedAt;
  final int? droneNumber;
  final int? cameraNumber;
  final String? violationType;
  final String? violationConfigId; // NOVO

  DetectionLog({
    required this.id,
    required this.lotId,
    required this.lotName,
    this.spotId,
    required this.detectionCameraType,
    required this.licensePlate,
    required this.result,
    required this.status,
    this.imageUrl,
    this.reviewNote,
    this.reviewedAt,
    required this.detectedAt,
    this.droneNumber,
    this.cameraNumber,
    this.violationType,
    this.violationConfigId,
  });

  factory DetectionLog.fromJson(Map<String, dynamic> json) => DetectionLog(
    id: json['id'],
    lotId: json['lotId'],
    lotName: json['lotName'] ?? '',
    spotId: json['spotId'],
    detectionCameraType: json['detectionCameraType'],
    licensePlate: json['licensePlate'],
    result: json['result'],
    status: json['status'],
    imageUrl: json['imageUrl'],
    reviewNote: json['reviewNote'],
    reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
    detectedAt: DateTime.parse(json['detectedAt']),
    droneNumber: json['droneNumber'],
    cameraNumber: json['cameraNumber'],
    violationType: json['violationType'],
    violationConfigId: json['violationConfigId'],
  );
}