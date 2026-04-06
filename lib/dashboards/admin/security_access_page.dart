import 'package:flutter/material.dart';
import 'admin_colors.dart';

class SecurityAccessPage extends StatefulWidget {
  const SecurityAccessPage({super.key});

  @override
  State<SecurityAccessPage> createState() => _SecurityAccessPageState();
}

class _SecurityAccessPageState extends State<SecurityAccessPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _twoFactorEnabled = false;
  bool _strongPasswordEnabled = true;
  bool _sessionTimeoutEnabled = true;
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;
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
                                'Security & Access Control',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Manage roles, permissions, and security settings',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isSmallScreen)
                          OutlinedButton.icon(
                            onPressed: () {
                              _tabController.animateTo(1); // Go to Security Settings tab
                            },
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            label: const Text('Security Settings'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24), // Pill shape based on screenshot
                      ),
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        controller: _tabController,
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
                        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        tabs: const [
                          Tab(text: 'Roles & Permissions'),
                          Tab(text: 'Security Settings'),
                          Tab(text: 'Activity Logs'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRolesTab(isSmallScreen),
                    _buildSecuritySettingsTab(),
                    _buildActivityLogsTab(isSmallScreen),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRolesTab(bool isSmallScreen) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Create Role'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            title: 'Super Admin',
            description: 'Full system access',
            userCount: 2,
            permissionCount: 'All Permissions',
            icon: Icons.shield_outlined,
          ),
          _buildRoleCard(
            title: 'Admin',
            description: 'Manage users and events',
            userCount: 5,
            permissionCount: '4 Permissions',
            icon: Icons.shield_outlined,
          ),
          _buildRoleCard(
            title: 'Event Manager',
            description: 'Create and manage events',
            userCount: 20,
            permissionCount: '2 Permissions',
            icon: Icons.shield_outlined,
          ),
          _buildRoleCard(
            title: 'Volunteer',
            description: 'View and participate in events',
            userCount: 120,
            permissionCount: '2 Permissions',
            icon: Icons.shield_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required int userCount,
    required String permissionCount,
    required IconData icon,
  }) {
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(
                      label: Text('$userCount users'),
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(permissionCount),
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey[300]!),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '$title module coming soon',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettingsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSecurityCard(
            title: 'Two-Factor Authentication',
            description: 'Require users to verify their identity with a second factor',
            icon: Icons.key_outlined,
            iconColor: Colors.blue,
            value: _twoFactorEnabled,
            onChanged: (value) {
              setState(() => _twoFactorEnabled = value);
            },
          ),
          _buildSecurityCard(
            title: 'Strong Password Policy',
            description: 'Enforce minimum password requirements (length, complexity)',
            icon: Icons.password_outlined,
            iconColor: Colors.purple,
            value: _strongPasswordEnabled,
            onChanged: (value) {
              setState(() => _strongPasswordEnabled = value);
            },
          ),
          _buildSecurityCard(
            title: 'Session Timeout',
            description: 'Automatically log out users after 30 minutes of inactivity',
            icon: Icons.timer_outlined,
            iconColor: Colors.green,
            value: _sessionTimeoutEnabled,
            onChanged: (value) {
              setState(() => _sessionTimeoutEnabled = value);
            },
          ),
          _buildIPWhitelistCard(),
        ],
      ),
    );
  }

  Widget _buildSecurityCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildIPWhitelistCard() {
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_amber_rounded, size: 24, color: Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IP Whitelist',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Restrict access to specific IP addresses or ranges',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ipController,
            decoration: InputDecoration(
              hintText: 'Enter IP address (e.g., 192.168.1.0/24)',
              filled: true,
              fillColor: Colors.grey[50], // Very light grey for input
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement add IP logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add IP Address'),
          ),
        ],
      ),
    );
  }
  Widget _buildActivityLogsTab(bool isSmallScreen) {
    if (isSmallScreen) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            _buildMobileLogCard(
              status: 'success',
              action: 'User Login',
              user: 'admin@volhub.com',
              ipAddress: '192.168.1.100',
              timestamp: '2026-01-19 10:30:15',
            ),
            _buildMobileLogCard(
              status: 'failed',
              action: 'Failed Login Attempt',
              user: 'unknown@email.com',
              ipAddress: '203.45.67.89',
              timestamp: '2026-01-19 09:45:22',
            ),
            _buildMobileLogCard(
              status: 'success',
              action: 'Password Changed',
              user: 'emma@email.com',
              ipAddress: '192.168.1.105',
              timestamp: '2026-01-19 08:20:45',
            ),
            _buildMobileLogCard(
              status: 'success',
              action: 'Role Modified',
              user: 'admin@volhub.com',
              ipAddress: '192.168.1.100',
              timestamp: '2026-01-18 16:15:30',
            ),
            _buildMobileLogCard(
              status: 'warning',
              action: 'Multiple Failed Login',
              user: 'test@email.com',
              ipAddress: '45.67.89.123',
              timestamp: '2026-01-18 14:22:10',
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildLogTableHeader(),
            const Divider(height: 1),
            _buildLogTableRow(
              status: 'success',
              action: 'User Login',
              user: 'admin@volhub.com',
              ipAddress: '192.168.1.100',
              timestamp: '2026-01-19 10:30:15',
            ),
            _buildLogTableRow(
              status: 'failed',
              action: 'Failed Login Attempt',
              user: 'unknown@email.com',
              ipAddress: '203.45.67.89',
              timestamp: '2026-01-19 09:45:22',
            ),
            _buildLogTableRow(
              status: 'success',
              action: 'Password Changed',
              user: 'emma@email.com',
              ipAddress: '192.168.1.105',
              timestamp: '2026-01-19 08:20:45',
            ),
            _buildLogTableRow(
              status: 'success',
              action: 'Role Modified',
              user: 'admin@volhub.com',
              ipAddress: '192.168.1.100',
              timestamp: '2026-01-18 16:15:30',
            ),
            _buildLogTableRow(
              status: 'warning',
              action: 'Multiple Failed Login',
              user: 'test@email.com',
              ipAddress: '45.67.89.123',
              timestamp: '2026-01-18 14:22:10',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLogCard({
    required String status,
    required String action,
    required String user,
    required String ipAddress,
    required String timestamp,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                action,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              _buildStatusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                user,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.wifi, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    ipAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              Text(
                timestamp,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]))),
          Expanded(flex: 2, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]))),
          Expanded(flex: 2, child: Text('User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]))),
          Expanded(child: Text('IP Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]))),
          Expanded(child: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]))),
        ],
      ),
    );
  }

  Widget _buildLogTableRow({
    required String status,
    required String action,
    required String user,
    required String ipAddress,
    required String timestamp,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Align(alignment: Alignment.centerLeft, child: _buildStatusChip(status))),
          Expanded(flex: 2, child: Text(action, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87))),
          Expanded(flex: 2, child: Text(user, style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
          Expanded(child: Text(ipAddress, style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
          Expanded(child: Text(timestamp, style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'success':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        label = 'success';
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error_outline;
        label = 'failed';
        break;
      case 'warning':
        color = Colors.amber;
        icon = Icons.warning_amber_rounded;
        label = 'warning';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info_outline;
        label = 'unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
