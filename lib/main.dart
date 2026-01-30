import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'config/supabase_config.dart';
import 'front_page.dart';
import 'about_app.dart';
import 'about_us.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'email_confirm_page.dart';
import 'reset_password_page.dart';
import 'screens/app_opening.dart';
import 'dashboards/volunteers/volunteer_home_page.dart';
import 'auth/auth_session_holder.dart';
import 'services/verification_stream.dart';
import 'services/supabase_service.dart';
import 'enduser_type_selection.dart';
import 'volunteer_type_selection.dart';

// Global navigator key for deep link navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Handle deep links for email confirmation and OAuth (mobile only)
  if (!kIsWeb) {
    final appLinks = AppLinks();

    // Helper function to handle deep link navigation
    Future<void> handleDeepLink(Uri uri) async {
      debugPrint('=== Deep link received: ${uri.toString()} ===');

      // Check if the URL actually contains Supabase auth parameters
      final hasAuthParams =
          uri.fragment.contains('access_token') ||
          uri.fragment.contains('refresh_token') ||
          uri.queryParameters.containsKey('code') ||
          uri.queryParameters.containsKey('access_token');

      // Handle email confirmation: let SupabaseFlutter process the session,
      // we only take care of navigation.
      if (uri.toString().contains('email-confirm')) {
        debugPrint('Processing email-confirm deep link');
        
        // Notify the stream that verification is likely successful (or processing)
        VerificationStream().add(VerificationEvent.verified);
        
        if (!hasAuthParams) {
          debugPrint(
            'Email-confirm deep link without auth params (likely already handled), navigating only.',
          );
        }

        // We comment out the navigation to /email-confirm because the SignupPage 
        // is listening to the stream and will update its state in-place.
        // This allows the user to stay on the signup page and see the "Verified" button.
        
        /*
        // Wait a bit to ensure navigator is ready
        await Future.delayed(const Duration(milliseconds: 100));
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/email-confirm',
          (route) => false,
        );
        debugPrint('Navigated to /email-confirm');
        */
      }
      // Handle "Not Me" / Reject link
      else if (uri.toString().contains('signup-reject')) {
        debugPrint('Processing signup-reject deep link');
        VerificationStream().add(VerificationEvent.rejected);
        // Bring app to foreground (handled by OS), no nav needed.
        return;
      }
      // Handle password reset: let SupabaseFlutter process the session,
      // we only take care of navigation.
      else if (uri.toString().contains('reset-password')) {
        debugPrint('Processing reset-password deep link');
        if (!hasAuthParams) {
          debugPrint(
            'Reset-password deep link without auth params (likely already handled), navigating only.',
          );
        }
        // Process the session from URL if it has auth params
        if (hasAuthParams) {
          try {
            debugPrint('Processing session from URL...');
            await Supabase.instance.client.auth.getSessionFromUrl(uri);
            debugPrint('Session processed successfully');
          } catch (e) {
            debugPrint('Error processing reset password session: $e');
          }
        }
        // Wait a bit to ensure navigator is ready
        await Future.delayed(const Duration(milliseconds: 100));
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/reset-password',
          (route) => false,
        );
        debugPrint('Navigated to /reset-password');
      }
      // Handle OAuth callbacks: Process the session from URL and navigate
      else if (uri.toString().contains('login-callback')) {
        debugPrint('Processing login-callback deep link');

        // ✅ DO NOT process session manually
        // SupabaseFlutter automatically handles OAuth deep links
        // Navigation will happen via onAuthStateChange listener

        return;
      }
    }

    // Handle initial link (when app is opened from a link)
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint(
          '=== Initial deep link detected: ${initialUri.toString()} ===',
        );
        // Wait for app to be fully initialized
        await Future.delayed(const Duration(milliseconds: 500));
        await handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen for deep links when app is already running
    appLinks.uriLinkStream.listen((uri) async {
      await handleDeepLink(uri);
    });
  }

  // Handle web OAuth callbacks and password reset
  if (kIsWeb) {
    // Check if there's an OAuth callback or password reset in the URL
    final uri = Uri.base;
    debugPrint('Web URL at startup: ${uri.toString()}');
    if (uri.hasFragment &&
        (uri.fragment.contains('access_token') ||
            uri.fragment.contains('error') ||
            uri.fragment.contains('type=recovery'))) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        // Check if it's a password reset link
        if (uri.fragment.contains('type=recovery') ||
            uri.toString().contains('reset-password')) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/reset-password',
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Error handling web callback: $e');
      }
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) return;

      // Store session globally
      AuthSessionHolder.session = session;

      // Check role and navigate
      _checkUserRoleAndNavigate(session.user);
    });
  }

  Future<void> _checkUserRoleAndNavigate(User user) async {
    try {
      final userData = await SupabaseService.getUserFromUsersTable();
      if (userData == null || userData['role'] == null) {
        // New user or missing role - redirect to selection
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/end-user-type-selection',
          (route) => false,
        );
      } else {
        // Existing user with role
        final role = userData['role'];
        if (role == 'volunteer') {
          // Check if volunteer has selected their type
          if (userData['volunteer_type'] == null) {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/volunteer-type-selection',
              (route) => false,
            );
          } else {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/volunteer-dashboard',
              (route) => false,
            );
          }
        } else if (role == 'organizer') {
          // Placeholder for organizer dashboard
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/volunteer-dashboard', // Change when organizer dashboard exists
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/opening',
      // initialRoute: '/volunteer-dashboard',
      routes: {
        '/': (context) => FrontPage(),
        '/opening': (context) => AppOpeningPage(),
        '/aboutApp': (context) => AboutAppPage(),
        '/aboutUs': (context) => AboutUsPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/email-confirm': (context) => const EmailConfirmPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/end-user-type-selection': (context) => const EndUserTypeSelectionPage(),
        '/volunteer-type-selection': (context) => const VolunteerTypeSelectionPage(),

        // ✅ ADD YOUR DASHBOARD ROUTES
        '/volunteer-dashboard': (context) => const VolunteerHomePage(),
        // '/event-dashboard': (context) =>
        //     const EventDashboardPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/email-confirm' ||
            (settings.name?.contains('email-confirm') ?? false)) {
          return MaterialPageRoute(
            builder: (context) => const EmailConfirmPage(),
          );
        }
        if (settings.name == '/reset-password' ||
            (settings.name?.contains('reset-password') ?? false)) {
          return MaterialPageRoute(
            builder: (context) => const ResetPasswordPage(),
          );
        }
        return null;
      },
    );
  }
}
