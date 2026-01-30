import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class SupabaseExamples {
  // Example 1: Sign up a new user
  static Future<void> exampleSignUp() async {
    try {
      final response = await SupabaseService.signUp(
        email: 'user@example.com',
        password: 'securepassword123',
        fullName: 'John Doe',
        userType: 'volunteer',
        phone: '9207509857',
        dob: '2000-01-01',
      );
      print('User signed up: ${response.user?.email}');
    } catch (e) {
      print('Sign up error: $e');
    }
  }

  // Example 2: Sign in a user
  static Future<void> exampleSignIn() async {
    try {
      final response = await SupabaseService.signIn(
        email: 'user@example.com',
        password: 'securepassword123',
      );
      print('User signed in: ${response.user?.email}');
    } catch (e) {
      print('Sign in error: $e');
    }
  }

  // Example 3: Get current user
  static void exampleGetCurrentUser() {
    final user = SupabaseService.currentUser;
    if (user != null) {
      print('Current user: ${user.email}');
      print('User ID: ${user.id}');
    } else {
      print('No user logged in');
    }
  }

  // Example 4: Sign out
  static Future<void> exampleSignOut() async {
    try {
      await SupabaseService.signOut();
      print('User signed out');
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Example 5: Reset password
  static Future<void> exampleResetPassword() async {
    try {
      await SupabaseService.resetPassword('user@example.com');
      print('Password reset email sent');
    } catch (e) {
      print('Reset password error: $e');
    }
  }

  // Example 6: Insert data into a table
  static Future<void> exampleInsertData() async {
    try {
      final response = await SupabaseService.client
          .from('volunteer_opportunities') // Replace with your table name
          .insert({
            'title': 'Community Cleanup',
            'description': 'Help clean up the local park',
            'location': 'Central Park',
            'date': '2024-12-25',
          });
      print('Data inserted: $response');
    } catch (e) {
      print('Insert error: $e');
    }
  }

  // Example 7: Query data from a table
  static Future<void> exampleQueryData() async {
    try {
      final response = await SupabaseService.client
          .from('volunteer_opportunities') // Replace with your table name
          .select()
          .limit(10);
      print('Data retrieved: $response');
    } catch (e) {
      print('Query error: $e');
    }
  }

  // Example 8: Update data
  static Future<void> exampleUpdateData() async {
    try {
      final response = await SupabaseService.client
          .from('volunteer_opportunities') // Replace with your table name
          .update({'title': 'Updated Title'})
          .eq('id', 'some-id'); // Replace with actual ID
      print('Data updated: $response');
    } catch (e) {
      print('Update error: $e');
    }
  }

  // Example 9: Delete data
  static Future<void> exampleDeleteData() async {
    try {
      final response = await SupabaseService.client
          .from('volunteer_opportunities') // Replace with your table name
          .delete()
          .eq('id', 'some-id'); // Replace with actual ID
      print('Data deleted: $response');
    } catch (e) {
      print('Delete error: $e');
    }
  }

  // Example 10: Listen to real-time changes
  static StreamSubscription exampleRealtimeSubscription() {
    return SupabaseService.client
        .from('volunteer_opportunities') // Replace with your table name
        .stream(primaryKey: ['id'])
        .listen((data) {
          print('Real-time update: $data');
        });

    // Usage:
    // final subscription = exampleRealtimeSubscription();
    // Don't forget to cancel when done: subscription.cancel();
  }

  // Example 11: Upload a file
  // Note: You need to import 'dart:io' and use File object
  // import 'dart:io';
  static Future<void> exampleUploadFile(File file) async {
    try {
      final fileName = 'avatar.jpg';

      await SupabaseService.client.storage
          .from('avatars') // Your storage bucket name
          .upload(fileName, file);

      print('File uploaded: $fileName');
    } catch (e) {
      print('Upload error: $e');
    }
  }

  // Alternative: Upload from bytes using Uint8List
  static Future<void> exampleUploadFileFromBytes(Uint8List fileBytes) async {
    try {
      final fileName = 'avatar.jpg';

      await SupabaseService.client.storage
          .from('avatars') // Your storage bucket name
          .uploadBinary(fileName, fileBytes);

      print('File uploaded: $fileName');
    } catch (e) {
      print('Upload error: $e');
    }
  }

  // Example 12: Download a file
  static Future<void> exampleDownloadFile() async {
    try {
      final fileBytes = await SupabaseService.client.storage
          .from('avatars') // Your storage bucket name
          .download('avatar.jpg');

      print('File downloaded: ${fileBytes.length} bytes');
    } catch (e) {
      print('Download error: $e');
    }
  }

  // Example 13: Listen to auth state changes
  static void exampleAuthStateListener() {
    SupabaseService.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn) {
        print('User signed in: ${session?.user.email}');
      } else if (event == AuthChangeEvent.signedOut) {
        print('User signed out');
      }
    });
  }
}
