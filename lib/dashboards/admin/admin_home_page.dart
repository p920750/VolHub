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
    List<String> roles = ['volunteer'];
    switch (_tabController.index) {
      case 0:
        roles = ['volunteer'];
        break;
      case 1:
        roles = ['manager', 'event_manager'];
        break;
      case 2:
        roles = ['organizer', 'host', 'event_host'];
        break;
    }

    try {
      final response = await SupabaseService.client
          .from('users')
          .select()
          .filter('role', 'in', roles)
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
                        'Manage volunteers, event managers, and organizers',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddManagerDialog(context),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Add Manager'),
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
                                 const Text(
                                  'Manage volunteers, event managers, and organizers',
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
                            onPressed: () => _showAddManagerDialog(context),
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Add Manager'),
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
                          Tab(text: 'Managers'),
                          Tab(text: 'Organizers'),
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
                              final status = user['verification_status'] ?? 'pending';
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

  void _showAddManagerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddManagerDialog(),
    ).then((value) {
      if (value == true) {
        _fetchUsers(); // Refresh the list if a manager was added
      }
    });
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

class AddManagerDialog extends StatefulWidget {
  const AddManagerDialog({super.key});

  @override
  State<AddManagerDialog> createState() => _AddManagerDialogState();
}

class _AddManagerDialogState extends State<AddManagerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyLocationController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _companyNameError;
  String? _companyLocationError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _companyLocationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    bool isValid = true;
    setState(() {
      _nameError = _nameController.text.isEmpty ? 'This field is required' : null;
      
      final emailValue = _emailController.text.trim();
      if (emailValue.isEmpty) {
        _emailError = 'This field is required';
      } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(emailValue)) {
        _emailError = 'Invalid email';
      } else {
        _emailError = null;
      }

      final phoneValue = _phoneController.text.trim();
      if (phoneValue.isEmpty) {
        _phoneError = 'This field is required';
      } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phoneValue)) {
        _phoneError = 'Invalid phone number';
      } else {
        _phoneError = null;
      }

      _companyNameError = _companyNameController.text.isEmpty ? 'This field is required' : null;
      _companyLocationError = _companyLocationController.text.isEmpty ? 'This field is required' : null;

      final passwordValue = _passwordController.text.trim();
      if (passwordValue.isEmpty) {
        _passwordError = 'This field is required';
      } else if (passwordValue.length < 6) {
        _passwordError = 'Invalid password must be at least 6 characters';
      } else {
        _passwordError = null;
      }

      if (_nameError != null || _emailError != null || _phoneError != null || 
          _companyNameError != null || _companyLocationError != null || _passwordError != null) {
        isValid = false;
      }
    });
    return isValid;
  }

  Future<void> _addManager() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.addManager(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        companyName: _companyNameController.text.trim(),
        companyLocation: _companyLocationController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manager added successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding manager: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildErrorText(String? errorText) {
    if (errorText == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Text(
          errorText,
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Manager',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildErrorText(_nameError),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _nameError = value.isEmpty ? 'This field is required' : null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildErrorText(_emailError),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          final val = value.trim();
                          setState(() {
                            if (val.isEmpty) {
                              _emailError = 'This field is required';
                            } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(val)) {
                              _emailError = 'Invalid email';
                            } else {
                              _emailError = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildErrorText(_phoneError),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'e.g. 9876543210',
                          prefixText: '+91 ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          final val = value.trim();
                          setState(() {
                            if (val.isEmpty) {
                              _phoneError = 'This field is required';
                            } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val)) {
                              _phoneError = 'Invalid phone number';
                            } else {
                              _phoneError = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildErrorText(_companyNameError),
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _companyNameError = value.isEmpty ? 'This field is required' : null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildErrorText(_companyLocationError),
                      TextFormField(
                        controller: _companyLocationController,
                        decoration: const InputDecoration(
                          labelText: 'Company Location',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _companyLocationError = value.isEmpty ? 'This field is required' : null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildErrorText(_passwordError),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        onChanged: (value) {
                          final val = value.trim();
                          setState(() {
                            if (val.isEmpty) {
                              _passwordError = 'This field is required';
                            } else if (val.length < 6) {
                              _passwordError = 'Invalid password';
                            } else {
                              _passwordError = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _addManager,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Manager'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
