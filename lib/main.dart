import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'config/supabase_config.dart';
import 'front_page.dart';
import 'about_app.dart';
import 'about_us.dart';
import 'login_page.dart';
import 'email_confirm_page.dart';

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
    appLinks.uriLinkStream.listen((uri) async {
      // Log every deep link we receive for debugging
      debugPrint('Deep link received: ${uri.toString()}');

      // Check if the URL actually contains Supabase auth parameters
      final hasAuthParams =
          uri.fragment.contains('access_token') ||
          uri.fragment.contains('refresh_token') ||
          uri.queryParameters.containsKey('code') ||
          uri.queryParameters.containsKey('access_token');

      // Handle email confirmation: let SupabaseFlutter process the session,
      // we only take care of navigation.
      if (uri.toString().contains('email-confirm')) {
        if (!hasAuthParams) {
          debugPrint(
              'Email-confirm deep link without auth params (likely already handled), navigating only. uri=$uri');
        }
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/email-confirm',
          (route) => false,
        );
      }
      // Handle OAuth callbacks: SupabaseFlutter already calls getSessionFromUrl
      // for magic links and OAuth; we just navigate to the login page.
      else if (uri.toString().contains('login-callback')) {
        if (!hasAuthParams) {
          debugPrint(
              'OAuth login-callback deep link without auth params (likely already handled), navigating only. uri=$uri');
        }
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    });
  }
  
  // Handle web OAuth callbacks
  if (kIsWeb) {
    // Check if there's an OAuth callback in the URL
    final uri = Uri.base;
    debugPrint('Web URL at startup: ${uri.toString()}');
    if (uri.hasFragment && (uri.fragment.contains('access_token') || uri.fragment.contains('error'))) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (e) {
        debugPrint('Error handling web OAuth callback: $e');
      }
    }
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => FrontPage(),
        '/aboutApp': (context) => AboutAppPage(),
        '/aboutUs': (context) => AboutUsPage(),
        '/login': (context) => LoginPage(),
        '/email-confirm': (context) => const EmailConfirmPage(),
      },
      // Handle initial deep link
      onGenerateRoute: (settings) {
        if (settings.name == '/email-confirm' || 
            (settings.name?.contains('email-confirm') ?? false)) {
          return MaterialPageRoute(
            builder: (context) => const EmailConfirmPage(),
          );
        }
        return null;
      },
    );
  }
}

