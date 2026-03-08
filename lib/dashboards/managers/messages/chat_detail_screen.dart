import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';
import 'group_info_screen.dart';
import '../../../services/supabase_service.dart';
import '../../../services/event_manager_service.dart';
import '../../organizers/widgets/enhanced_media_viewer.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String? chatName;
  final String? avatarUrl;
  final bool? isGroup;
  
  const ChatDetailScreen({super.key, required this.chatId, this.chatName, this.avatarUrl, this.isGroup});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _conversationName;
  late bool _isGroup;
  late String _currentUserId;
  late Stream<List<Map<String, dynamic>>> _messagesStream;
  StreamSubscription? _messagesSubscription;
  Map<String, dynamic>? _replyingToMessage;
  String? _touchedMessageId;
  Map<String, Map<String, dynamic>> _groupMembersProfile = {}; // id -> profile
  bool _isMembersLoading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    // Assuming 'isGroup' is passed as true or false in the chat screen initialization
    _isGroup = widget.isGroup ?? false;
    _conversationName = widget.chatName ?? (_isGroup ? 'Group Chat' : 'Chat');
    _currentUserId = SupabaseService.currentUser?.id ?? '';
    
    // Initialize stream here to prevent re-subscriptions on build
    if (!_isGroup) {
      _avatarUrl = widget.avatarUrl;
      _messagesStream = SupabaseService.getMessagesStream(widget.chatId);
      // Mark messages as read when opening chat
      SupabaseService.markMessagesAsRead(widget.chatId);
      
      // Listen to stream for real-time unread clearing
      _messagesSubscription = _messagesStream.listen((messages) {
        final hasUnread = messages.any((msg) => 
          msg['sender_id'] == widget.chatId && 
          msg['is_read'] == false
        );
        if (hasUnread) {
          SupabaseService.markMessagesAsRead(widget.chatId);
        }
      });
    } else {
      _avatarUrl = widget.avatarUrl;
      _messagesStream = SupabaseService.getGroupMessagesStream(widget.chatId);
      
      // Mark group messages as read when opening
      SupabaseService.markGroupMessagesAsRead(widget.chatId);
      
      // Listen to stream for real-time group unread clearing
      _messagesSubscription = _messagesStream.listen((messages) {
        final hasUnread = messages.any((msg) => 
          msg['sender_id'] != _currentUserId && 
          msg['is_read'] == false
        );
        if (hasUnread) {
          SupabaseService.markGroupMessagesAsRead(widget.chatId);
        }
      });

      _fetchGroupMetadata();
      _fetchGroupMembers();
    }
  }

  Future<void> _fetchGroupMetadata() async {
    if (!_isGroup) return;
    try {
      final event = await SupabaseService.client
          .from('events')
          .select('name, image_url')
          .eq('id', widget.chatId)
          .maybeSingle();

      if (event != null && mounted) {
        setState(() {
          _conversationName = event['name'] ?? _conversationName;
          _avatarUrl = event['image_url'];
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching group metadata: $e');
    }
  }

  Future<void> _fetchGroupMembers() async {
    if (!mounted) return;
    setState(() => _isMembersLoading = true);
    try {
      final members = await EventManagerService.getGroupMembers(widget.chatId);
      final Map<String, Map<String, dynamic>> memberMap = {};
      for (var member in members) {
        memberMap[member['id'].toString()] = member;
      }
      if (mounted) {
        setState(() {
          _groupMembersProfile = memberMap;
          _isMembersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isMembersLoading = false);
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    
    final content = _controller.text.trim();
    final replyToId = _replyingToMessage?['id'];
    
    _controller.clear();
    setState(() {
      _replyingToMessage = null;
    });

    await SupabaseService.sendMessage(
      receiverId: widget.chatId,
      content: content,
      replyToId: replyToId?.toString(),
    );
    _scrollToBottom();
  }

  Future<void> _sendMedia(String type) async {
    try {
      if (type == 'Image') {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        
        if (image != null) {
          final imageUrl = await SupabaseService.uploadChatAttachment(file: File(image.path), chatId: widget.chatId);
          if (imageUrl != null) {
            await SupabaseService.sendMessage(receiverId: widget.chatId, content: imageUrl, type: 'image');
          }
        }
      } else if (type == 'Document') {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        
        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final fileUrl = await SupabaseService.uploadChatAttachment(file: file, chatId: widget.chatId);
          if (fileUrl != null) {
            // Store filename|url to display nice name
            final content = '${result.files.single.name}|$fileUrl';
            await SupabaseService.sendMessage(receiverId: widget.chatId, content: content, type: 'file');
          }
        }
      } else if (type == 'Location') {
        // Request permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return;
        }
        
        if (permission == LocationPermission.deniedForever) return;

        final position = await Geolocator.getCurrentPosition();
        final content = '${position.latitude},${position.longitude}';
        await SupabaseService.sendMessage(receiverId: widget.chatId, content: content, type: 'location');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending $type: $e')));
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // In reversed list, 0.0 is the bottom (latest message)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.midnightBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.midnightBlue.withOpacity(0.1),
              backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty 
                ? NetworkImage(_avatarUrl!) 
                : null,
              child: (_avatarUrl == null || _avatarUrl!.isEmpty) 
                ? Text(
                    _conversationName.isNotEmpty ? _conversationName[0].toUpperCase() : 'C',
                    style: const TextStyle(color: AppColors.midnightBlue, fontWeight: FontWeight.bold, fontSize: 16),
                  )
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conversationName,
                    style: const TextStyle(
                      color: AppColors.midnightBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.midnightBlue),
            onPressed: () async {
              if (_isGroup) {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => GroupInfoScreen(
                  chatId: widget.chatId,
                  groupName: _conversationName,
                )));
                
                // Refresh if settings might have changed
                _fetchGroupMetadata();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB), // Soft gray background
          image: DecorationImage(
            image: const AssetImage('assets/images/chat_bg.png'), // Fallback if exists
            opacity: 0.05,
            fit: BoxFit.cover,
            onError: (e, s) {},
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.midnightBlue)));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.midnightBlue));
                      }

                      final messages = snapshot.data!;
                      if (messages.isEmpty) {
                         return Center(
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.midnightBlue.withOpacity(0.1)),
                               const SizedBox(height: 16),
                               const Text('No messages yet. Say hi!', style: TextStyle(color: AppColors.darkGrey)),
                             ],
                           ),
                         );
                      }

                      // Auto-scroll on new messages if near bottom
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                         if (_scrollController.hasClients && _scrollController.position.pixels < 50.0) {
                           _scrollToBottom();
                         }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        reverse: true, // Show newest at bottom
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['sender_id'] == _currentUserId;
                          // Parse time properly
                          final timestamp = DateTime.parse(msg['created_at']).toLocal();
                          final timeStr = "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";

                          return Dismissible(
                            key: Key(msg['id'].toString()),
                            direction: DismissDirection.startToEnd,
                            confirmDismiss: (direction) async {
                              setState(() {
                                _replyingToMessage = msg;
                              });
                              return false;
                            },
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(Icons.reply, color: AppColors.midnightBlue),
                            ),
                            child: Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (_touchedMessageId == msg['id'].toString()) {
                                            _touchedMessageId = null;
                                          } else {
                                            _touchedMessageId = msg['id'].toString();
                                          }
                                        });
                                      },
                                      child: _buildMessageBubble(
                                        context, 
                                        msg, 
                                        isMe,
                                        messages,
                                        _touchedMessageId == msg['id'].toString(), // Pass whether this message is touched
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
            ),
            if (_replyingToMessage != null) _buildReplyPreview(),
            _buildInputArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final type = _replyingToMessage!['message_type'] ?? 'text';
    final content = _replyingToMessage!['content'] ?? '';
    final isMe = _replyingToMessage!['sender_id'] == _currentUserId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05)), left: const BorderSide(color: AppColors.midnightBlue, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMe ? 'You' : (_conversationName),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.midnightBlue),
                ),
                Text(
                  type == 'text' ? content : '[Media]',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.midnightBlue),
            onPressed: () => setState(() => _replyingToMessage = null),
          ),
        ],
      ),
    );
  }

  // Fallback for groups until schema supports them
  Widget _buildMockGroupChat() {
    return Center(child: Text('Group chat is currently read-only mock.', style: TextStyle(color: Colors.white)));
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.midnightBlue, size: 28),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Share Content',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.midnightBlue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMediaOption(Icons.image, 'Gallery', Colors.blue, () => _sendMedia('Image')),
                            _buildMediaOption(Icons.description, 'Document', Colors.orange, () => _sendMedia('Document')),
                            _buildMediaOption(Icons.location_on, 'Location', Colors.green, () => _sendMedia('Location')),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: AppColors.midnightBlue, fontSize: 15),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.midnightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.midnightBlue, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showDeleteOptions(Map<String, dynamic> message, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.charcoalBlue,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Message Options',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.blueAccent),
              title: const Text('Reply', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyingToMessage = message;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: Colors.blue),
              title: const Text('Copy', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                final content = message['content'] ?? '';
                final type = message['message_type'] ?? 'text';
                if (type == 'text') {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied to clipboard')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply_all, color: Colors.green),
              title: const Text('Forward', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showForwardDialog(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete for me', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final success = await SupabaseService.deleteMessage(
                  messageId: message['id'].toString(),
                  forEveryone: false,
                );
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete message')),
                  );
                }
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete for everyone', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await SupabaseService.deleteMessage(
                    messageId: message['id'].toString(),
                    forEveryone: true,
                  );
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete message for everyone')),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.white54),
              title: const Text('Cancel', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context, 
    Map<String, dynamic> msg,
    bool isMe, 
    List<Map<String, dynamic>> allMessages,
    bool isTouched,
  ) {
    final bool isDeleted = msg['is_deleted'] ?? false;
    final message = msg['content'] as String;
    final type = msg['message_type'] ?? 'text';
    final messageId = msg['id']?.toString() ?? '';
    final isRead = msg['is_read'] ?? false;
    final createdAt = msg['created_at'] != null ? DateTime.parse(msg['created_at']).toLocal() : DateTime.now();
    final time = "${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}";

    if (isDeleted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.midnightBlue.withOpacity(0.1),
                backgroundImage: _getSenderAvatar(msg) != null && _getSenderAvatar(msg)!.startsWith('http') 
                    ? NetworkImage(_getSenderAvatar(msg)!) 
                    : null,
                child: (_getSenderAvatar(msg) == null || !_getSenderAvatar(msg)!.startsWith('http')) 
                    ? Text(_getSenderName(msg)[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.midnightBlue)) 
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _getSenderName(msg),
                      style: const TextStyle(
                        color: Color(0xFF00AA8D),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (isTouched)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.grey.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.block, size: 16, color: Colors.black26),
                        const SizedBox(width: 8),
                        const Text(
                          'This message was deleted',
                          style: TextStyle(
                            color: Colors.black26,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.midnightBlue.withOpacity(0.1),
              backgroundImage: _getSenderAvatar(msg) != null && _getSenderAvatar(msg)!.startsWith('http') 
                  ? NetworkImage(_getSenderAvatar(msg)!) 
                  : null,
              child: (_getSenderAvatar(msg) == null || !_getSenderAvatar(msg)!.startsWith('http')) 
                  ? Text(_getSenderName(msg)[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.midnightBlue)) 
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _getSenderName(msg),
                    style: const TextStyle(
                      color: Color(0xFF00AA8D),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              GestureDetector(
                onLongPress: () => _showDeleteOptions(msg, isMe),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  child: Container(
                    padding: type == 'image' ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.midnightBlue : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: isMe ? Colors.transparent : Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (msg['reply_to_id'] != null) ...[
                                _buildQuotedMessage(msg['reply_to_id'].toString(), allMessages),
                                const SizedBox(height: 8),
                              ],
                              if (type == 'image')
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => EnhancedMediaViewer(
                                      imageUrl: message, 
                                      heroTag: messageId, 
                                      messageId: messageId,
                                      onReply: () {
                                        setState(() {
                                          _replyingToMessage = msg;
                                        });
                                      },
                                    )));
                                  },
                                  child: Hero(
                                    tag: messageId,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        message,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (ctx, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                              height: 150, 
                                              width: 150, 
                                              color: Colors.black12, 
                                              child: const Center(child: CircularProgressIndicator(color: AppColors.midnightBlue))
                                          );
                                        },
                                        errorBuilder: (ctx, err, stack) => Container(
                                          height: 150,
                                          width: 150,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.broken_image, color: Colors.black26, size: 40),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else if (type == 'file')
                                GestureDetector(
                                  onTap: () async {
                                    String url = message;
                                    if (message.contains('|')) {
                                      url = message.split('|').last;
                                    }

                                    if (await canLaunchUrl(Uri.parse(url))) {
                                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not open document')),
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.white.withOpacity(0.1) : const Color(0xFFF0F2F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.insert_drive_file, color: isMe ? Colors.white : AppColors.midnightBlue, size: 30),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                message.contains('|') ? message.split('|').first : 'Document',
                                                style: TextStyle(
                                                  color: isMe ? Colors.white : AppColors.midnightBlue, 
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Tap to view', 
                                                style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (type == 'location')
                                GestureDetector(
                                  onTap: () async {
                                    final coords = message;
                                    final geoUrl = 'geo:$coords';
                                    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$coords';
                                    
                                    try {
                                      if (await canLaunchUrl(Uri.parse(geoUrl))) {
                                        await launchUrl(Uri.parse(geoUrl));
                                      } else if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                                        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
                                      } else {
                                        throw 'Could not launch maps';
                                      }
                                    } catch (e) {
                                       if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not open maps application')),
                                        );
                                      }
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          height: 150,
                                          width: 250,
                                          color: Colors.grey[200],
                                          alignment: Alignment.center,
                                          child: Icon(Icons.map, color: AppColors.midnightBlue.withOpacity(0.3), size: 50),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                          const SizedBox(width: 4),
                                          Text('Location: Shared', style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  message,
                                  textAlign: isMe ? TextAlign.end : TextAlign.start,
                                  style: TextStyle(
                                    fontSize: 15, 
                                    color: isMe ? Colors.white : AppColors.midnightBlue, 
                                    height: 1.4,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isTouched)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: IconButton(
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: isMe ? Colors.white54 : Colors.grey.shade400,
                              ),
                              onPressed: () => _showDeleteOptions(msg, isMe),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: isRead ? Colors.blueAccent : Colors.grey.shade500,
                    ),
                  ]
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showForwardDialog(Map<String, dynamic> message) async {
    final managers = await SupabaseService.getUsersByRole('manager');
    final hosts = await SupabaseService.getUsersByRole('host');
    final organizers = await SupabaseService.getUsersByRole('organizer');
    
    final allContacts = [...managers, ...hosts, ...organizers].where((u) => u['id'] != SupabaseService.currentUser?.id).fold<List<Map<String, dynamic>>>([], (list, user) {
      if (!list.any((u) => u['id'] == user['id'])) list.add(user);
      return list;
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoalBlue,
        title: const Text('Forward to...', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allContacts.length,
            itemBuilder: (context, index) {
              final contact = allContacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.midnightBlue.withOpacity(0.1),
                  backgroundImage: contact['profile_photo'] != null && contact['profile_photo'].toString().startsWith('http') 
                      ? NetworkImage(contact['profile_photo']) 
                      : null,
                  child: contact['profile_photo'] == null ? Text(contact['full_name']?[0] ?? '') : null,
                ),
                title: Text(contact['full_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await SupabaseService.sendMessage(
                    receiverId: contact['id'],
                    content: message['content'],
                    type: message['message_type'] ?? 'text',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Forwarded to ${contact['full_name']}')),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _shareMessage(Map<String, dynamic> message) {
    final type = message['message_type'] ?? 'text';
    final content = message['content'] ?? '';
    
    if (type == 'text') {
      Share.share(content);
    } else {
      // For media, share the URL
      final url = content.contains('|') ? content.split('|').last : content;
      Share.share(url);
    }
  }

  Widget _buildQuotedMessage(String replyToId, List<Map<String, dynamic>> allMessages) {
    final quotedMsg = allMessages.cast<Map<String, dynamic>?>().firstWhere(
      (m) => m?['id'].toString() == replyToId,
      orElse: () => null,
    );

    if (quotedMsg == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: Colors.grey.shade400, width: 3)),
        ),
        child: const Text('Original message not found', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }

    final type = quotedMsg['message_type'] ?? 'text';
    final content = quotedMsg['content'] ?? '';
    final isMe = quotedMsg['sender_id'] == _currentUserId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: AppColors.midnightBlue, width: 4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMe ? 'You' : _conversationName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.midnightBlue),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (type == 'image')
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.image, size: 12, color: isMe ? Colors.white70 : Colors.grey),
                      ),
                    if (type == 'file')
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.insert_drive_file, size: 12, color: isMe ? Colors.white70 : Colors.grey),
                      ),
                    Flexible(
                      child: Text(
                        type == 'text' ? content : (type == 'image' ? 'Photo' : (content.contains('|') ? content.split('|').first : 'Document')),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: isMe ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (type == 'image')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  content,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
  String _getSenderName(Map<String, dynamic> msg) {
    final senderId = msg['sender_id']?.toString() ?? '';
    if (senderId == _currentUserId) return 'You';
    
    if (_isGroup) {
      final name = _groupMembersProfile[senderId]?['name'];
      if (name == null) {
        _fetchMissingProfile(senderId);
        return 'Loading...';
      }
      return name;
    }
    return _conversationName;
  }

  void _fetchMissingProfile(String userId) async {
    if (_groupMembersProfile.containsKey(userId)) return;
    
    // Add a placeholder to prevent duplicate requests
    _groupMembersProfile[userId] = {'name': 'User', 'role': 'User'};
    
    try {
      final data = await SupabaseService.getUserProfileById(userId);
      if (data != null && mounted) {
        setState(() {
          _groupMembersProfile[userId] = {
            'id': data['id'],
            'name': data['full_name'] ?? 'User',
            'avatar': data['profile_photo'] ?? '',
            'role': data['user_type'] ?? 'Volunteer',
          };
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching missing profile: $e');
    }
  }

  String? _getSenderAvatar(Map<String, dynamic> msg) {
    final senderId = msg['sender_id']?.toString() ?? '';
    
    if (_isGroup) {
      return _groupMembersProfile[senderId]?['avatar'];
    }
    return widget.avatarUrl;
  }
}
