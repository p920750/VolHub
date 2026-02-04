import 'package:flutter/material.dart';
import 'forget_page.dart';
import 'services/supabase_service.dart';
import 'dashboards/volunteers/volunteer_home_page.dart';
import 'dashboards/admin/admin_home_page.dart';

class LoginPage extends StatefulWidget {
  // final String? userType;

  // const LoginPage({super.key, this.userType});
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  // final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // final _phoneController = TextEditingController();
  // final _dobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  // bool _isLogin = true; // Toggle between login and signup
  // late String _userType; // 'event_host' or 'volunteer'

  // @override
  // void initState() {
  //   super.initState();
  //   // Get user type from widget parameter, default to 'volunteer'
  //   _userType = widget.userType ?? 'volunteer';
  // }

  @override
  void dispose() {
    // _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    // _phoneController.dispose();
    // _dobController.dispose();
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button and title
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
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
                    // Welcome text
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
                    Text(
                      // _isLogin
                      //     ? "Sign in to continue your ${_userType == 'event_host' ? 'event hosting' : 'volunteer'} journey"
                      //     : "Create an account to get started",
                      //
                      "Sign in to continue",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // User Type Badge
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 16,
                    //     vertical: 8,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white.withOpacity(0.2),
                    //     borderRadius: BorderRadius.circular(20),
                    //   ),
                    //   child: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       Icon(
                    //         _userType == 'event_host'
                    //             ? Icons.event_note
                    //             : Icons.people,
                    //         color: Colors.white,
                    //         size: 18,
                    //       ),
                    //       const SizedBox(width: 8),
                    //       Text(
                    //         _userType == 'event_host'
                    //             ? 'Event Host'
                    //             : 'Volunteer',
                    //         style: const TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 14,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 40),
                    // Login Card
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
                          // Name Field (only for signup)
                          // if (!_isLogin) ...[
                          //   TextFormField(
                          //     controller: _nameController,
                          //     decoration: InputDecoration(
                          //       labelText: "Full Name",
                          //       prefixIcon: const Icon(Icons.person_outlined),
                          //       border: OutlineInputBorder(
                          //         borderRadius: BorderRadius.circular(12),
                          //       ),
                          //       filled: true,
                          //       fillColor: Colors.grey[50],
                          //     ),
                          //     validator: (value) {
                          //       if (!_isLogin &&
                          //           (value == null || value.isEmpty)) {
                          //         return 'Please enter your name';
                          //       }
                          //       return null;
                          //     },
                          //   ),
                          //   const SizedBox(height: 16),
                          //   // Date of Birth (only for signup)
                          //   TextFormField(
                          //     controller: _dobController,
                          //     readOnly: true,
                          //     decoration: InputDecoration(
                          //       labelText: "Date of Birth",
                          //       hintText:
                          //           "Select your date of birth (18+ only)",
                          //       prefixIcon: const Icon(Icons.cake_outlined),
                          //       border: OutlineInputBorder(
                          //         borderRadius: BorderRadius.circular(12),
                          //       ),
                          //       filled: true,
                          //       fillColor: Colors.grey[50],
                          //     ),
                          //     onTap: () async {
                          //       FocusScope.of(context).unfocus();
                          //       final now = DateTime.now();
                          //       final initialDate = DateTime(
                          //         now.year - 18,
                          //         now.month,
                          //         now.day,
                          //       );
                          //       final firstDate = DateTime(1900);
                          //       final lastDate = now;

                          //       final picked = await showDatePicker(
                          //         context: context,
                          //         initialDate: initialDate,
                          //         firstDate: firstDate,
                          //         lastDate: lastDate,
                          //       );

                          //       if (picked != null) {
                          //         _dobController.text =
                          //             "${picked.day.toString().padLeft(2, '0')}/"
                          //             "${picked.month.toString().padLeft(2, '0')}/"
                          //             "${picked.year}";
                          //       }
                          //     },
                          //     validator: (value) {
                          //       if (!_isLogin &&
                          //           (value == null || value.isEmpty)) {
                          //         return 'Please select your date of birth';
                          //       }
                          //       // Enforce minimum age of 18
                          //       try {
                          //         final parts = value!.split('/');
                          //         if (parts.length != 3) {
                          //           return 'Invalid date format';
                          //         }
                          //         final day = int.parse(parts[0]);
                          //         final month = int.parse(parts[1]);
                          //         final year = int.parse(parts[2]);
                          //         final dob = DateTime(year, month, day);
                          //         final now = DateTime.now();
                          //         final eighteenYearsAgo = DateTime(
                          //           now.year - 18,
                          //           now.month,
                          //           now.day,
                          //         );
                          //         if (dob.isAfter(eighteenYearsAgo)) {
                          //           return 'You must be at least 18 years old';
                          //         }
                          //       } catch (_) {
                          //         return 'Invalid date of birth';
                          //       }
                          //       return null;
                          //     },
                          //   ),
                          //   const SizedBox(height: 16),
                          //   TextFormField(
                          //     controller: _phoneController,
                          //     keyboardType: TextInputType.phone,
                          //     decoration: InputDecoration(
                          //       labelText: "Phone Number (India)",
                          //       prefixIcon: const Icon(Icons.phone_outlined),
                          //       prefixText: "+91 ",
                          //       border: OutlineInputBorder(
                          //         borderRadius: BorderRadius.circular(12),
                          //       ),
                          //       filled: true,
                          //       fillColor: Colors.grey[50],
                          //     ),
                          //     validator: (value) {
                          //       if (!_isLogin &&
                          //           (value == null || value.isEmpty)) {
                          //         return 'Please enter your Indian mobile number';
                          //       }
                          //       final digits = value!.replaceAll(
                          //         RegExp(r'[^0-9]'),
                          //         '',
                          //       );
                          //       // Indian mobile numbers are 10 digits, starting with 6-9
                          //       if (digits.length != 10 ||
                          //           !RegExp(r'^[6-9]').hasMatch(digits)) {
                          //         return 'Enter a valid 10-digit Indian mobile number';
                          //       }
                          //       return null;
                          //     },
                          //   ),
                          //   const SizedBox(height: 16),
                          // ],
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }

                              // Trim whitespace for validation
                              final trimmedValue = value.trim();

                              // Check for @ symbol
                              if (!trimmedValue.contains('@')) {
                                return 'Email must contain @ symbol';
                              }

                              // Split email into local and domain parts
                              final parts = trimmedValue.split('@');
                              if (parts.length != 2) {
                                return 'Email must have exactly one @ symbol';
                              }

                              final localPart = parts[0];
                              final domainPart = parts[1];

                              // Check local part (before @)
                              if (localPart.isEmpty) {
                                return 'Email must have a username before @';
                              }

                              // Check domain part (after @)
                              if (domainPart.isEmpty) {
                                return 'Email must have a domain after @';
                              }

                              // Check for TLD (must contain a dot and have extension)
                              if (!domainPart.contains('.')) {
                                return 'Email must include a domain extension (e.g., .com, .org)';
                              }

                              // Check that TLD has at least 2 characters
                              final domainParts = domainPart.split('.');
                              if (domainParts.length < 2 ||
                                  domainParts.last.length < 2) {
                                return 'Email must have a valid domain extension (e.g., .com, .org, .net)';
                              }

                              // Comprehensive email format validation using regex
                              final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              );

