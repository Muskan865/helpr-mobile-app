import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/worker_dashboard.dart';
import 'screens/requester_dashboard.dart';
import 'screens/worker_profile_screen.dart';
import 'screens/worker_profile_completion_screen.dart';
import 'screens/requester_profile_completion_screen.dart';
import 'screens/requester_profile_screen.dart';
import 'screens/post_request_screen.dart';
import 'screens/received_bids_screen.dart';
import 'screens/requester_active_jobs_screen.dart';
import 'screens/requester_job_history_screen.dart';
import 'screens/worker_public_profile_screen.dart';
import 'screens/rating_review_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0.5,
          shadowColor: Colors.grey.shade200,
          centerTitle: true,
          titleTextStyle: GoogleFonts.nunito(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/resetPassword': (context) => const ResetPasswordScreen(),

        // DASHBOARDS
        '/workerDashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final userId = args?['userId'];
          return WorkerDashboard(userId: userId);
        },

        '/requesterDashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final userId = args?['userId'];
          return RequesterDashboard(userId: userId);
        },

        // WORKER FLOW
        '/workerProfile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final userId = args?['userId'] ?? 0;
          return WorkerProfileScreen(userId: userId);
        },

        '/workerProfileCompletion': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final userId = args?['userId'] ?? 0;
          return WorkerProfileCompletionScreen(userId: userId);
        },

        // REQUESTER FLOW
        '/requesterProfileCompletion': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final userId = args?['userId'] ?? 0;
          return RequesterProfileCompletionScreen(userId: userId);
        },

        '/requesterProfile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final userId = args?['userId'] ?? 0;
          return RequesterProfileScreen(userId: userId);
        },
        '/postRequest': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final requesterId = args?['requesterId'] ?? 0;
          return PostRequestScreen(requesterId: requesterId);
        },
 
        '/receivedBids': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final requesterId = args?['requesterId'] ?? 0;
          return ReceivedBidsScreen(requesterId: requesterId);
        },
 
        '/requesterActiveJobs': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final requesterId = args?['requesterId'] ?? 0;
          return RequesterActiveJobsScreen(requesterId: requesterId);
        },
 
        '/requesterJobHistory': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final requesterId = args?['requesterId'] ?? 0;
          return RequesterJobHistoryScreen(requesterId: requesterId);
        },
 
        '/workerPublicProfile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final workerId = args?['workerId'] ?? 0;
          return WorkerPublicProfileScreen(workerId: workerId);
        },
 
        '/ratingReview': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          return RatingReviewScreen(
            reviewerId: args?['reviewerId'] ?? 0,
            revieweeId: args?['revieweeId'] ?? 0,
            workerName: args?['workerName'] ?? "Worker",
            jobId: args?['jobId'] ?? 0,
            profession: args?['profession'] ?? "",
          );
        },
      },
    );
  }
}
