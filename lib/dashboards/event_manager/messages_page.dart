import 'package:flutter/material.dart';
import 'event_colors.dart';
import 'event_dashboard_page.dart';
import 'my_teams_page.dart';
import 'recruit_page.dart';
import 'event_marketplace_page.dart';
import 'proposals_page.dart';
import 'widgets/event_drawer.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  bool _isHostMessages = true;

  // Mock Data
  // ... (keep data but truncated here for brevity in tool call, will use previous content in edit logic)
  final List<Map<String, dynamic>> _hostConversations = [
    {
      'title': 'Wedding Photography Package',
      'subtitle': 'Community Wedding',
      'last_message': 'You: Absolutely! I\'m available tomorrow afternoon. Wh...',
      'timestamp': 'Jan 8, 02:30 PM',
      'selected': true,
    },
    {
      'title': 'Conference Photography',
      'subtitle': 'Tech Conference 2025',
      'last_message': 'Host: Can you confirm the team size?',
      'timestamp': 'Jan 7, 10:15 AM',
      'selected': false,
    },
  ];

  final List<Map<String, dynamic>> _hostMessages = [
    {
      'sender': 'host',
      'text': 'Thank you for your proposal! Can we schedule a call to discuss details?',
      'timestamp': 'Jan 8, 02:30 PM',
    },
    {
      'sender': 'me',
      'text': 'Absolutely! I\'m available tomorrow afternoon. What time works best for you?',
      'timestamp': 'Jan 8, 02:32 PM',
    },
  ];

  final List<Map<String, dynamic>> _teamConversations = [
    {
      'title': 'Tech Conference Planning',
      'subtitle': '3 members',
      'last_message': 'Alex Thompson: I\'ll handle the main stage photography. Sarah, can you cover the breakout rooms?',
      'timestamp': 'Jan 9, 10:15 AM',
      'selected': true,
    },
  ];

  final List<Map<String, dynamic>> _teamMessages = [
    {
      'sender': 'Alex Thompson',
      'text': 'I\'ll handle the main stage photography. Sarah, can you cover the breakout rooms?',
      'timestamp': 'Jan 9, 10:15 AM',
      'color': const Color(0xFF5C7C8A), // Blue-ish grey for Alex
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EventColors.background,
      drawer: const EventDrawer(currentRoute: 'Messages'),
      appBar: AppBar(
        // automaticallyImplyLeading: true,
        backgroundColor: EventColors.headerBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Volunteer Manager Platform',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E4D40),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Communicate with event hosts and manage team discussions',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Toggle Switch
            Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isHostMessages = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isHostMessages ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Host Messages',
                            style: TextStyle(
                              color: _isHostMessages ? const Color(0xFF1E4D40) : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isHostMessages = false),
                      child: Container(
                         decoration: BoxDecoration(
                          color: !_isHostMessages ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Team Messages',
                            style: TextStyle(
                              color: !_isHostMessages ? const Color(0xFF1E4D40) : Colors.white70,
                              fontWeight: !_isHostMessages ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Main Content Area (Split View)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Pane: Conversations List
                  Container(
                    width: 350,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3B2F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isHostMessages ? 'Conversations' : 'Team Groups',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _isHostMessages ? _hostConversations.length : _teamConversations.length,
                            itemBuilder: (context, index) => _buildConversationItem(
                              _isHostMessages ? _hostConversations[index] : _teamConversations[index]
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Pane: Chat Window
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3B2F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Chat Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.white10)),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isHostMessages ? 'Wedding Photography Package' : 'Tech Conference Planning',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    if (_isHostMessages)
                                      Text(
                                        'Community Wedding',
                                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                      )
                                    else
                                      Row(
                                        children: [
                                          Text(
                                            'Conference Photography & Catering',
                                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.white),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text('3 members', style: TextStyle(color: Colors.white, fontSize: 11)),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Messages List
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _isHostMessages ? _hostMessages.length : _teamMessages.length,
                              itemBuilder: (context, index) => _isHostMessages 
                                ? _buildMessageBubble(_hostMessages[index]) 
                                : _buildTeamMessageBubble(_teamMessages[index]),
                            ),
                          ),

                          // Input Area
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3E50),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Type your message...',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  // Send button placeholder
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildConversationItem(Map<String, dynamic> conversation) {
    bool isSelected = conversation['selected'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.transparent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Colors.white) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conversation['title'],
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            conversation['subtitle'],
             style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            conversation['last_message'],
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    bool isMe = message['sender'] == 'me';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE8F5E9) : const Color(0xFF2C3E50),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['text'],
              style: TextStyle(color: isMe ? Colors.black87 : Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              message['timestamp'],
              style: TextStyle(color: isMe ? Colors.black54 : Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMessageBubble(Map<String, dynamic> message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: message['color'] ?? Colors.blue, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              message['sender'],
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              message['text'],
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              message['timestamp'],
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
