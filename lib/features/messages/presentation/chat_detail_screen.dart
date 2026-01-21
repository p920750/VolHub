import 'package:flutter/material.dart';
import 'package:vol_hub/core/theme.dart';
import 'group_info_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  
  const ChatDetailScreen({super.key, required this.chatId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _groupName;

  // Mock Data for a group chat (Mutable)
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hi team, is everyone ready for the event?', 'isMe': false, 'sender': 'Alice', 'time': '10:30 AM', 'color': Colors.orange},
    {'text': 'Yes, all set!', 'isMe': true, 'sender': 'You', 'time': '10:31 AM', 'color': AppColors.mintIce},
    {'text': 'I need help with the lighting setup.', 'isMe': false, 'sender': 'Bob', 'time': '10:32 AM', 'color': Colors.purple},
    {'text': 'I can help with that, Bob.', 'isMe': false, 'sender': 'Charlie', 'time': '10:33 AM', 'color': Colors.teal},
    {'text': 'Great, thanks Charlie!', 'isMe': false, 'sender': 'Bob', 'time': '10:33 AM', 'color': Colors.purple},
  ];

  late bool _isGroup;

  @override
  void initState() {
    super.initState();
    _isGroup = ['3', '4'].contains(widget.chatId);
    _groupName = _isGroup ? (widget.chatId == '3' ? 'Photography Team' : 'Logistics Crew') : 'Chat';
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _controller.text.trim(),
        'isMe': true,
        'sender': 'You',
        'time': 'Just now',
        'color': AppColors.mintIce,
      });
      _controller.clear();
    });
    _scrollToBottom();
  }

  void _sendMedia(String type) {
    setState(() {
      _messages.add({
        'text': 'Sent a $type',
        'isMe': true,
        'sender': 'You',
        'time': 'Just now',
        'color': AppColors.mintIce,
        'isMedia': true,
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          onTap: () async {
            if (_isGroup) {
              final newName = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupInfoScreen(
                    chatId: widget.chatId,
                    groupName: _groupName,
                  ),
                ),
              );
              if (newName != null) {
                setState(() {
                  _groupName = newName;
                });
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_groupName, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              if (_isGroup)
                Text('tap for group info', style: TextStyle(fontSize: 12, color: AppColors.mintIce.withOpacity(0.7))),
            ],
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.call, color: AppColors.mintIce), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam, color: AppColors.mintIce), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.midnightBlue,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(
                    context, 
                    msg['text'] as String, 
                    msg['isMe'] as bool,
                    sender: msg['sender'] as String,
                    time: msg['time'] as String,
                    senderColor: msg['color'] as Color?,
                    isGroup: _isGroup,
                    isMedia: msg['isMedia'] ?? false,
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
                      _buildMediaOption(Icons.location_on, 'Location', Colors.green, () => {}),
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

  Widget _buildMessageBubble(
    BuildContext context, 
    String message, 
    bool isMe, 
    {String? sender, String? time, Color? senderColor, required bool isGroup, bool isMedia = false}
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
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
              if (isMedia)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file, color: isMe ? AppColors.mintIce : Colors.white70),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message, 
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.white70,
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  message,
                  style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    time ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white38,
                    ),
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
    );
  }
}
