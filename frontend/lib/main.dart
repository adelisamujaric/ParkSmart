import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/constants/api_constants.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/verify_email_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/mobile_home_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/parking/models/parking_lot.dart';
import 'features/parking/screens/mobile _parking_details_screen.dart';
import 'features/parking/screens/mobile_my_parkings_screen.dart';
import 'features/payment/screens/payments_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'features/profile/screens/profile_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Stripe samo na mobilnom, ne na webu ni Windowsu
  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
    Stripe.publishableKey = ApiConstants.stripePublishableKey;
    await Stripe.instance.applySettings();
  }
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        //------------------admin--------------------------
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/verify-email': (context) => VerifyEmailScreen(email: ModalRoute.of(context)!.settings.arguments as String),
        '/admin': (context) => const AdminDashboardScreen(),

        //------------user--------------------------------------
        '/home': (context) => const HomeScreen(),
        '/parking-details': (context) => ParkingDetailsScreen(
          lot: ModalRoute.of(context)!.settings.arguments as ParkingLot,
        ),
        '/my-parkings': (context) => const MyParkingsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/payments': (context) => const PaymentsScreen(),
        '/profile': (context) => const ProfileScreen(),

        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),


      },
    );
  }
}