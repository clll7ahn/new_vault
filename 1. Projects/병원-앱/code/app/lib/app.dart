import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'modules/common/appointment/presentation/appointment_list_page.dart';
import 'modules/common/appointment/presentation/booking_page.dart';
import 'modules/common/auth/presentation/login_page.dart';
import 'modules/common/auth/presentation/register_page.dart';
import 'modules/common/auth/providers/auth_provider.dart';
import 'modules/common/home/presentation/home_page.dart';
import 'modules/common/hospital_info/presentation/doctor_list_page.dart';
import 'modules/common/hospital_info/presentation/hospital_info_page.dart';
import 'modules/common/notification/presentation/notification_list_page.dart';
import 'modules/common/notification/providers/notification_provider.dart';
import 'modules/common/chatbot/presentation/chat_page.dart';
import 'modules/common/gamification/presentation/gamification_page.dart';
import 'modules/common/health_tracker/presentation/health_dashboard_page.dart';
import 'modules/common/queue/presentation/queue_status_page.dart';
import 'modules/specialty/pediatrics/presentation/pediatrics_page.dart';
import 'modules/specialty/ophthalmology/presentation/ophthalmology_page.dart';
import 'modules/specialty/dental/presentation/dental_page.dart';
import 'modules/specialty/obstetrics/presentation/obstetrics_page.dart';
import 'modules/specialty/psychiatry/presentation/psychiatry_page.dart';
import 'modules/specialty/internal_medicine/presentation/im_dashboard_page.dart';
import 'modules/specialty/dermatology/presentation/derm_dashboard_page.dart';
import 'modules/specialty/orthopedics/presentation/ortho_dashboard_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authState is AuthLoading) return null; // 로딩 중 리다이렉트 보류
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // ── Home ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // ── Hospital Info ──────────────────────────────────────────────────────
      GoRoute(
        path: '/hospital-info',
        name: 'hospitalInfo',
        builder: (context, state) => const HospitalInfoPage(),
      ),
      GoRoute(
        path: '/doctors',
        name: 'doctors',
        builder: (context, state) => const DoctorListPage(),
      ),

      // ── Queue ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/queue',
        name: 'queue',
        builder: (context, state) => const QueueStatusPage(),
      ),

      // ── Notifications ──────────────────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationListPage(),
      ),

      // ── Chatbot ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) {
          final extra = state.extra;
          String? sessionId;
          if (extra is Map<String, dynamic>) {
            sessionId = extra['sessionId'] as String?;
          }
          return ChatPage(sessionId: sessionId);
        },
      ),

      // ── Gamification ───────────────────────────────────────────────────────
      GoRoute(
        path: '/gamification',
        name: 'gamification',
        builder: (context, state) => const GamificationPage(),
      ),

      // ── Health Tracker ────────────────────────────────────────────────────
      GoRoute(
        path: '/health',
        name: 'health',
        builder: (context, state) => const HealthDashboardPage(),
      ),

      // ── Specialty ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/specialty/pediatrics',
        name: 'specialtyPediatrics',
        builder: (context, state) => const PediatricsPage(),
      ),
      GoRoute(
        path: '/specialty/ophthalmology',
        name: 'specialtyOphthalmology',
        builder: (context, state) => const OphthalmologyPage(),
      ),
      GoRoute(
        path: '/specialty/dental',
        name: 'specialtyDental',
        builder: (context, state) => const DentalPage(),
      ),
      GoRoute(
        path: '/specialty/obstetrics',
        name: 'specialtyObstetrics',
        builder: (context, state) => const ObstetricsPage(),
      ),
      GoRoute(
        path: '/specialty/psychiatry',
        name: 'specialtyPsychiatry',
        builder: (context, state) => const PsychiatryPage(),
      ),
      GoRoute(
        path: '/specialty/internal-medicine',
        name: 'specialtyInternalMedicine',
        builder: (context, state) => const ImDashboardPage(),
      ),
      GoRoute(
        path: '/specialty/dermatology',
        name: 'specialtyDermatology',
        builder: (context, state) => const DermDashboardPage(),
      ),
      GoRoute(
        path: '/specialty/orthopedics',
        name: 'specialtyOrthopedics',
        builder: (context, state) => const OrthoDashboardPage(),
      ),

      // ── Appointment ────────────────────────────────────────────────────────
      GoRoute(
        path: '/appointments',
        name: 'appointments',
        builder: (context, state) => const AppointmentListPage(),
      ),
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) {
          // extra로 {'doctorId': String} 전달 가능
          final extra = state.extra;
          String? doctorId;
          if (extra is Map<String, dynamic>) {
            doctorId = extra['doctorId'] as String?;
          }
          return BookingPage(initialDoctorId: doctorId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('페이지를 찾을 수 없습니다.'),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 52)),
              child: const Text('홈으로'),
            ),
          ],
        ),
      ),
    ),
  );
});

class HospitalApp extends ConsumerWidget {
  const HospitalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '병원 앱',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      // DatePicker 한국어 지원
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
    );
  }
}
