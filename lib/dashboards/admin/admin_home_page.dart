import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'admin_colors.dart';
import 'admin_profile_page.dart';
import 'verification_requests_page.dart';
import 'reports_analytics_page.dart';
import 'security_access_page.dart';
import 'notifications_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String _selectedRoute = 'User Management';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AdminColors.background,
            body: Row(
              children: [
                // Permanent Sidebar for Desktop
                _buildSidebar(isDesktop: true),
                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(isDesktop: true),
                      Expanded(
                        child: _buildBody(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile/Tablet Layout with Drawer
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AdminColors.background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                _selectedRoute,
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              actions: [
                 IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                 Padding(
                   padding: const EdgeInsets.only(right: 16.0),
                   child: InkWell(
                     onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminProfilePage()),
                      );
                     },
                     child: CircleAvatar(
                        backgroundColor: const Color(0xFF6C63FF),
                        radius: 16,
                        child: const Text('A', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                   ),
                 ),
              ],
            ),
            drawer: Drawer(
              child: _buildSidebar(isDesktop: false),
            ),
            body: _buildBody(),
          );
        }
      },
    );
  }

  Widget _buildSidebar({required bool isDesktop}) {
    // If desktop, plain container. If mobile (in drawer), it already has material parent, but consistent styling helps.
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'V',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Volhub',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Menu Items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMenuItem('User Management', Icons.people_outline, isMobile: !isDesktop),
                  _buildMenuItem('Pending Verification', Icons.verified_user_outlined, isMobile: !isDesktop),
                  _buildMenuItem('Notifications', Icons.notifications_none, isMobile: !isDesktop),
                  _buildMenuItem('Reports & Analytics', Icons.bar_chart, isMobile: !isDesktop),
                  _buildMenuItem('Security & Access', Icons.security, isMobile: !isDesktop),
                ],
              ),
            ),
          ),
          
          // Bottom Items
          const Divider(),
          _buildMenuItem('Settings', Icons.settings_outlined, isMobile: !isDesktop),
          _buildMenuItem('Logout', Icons.logout, isLogout: true, isMobile: !isDesktop),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, {bool isLogout = false, bool isMobile = false}) {
    final isSelected = _selectedRoute == title && !isLogout;
    return InkWell(
      onTap: () async {
        if (isLogout) {
          await SupabaseService.signOut();
           if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
           }
        } else {
          setState(() {
            _selectedRoute = title;
          });
          if (isMobile) {
            Navigator.pop(context); // Close drawer
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : (isSelected ? Colors.white : Colors.grey[600]),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isLogout ? Colors.red : (isSelected ? Colors.white : Colors.grey[800]),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar({required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: Colors.white,
      child: Row(
        children: [
           // Title Section
           Row(
             children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(
                     _selectedRoute,
                     style: const TextStyle(
                       fontSize: 20,
                       fontWeight: FontWeight.bold,
                       color: Colors.black87,
                     ),
                   ),
                   const Text(
                     'Welcome back, Admin',
                     style: TextStyle(
                       fontSize: 14,
                       color: Colors.grey,
                     ),
                   ),
                 ],
               ),
             ],
           ),

          const Spacer(),
          
          // Right side actions
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          // Profile
           InkWell(
             onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProfilePage()),
              );
             },
             child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF6C63FF),
                  radius: 18,
                  child: const Text('A', style: TextStyle(color: Colors.white)),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Admin User',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        'Super Admin',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
           ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedRoute) {
      case 'User Management':
        return const UserManagementView();
      case 'Pending Verification':
        // Use the embedded version of the existing page
        return const VerificationRequestsPage(isEmbedded: true);
      case 'Reports & Analytics':
        return const ReportsAnalyticsPage();
      case 'Security & Access':
        return const SecurityAccessPage();
      case 'Notifications':
        return const NotificationsPage();
      default:
        return Center(
          child: Text(
            '$_selectedRoute Content Coming Soon',
            style: const TextStyle(fontSize: 24, color: Colors.grey),
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// User Management View (Matching Screenshot)
// ---------------------------------------------------------------------------
class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchUsers();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    String userType = 'volunteer';
    switch (_tabController.index) {
      case 0:
        userType = 'volunteer';
        break;
      case 1:
        userType = 'event_manager';
        break;
      case 2:
        userType = 'event_host';
        break;
    }

    try {
      final response = await SupabaseService.client
          .from('users')
          .select()
          .eq('role', userType)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      if (mounted) {
        setState(() {
          _users = [];
          _isLoading = false;
        });
        // Optional: Show snackbar or error message
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
                    if (isSmallScreen) ...[
                      // Mobile Header Layout (Stacked)
                      const Text(
                        'User Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage volunteers, event managers, and event hosts',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Add User'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Desktop Header Layout (Row)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'User Management',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Manage volunteers, event managers, and event hosts',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                           const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Add User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users by name or email...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
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
                          Tab(text: 'Volunteers'),
                          Tab(text: 'Managers'), // Shortened for mobile
                          Tab(text: 'Hosts'), // Shortened for mobile
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // User Table Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical, // Vertical Scroll for list
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal, // Horizontal Scroll for columns
                        child: ConstrainedBox(
                           constraints: BoxConstraints(
                             minWidth: constraints.maxWidth - (padding * 2), // Ensure full width usage
                           ),
                          child: _isLoading 
                                ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                                : _users.isEmpty
                                  ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("No users found")))
                                  : DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.white),
                            dataRowHeight: 72,
                            columnSpacing: 24,
                            columns: const [
                              DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Join Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Events', style: TextStyle(fontWeight: FontWeight.bold))), // Shortened
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _users.map((user) {
                              // Safely handle potential nulls
                              final id = user['id']?.toString().substring(0, 8) ?? 'N/A';
                              final name = user['full_name'] ?? 'No Name';
                              final email = user['email'] ?? 'No Email';
                              final phone = user['phone_number'] ?? 'No Phone';
                              final isVerified = user['is_aadhar_verified'] == true;
                              final status = isVerified ? 'verified' : 'pending';
                              final joined = user['created_at'] != null 
                                  ? DateTime.parse(user['created_at']).toString().split(' ')[0] 
                                  : 'N/A';
                              final events = '0'; // Placeholder as we don't have this count yet

                              return DataRow(cells: [
                                DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(name)),
                                DataCell(Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(email, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                                    ]),
                                    const SizedBox(height: 2),
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.phone_outlined, size: 14, color: Colors.grey[600]),
                                       const SizedBox(width: 4),
                                      Text(phone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    ]),
                                  ],
                                )),
                                DataCell(_buildStatusChip(status)),
                                DataCell(Text(joined)),
                                DataCell(Text(events)),
                                DataCell(IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {},
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;

    switch (status.toLowerCase()) {
      case 'active':
        bg = const Color(0xFFE6F4EA); // Light green
        text = const Color(0xFF1E8E3E); // Green
        break;
      case 'pending':
        bg = const Color(0xFFFEF7E0); // Light orange/yellow
        text = const Color(0xFFB06000); // Orange
        break;
      case 'inactive':
        bg = const Color(0xFFF1F3F4); // Grey
        text = const Color(0xFF5F6368); // Dark grey
        break;
      default:
        bg = Colors.grey[100]!;
        text = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
