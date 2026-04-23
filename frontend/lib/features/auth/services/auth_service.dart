import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/user.dart';
import '../models/vehicle_with_owner.dart';

class AuthService {
  final Dio _dio = DioClient.instance;
//-------------------------------------------------------------
  Future<void> register(RegisterRequest request) async {
    try {
      await _dio.post(
        ApiConstants.register,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ??
          e.response?.data?['title'] ??
          'Registracija neuspješna.';
      throw Exception(message);
    }
  }
//-------------------------------------------------------------
  Future<AuthResponse> login(LoginRequest request) async {
    print('Login URL: ${ApiConstants.login}');
    print('UserServiceBase: ${ApiConstants.userServiceBase}');
    final response = await _dio.post(
      ApiConstants.login,
      data: request.toJson(),
    );

    final authResponse = AuthResponse.fromJson(response.data);

    await TokenStorage.saveToken(authResponse.token);
    await TokenStorage.saveRole(authResponse.user.role);
    await TokenStorage.saveUserId(authResponse.user.id);
    await TokenStorage.saveFirstName(authResponse.user.firstName);

    return authResponse;
  }

//-------------------------------------------------------------

  Future<bool> checkEmailVerified(String email) async {
    final response = await _dio.get(
      ApiConstants.verifyStatus,
      queryParameters: {'email': email},
    );
    return response.data['isEmailVerified'] as bool;
  }
//-------------------------------------------------------------

  Future<VehicleWithOwnerResponse?> getVehicleByLicensePlate(String licensePlate) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.userServiceBase}/api/vehicles/by-license/$licensePlate',
      );
      return VehicleWithOwnerResponse.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
//-------------------------------------------------------------

  Future<List<UserModel>> getAllUsers() async {
    final response = await _dio.get(
      '${ApiConstants.userServiceBase}/api/users/all',
      queryParameters: {'page': 1, 'pageSize': 100},
    );
    final data = response.data['data'] ?? response.data['items'];
    if (data == null) return [];
    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }
//-------------------------------------------------------------

  Future<void> deleteUser(String id) async {
    await _dio.delete('${ApiConstants.userServiceBase}/api/users/delete/$id');
  }
//-------------------------------------------------------------
  Future<void> forgotPassword(String email) async {
    await _dio.post(
      '${ApiConstants.userServiceBase}/api/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post(
      '${ApiConstants.userServiceBase}/api/auth/reset-password',
      data: {
        'token': token,
        'newPassword': newPassword,
      },
    );
  }


}