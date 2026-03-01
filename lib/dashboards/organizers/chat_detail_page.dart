import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../services/supabase_service.dart';
import '../managers/core/theme.dart';
import 'widgets/enhanced_media_viewer.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String name;
  final String avatar;
  final bool isOnline;

  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.name,
    required this.avatar,
    required this.isOnline,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late Stream<List<Map<String, dynamic>>> _messagesStream;
  StreamSubscription? _messagesSubscription;

  Map<String, dynamic>? _replyingToMessage;
  String? _touchedMessageId;

  @override
  void initState() {
    super.initState();
    _messagesStream = SupabaseService.getMessagesStream(widget.chatId);
    _markRead();
    
    // Listen to stream for real-time unread clearing
    _messagesSubscription = _messagesStream.listen((messages) {
      final hasUnread = messages.any((msg) => 
        msg['sender_id'] == widget.chatId && 
        msg['is_read'] == false
      );
      if (hasUnread) {
        _markRead();
      }
    });
  }

  void _markRead() async {
    await SupabaseService.markMessagesAsRead(widget.chatId);
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final content = _messageController.text.trim();
    final replyToId = _replyingToMessage?['id'];
    
    _messageController.clear();
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // In reversed list, 0.0 is the bottom (latest message)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return;
    } 

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching location...')));
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      final content = '${position.latitude},${position.longitude}';
      
      await SupabaseService.sendMessage(
        receiverId: widget.chatId,
        content: content,
        type: 'location',
      );
      
      _scrollToBottom();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not fetch location.')));
    }
  }

  void _sendSticker(String stickerUrl) async {
    await SupabaseService.sendMessage(
      receiverId: widget.chatId,
      content: stickerUrl,
      type: 'sticker',
    );
    _scrollToBottom();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.avatar.isNotEmpty ? (widget.avatar.startsWith('http') ? NetworkImage(widget.avatar) : null) : null,
                  child: widget.avatar.isEmpty ? const Icon(Icons.person) : (!widget.avatar.startsWith('http') ? Text(widget.name.isNotEmpty ? widget.name[0] : '') : null),
                ),
                if (widget.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender_id'] == SupabaseService.currentUser?.id;
                    return Dismissible(
                      key: Key(message['id'].toString()),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (direction) async {
                        setState(() {
                          _replyingToMessage = message;
                        });
                        return false; // Don't actually dismiss
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.reply, color: Color(0xFF001529)),
                      ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_touchedMessageId == message['id']?.toString()) {
                                _touchedMessageId = null;
                              } else {
                                _touchedMessageId = message['id']?.toString();
                              }
                            });
                          },
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              Flexible(child: _buildMessageBubble(
                                message, 
                                isMe, 
                                messages,
                                _touchedMessageId == message['id']?.toString(),
                              )),
                            ],
                          ),
                        ),
                    );
                  },
                );
              },
            ),
          ),
          if (_replyingToMessage != null) _buildReplyPreview(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    final type = _replyingToMessage!['message_type'] ?? 'text';
    final content = _replyingToMessage!['content'] ?? '';
    final isMe = _replyingToMessage!['sender_id'] == SupabaseService.currentUser?.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(left: BorderSide(color: const Color(0xFF001529), width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingToMessage!['imagePath'] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb 
                      ? Image.network(_replyingToMessage!['imagePath'], width: 200, fit: BoxFit.cover)
                      : Image.file(
                          File(_replyingToMessage!['imagePath']),
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  isMe ? 'You' : widget.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF001529)),
                ),
                Text(
                  type == 'text' ? content : '[Media]',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyingToMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe, List<Map<String, dynamic>> allMessages, bool isTouched) {
    final bool isDeleted = message['is_deleted'] ?? false;
    final type = message['message_type'] ?? 'text';
    final content = message['content'] ?? '';
    final messageId = message['id']?.toString() ?? UniqueKey().toString();
    final bool isRead = message['is_read'] ?? false;
    final timeStr = message['created_at'] != null 
        ? DateTime.parse(message['created_at']).toLocal().toString().substring(11, 16) 
        : '';

    if (isDeleted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.grey.shade200 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
                child: isTouched ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      'This message was deleted',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ) : const SizedBox.shrink(),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
            ),
          ],
        ),
      );
    }

    if (type == 'sticker') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 14,
                backgroundImage: widget.avatar.startsWith('http') ? NetworkImage(widget.avatar) : null,
                child: !widget.avatar.startsWith('http') ? Text(widget.name[0], style: const TextStyle(fontSize: 10)) : null,
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
                      widget.name,
                      style: const TextStyle(
                        color: Color(0xFF00AA8D),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Stack(
                  children: [
                    GestureDetector(
                      onLongPress: () => _showDeleteOptions(message, isMe),
                      child: Image.network(
                        content,
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.emoji_emotions_outlined, size: 64, color: Colors.grey),
                      ),
                    ),
                    if (isTouched)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade400),
                          onPressed: () => _showDeleteOptions(message, isMe),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: widget.avatar.startsWith('http') ? NetworkImage(widget.avatar) : null,
              child: !widget.avatar.startsWith('http') ? Text(widget.name[0], style: const TextStyle(fontSize: 10)) : null,
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
                    widget.name,
                    style: const TextStyle(
                      color: Color(0xFF00AA8D),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              GestureDetector(
                onLongPress: () => _showDeleteOptions(message, isMe),
                onTap: () async {
                  if (type == 'image') {
                    _showFullScreenImage(message, messageId);
                  } else if (type == 'file') {
                    final url = content.contains('|') ? content.split('|').last : content;
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  } else if (type == 'location') {
                    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$content';
                    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                      await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
                    }
                  }
                },
                child: Container(
                  padding: type == 'image' ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF001529) : const Color(0xFFF1F4F3),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 16),
                    ),
                    boxShadow: [
                      if (!isMe)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 24.0), // Space for chevron
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message['reply_to_id'] != null) ...[
                              _buildQuotedMessage(message['reply_to_id'].toString(), allMessages),
                              const SizedBox(height: 8),
                            ],
                            if (type == 'image') ...[
                              Hero(
                                tag: messageId,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    content,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                            ],
                            if (type == 'text')
                              Text(
                                content,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            if (type == 'file')
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.description, color: isMe ? Colors.white : const Color(0xFF001529), size: 32),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          content.contains('|') ? content.split('|').first : 'Document',
                                          style: TextStyle(
                                            color: isMe ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Tap to view',
                                          style: TextStyle(
                                            color: isMe ? Colors.white70 : Colors.grey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            if (type == 'location')
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.redAccent, size: 28),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Shared Location',
                                        style: TextStyle(
                                          color: isMe ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to view in maps',
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (isTouched)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: isMe ? Colors.white54 : Colors.grey.shade400,
                            ),
                            onPressed: () => _showDeleteOptions(message, isMe),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: isRead ? Colors.blue : Colors.grey.shade400,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotedMessage(String replyToId, List<Map<String, dynamic>> allMessages) {
    // Find the original message in the current list
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
        child: const Text(
          'Original message not found',
          style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    final type = quotedMsg['message_type'] ?? 'text';
    final content = quotedMsg['content'] ?? '';
    final isMe = quotedMsg['sender_id'] == SupabaseService.currentUser?.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Color(0xFF001529), width: 4)),
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
                  isMe ? 'You' : widget.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF001529)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (type == 'image')
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.image, size: 12, color: Colors.grey),
                      ),
                    if (type == 'file')
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.insert_drive_file, size: 12, color: Colors.grey),
                      ),
                    Flexible(
                      child: Text(
                        type == 'text' ? content : (type == 'image' ? 'Photo' : (content.contains('|') ? content.split('|').first : 'Document')),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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

  void _showDeleteOptions(Map<String, dynamic> message, bool isMe) {
    final messageId = message['id']?.toString() ?? '';
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
              'Message Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001529)),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.reply_outlined, color: Colors.blue),
              title: const Text('Reply', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyingToMessage = message;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: Colors.blue),
              title: const Text('Copy', style: TextStyle(color: Colors.black87)),
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
              leading: const Icon(Icons.reply_all, color: Colors.blue),
              title: const Text('Forward', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                _showForwardDialog(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete for me', style: TextStyle(color: Colors.black87)),
              onTap: () async {
                Navigator.pop(context);
                final success = await SupabaseService.deleteMessage(
                  messageId: messageId,
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
                title: const Text('Delete for everyone', style: TextStyle(color: Colors.black87)),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await SupabaseService.deleteMessage(
                    messageId: messageId,
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
              leading: const Icon(Icons.cancel_outlined, color: Colors.grey),
              title: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _shareMessage(Map<String, dynamic> message) async {
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

  void _showFullScreenImage(Map<String, dynamic> message, String heroTag) {
    final imageUrl = message['content'] ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedMediaViewer(
          imageUrl: imageUrl, 
          heroTag: heroTag, 
          messageId: message['id']?.toString() ?? '',
          onReply: () {
            setState(() {
              _replyingToMessage = message;
            });
          },
        ),
      ),
    );
  }

  Widget _buildInputBar() {
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
            // Attachment Icon
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Color(0xFF001529)),
                onPressed: () {
                  _showAttachmentOptions(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _messageController,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Send Icon
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF001529),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF001529).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Send Attachment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentItem(Icons.image, 'Photo', Colors.blue, onTap: _pickImage),
                  _buildAttachmentItem(Icons.description, 'Document', Colors.orange, onTap: _pickFile),
                  _buildAttachmentItem(Icons.sticky_note_2, 'Stickers', Colors.purple, onTap: () {
                    Navigator.pop(context);
                    _showStickerPicker(context);
                  }),
                  _buildAttachmentItem(Icons.location_on, 'Location', Colors.green, onTap: _sendLocation),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showStickerPicker(BuildContext context) {
    // Curated funny/useful stickers
    final stickers = [
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png', // Pikachu
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png',  // Bulbasaur
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/4.png',  // Charmander
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/7.png',  // Squirtle
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/94.png', // Gengar
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/133.png', // Eevee
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a Sticker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: stickers.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _sendSticker(stickers[index]),
                child: Image.network(stickers[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageUrl = await SupabaseService.uploadChatAttachment(
        file: File(image.path),
        chatId: widget.chatId,
      );
      
      if (imageUrl != null) {
        await SupabaseService.sendMessage(
          receiverId: widget.chatId,
          content: imageUrl,
          type: 'image',
        );
      }
      
      _scrollToBottom();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;
      
      final fileUrl = await SupabaseService.uploadChatAttachment(
        file: file,
        chatId: widget.chatId,
      );
      
      if (fileUrl != null) {
        await SupabaseService.sendMessage(
          receiverId: widget.chatId,
          content: '$fileName|$fileUrl',
          type: 'file',
        );
      }
      
      _scrollToBottom();
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildAttachmentItem(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
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
        title: const Text('Forward to...'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allContacts.length,
            itemBuilder: (context, index) {
              final contact = allContacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: contact['profile_photo'] != null && contact['profile_photo'].toString().startsWith('http') 
                      ? NetworkImage(contact['profile_photo']) 
                      : null,
                  child: contact['profile_photo'] == null ? Text(contact['full_name']?[0] ?? '') : null,
                ),
                title: Text(contact['full_name'] ?? 'Unknown'),
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
}
