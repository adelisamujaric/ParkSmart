import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/parking_lot.dart';
import '../models/parking_reservations.dart';
import '../models/parking_violation.dart';
import '../models/parking_ticket.dart';
import '../models/parking_spot.dart';

class ParkingLotService {
  final Dio _dio = DioClient.instance;
//--------------------------------------------------------------------------------------

  Future<List<ParkingLot>> getAll() async {
    final response = await _dio.get(
      '${ApiConstants.parkingServiceBase}/parkingLot/ParkingLot/getAll',
    );
    final data = response.data['data'];
    if (data == null) return [];
    return (data as List)
        .map((e) => ParkingLot.fromJson(e))
        .toList();
  }
//--------------------------------------------------------------------------------------
  Future<ParkingViolation?> getLatestViolationByPlate(String licensePlate) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.parkingServiceBase}/api/Violation/by-plate',
        queryParameters: {'licensePlate': licensePlate, 'page': 1, 'pageSize': 1},
      );
      final data = response.data['data'] as List;
      if (data.isEmpty) return null;
      return ParkingViolation.fromJson(data.first);
    } catch (e) {
      return null;
    }
  }
//--------------------------------------------------------------------------------------
  Future<List<ParkingTicket>> getAllTickets() async {
    final response = await _dio.get(
      '${ApiConstants.parkingServiceBase}/api/ParkingTicket/getAll',
    );
    return (response.data['data'] as List)
        .map((e) => ParkingTicket.fromJson(e))
        .toList();
  }
//--------------------------------------------------------------------------------------
  Future<List<ParkingSpot>> getSpotsByLotId(String lotId) async {
    final response = await _dio.get(
      '${ApiConstants.parkingServiceBase}/parkingSpot/ParkingSpot/getLotById/$lotId',
      queryParameters: {'page': 1, 'pageSize': 100},
    );
    final data = response.data['data'];
    if (data == null) return [];
    return (data as List).map((e) => ParkingSpot.fromJson(e)).toList();
  }
//--------------------------------------------------------------------------------------

  Future<void> updateLot(String id, Map<String, dynamic> data) async {
    await _dio.put(
      '${ApiConstants.parkingServiceBase}/parkingLot/ParkingLot/update$id',
      data: data,
    );
  }
//--------------------------------------------------------------------------------------

  Future<void> deleteLot(String id) async {
    await _dio.delete(
      '${ApiConstants.parkingServiceBase}/parkingLot/ParkingLot/delete$id',
    );
  }
//--------------------------------------------------------------------------------------

  Future<ParkingLot> createLot(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${ApiConstants.parkingServiceBase}/parkingLot/ParkingLot/create',
      data: data,
    );
    return ParkingLot.fromJson(response.data['data']);
  }
//--------------------------------------------------------------------------------------

  Future<void> updateSpot(String id, Map<String, dynamic> data) async {
    await _dio.put(
      '${ApiConstants.parkingServiceBase}/parkingSpot/ParkingSpot/update$id',
      data: data,
    );
  }
//--------------------------------------------------------------------------------------

  Future<void> deleteSpot(String id) async {
    await _dio.delete(
      '${ApiConstants.parkingServiceBase}/parkingSpot/ParkingSpot/delete$id',
    );
  }
//--------------------------------------------------------------------------------------

  Future<void> createSpot(Map<String, dynamic> data) async {
    await _dio.post(
      '${ApiConstants.parkingServiceBase}/parkingSpot/ParkingSpot/create',
      data: data,
    );
  }
//--------------------------------------------------------------------------------------
  Future<List<ParkingLot>> getAllAdmin() async {
    final response = await _dio.get(
      '${ApiConstants.parkingServiceBase}/parkingLot/ParkingLot/getAllAdmin',
      queryParameters: {'page': 1, 'pageSize': 100},
    );
    final data = response.data['data'];
    if (data == null) return [];
    return (data as List).map((e) => ParkingLot.fromJson(e)).toList();
  }
//--------------------------------------------------------------------------------------
  Future<List<ParkingTicket>> getMyTickets() async {
    final response = await _dio.get(
      '${ApiConstants.parkingServiceBase}/api/ParkingTicket/getMyTicket',
      queryParameters: {'page': 1, 'pageSize': 100},
    );
    final data = response.data['data'];
    if (data == null) return [];
    return (data as List).map((e) => ParkingTicket.fromJson(e)).toList();
  }
//--------------------------------------------------------------------------------------

  Future<List<ParkingReservation>> getMyReservations() async {
    final response = await _dio.get(
      '${ApiConstants.parkingServiceBase}/parkingReservation/Reservation/getMyReservation',
      queryParameters: {'page': 1, 'pageSize': 100},
    );
    final data = response.data['data'];
    if (data == null) return [];
    return (data as List).map((e) => ParkingReservation.fromJson(e)).toList();
  }
//--------------------------------------------------------------------------------------

  Future<List<ParkingViolation>> getViolationsByPlate(String licensePlate) async {
    final response = await _dio.get(
      '${ApiConstants.parkingServiceBase}/api/Violation/by-plate',
      queryParameters: {'licensePlate': licensePlate, 'page': 1, 'pageSize': 100},
    );
    final data = response.data['data'];
    if (data == null) return [];
    return (data as List).map((e) => ParkingViolation.fromJson(e)).toList();
  }
//--------------------------------------------------------------------------------------

  Future<List<ParkingViolation>> getViolationsByUserId(String userId) async {
    final response = await _dio.get(
      '${ApiConstants.parkingServiceBase}/api/Violation/user/$userId',
    );
    final data = response.data;
    if (data == null) return [];
    return (data as List).map((e) => ParkingViolation.fromJson(e)).toList();
  }


}