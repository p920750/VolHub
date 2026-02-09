import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import 'dart:io';

class SupabaseService {
  // Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  // Get the current user
  static User? get currentUser => client.auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  // Insert into public.users (source of truth)
  static Future<void> insertUserIntoUsersTable({
    required String id,
    required String role,
    required String email,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? countryCode,
    bool isEmailVerified = false,
  }) async {
    await client.from('users').insert({
      'id': id,
      'role': role,
      'email': email,
      'full_name': fullName,
      'profile_photo': avatarUrl,
      'phone_number': phone,
      'country_code': countryCode,
      'is_email_verified': isEmailVerified,
    });
  }

  // Read from public.users ONLY
  static Future<Map<String, dynamic>?> getUserFromUsersTable() async {
    if (currentUser == null) return null;

    return await client
        .from('users')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();
  }

  // Update public.users ONLY
  static Future<void> updateUsersTable(Map<String, dynamic> data) async {
    if (currentUser == null) throw Exception('Not authenticated');

    data['updated_at'] = DateTime.now().toIso8601String();

    await client.from('users').update(data).eq('id', currentUser!.id);
  }

  // Sign up with email and password
  // static Future<AuthResponse> signUp({
  //   required String email,
  //   required String password,
  //   String? fullName,
  //   String? phone,
  //   String? dob,
  //   String? userType,
  // }) async {
  //   try {
  //     final response = await client.auth.signUp(
  //       email: email,
  //       password: password,
  //       data: {
  //         if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
  //         if (phone != null && phone.isNotEmpty) 'phone': phone,
  //         if (dob != null && dob.isNotEmpty) 'dob': dob,
  //         if (userType != null && userType.isNotEmpty) 'user_type': userType,
  //       },
  //       emailRedirectTo:
  //           'io.supabase.volhub://email-confirm', // Deep link for email confirmation
  //     );

  //     final user = response.user;

  //     if (user != null) {
  //       await insertUserIntoUsersTable(
  //         id: user.id,
  //         role: userType ?? 'volunteer',
  //         email: email,
  //         fullName: fullName,
  //         avatarUrl: user.userMetadata?['avatar_url'],
  //       );
  //     }

