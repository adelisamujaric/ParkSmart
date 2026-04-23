import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/detection_log.dart';
import '../models/drone.dart';
import '../models/camera.dart';

class DetectionService {
  final Dio _dio = DioClient.instance;

  Future<List<DetectionLog>> getPendingReviews() async {
    final response = await _dio.get('${ApiConstants.detectionServiceBase}/api/detection/pending');
    return (response.data as List)
        .map((e) => DetectionLog.fromJson(e))
        .toList();
  }
  //---------------------------------------------------------------------------------------------------
  Future<List<Drone>> getDrones() async {
    final response = await _dio.get('${ApiConstants.detectionServiceBase}/api/drone');
    return (response.data as List)
        .map((e) => Drone.fromJson(e))
        .toList();
  }
  //---------------------------------------------------------------------------------------------------

  Future<List<Camera>> getCameras() async {
    final response = await _dio.get('${ApiConstants.detectionServiceBase}/api/camera');
    return (response.data as List)
        .map((e) => Camera.fromJson(e))
        .toList();
  }
  //---------------------------------------------------------------------------------------------------

  Future<void> updateDroneStatus(String droneId, int status) async {
    await _dio.put(
      '${ApiConstants.detectionServiceBase}/api/drone/$droneId/status',
      data: status,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }
  //---------------------------------------------------------------------------------------------------

  Future<void> updateCameraStatus(String cameraId, int status) async {
    await _dio.put(
      '${ApiConstants.detectionServiceBase}/api/camera/$cameraId/status',
      data: status,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }
  //---------------------------------------------------------------------------------------------------

  Future<void> createDrone(Map<String, dynamic> data) async {
    await _dio.post(
      '${ApiConstants.detectionServiceBase}/api/drone',
      data: data,
    );
  }
  //---------------------------------------------------------------------------------------------------

  Future<void> createCamera(Map<String, dynamic> data) async {
    await _dio.post(
      '${ApiConstants.detectionServiceBase}/api/camera',
      data: data,
    );
  }
  //---------------------------------------------------------------------------------------------------

  Future<void> reviewDetection(String logId, bool confirmed, String? reviewNote) async {
    await _dio.put(
      '${ApiConstants.detectionServiceBase}/api/detection/review/$logId',
      data: {
        'confirmed': confirmed,
        'reviewNote': reviewNote,
      },
    );
  }


//---------------------------------------------------------------------------------------------------
  Future<List<DetectionLog>> getAllLogs() async {
    final response = await _dio.get('${ApiConstants.detectionServiceBase}/api/detection/all');
    return (response.data as List)
        .map((e) => DetectionLog.fromJson(e))
        .toList();
  }

  Future<void> createManualLog(Map<String, dynamic> data) async {
    await _dio.post(
      '${ApiConstants.detectionServiceBase}/api/detection/manual',
      data: data,
    );
  }
}