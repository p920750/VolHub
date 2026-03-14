import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class NotificationService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Get a stream of notifications for the current user
  static Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final user = SupabaseService.currentUser;
    if (user == null) {
      if (kDebugMode) print('NotificationService: User not logged in');
      return Stream.value([]);
    }

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((error) {
      if (kDebugMode) print('Error fetching notifications stream: $error');
      // On error, return an empty stream to avoid breaking UI immediately
      return <Map<String, dynamic>>[];
    });
  }

  /// Mark a specific notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', user.id);
    } catch (e) {
      if (kDebugMode) print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for the current user
  static Future<void> markAllAsRead() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (e) {
      if (kDebugMode) print('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', user.id);
    } catch (e) {
      if (kDebugMode) print('Error deleting notification: $e');
    }
  }
}
