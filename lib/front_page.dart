import 'package:flutter/material.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "VOLHUB",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Connecting volunteers For the Future.",
                  style: TextStyle(
                    color: Color.fromARGB(179, 255, 255, 255),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage('assets/icons/icon_1.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Welcome to your volunteer hub!",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Choose where you’d like to go:",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        _FrontPageButton(
                          label: "About the App",
                          icon: Icons.lightbulb_outline,
                          onTap: () {
                            Navigator.pushNamed(context, '/aboutApp');
                          },
                        ),
                        _FrontPageButton(
                          label: "About Us",
                          icon: Icons.group_outlined,
                          onTap: () {
                            Navigator.pushNamed(context, '/aboutUs');
                          },
                        ),
                        _FrontPageButton(
                          label: "Go to Login",
                          icon: Icons.login,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/user-type-selection',
                            );
                          },
                        ),
                        const Spacer(),
                        Row(
                          children: const [
                            Icon(Icons.shield_outlined, color: Colors.black45),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Your impact starts here. Let’s get moving!",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FrontPageButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FrontPageButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 33, 78, 52),
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          shadowColor: Colors.black26,
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
