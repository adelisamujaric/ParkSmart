import 'package:dio/dio.dart';
import '../models/vehicle_profil.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class VehicleService {
  final Dio _dio = DioClient.instance;

  Future<List<Vehicle>> getVehiclesByUser(String userId) async {
    final response = await _dio.get(
      '${ApiConstants.userServiceBase}/api/vehicles/user/$userId',
    );
    return (response.data as List)
        .map((v) => Vehicle.fromJson(v))
        .toList();
  }

  Future<Vehicle> addVehicle({
    required String licensePlate,
    required String brand,
    required String model,
    required String userId,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.userServiceBase}/api/vehicles/add',
      data: {
        'licensePlate': licensePlate,
        'brand': brand,
        'model': model,
        'userId': userId,
      },
    );
    return Vehicle.fromJson(response.data);
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await _dio.delete(
      '${ApiConstants.userServiceBase}/api/vehicles/delete/$vehicleId',
    );
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final response = await _dio.get(
      '${ApiConstants.userServiceBase}/api/vehicles/all',
      queryParameters: {'page': 1, 'pageSize': 1000},
    );
    final data = response.data['data'] ?? response.data['items'];
    if (data == null) return [];
    return (data as List).map((v) => Vehicle.fromJson(v)).toList();
  }
}