                              if (!emailRegex.hasMatch(trimmedValue)) {
                                return 'Please enter a valid email address (e.g., name@example.com)';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              // Apply stronger requirement only during account creation
                              // if (!_isLogin) {
                              //   // Must include at least one of # @ _
                              //   final hasRequiredSpecial =
                              //       value.contains('#') ||
                              //       value.contains('@') ||
                              //       value.contains('_');
                              //   if (!hasRequiredSpecial) {
                              //     return 'Password must include at least one of: #, @, _';
                              //   }
                              // }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          // Forgot Password
                          // if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ForgetPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 33, 78, 52),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Login/Sign Up Button
                          ElevatedButton(
                            // onPressed: () async {
                            //   if (_formKey.currentState!.validate()) {
                            //     try {
                            //       // Show loading indicator
                            //       showDialog(
                            //         context: context,
                            //         barrierDismissible: false,
                            //         builder: (context) => const Center(
                            //           child: CircularProgressIndicator(
                            //             color: Color.fromARGB(255, 33, 78, 52),
                            //           ),
                            //         ),
                            //       );

                            //       if (_isLogin) {
                            //         // Sign in
                            //         await SupabaseService.signIn(
                            //           email: _emailController.text.trim(),
                            //           password: _passwordController.text,
                            //         );

                            //         // Close loading dialog
                            //         if (context.mounted) Navigator.pop(context);

                            //         // Show success message
                            //         if (context.mounted) {
                            //           ScaffoldMessenger.of(
                            //             context,
                            //           ).showSnackBar(
                            //             const SnackBar(
                            //               content: Text('Login successful!'),
                            //               backgroundColor: Color.fromARGB(
                            //                 255,
                            //                 33,
                            //                 78,
                            //                 52,
                            //               ),
                            //             ),
                            //           );
                            //           // Navigate to home or dashboard
                            //           Navigator.pop(context);
                            //         }
                            //       }
                            //       // else {
                            //       //   // Sign up
                            //       //   await SupabaseService.signUp(
                            //       //     email: _emailController.text.trim(),
                            //       //     password: _passwordController.text,
                            //       //     fullName: _nameController.text.trim(),
                            //       //     phone: _phoneController.text.trim(),
                            //       //     dob: _dobController.text.trim(),
                            //       //   );

                            //       //   // Close loading dialog
                            //       //   if (context.mounted) Navigator.pop(context);

                            //       //   // Show success message
                            //       //   if (context.mounted) {
                            //       //     ScaffoldMessenger.of(
                            //       //       context,
                            //       //     ).showSnackBar(
                            //       //       const SnackBar(
                            //       //         content: Text(
                            //       //           'Account created successfully! Please check your email to verify your account.',
                            //       //         ),
                            //       //         backgroundColor: Color.fromARGB(
                            //       //           255,
                            //       //           33,
                            //       //           78,
                            //       //           52,
                            //       //         ),
                            //       //         duration: Duration(seconds: 4),
                            //       //       ),
                            //       //     );
                            //       //   }
                            //       // }
                            //     } catch (e) {
                            //       // Close loading dialog
                            //       if (context.mounted) Navigator.pop(context);

                            //       // Show error message
                            //       if (context.mounted) {
                            //         ScaffoldMessenger.of(context).showSnackBar(
                            //           SnackBar(
                            //             content: Text(
                            //               _isLogin
                            //                   ? 'Login failed: ${e.toString()}'
                            //                   : 'Sign up failed: ${e.toString()}',
                            //             ),
                            //             backgroundColor: Colors.red,
                            //           ),
                            //         );
                            //       }
                            //     }
                            //   }
                            // },
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  await SupabaseService.signIn(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                  );

                                  if (context.mounted) Navigator.pop(context); // Pop loading dialog

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Login successful!'),
                                      ),
                                    );
                                    
