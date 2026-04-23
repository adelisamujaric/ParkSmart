import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/user_profile.dart';

class ProfileService {
  final Dio _dio = DioClient.instance;

  Future<UserProfile> getProfile(String userId) async {
    final response = await _dio.get('${ApiConstants.userServiceBase}/api/users/$userId');
    return UserProfile.fromJson(response.data);
  }

  Future<UserProfile> updateProfile(String userId, {
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    String? city,
    String? postalCode,
    String? country,
    bool? isDisabled,
  }) async {
    final response = await _dio.put(
      '${ApiConstants.userServiceBase}/api/users/update/$userId',
      data: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (postalCode != null) 'postalCode': postalCode,
        if (country != null) 'country': country,
        if (isDisabled != null) 'isDisabled': isDisabled,
      },
    );
    return UserProfile.fromJson(response.data);
  }
}