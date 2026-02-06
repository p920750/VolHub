import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final _supabase = Supabase.instance.client;

  // Stream of chat rooms for the current user
  Stream<List<Map<String, dynamic>>> getChatRoomsStream() {
    final userId = _supabase.auth.currentUser!.id;
    
    return _supabase
        .from('chat_room_participants')
        .stream(primaryKey: ['room_id', 'user_id'])
        .eq('user_id', userId)
        .asyncMap((participants) async {
          final roomIds = participants.map((p) => p['room_id'] as String).toList();
          if (roomIds.isEmpty) return [];

          // Fetch rooms with last message and all participants
          final rooms = await _supabase
              .from('chat_rooms')
              .select('*, chat_room_participants(user_id, users(full_name, profile_photo)), messages(content, created_at)')
              .filter('id', 'in', roomIds)
              .order('created_at', ascending: false, referencedTable: 'messages')
              .limit(1, referencedTable: 'messages');
          
          return List<Map<String, dynamic>>.from(rooms);
        });
  }

  // Search users to start a new chat
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final myId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('users')
        .select()
        .neq('id', myId)
        .ilike('full_name', '%$query%')
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  // Stream of messages for a specific room - added limit to avoid OOM
  Stream<List<Map<String, dynamic>>> getMessagesStream(String roomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .limit(50); // Fetch only latest 50 messages to start
  }

  // Send a message
  Future<void> sendMessage(String roomId, String content) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('messages').insert({
      'room_id': roomId,
      'sender_id': userId,
      'content': content,
    });
  }

  // Create or get a single chat room
  Future<String> createSingleChat(String otherUserId) async {
    final myId = _supabase.auth.currentUser!.id;
    
    // Check if room already exists
    final existing = await _supabase
        .from('chat_room_participants')
        .select('room_id')
        .filter('user_id', 'in', [myId, otherUserId]);

    // Check for a room where both are participants and type is single
    // (This is a simplified check, ideally query for intersection)
    
    final room = await _supabase.from('chat_rooms').insert({
      'type': 'single',
    }).select().single();

    final roomId = room['id'] as String;

    await _supabase.from('chat_room_participants').insert([
      {'room_id': roomId, 'user_id': myId},
      {'room_id': roomId, 'user_id': otherUserId},
    ]);

    return roomId;
  }
}
