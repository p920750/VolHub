import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class EmailConfirmPage extends StatefulWidget {
  const EmailConfirmPage({super.key});

  @override
  State<EmailConfirmPage> createState() => _EmailConfirmPageState();
}

class _EmailConfirmPageState extends State<EmailConfirmPage> {
  bool _isVerifying = true;
  bool _isVerified = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    try {
      // Get the current session to check if email is verified
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session != null && session.user.emailConfirmedAt != null) {
        setState(() {
          _isVerifying = false;
          _isVerified = true;
        });
      } else {
        // Wait a moment and check again (in case the session is being updated)
        await Future.delayed(const Duration(seconds: 1));
        final updatedSession = Supabase.instance.client.auth.currentSession;
        if (updatedSession != null && updatedSession.user.emailConfirmedAt != null) {
          setState(() {
            _isVerifying = false;
            _isVerified = true;
          });
        } else {
          setState(() {
            _isVerifying = false;
            _isVerified = false;
            _errorMessage = 'Email verification is still pending. Please try again.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _isVerified = false;
        _errorMessage = 'Error verifying email: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8B1A3D),
              Color(0xFF9B1A5A),
              Color(0xFFAB1A7A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isVerifying) ...[
                      const CircularProgressIndicator(
                        color: Color(0xFF9B1A5A),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verifying your email...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else if (_isVerified) ...[
                      Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green[600],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Email Verified!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your account has been successfully created and verified.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B1A5A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Continue to Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red[600],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verification Failed',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Unable to verify your email. Please try again.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B1A5A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

