import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF011638), Color(0xFF011638), Color(0xFF011638)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "About Us",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8B1A3D),
                                      Color(0xFF9B1A5A),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                  'assets/icons/icon_1.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Meet the VOLHUB Team",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF214E34),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Passionate developers building the future of volunteerism",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Our Story Section
                        _SectionTitle(icon: Icons.history, title: "Our Story"),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF364156).withOpacity(0.1),
                                const Color(0xFF364156).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF214E34).withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            "VOLHUB was born from a simple belief: everyone has the power to make a difference. "
                            "We're a team of passionate developers, designers, and changemakers dedicated to "
                            "connecting volunteers with meaningful opportunities. Our mission is to make volunteerism "
                            "accessible, organized, and rewarding for everyone.",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Our Mission Section
                        _SectionTitle(icon: Icons.flag, title: "Our Mission"),
                        const SizedBox(height: 12),
                        _MissionCard(
                          icon: Icons.connect_without_contact,
                          title: "Connect",
                          description:
                              "Bridge the gap between volunteers and organizations",
                          color: const Color(0xFF364156),
                        ),
                        const SizedBox(height: 12),
                        _MissionCard(
                          icon: Icons.volunteer_activism,
                          title: "Empower",
                          description:
                              "Empower individuals to create positive change",
                          color: const Color(0xFF364156),
                        ),
                        const SizedBox(height: 12),
                        _MissionCard(
                          icon: Icons.trending_up,
                          title: "Grow",
                          description:
                              "Build a thriving community of changemakers",
                          color: const Color(0xFF364156),
                        ),
                        const SizedBox(height: 32),
                        // Our Values Section
                        _SectionTitle(
                          icon: Icons.volunteer_activism,
                          title: "Our Values",
                        ),
                        const SizedBox(height: 12),
                        _ValueItem(
                          icon: Icons.verified,
                          text: "Integrity & Transparency",
                        ),
                        _ValueItem(
                          icon: Icons.diversity_3,
                          text: "Inclusivity & Diversity",
                        ),
                        _ValueItem(
                          icon: Icons.lightbulb,
                          text: "Innovation & Excellence",
                        ),
                        _ValueItem(
                          icon: Icons.handshake,
                          text: "Community & Collaboration",
                        ),
                        const SizedBox(height: 32),
                        // Team Members Section
                        _SectionTitle(icon: Icons.people, title: "Our Team"),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _TeamMemberCard(
                                name: "Development Team",
                                role: "Building the Future",
                                icon: Icons.code,
                                color: const Color(0xFF011638),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TeamMemberCard(
                                name: "Design Team",
                                role: "Creating Experiences",
                                icon: Icons.palette,
                                color: const Color(0xFF011638),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TeamMemberCard(
                                name: "Community Team",
                                role: "Connecting People",
                                icon: Icons.forum,
                                color: const Color(0xFF011638),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TeamMemberCard(
                                name: "Support Team",
                                role: "Helping You Succeed",
                                icon: Icons.support_agent,
                                color: const Color(0xFF011638),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Contact Section
                        _SectionTitle(
                          icon: Icons.contact_mail,
                          title: "Get in Touch",
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF214E34), Color(0xFF214E34)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _ContactItem(
                                icon: Icons.email,
                                text: "contact@volhub.com",
                                onTap: () {
                                  // TODO: Open email
                                },
                              ),
                              const SizedBox(height: 16),
                              _ContactItem(
                                icon: Icons.phone,
                                text: "+1 (555) 123-4567",
                                onTap: () {
                                  // TODO: Make phone call
                                },
                              ),
                              const SizedBox(height: 16),
                              _ContactItem(
                                icon: Icons.location_on,
                                text: "123 Volunteer Street, Community City",
                                onTap: () {
                                  // TODO: Open maps
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Social Media
                        const Center(
                          child: Text(
                            "Follow Us",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF214E34),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialIconButton(
                              icon: Icons.facebook,
                              color: const Color(0xFF1877F2),
                              onTap: () {
                                // TODO: Open Facebook
                              },
                            ),
                            const SizedBox(width: 16),
                            _SocialIconButton(
                              icon: Icons.g_mobiledata,
                              color: Colors.black87,
                              onTap: () {
                                // TODO: Open Google+
                              },
                            ),
                            const SizedBox(width: 16),
                            _SocialIconButton(
                              icon: Icons.link,
                              color: const Color(0xFF1DA1F2),
                              onTap: () {
                                // TODO: Open Twitter
                              },
                            ),
                            const SizedBox(width: 16),
                            _SocialIconButton(
                              icon: Icons.camera_alt,
                              color: Color(0xFF214E34),
                              onTap: () {
                                // TODO: Open Instagram
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF214E34),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF214E34),
          ),
        ),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _MissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ValueItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF214E34), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final String name;
  final String role;
  final IconData icon;
  final Color color;

  const _TeamMemberCard({
    required this.name,
    required this.role,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
