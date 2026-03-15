import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/authentication_service.dart';
import 'services/firestore_service.dart';

// 🔹 Screens
// import 'home_screen.dart';
// import 'hks_home_screen.dart';
import 'panchayath_home_screen.dart';
import 'admin_home_screen.dart';
import 'citizen_signup_screen.dart';
import 'forgot_password_screen.dart';
import 'screens/citizen/citizen_main_wrapper.dart';
import 'screens/worker/worker_main_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.recycling, size: 80, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'HARITHAM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                
                _buildLabel('Email / Username'),
                TextFormField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: 'Enter your email or username',
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                
                _buildLabel('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hidePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
                ),
                
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _loading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _login();
                          }
                        },
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'LOGIN',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 48),
                
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CitizenSignupScreen()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(
                          text: "Sign up",
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }

  // ================= LOGIN =================

  Future<void> _login() async {
    final String identifier = _inputController.text.trim();
    final String password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _show("Please enter both email/username and password");
      return;
    }

    print("LOGIN_UI: Login button pressed. Identifier: $identifier");
    setState(() => _loading = true);

    try {
      final authService = AuthenticationService();
      final firestoreService = FirestoreService();

      print("LOGIN_UI: Calling AuthenticationService.loginWithIdentifier...");
      final user = await authService.loginWithIdentifier(identifier, password);

      if (user != null) {
        print("LOGIN_UI: Firebase Auth confirmed for UID: ${user.uid}");

        // Reload user to get latest emailVerified status
        await user.reload();
        final updatedUser = authService.currentUser;

        // Check if email is verified
        if (updatedUser != null && !updatedUser.emailVerified) {
          print("LOGIN_UI: Email not verified for UID: ${updatedUser.uid}");
          _show("Please verify your email before logging in.");
          await authService.logout();
          return;
        }

        // Fetch profile for routing
        final currentUser = updatedUser ?? user;
        print("LOGIN_UI: Retrieving Firestore profile to determine role...");
        final profile = await firestoreService.getUserProfile(currentUser.uid);

        if (profile != null) {
          final String role = (profile['role'] ?? 'citizen')
              .toString()
              .trim()
              .toLowerCase();
          final String name = profile['name'] ?? profile['username'] ?? 'User';

          print("LOGIN_UI: Firestore lookup successful. Profile Role: $role");

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('role', role);
          await prefs.setString('userId', currentUser.uid);
          await prefs.setString('userName', name);

          print("LOGIN_UI: Preferences saved. Initiating redirection...");
          _openByRole(role);
        } else {
          print(
            "LOGIN_UI: ERROR - Profile document missing for UID: ${user.uid}",
          );
          _show("User profile setup incomplete. Contact support.");
        }
      } else {
        print(
          "LOGIN_UI: ERROR - Auth service returned null user without throwing.",
        );
      }
    } catch (e) {
      print("LOGIN_UI: CATCH block triggered. Error type/msg: ${e.toString()}");
      String errorMsg = 'Login failed';

      if (e == 'username-not-found') {
        errorMsg = 'Username not found';
      } else if (e == 'invalid-credential') {
        errorMsg = 'Incorrect username or password';
      } else if (e == 'user-not-found') {
        errorMsg = 'User profile not found in system';
      } else if (e.toString().contains('network-request-failed')) {
        errorMsg = 'Network error. Please check your connection.';
      } else {
        errorMsg = "Login Error: $e";
      }

      _show(errorMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= ROLE ROUTING =================

  void _openByRole(String role) {
    print("LOGIN_ROUTING: Navigating user for role: [$role]");

    if (role == 'hks_worker' || role == 'hks') {
      print("LOGIN_ROUTING: Redirecting to HKS Dashboard");
      _go(const WorkerMainWrapper());
    } else if (role == 'panchayath') {
      print("LOGIN_ROUTING: Redirecting to Panchayath Dashboard");
      _go(const PanchayathHomeScreen());
    } else if (role == 'admin') {
      print("LOGIN_ROUTING: Redirecting to Admin Dashboard");
      _go(const AdminHomeScreen());
    } else {
      print("LOGIN_ROUTING: Redirecting to Citizen Home Screen (Default)");
      _go(const CitizenMainWrapper());
    }
  }

  void _go(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
