import 'package:flutter/foundation.dart';

class ApiConstants {
  static const bool _physicalDevice = false;
  static String get _mobileBase => _physicalDevice ? '192.168.178.29' : '10.0.2.2';

  static bool get _isDesktop => !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  // --dart-define vrijednosti (default je localhost sa Docker portovima)
  static const String _userWebUrl = String.fromEnvironment('USER_SERVICE_URL', defaultValue: 'http://localhost:5072');
  static const String _parkingWebUrl = String.fromEnvironment('PARKING_SERVICE_URL', defaultValue: 'http://localhost:5148');
  static const String _paymentWebUrl = String.fromEnvironment('PAYMENT_SERVICE_URL', defaultValue: 'http://localhost:5038');
  static const String _notificationWebUrl = String.fromEnvironment('NOTIFICATION_SERVICE_URL', defaultValue: 'http://localhost:5175');
  static const String _recommenderWebUrl = String.fromEnvironment('RECOMMENDER_SERVICE_URL', defaultValue: 'http://localhost:8001');
  static const String _reportingWebUrl = String.fromEnvironment('REPORTING_SERVICE_URL', defaultValue: 'http://localhost:5113');
  static const String _detectionWebUrl = String.fromEnvironment('DETECTION_SERVICE_URL', defaultValue: 'http://localhost:5164');
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE', defaultValue: '',);


  // UserService
  static String get _userMobile => 'http://$_mobileBase:5072';
  static String get userServiceBase => kIsWeb || _isDesktop ? _userWebUrl : _userMobile;

  // ParkingService
  static String get _parkingMobile => 'http://$_mobileBase:5148';
  static String get parkingServiceBase => kIsWeb || _isDesktop ? _parkingWebUrl : _parkingMobile;

  // PaymentService
  static String get _paymentMobile => 'http://$_mobileBase:5038';
  static String get paymentServiceBase => kIsWeb || _isDesktop ? _paymentWebUrl : _paymentMobile;


  // NotificationService
  static String get _notificationMobile => 'http://$_mobileBase:5175';
  static String get notificationServiceBase => kIsWeb || _isDesktop ? _notificationWebUrl : _notificationMobile;


  // RecommenderService
  static String get _recommenderMobile => 'http://$_mobileBase:8001';
  static String get recommenderServiceBase => kIsWeb || _isDesktop ? _recommenderWebUrl : _recommenderMobile;


  // ReportingService
  static String get _reportingMobile => 'http://$_mobileBase:5113';
  static String get reportingServiceBase => kIsWeb || _isDesktop ? _reportingWebUrl : _reportingMobile;



  // DetectionService
  static String get _detectionMobile => 'http://$_mobileBase:5164';
  static String get detectionServiceBase => kIsWeb || _isDesktop ? _detectionWebUrl : _detectionMobile;


  // Auth endpoints
  static String get login => '$userServiceBase/api/auth/login';
  static String get register => '$userServiceBase/api/auth/register';
  static String get verifyEmail => '$userServiceBase/api/auth/verify-email';
  static String get verifyStatus => '$userServiceBase/api/auth/verify-status';
}


