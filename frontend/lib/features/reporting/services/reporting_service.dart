import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/occupancy_report.dart';
import '../models/violations_report.dart';
import '../models/revenue_report.dart';

class ReportingService {
  final Dio _dio = DioClient.instance;

  Future<OccupancyReportDto> getOccupancyReport(DateTime from, DateTime to) async {
    final response = await _dio.get(
      '${ApiConstants.reportingServiceBase}/api/Reports/occupancy',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
    return OccupancyReportDto.fromJson(response.data);
  }
//-------------------------------------------------------------------------------------------
  Future<ViolationsReportDto> getViolationsReport(DateTime from, DateTime to) async {
    final response = await _dio.get(
      '${ApiConstants.reportingServiceBase}/api/Reports/violations',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
    return ViolationsReportDto.fromJson(response.data);
  }
//-------------------------------------------------------------------------------------------

  Future<RevenueReportDto> getRevenueReport(DateTime from, DateTime to) async {
    final response = await _dio.get(
      '${ApiConstants.reportingServiceBase}/api/Reports/revenue',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
    return RevenueReportDto.fromJson(response.data);
  }
//-------------------------------------------------------------------------------------------

  Future<List<int>> downloadPdf(String type, String from, String to) async {
    final response = await _dio.get(
      '${ApiConstants.reportingServiceBase}/api/Reports/$type/pdf',
      queryParameters: {'from': from, 'to': to},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }
//-------------------------------------------------------------------------------------------

}