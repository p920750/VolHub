import 'dart:io';
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
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... (appBar code)
      body: Container(
        // ... (decoration code)
        child: Column(
          children: [
            Expanded(
              child: _isGroup 
                ? _buildMockGroupChat() 
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.mintIce));
                      }

                      final messages = snapshot.data!;
                      if (messages.isEmpty) {
                         return const Center(child: Text('No messages yet. Say hi!', style: TextStyle(color: Colors.white54)));
                      }

                      // Auto-scroll on new messages if near bottom
                      // Use a slight delay or condition to prevent fighting with user scroll
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                         if (_scrollController.hasClients && _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
                           _scrollToBottom();
                         }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
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
                            messageId: msg['id'], // Pass ID for deletion
                            time: timeStr,
                            isGroup: false,
                            type: msg['message_type'] ?? 'text',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoalBlue.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.mintIce, size: 28),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.charcoalBlue,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (context) => Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMediaOption(Icons.image, 'Gallery', Colors.blue, () => _sendMedia('Image')),
                      _buildMediaOption(Icons.description, 'Document', Colors.orange, () => _sendMedia('Document')),
                      _buildMediaOption(Icons.location_on, 'Location', Colors.green, () => _sendMedia('Location')),
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
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
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
                color: AppColors.mintIce,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: AppColors.midnightBlue, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
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
              onTap: () {
                Navigator.pop(context);
                SupabaseService.deleteMessage(messageId: messageId, forEveryone: false);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete for everyone', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  SupabaseService.deleteMessage(messageId: messageId, forEveryone: true);
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
    {String? sender, String? time, Color? senderColor, required bool isGroup, bool isMedia = false, String? messageId, String type = 'text'}
  ) {
    return GestureDetector(
      onLongPress: () {
        if (messageId != null) {
          _showDeleteOptions(messageId, isMe);
        }
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isMe ? const LinearGradient(
                colors: [AppColors.midnightBlue, Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              color: isMe ? null : AppColors.charcoalBlue.withOpacity(0.8),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
              ),
              border: Border.all(
                color: isMe ? AppColors.mintIce.withOpacity(0.3) : Colors.white10,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe && isGroup && sender != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      sender,
                      style: TextStyle(
                        color: senderColor ?? AppColors.mintIce,
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
                                  Text('Failed to load image', style: const TextStyle(color: Colors.white)),
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
                              child: const Center(child: CircularProgressIndicator(color: AppColors.mintIce))
                          );
                        },
                        errorBuilder: (ctx, err, stack) => Container(
                          height: 150,
                          width: 150,
                          color: Colors.grey[800],
                          child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                        ),
                      ),
                    ),
                  )
                else if (type == 'file')
                  GestureDetector(
                    onTap: () async {
                      String url = message;
                      String name = 'Document';
                      
                      if (message.contains('|')) {
                        final parts = message.split('|');
                        name = parts.first;
                        url = parts.last;
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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description, color: AppColors.mintIce, size: 30),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.contains('|') ? message.split('|').first : 'Document',
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Tap to view', 
                                  style: TextStyle(color: Colors.white54, fontSize: 10),
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
                            color: Colors.grey[800],
                            alignment: Alignment.center,
                            child: const Icon(Icons.map, color: Colors.white, size: 50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.mintIce),
                            const SizedBox(width: 4),
                            Text('Location: $message', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    message,
                    style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
                  ),

                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      time ?? '',
                      style: const TextStyle(fontSize: 10, color: Colors.white38),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 14, color: AppColors.mintIce),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
