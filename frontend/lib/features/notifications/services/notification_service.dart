import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/notification.dart';

class NotificationService {
  final Dio _dio = DioClient.instance;

  Future<List<NotificationModel>> getByUserId(String userId) async {
    final response = await _dio.get(
      '${ApiConstants.notificationServiceBase}/api/Notification/user/$userId',
    );
    final data = response.data as List;
    return data.map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch(
      '${ApiConstants.notificationServiceBase}/api/Notification/$id/read',
    );
  }
}