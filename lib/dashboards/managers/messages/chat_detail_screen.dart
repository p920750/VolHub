import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import 'group_info_screen.dart';
import '../../../services/supabase_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String? chatName;
  
  const ChatDetailScreen({super.key, required this.chatId, this.chatName});

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

  @override
  void initState() {
    super.initState();
    _isGroup = ['3', '4'].contains(widget.chatId); // Keep group check for mock groups
    _conversationName = widget.chatName ?? (_isGroup ? 'Group Chat' : 'Chat');
    _currentUserId = SupabaseService.currentUser?.id ?? '';
    
    // Initialize stream here to prevent re-subscriptions on build
    if (!_isGroup) {
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
      _messagesStream = const Stream.empty();
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    
    final content = _controller.text.trim();
    _controller.clear();

    if (_isGroup) {
      // Handle group message sending (mock or future impl)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group chat sending not implemented yet')));
    } else {
      await SupabaseService.sendMessage(
        receiverId: widget.chatId,
        content: content,
      );
      _scrollToBottom();
    }
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
              child: Text(
                _conversationName.isNotEmpty ? _conversationName[0].toUpperCase() : 'C',
                style: const TextStyle(color: AppColors.midnightBlue, fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
            onPressed: () {
              if (_isGroup) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GroupInfoScreen(
                  chatId: widget.chatId,
                  groupName: _conversationName,
                )));
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
              child: _isGroup 
                ? _buildMockGroupChat() 
                : StreamBuilder<List<Map<String, dynamic>>>(
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

                          return _buildMessageBubble(
                            context, 
                            msg['content'] as String, 
                            isMe,
                            messageId: msg['id'],
                            time: timeStr,
                            isGroup: false,
                            type: msg['message_type'] ?? 'text',
                            isRead: msg['is_read'] ?? false,
                          );
                        },
                      );
                    },
                  ),
            ),
            _buildInputArea(context),
          ],
        ),
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

  void _showDeleteOptions(String messageId, bool isMe) {
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
              'Delete Message?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete for me', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final success = await SupabaseService.deleteMessage(messageId: messageId, forEveryone: false);
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete message for you. Check connection.')),
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
                  final success = await SupabaseService.deleteMessage(messageId: messageId, forEveryone: true);
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete message for everyone.')),
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
    String message, 
    bool isMe, 
    {String? sender, String? time, Color? senderColor, required bool isGroup, bool isMedia = false, String? messageId, String type = 'text', bool isRead = false}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () {
                if (messageId != null) {
                  _showDeleteOptions(messageId, isMe);
                }
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.midnightBlue : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
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
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMe && isGroup && sender != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            sender,
                            style: TextStyle(
                              color: senderColor ?? AppColors.midnightBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      
                      if (type == 'image')
                        GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.network(
                                    message,
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return const CircularProgressIndicator(color: AppColors.mintIce);
                                    },
                                    errorBuilder: (ctx, err, stack) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.broken_image, color: Colors.white, size: 50),
                                        const SizedBox(height: 8),
                                        const Text('Failed to load image', style: TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                                Icon(Icons.description, color: isMe ? Colors.white : AppColors.midnightBlue, size: 30),
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
                                  Text('Location: $message', style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 12)),
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
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time ?? '',
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
      ),
    );
  }
}
