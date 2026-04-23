import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class PaymentService {
  final Dio _dio = DioClient.instance;

  Future<void> payTicket({
    required String userId,
    required String ticketId,
    required double amount,
  }) async {
    // 1. Kreiraj payment intent
    final response = await _dio.post(
      '${ApiConstants.paymentServiceBase}/api/ParkingPayment/create',
      data: {
        'userId': userId,
        'ticketId': ticketId,
        'amount': amount,
        'method': 0,
      },
    );

    final paymentId = response.data['id'];
    final clientSecret = response.data['stripeClientSecret'];

    // 2. Prikaži Stripe payment sheet samo na mobilnom
    if (!kIsWeb) {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'ParkSmart',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    }

    // 3. Potvrdi plaćanje
    await _dio.patch(
      '${ApiConstants.paymentServiceBase}/api/ParkingPayment/$paymentId/complete',
    );
  }

  Future<void> payViolation({
    required String userId,
    required String violationId,
    required double amount,
  }) async {
    // 1. Kreiraj payment intent
    final response = await _dio.post(
      '${ApiConstants.paymentServiceBase}/api/ViolationPayment/create',
      data: {
        'userId': userId,
        'violationId': violationId,
        'amount': amount,
      },
    );

    final paymentId = response.data['id'];
    final clientSecret = response.data['stripeClientSecret'];

    // 2. Prikaži Stripe payment sheet samo na mobilnom
    if (!kIsWeb) {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'ParkSmart',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    }

    // 3. Potvrdi plaćanje
    await _dio.patch(
      '${ApiConstants.paymentServiceBase}/api/ViolationPayment/$paymentId/complete',
    );
  }



  Future<void> payReservation({
    required String userId,
    required String reservationId,
    required double amount,
  }) async {
    // 1. Kreiraj payment intent
    final response = await _dio.post(
      '${ApiConstants.paymentServiceBase}/api/ReservationPayment/create',
      data: {
        'userId': userId,
        'reservationId': reservationId,
        'amount': amount,
        'method': 0,
      },
    );

    final paymentId = response.data['id'];
    final clientSecret = response.data['stripeClientSecret'];

    // 2. Prikaži Stripe payment sheet
    if (!kIsWeb) {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'ParkSmart',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    }

    // 3. Potvrdi plaćanje
    await _dio.patch(
      '${ApiConstants.paymentServiceBase}/api/ReservationPayment/$paymentId/complete',
    );
  }



}


