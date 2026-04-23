import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/violation_config.dart';

class ViolationConfigService {
  final Dio _dio = DioClient.instance;

  Future<List<ViolationConfig>> getAll() async {
    final response = await _dio.get(
      '${ApiConstants.parkingServiceBase}/api/ViolationConfig/getAll',
    );
    final data = response.data['data'];
    if (data == null) return [];
    return (data as List).map((e) => ViolationConfig.fromJson(e)).toList();
  }

  Future<ViolationConfig> create(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${ApiConstants.parkingServiceBase}/api/ViolationConfig/create',
      data: data,
    );
    return ViolationConfig.fromJson(response.data['data']);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _dio.put(
      '${ApiConstants.parkingServiceBase}/api/ViolationConfig/update/$id',
      data: data,
    );
  }

  Future<void> delete(String id) async {
    await _dio.delete(
      '${ApiConstants.parkingServiceBase}/api/ViolationConfig/delete/$id',
    );
  }
}