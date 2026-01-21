import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vol_hub/features/dashboard/presentation/dashboard_screen.dart';
import 'package:vol_hub/features/auth/presentation/login_screen.dart';
import 'package:vol_hub/features/auth/presentation/signup_screen.dart';
import 'package:vol_hub/features/auth/presentation/id_verification_screen.dart';
import 'package:vol_hub/features/auth/presentation/profile_setup_screen.dart';
import 'package:vol_hub/features/teams/presentation/my_teams_screen.dart';
import 'package:vol_hub/features/recruit/presentation/recruit_screen.dart';
import 'package:vol_hub/features/marketplace/presentation/marketplace_screen.dart';
import 'package:vol_hub/features/proposals/presentation/proposals_screen.dart';
import 'package:vol_hub/features/messages/presentation/messages_screen.dart';
import 'package:vol_hub/features/messages/presentation/chat_detail_screen.dart';
import 'package:vol_hub/features/portfolio/presentation/portfolio_screen.dart';
import 'package:vol_hub/features/profile/presentation/profile_screen.dart';
import 'package:vol_hub/features/profile/presentation/edit_profile_screen.dart';
import 'package:vol_hub/main.dart'; 

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/verify-id',
      builder: (context, state) => const IdVerificationScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) => ChatDetailScreen(chatId: state.pathParameters['id']!),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/teams',
          builder: (context, state) => const MyTeamsScreen(),
        ),
        GoRoute(
          path: '/recruit',
          builder: (context, state) => const RecruitScreen(),
        ),
        GoRoute(
          path: '/marketplace',
          builder: (context, state) => const MarketplaceScreen(),
        ),
        GoRoute(
          path: '/proposals',
          builder: (context, state) => const ProposalsScreen(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesScreen(),
        ),
        GoRoute(
          path: '/portfolio',
          builder: (context, state) => const PortfolioScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final firstTime = state.uri.queryParameters['firstTime'] == 'true';
                return EditProfileScreen(firstTime: firstTime);
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
    );
  }
}