                                    // Redirection is handled by the global auth listener in main.dart
                                    // await SupabaseService.handlePostAuthRedirect(context);
                                  }
                                } catch (e) {
                                  if (context.mounted) Navigator.pop(context); // Pop loading dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Login failed: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                33,
                                78,
                                52,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            // child: Text(
                            //   _isLogin ? "Sign In" : "Create Account",
                            //   style: const TextStyle(
                            //     fontSize: 16,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  "OR",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Google Sign In Button
                          _SocialButton(
                            icon: Icons.g_mobiledata,
                            label: "Continue with Google",
                            color: Colors.white,
                            textColor: Colors.black87,
                            borderColor: Colors.grey[300]!,
                            onPressed: () async {
                              try {
                                  await SupabaseService.signInWithGoogle();
                                  
                                  // Redirection is handled by the global auth listener in main.dart
                                  /*
                                  if (SupabaseService.isLoggedIn) {
                                    if (context.mounted) {
                                      await SupabaseService.handlePostAuthRedirect(context);
                                    }
                                  }
                                  */
                             } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Google sign-in failed: ${e.toString()}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }

                                // Handle redirect for Google Sign-In too if needed
                                // Currently SupabaseService.signInWithGoogle() is minimal
                                // Logic would ideally naturally flow if we check auth state or use a stream
                                // But for now, user requested specific flow.
                                // NOTE: The Google Sign-In implementation in SupabaseService relies on redirects
                                // and might not return execution here in the same way depending on platform.
                                // If it does await and complete, we should check role here too.
                                
                                // if (SupabaseService.isLoggedIn) {
                                //    final userProfile = await SupabaseService.getUserFromUsersTable();
                                //    final role = userProfile?['role'] as String?;
                                   
                                //    if (context.mounted) {
                                //         if (role == 'volunteer') {
                                //           Navigator.pushReplacementNamed(
                                //             context,
                                //             '/volunteer-dashboard',
                                //           );
                                //         } else if (role == 'admin') {
                                //            Navigator.pushReplacementNamed(
                                //             context,
                                //             '/admin-dashboard',
                                //           );
                                //         } 
                                //         // ... other roles ...
                                //    }
                                // }
                             },
                           ),
                          const SizedBox(height: 12),
                          // Facebook Sign In Button
                          _SocialButton(
                            icon: Icons.facebook,
                            label: "Continue with Facebook",
                            color: const Color(0xFF1877F2),
                            textColor: Colors.white,
                            borderColor: const Color(0xFF1877F2),
                            onPressed: () {
                              // TODO: Implement Facebook authentication
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Facebook authentication coming soon!',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/signup');
                                },
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 33, 78, 52),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onPressed;

  const _SocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
