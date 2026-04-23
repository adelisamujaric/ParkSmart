class NotificationModel {
  final String id;
  final String title;
  final String message;
  final int type;
  final int status;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'],
    title: json['title'],
    message: json['message'],
    type: json['type'],
    status: json['status'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  bool get isRead => status == 3;
}