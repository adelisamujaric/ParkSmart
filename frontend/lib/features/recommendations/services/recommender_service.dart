import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/recommendation.dart';

class RecommenderService {
  final Dio _dio = DioClient.instance;

  Future<List<Recommendation>> getRecommendations(String userId) async {
    final response = await _dio.get(
      '${ApiConstants.recommenderServiceBase}/recommend/$userId',
    );
    final data = response.data['recommendations'] as List;
    return data.map((e) => Recommendation.fromJson(e)).toList();
  }
}