import 'package:flutter/material.dart';
import 'services/supabase_service.dart';

class ForgetPage extends StatefulWidget {
  const ForgetPage({super.key});

  @override
  ForgetPageState createState() => ForgetPageState();
}

class ForgetPageState extends State<ForgetPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
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
                          'assets/images/Volhub_symbol.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Enter your Gmail account and we'll send you a link to reset your password",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Reset Password Card
                    Container(
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Gmail Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Gmail Account",
                              hintText: "Enter your Gmail address",
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Gmail account';
                              }
                              if (!value.contains('@gmail.com')) {
                                return 'Please enter a valid Gmail address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Send Reset Link Button
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  // Show loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF9B1A5A),
                                      ),
                                    ),
                                  );

                                  // Send password reset email
                                  await SupabaseService.resetPassword(
                                    _emailController.text.trim(),
                                  );
                                  
                                  // Close loading dialog
                                  if (context.mounted) Navigator.pop(context);
                                  
                                  // Show success message
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Password reset link sent to ${_emailController.text}',
                                        ),
                                        backgroundColor: const Color(0xFF9B1A5A),
                                      ),
                                    );
                                    // Navigate back to login page after a short delay
                                    Future.delayed(const Duration(seconds: 2), () {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    });
                                  }
                                } catch (e) {
                                  // Close loading dialog
                                  if (context.mounted) Navigator.pop(context);
                                  
                                  // Show error message
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to send reset link: ${e.toString()}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9B1A5A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              "Send Reset Link",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Back to Login
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Back to Login",
                              style: TextStyle(
                                color: Color(0xFF9B1A5A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

