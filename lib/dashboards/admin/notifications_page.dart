import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _allNotifications = [
    {
      'title': 'Event Registration Open',
      'body': 'Registration for the annual volunteer meetup is now open!',
      'audience': 'All Volunteers',
      'date': '2026-01-18',
      'type': 'Email',
      'status': 'sent',
      'icon': Icons.email_outlined,
    },
    {
      'title': 'Manager Meeting Reminder',
      'body': 'Monthly manager sync meeting tomorrow at 10 AM',
      'audience': 'Event Managers',
      'date': '2026-01-17',
      'type': 'Push',
      'status': 'sent',
      'icon': Icons.notifications_none,
    },
    {
      'title': 'New Event Published',
      'body': 'Community cleanup event scheduled for next week',
      'audience': 'Active Users',
      'date': '2026-01-20',
      'type': 'Sms',
      'status': 'scheduled',
      'icon': Icons.message_outlined,
    },
    {
      'title': 'Policy Update',
      'body': 'Updated volunteer guidelines available',
      'audience': 'All Users',
      'date': '2026-01-19',
      'type': 'Email',
      'status': 'draft',
      'icon': Icons.email_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredNotifications(String status) {
    if (status == 'all') return _allNotifications;
    return _allNotifications.where((n) => n['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final padding = isSmallScreen ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Notification & Communication',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Send notifications and messages to users',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isSmallScreen)
                          ElevatedButton.icon(
                            onPressed: () {
                              // Action to create notification
                            },
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Create Notification'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A), // Dark color from Screenshot
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (isSmallScreen) ...[
                      const SizedBox(height: 16),
                       SizedBox(
                        width: double.infinity,
                         child: ElevatedButton.icon(
                            onPressed: () {
                              // Action to create notification
                            },
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Create Notification'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                       ),
                    ],

                    const SizedBox(height: 24),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey[600],
                        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        tabs: const [
                          Tab(text: 'All Notifications'),
                          Tab(text: 'Sent'),
                          Tab(text: 'Scheduled'),
                          Tab(text: 'Drafts'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationList('all'),
                    _buildNotificationList('sent'),
                    _buildNotificationList('scheduled'),
                    _buildNotificationList('draft'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationList(String filterStatus) {
    final notifications = _getFilteredNotifications(filterStatus);
    
    if (notifications.isEmpty) {
      return Center(
        child: Text(
          'No ${filterStatus == 'all' ? '' : filterStatus} notifications found',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: notifications.map((notification) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notification['icon'], size: 20, color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _buildStatusChip(notification['status']),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['body'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        children: [
                          Text(
                            'To: ${notification['audience']}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                          Text('•', style: TextStyle(color: Colors.grey[400])),
                          Text(
                            notification['date'],
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                          Text('•', style: TextStyle(color: Colors.grey[400])),
                          Text(
                            notification['type'],
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    Color bg;

    switch (status) {
      case 'sent':
        color = const Color(0xFF22C55E); // Green
        bg = const Color(0xFFDCFCE7);
        break;
      case 'scheduled':
        color = const Color(0xFF3B82F6); // Blue
        bg = const Color(0xFFDBEAFE);
        break;
      case 'draft':
        color = const Color(0xFF6B7280); // Grey
        bg = const Color(0xFFF3F4F6);
        break;
      default:
        color = Colors.grey;
        bg = Colors.grey[100]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
