import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/supabase_config.dart';

class SupabaseService {
  // Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  // Get the current user
  static User? get currentUser => client.auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
    String? dob,
    String? userType,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (dob != null && dob.isNotEmpty) 'dob': dob,
          if (userType != null && userType.isNotEmpty) 'user_type': userType,
        },
        emailRedirectTo: 'io.supabase.volhub://email-confirm', // Deep link for email confirmation
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password (send reset email)
  static Future<void> resetPassword(String email) async {
    try {
      // Always use deep link for mobile apps (works on both phone and when code runs on laptop)
      // For web, use the current URL with password-reset path
      String redirectTo;
      if (kIsWeb) {
        // For web, use the current URL with password-reset path
        redirectTo = '${Uri.base.origin}/#/reset-password';
      } else {
        // For mobile (Android/iOS), always use deep link
        // This deep link must be added to Supabase dashboard → Authentication → URL Configuration
        redirectTo = 'io.supabase.volhub://reset-password';
      }
      
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update password (after clicking reset link)
  static Future<void> updatePassword(String newPassword) async {
    try {
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;
      
      final response = await client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      if (currentUser == null) throw Exception('User not logged in');
      
      await client
          .from('profiles')
          .update(updates)
          .eq('id', currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google OAuth
  static Future<bool> signInWithGoogle() async {
    try {
      // Use appropriate redirect URL based on platform
      String redirectTo;
      if (kIsWeb) {
        // For web, use the Supabase callback URL
        // This must match what's configured in Supabase dashboard
        redirectTo = '${SupabaseConfig.supabaseUrl}/auth/v1/callback';
      } else {
        // For mobile, use deep link
        redirectTo = 'io.supabase.volhub://login-callback';
      }
      
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Facebook OAuth
  static Future<bool> signInWithFacebook() async {
    try {
      // Use appropriate redirect URL based on platform
      String redirectTo;
      if (kIsWeb) {
        // For web, use the Supabase callback URL
        // This must match what's configured in Supabase dashboard
        redirectTo = '${SupabaseConfig.supabaseUrl}/auth/v1/callback';
      } else {
        // For mobile, use deep link
        redirectTo = 'io.supabase.volhub://login-callback';
      }
      
      await client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: redirectTo,
        authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Handle OAuth callback (for deep linking)
  static Future<AuthSessionUrlResponse?> handleOAuthCallback(Uri uri) async {
    try {
      final response = await client.auth.getSessionFromUrl(uri);
      return response;
    } catch (e) {
      return null;
    }
  }

  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}