  //     return response;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String userType,
    required String phone,
    required String dob,
    String countryCode = '+91',
  }) async {
    // We pass all these details as 'data' (user_metadata) so the Trigger
    // can pick them up and insert them into public.users immediately.
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role':
            userType, // We use 'role' to match the column name logic in trigger
        'phone_number': phone,
        'country_code': countryCode,
        'dob': dob, // Format: YYYY-MM-DD
      },
      emailRedirectTo: kIsWeb
          ? '${Uri.base.origin}/#/email-confirm'
          : 'io.supabase.volhub://email-confirm',
    );

    // No need to manually insert into public.users here.
    // The Postgres Trigger 'on_auth_user_created' handles it securely.

    return response;
  }

  // Check if user exists in public.users
  static Future<bool> checkUserExists(String email, String phone,
      {String? excludeUserId}) async {
    var query = client
        .from('users')
        .select()
        .or('email.eq.$email,phone_number.eq.$phone');

    if (excludeUserId != null) {
      query = query.neq('id', excludeUserId);
    }

    final response = await query.maybeSingle();
    return response != null;
  }

  // Check if email exists in public.users
  static Future<bool> checkEmailExists(String email) async {
    final response = await client
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    return response != null;
  }

  // Check if phone number exists in public.users
  static Future<bool> checkPhoneExists(String phone) async {
    final response = await client
        .from('users')
        .select('id')
        .eq('phone_number', phone)
        .maybeSingle();
    return response != null;
  }

  // Step 1: Send Verification Link (Magic Link) - No password required at this stage
  static Future<void> startEmailVerification(String email) async {
    // Uses Magic Link (signInWithOtp).
    // This creates the user if they don't exist, or logs them in if they do.
    // In both cases, it verifies the email when clicked.
    await client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: kIsWeb
          ? '${Uri.base.origin}/#/email-confirm'
          : 'io.supabase.volhub://email-confirm',
    );
  }

  // Step 1: Send Signup Confirmation Link (Uses "Confirm Signup" template)
  // Note: This will create user in auth.users, but trigger is disabled
  // so public.users record is NOT created until "Create Account" is clicked
  static Future<void> sendSignupConfirmation({
    required String email,
    required String password,
    String? fullName,
    String? userType,
    String? phone,
    String? dob,
    String countryCode = '+91',
  }) async {
    // Use Confirm Signup template
    // This creates user in auth.users (but NOT in public.users due to disabled trigger)
    await client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (userType != null) 'role': userType,
        if (phone != null) 'phone_number': phone,
        'country_code': countryCode,
        if (dob != null) 'dob': dob,
      },
      emailRedirectTo: kIsWeb
          ? '${Uri.base.origin}/#/email-confirm'
          : 'io.supabase.volhub://email-confirm',
    );
    
    if (kDebugMode) print('Confirmation email sent');
  }

  // Step 2: Send OTP to Email for Phone Verification (Uses "Magic Link" template)
  static Future<void> sendPhoneVerificationOtp(String email) async {
    await client.auth.signInWithOtp(
      email: email,
      // Note: Do NOT provide emailRedirectTo here if you want OTP by default,
      // but if the dashboard is set to "Magic Link", it will use that template.
    );
  }

  // Verify phone OTP
  static Future<void> verifyPhoneOtp(String phone, String token) async {
    await client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
  }

  // Verify email OTP (for phone verification step)
  static Future<void> verifyEmailOtp(String email, String token) async {
    await client.auth.verifyOTP(email: email, token: token, type: OtpType.email);
  }

  // Step 3: Complete Signup (Create public.users record only)
  // Auth user already exists from email verification step
  static Future<void> completeSignup({
    required String email,
    required String fullName,
    required String userType,
    required String phone,
    required String dob,
    required bool isEmailVerified,
    required bool isPhoneVerified,
    String countryCode = '+91',
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not verified or logged in.');

    if (kDebugMode) {
      print('--- SUPABASE: Creating Account in public.users ---');
      print('User ID: ${user.id}');
      print('Email: $email');
    }

    // Insert into public.users (trigger is disabled, so we do it manually)
    await client.from('users').insert({
      'id': user.id,
      'email': email,
      'full_name': fullName,
      'role': userType,
      'phone_number': phone,
      'country_code': countryCode,
      'date_of_birth': dob,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
    });

    if (kDebugMode) print('User record created in public.users');
  }

  // Legacy/Direct Sign up (Kept for reference or alternative flow)
  static Future<AuthResponse> signUpLegacy({
    required String email,
    required String password,
    required String fullName,
    required String userType,
    required String phone,
    required String dob,
    String countryCode = '+91',
  }) async {
    // ... existing implementation ...
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': userType,
        'phone': phone,
        'country_code': countryCode,
        'dob': dob,
      },
      emailRedirectTo: kIsWeb
          ? '${Uri.base.origin}/#/email-confirm'
          : 'io.supabase.volhub://email-confirm',
    );
    return response;
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

      await client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
    } catch (e) {
      rethrow;
    }
  }

  // Update password (after clicking reset link)
  static Future<void> updatePassword(String newPassword) async {
    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    return await getUserFromUsersTable();
  }

  // Update user profile (public.users ONLY)
  static Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    await updateUsersTable(updates);
  }

  // Upsert user profile (Create if not exists, Update if exists)
  static Future<void> upsertUserProfile(Map<String, dynamic> data) async {
    try {
      if (currentUser == null) throw Exception('User not logged in');
      
      final updates = {
        ...data,
        'id': currentUser!.id,
        'updated_at': DateTime.now().toIso8601String(),
        'email': currentUser!.email, // Ensure email is always present
      };

      await client.from('users').upsert(updates);
    } catch (e) {
      rethrow;
    }
  }

  // Alias for updateUsersTable/updateUserProfile
  static Future<void> updateUsersTableAlias(Map<String, dynamic> data) async {
    await updateUsersTable(data);
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
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
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
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
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
  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange.map((event) {
        final session = event.session;

        if (session != null) {
          if (kDebugMode) {
            print('--- SUPABASE AUTH SESSION ---');
            print('User ID: ${session.user.id}');
            print('Email: ${session.user.email}');
            print('Access Token: ${session.accessToken}');
            print('Refresh Token: ${session.refreshToken}');
            print('Provider: ${session.user.appMetadata['provider']}');
            print('Expires At: ${session.expiresAt}');
            print('--------------------------------');
          }
        }

        return event;
      });

  // Centralized redirection logic after any successful login
  static Future<void> handlePostAuthRedirect(BuildContext context) async {
    try {
      if (kDebugMode) print('--- Handling Post-Auth Redirect ---');
      
      final userData = await getUserFromUsersTable();
      
      if (!context.mounted) return;

      if (userData == null || userData['role'] == null) {
        // New user or missing role (e.g., first-time Google user)
        if (kDebugMode) print('No profile found, redirecting to role selection');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/end-user-type-selection',
          (route) => false,
        );
      } else {
        // Existing user with role
        final role = userData['role'];
        if (kDebugMode) print('Profile found with role: $role');
        
        if (role == 'volunteer') {
          // Check if volunteer has selected their type (experienced/inexperienced)
          if (userData['volunteer_type'] == null) {
            if (kDebugMode) print('Volunteer type not set, redirecting to type selection');
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/volunteer-type-selection',
              (route) => false,
            );
          } else {
            if (kDebugMode) print('Redirecting to volunteer dashboard');
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/volunteer-dashboard',
              (route) => false,
            );
          }
        } else if (role == 'admin') {
          if (kDebugMode) print('Redirecting to admin dashboard');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin-dashboard',
            (route) => false,
          );
        } else if (role == 'organizer' || role == 'host') {
          if (kDebugMode) print('Redirecting to organizer dashboard');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/organizer-dashboard',
            (route) => false,
          );
        } else if (role == 'manager' || role == 'event_manager') {
          if (kDebugMode) print('Redirecting to manager dashboard');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/manager-dashboard',
            (route) => false,
          );
        } else {
            if (kDebugMode) print('Unknown role: $role');
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unknown role or role not set.')),
            );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error in handlePostAuthRedirect: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error determining redirection: $e')),
        );
      }
    }
  }

  // Upload verification document
  static Future<String?> uploadVerificationDocument(
    File file,
    String userId,
  ) async {
    try {
      final fileExt = file.path.split('.').last;
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = '$userId/$timestamp.$fileExt';
      final filePath = fileName;

      await client.storage.from('verification_docs').upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get the public URL
      final String publicUrl = client.storage
          .from('verification_docs')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading document: $e');
      }
      rethrow; 
      // return null;
    }
  }

  // Upload profile image
  static Future<String?> uploadProfileImage(
    File file,
    String userId,
  ) async {
    try {
      final fileExt = file.path.split('.').last;
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      // Storing directly in userId folder to comply with RLS policy: 
      // (storage.foldername(name))[1] = auth.uid()::text
      final fileName = '$userId/avatar_$timestamp.$fileExt';
      
      const bucketName = 'verification_docs'; 

      await client.storage.from(bucketName).upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String publicUrl = client.storage.from(bucketName).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile image: $e');
      }
      rethrow;
    }
  }

  // Update user metadata (phone, address, avatar, etc.)
  static Future<void> updateUserMetadata(Map<String, dynamic> data) async {
    try {
      await client.auth.updateUser(
        UserAttributes(
          data: data,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
