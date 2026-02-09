import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Utility class to manually insert an event manager user into Supabase.
/// This can be used for testing purposes or to manually create administrative users.
class InsertEventManager {
  /// Inserts a new user with the 'event_manager' role.
  /// 
  /// NOTE: This uses the standard signUp flow which requires email verification
  /// unless you have disabled it in your Supabase Auth settings.
  static Future<void> insert({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String dob,
  }) async {
    try {
      print('--- Manually inserting Event Manager user ---');
      
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        userType: 'event_manager',
        phone: phone,
        dob: dob,
      );

      print('Signup initiated for: ${response.user?.email}');
      print('User ID: ${response.user?.id}');
      print('Please check email for verification (if enabled) or use Supabase dashboard to auto-confirm.');
      
    } catch (e) {
      print('Error inserting event manager: $e');
      rethrow;
    }
  }

  /*
  SQL SNIPPET FOR MANUAL INSERT IN DATABASE (Bypassing Auth Flow):
  
  -- 1. Create User in Auth
  -- (Use Supabase Dashboard for this to handle password hashing)
  
  -- 2. Once you have the User ID from Auth, run:
  INSERT INTO public.users (
    id, 
    email, 
    full_name, 
    role, 
    phone_number, 
    date_of_birth, 
    is_email_verified, 
    is_phone_verified
  ) VALUES (
    'YOUR_USER_ID_HERE',
    'example@email.com',
    'Full Name',
    'event_manager',
    '9876543210',
    '1990-01-01',
    true,
    true
  );
  */
}
