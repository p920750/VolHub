import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'services/supabase_service.dart';
import 'services/verification_stream.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  SignupPageState createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  bool _isEmailVerified = false;
  bool _isVerifyingEmail = false;
  Timer? _verificationTimer;
  StreamSubscription? _verificationSubscription;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedRole;
  bool _obscurePassword = true;

  // Regex for validation
  final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  // Error messages for each field
  String? _nameError;
  String? _dobError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _roleError;

  // Phone verification state
  bool _isPhoneVerified = false;
  bool _isVerifyingPhone = false;
  bool _isEnteringOtp = false;
  final _otpController = TextEditingController();
  Timer? _resendTimer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  void _startResendTimer() {
    _canResend = false;
    _secondsRemaining = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _startPhoneVerification() async {
    if (!_isEmailVerified) {
      setState(() {
        _phoneError = "Please verify email first";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email address first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _isVerifyingPhone = true;
      _phoneError = null;
    });

    try {
      await SupabaseService.sendPhoneVerificationOtp(email);
      setState(() {
        _isVerifyingPhone = false;
        _isEnteringOtp = true;
      });
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verification OTP sent to your email.')),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifyingPhone = false;
        _phoneError = "Failed to send OTP: ${e.toString()}";
      });
    }
  }

  Future<void> _verifyPhoneOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 8) {
      setState(() {
        _phoneError = "Please enter 8-digit OTP";
      });
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _isVerifyingPhone = true;
      _phoneError = null;
    });

    try {
      await SupabaseService.verifyEmailOtp(email, otp);
      setState(() {
        _isVerifyingPhone = false;
        _isPhoneVerified = true;
        _isEnteringOtp = false;
        _resendTimer?.cancel();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number verified!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifyingPhone = false;
        _phoneError = "Invalid OTP. Please try again.";
      });
    }
  }

  Future<void> _handleCreateAccount() async {
    if (!_validateForm()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final dob = _dobController.text.trim();
    final password = _passwordController.text.trim();
    
    // Map role
    final String role;
    if (_selectedRole == "Volunteers") {
      role = "volunteer";
    } else if (_selectedRole == "Event Organizers") {
      role = "event_manager";
    } else {
      // This should not happen if validation works
      role = _selectedRole ?? "volunteer";
    }

    String formattedDob = "";
    try {
      final parts = dob.split('/');
      if (parts.length == 3) {
        formattedDob = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    } catch (_) {}

    try {
      // Check if user exists in public.users
      final emailExists = await SupabaseService.checkEmailExists(email);
      final phoneExists = await SupabaseService.checkPhoneExists(phone);

      if (emailExists || phoneExists) {
        setState(() {
          if (emailExists) _emailError = "Email already exists";
          if (phoneExists) _phoneError = "Phone number already exists";
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(emailExists && phoneExists
                  ? 'Email and phone number already exist. Try logging in.'
                  : (emailExists
                      ? 'Email already exists. Try Google Log In or verify your credentials.'
                      : 'Phone number already exists.')),
              backgroundColor: Colors.red,
              action: emailExists ? SnackBarAction(
                label: 'Login',
                textColor: Colors.white,
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              ) : null,
            ),
          );
        }
        return;
      }

      // Create account in public.users (auth user already exists from email verification)
      await SupabaseService.completeSignup(
        email: email,
        fullName: name,
        userType: role,
        phone: phone,
        dob: formattedDob,
        isEmailVerified: _isEmailVerified,
        isPhoneVerified: _isPhoneVerified,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate or show success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen for Deep Link events from main.dart
    _verificationSubscription = VerificationStream().stream.listen((event) {
      if (!mounted) return;
      if (event == VerificationEvent.verified) {
        setState(() {
          _isEmailVerified = true;
          _isVerifyingEmail = false;
          _emailError = null;
        });
      } else if (event == VerificationEvent.rejected) {
        setState(() {
          _isVerifyingEmail = false;
          _isEmailVerified = false;
          _emailError = "Not the intended user";
        });
      }
    });

    // Also listen to Supabase auth state changes as a backup/primary mechanism
    SupabaseService.authStateChanges.listen((data) {
      if (!mounted) return;
      final session = data.session;
      if (session != null && session.user.email == _emailController.text.trim()) {
        setState(() {
          _isEmailVerified = true;
          _isVerifyingEmail = false;
          _emailError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _verificationSubscription?.cancel();
    _verificationTimer?.cancel();
    _resendTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Widget _buildErrorText(String? errorText) {
    if (errorText == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        errorText,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _validateForm() {
    bool isValid = true;
    setState(() {
      _nameError = _nameController.text.isEmpty ? "This field is required" : null;
      _dobError =
          _dobController.text.isEmpty ? "This field is required" : null;
      _phoneError = _phoneController.text.isEmpty
          ? "This field is required"
          : (!_phoneRegex.hasMatch(_phoneController.text.trim())
              ? "Invalid phone number"
              : null);
      _emailError = _emailController.text.isEmpty
          ? "This field is required"
          : (!_emailRegex.hasMatch(_emailController.text.trim())
              ? "Invalid email"
              : null);
      _passwordError =
          _passwordController.text.isEmpty ? "This field is required" : null;
      _roleError = _selectedRole == null ? "This field is required" : null;

      if (_nameError != null ||
          _dobError != null ||
          _phoneError != null ||
          _emailError != null ||
          _passwordError != null ||
          _roleError != null) {
        isValid = false;
      }

      if (isValid) {
        if (!_isEmailVerified) {
          _emailError = "Verify email";
          isValid = false;
        } else if (!_isPhoneVerified) {
          _phoneError = "Verify phone number";
          isValid = false;
        }
      }
    });
    return isValid;
  }

  // Removed _checkVerificationStatus as it is now handled by stream listeners

  Future<void> _startEmailVerification() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate ALL fields before verifying email (required for Confirm Signup template)
    bool hasErrors = false;
    setState(() {
      _nameError = name.isEmpty ? "Required for verification" : null;
      _phoneError = phone.isEmpty ? "Required for verification" : null;
      _dobError = dob.isEmpty ? "Required for verification" : null;
      _roleError = _selectedRole == null ? "Select a role first" : null;
      _emailError = !_emailRegex.hasMatch(email) ? "Invalid email" : null;
      _passwordError = password.length < 6
          ? "Password must be at least 6 characters"
          : null;

      if (_nameError != null ||
          _phoneError != null ||
          _dobError != null ||
          _roleError != null ||
          _emailError != null ||
          _passwordError != null) {
        hasErrors = true;
      }
    });

    if (hasErrors) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please fill all fields before verifying email.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check if email or phone already exists in public.users
    final emailExists = await SupabaseService.checkEmailExists(email);
    final phoneExists = await SupabaseService.checkPhoneExists(phone);

    if (emailExists || phoneExists) {
      setState(() {
        if (emailExists) _emailError = "Email already exists";
        if (phoneExists) _phoneError = "Phone number already exists";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailExists && phoneExists
                ? 'Email and phone number already exist. Try logging in.'
                : (emailExists
                    ? 'Email already exists. Try Google Log In.'
                    : 'Phone number already exists.')),
            backgroundColor: Colors.red,
            action: emailExists ? SnackBarAction(
                label: 'Login',
                textColor: Colors.white,
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              ) : null,
          ),
        );
      }
      return;
    }

    setState(() {
      _emailError = null;
      _isVerifyingEmail = true;
    });

    String formattedDob = "";
    if (dob.isNotEmpty) {
      try {
        final parts = dob.split('/');
        if (parts.length == 3) {
          formattedDob = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      } catch (_) {}
    }

    // Map role
    final String mappedRole;
    if (_selectedRole == "Volunteers") {
      mappedRole = "volunteer";
    } else if (_selectedRole == "Event Organizers") {
      mappedRole = "event_manager";
    } else {
      mappedRole = _selectedRole ?? "volunteer";
    }

    try {
      // Use Confirm Signup template
      // Creates user in auth.users (but NOT in public.users due to disabled trigger)
      await SupabaseService.sendSignupConfirmation(
        email: email,
        password: password,
        fullName: name,
        userType: mappedRole,
        phone: phone,
        dob: formattedDob,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmation link sent! Check your email.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifyingEmail = false;
        _emailError = "Failed to send: ${e.toString()}";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                              color: Colors.black.withValues(alpha: 0.2),
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
                    const Text(
                      "Create an account to get started",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Login Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name Field
                          _buildErrorText(_nameError),
                          TextFormField(
                            controller: _nameController,
                            onChanged: (value) {
                              setState(() {
                                _nameError = value.isEmpty
                                    ? "Full Name is required"
                                    : null;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "Full Name",
                              prefixIcon: const Icon(Icons.person_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Date of Birth
                          _buildErrorText(_dobError),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Date of Birth",
                              hintText: "Select your date of birth (18+ only)",
                              prefixIcon: const Icon(Icons.cake_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            onTap: () async {
                              FocusScope.of(context).unfocus();
                              final now = DateTime.now();

                              final picked = await showDialog<DateTime>(
                                context: context,
                                builder: (context) => _CustomDatePickerDialog(
                                  initialDate: now,
                                  firstDate: DateTime(1900),
                                  lastDate: now,
                                ),
                              );

                              if (picked != null) {
                                setState(() {
                                  _dobController.text =
                                      "${picked.day.toString().padLeft(2, '0')}/"
                                      "${picked.month.toString().padLeft(2, '0')}/"
                                      "${picked.year}";
                                  _dobError = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          // Phone Number / OTP Field
                          _buildErrorText(_phoneError),
                          if (!_isEnteringOtp)
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              enabled: !_isPhoneVerified,
                              onChanged: (value) {
                                setState(() {
                                  if (value.isEmpty) {
                                    _phoneError = "Phone Number is required";
                                  } else if (!_phoneRegex
                                      .hasMatch(value.trim())) {
                                    _phoneError = "Invalid phone number";
                                  } else {
                                    _phoneError = null;
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                labelText: "Phone Number",
                                prefixIcon: Container(
                                  width: 48,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "🇮🇳",
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                                prefixText: "+91 ",
                                prefixStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                 suffixIcon: _isPhoneVerified
                                    ? Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            6, 6, 16, 6),
                                        child: Container(
                                          width: 100,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check,
                                                  color: Colors.white, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                "Verified",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                : (_phoneRegex.hasMatch(
                                            _phoneController.text.trim())
                                        ? Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                6, 6, 16, 6),
                                            child: ElevatedButton(
                                              onPressed: _isVerifyingPhone
                                                  ? null
                                                  : _startPhoneVerification,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16),
                                              ),
                                              child: _isVerifyingPhone
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Verify',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                            ),
                                          )
                                        : null),
                              ),
                            )
                          else
                            Column(
                              children: [
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 8,
                                  decoration: InputDecoration(
                                    labelText: "Enter 8-digit OTP",
                                    prefixIcon: const Icon(Icons.lock_clock),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ElevatedButton(
                                        onPressed: _isVerifyingPhone
                                            ? null
                                            : _verifyPhoneOtp,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        child: const Text("Verify",
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _canResend
                                          ? "Didn't receive OTP?"
                                          : "Resend in $_secondsRemaining s",
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12),
                                    ),
                                    if (_canResend)
                                      TextButton(
                                        onPressed: _startPhoneVerification,
                                        child: const Text("Resend Again",
                                            style: TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          // Email Field (with error message above)
                          _buildErrorText(_emailError),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) {
                              setState(() {
                                if (value.isEmpty) {
                                  _emailError = "Email is required";
                                } else if (!_emailRegex
                                    .hasMatch(value.trim())) {
                                  _emailError = "Invalid email";
                                } else {
                                  _emailError = null;
                                }
                                // Reset verification if email changes
                                if (_isEmailVerified) {
                                  _isEmailVerified = false;
                                }
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: const Icon(Icons.email_outlined),
                              suffixIcon: _isEmailVerified
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          6, 6, 16, 6),
                                      child: Container(
                                        width: 100,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check,
                                                color: Colors.white, size: 16),
                                            SizedBox(width: 4),
                                            Text(
                                              "Verified",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : (_emailRegex.hasMatch(
                                          _emailController.text.trim())
                                      ? Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              6, 6, 16, 6),
                                          child: ElevatedButton(
                                            onPressed: _isVerifyingEmail
                                                ? null
                                                : _startEmailVerification,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                            ),
                                            child: _isVerifyingEmail
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Text(
                                                    'Verify',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                          ),
                                        )
                                      : null),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Password Field
                          _buildErrorText(_passwordError),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onChanged: (value) {
                              setState(() {
                                if (value.isEmpty) {
                                  _passwordError = "Password is required";
                                } else if (value.length < 6) {
                                  _passwordError =
                                      "Password must be at least 6 characters";
                                } else {
                                  _passwordError = null;
                                }
                              });
                            },
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
                          ),
                          const SizedBox(height: 20),
                          // Role Dropdown
                          _buildErrorText(_roleError),
                          DropdownMenu<String>(
                            initialSelection: _selectedRole,
                            expandedInsets: EdgeInsets.zero,
                            label: const Text("Register as"),
                            leadingIcon: const Icon(Icons.work_outline),
                            inputDecorationTheme: InputDecorationTheme(
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            dropdownMenuEntries: ["Volunteers", "Event Organizers"]
                                .map((role) => DropdownMenuEntry<String>(
                                      value: role,
                                      label: role,
                                    ))
                                .toList(),
                            onSelected: (value) {
                              setState(() {
                                _selectedRole = value;
                                _roleError = null;
                              });
                            },
                          ),
                          const SizedBox(height: 32),
                          // Create Account Button
                          ElevatedButton(
                            onPressed: _handleCreateAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Link to Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Login",
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

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CustomDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

enum _PickerView { calendar, year, month }

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late DateTime _selectedDate;
  late _PickerView _currentView;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentView = _PickerView.calendar;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Integrated Header
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentView = _PickerView.year;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 33, 78, 52).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedDate.year.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${_getMonthName(_selectedDate.month)} ${_selectedDate.day}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 33, 78, 52),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit_calendar_outlined,
                          size: 20,
                          color: Color.fromARGB(255, 33, 78, 52),
                        ),
                      ],
                    ),
                    const Text(
                      "Tap to change Year/Month",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: _buildPickerChild(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                if (_currentView == _PickerView.calendar)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 33, 78, 52),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Confirm"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerChild() {
    switch (_currentView) {
      case _PickerView.calendar:
        return CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          onDateChanged: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        );
      case _PickerView.year:
        return YearPicker(
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          selectedDate: _selectedDate,
          onChanged: (date) {
            setState(() {
              _selectedDate = DateTime(date.year, _selectedDate.month, 1);
              _currentView = _PickerView.month;
            });
          },
        );
      case _PickerView.month:
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1;
            final isFuture = _selectedDate.year == widget.lastDate.year && month > widget.lastDate.month;
            final isSelected = month == _selectedDate.month;

            return InkWell(
              onTap: isFuture ? null : () {
                setState(() {
                  _selectedDate = DateTime(_selectedDate.year, month, 1);
                  _currentView = _PickerView.calendar;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color.fromARGB(255, 33, 78, 52) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey[300]!,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getMonthName(month).substring(0, 3),
                    style: TextStyle(
                      color: isFuture ? Colors.grey : (isSelected ? Colors.white : Colors.black),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        );
    }
  }
}