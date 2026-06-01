// signup_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  bool _obscurePassword = true;
  String _role = "requester";

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80),

                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign up to get started with Helpr',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Full Name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Phone
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (03XXXXXXXXX)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _role,
                  items: const [
                    DropdownMenuItem(
                      value: "requester",
                      child: Text("Requester"),
                    ),
                    DropdownMenuItem(value: "worker", child: Text("Worker")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _role = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Select Role",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Sign Up button
                ElevatedButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    final phone = _phoneController.text.trim();
                    final password = _passwordController.text.trim();

                    // 1. Empty check
                    final email = _emailController.text.trim();

                    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")),
                      );
                      return;
                    }

                    // 2. Phone format check (Pakistan format)
                    if (!RegExp(r'^03[0-9]{9}$').hasMatch(phone)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Enter phone like 03XXXXXXXXX"),
                        ),
                      );
                      return;
                    }

                    // 3. Email format check
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Enter a valid email address")),
                      );
                      return;
                    }

                    // 4. Password strength check
                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Password must be at least 6 characters",
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final result = await ApiService.signup(
                        name,
                        phone,
                        email,
                        password,
                        _role,
                      );

                      print("Signup response: $result");

                      if (result["message"] == "User created successfully") {
                        final userId = result["userId"];
                        final role = result["role"] ?? _role;

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Account created successfully!"),
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // Navigate to appropriate profile completion screen
                          await Future.delayed(const Duration(seconds: 1));
                          if (mounted) {
                            if (role == "worker") {
                              Navigator.pushReplacementNamed(
                                context,
                                '/workerProfileCompletion',
                                arguments: {'userId': userId},
                              );
                            } else {
                              Navigator.pushReplacementNamed(
                                context,
                                '/requesterProfileCompletion',
                                arguments: {'userId': userId},
                              );
                            }
                          }
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result["message"] ?? "Signup failed",
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print("Signup error: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ApiService.errorMessage(e))),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Sign Up', style: TextStyle(fontSize: 15)),
                ),

                const SizedBox(height: 20),

                // Already have an account
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
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
