import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/pages/confirm_email_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/workout/presentation/pages/workout_page.dart';
import '../../features/diet/presentation/pages/diet_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/data/models/profile_model.dart';
import '../../features/ranking/presentation/pages/ranking_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/confirm-email');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login',    builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/confirm-email',
        builder: (_, state) => ConfirmEmailPage(
          email: (state.extra as String?) ?? '',
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) {
          final profile = state.extra as ProfileModel;
          return EditProfilePage(profile: profile);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/workout',   builder: (_, __) => const WorkoutPage()),
          GoRoute(path: '/diet',      builder: (_, __) => const DietPage()),
          GoRoute(path: '/ranking',   builder: (_, __) => const RankingPage()),
          GoRoute(path: '/profile',   builder: (_, __) => const ProfilePage()),
        ],
      ),
    ],
  );
});
