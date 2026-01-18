import 'package:flutter/material.dart';

class UserTypeSelectionPage extends StatefulWidget {
  const UserTypeSelectionPage({super.key});

  @override
  State<UserTypeSelectionPage> createState() => _UserTypeSelectionPageState();
}

class _UserTypeSelectionPageState extends State<UserTypeSelectionPage> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 1, 22, 56),
              Color.fromARGB(255, 54, 65, 86),
              Color.fromARGB(255, 33, 78, 52),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Logo/Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/icons/icon_1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  const Text(
                    "Welcome to VOLHUB",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select your account type to continue",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // User Type Selection Cards
                  _AnimatedUserTypeCard(
                    title: "Event Host",
                    description: "Create and manage volunteer events",
                    icon: Icons.event_note,
                    color: const Color.fromARGB(255, 33, 78, 52),
                    userType: 'event_host',
                    isSelected: _selectedType == 'event_host',
                    onTap: () {
                      setState(() {
                        _selectedType = 'event_host';
                      });
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          Navigator.pushNamed(
                            context,
                            '/login',
                            arguments: 'event_host',
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                    _AnimatedUserTypeCard(
                    title: "Volunteers",
                    description: "Find and join volunteer opportunities",
                    icon: Icons.people,
                    color: const Color.fromARGB(255, 33, 78, 52),
                    userType: 'volunteer',
                    isSelected: _selectedType == 'volunteer',
                    onTap: () {
                      setState(() {
                        _selectedType = 'volunteer';
                      });
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          Navigator.pushNamed(
                            context,
                            '/login',
                            arguments: 'volunteer',
                          );
                        }
                      });
                    },
                  ),
                   const SizedBox(height: 20),
                   _AnimatedUserTypeCard(
                    title: "Admin",
                    description: "Manage users and verify documents",
                    icon: Icons.admin_panel_settings,
                    color: const Color(0xFF1E293B),
                    userType: 'admin',
                    isSelected: _selectedType == 'admin',
                    onTap: () {
                      setState(() {
                        _selectedType = 'admin';
                      });
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          Navigator.pushNamed(
                            context,
                            '/login',
                            arguments: 'admin',
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedUserTypeCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String userType;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedUserTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.userType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedUserTypeCard> createState() => _AnimatedUserTypeCardState();
}

class _AnimatedUserTypeCardState extends State<_AnimatedUserTypeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _elevationAnimation = Tween<double>(
      begin: 10.0,
      end: 5.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: widget.color.withOpacity(0.05),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_AnimatedUserTypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isSelected ? _colorAnimation.value : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: widget.isSelected
                    ? Border.all(color: widget.color, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(
                      widget.isSelected ? 0.3 : 0.1,
                    ),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                    spreadRadius: widget.isSelected ? 2 : 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? widget.color
                          : widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: widget.color.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.icon,
                        key: ValueKey(widget.isSelected),
                        color: widget.isSelected ? Colors.white : widget.color,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.isSelected
                                ? widget.color
                                : widget.color,
                          ),
                          child: Text(widget.title),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: widget.isSelected ? 0.25 : 0,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: widget.color,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
