import 'package:flutter/material.dart';
import 'package:task_slider/services/firebase_auth_service.dart';
import 'home_screen.dart';

const Color _kBg = Color(0xFF0D1028);
const Color _kAccent1 = Color(0xFF7A5CFF);
const Color _kAccent2 = Color(0xFF3D8BFF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureConfirmPassword = true;
  bool _authBusy = false;

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _continueToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (_validateEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email to reset password.')),
      );
      return;
    }
    setState(() => _authBusy = true);
    final response = await _authService.sendPasswordResetEmail(email);
    if (!mounted) {
      return;
    }
    setState(() => _authBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message)),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _authBusy = true);
    final response = await _authService.signInWithGoogle();
    if (!mounted) {
      return;
    }
    setState(() => _authBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message)),
    );
    if (response.success) {
      _continueToApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1F44), Color(0xFF0D1028)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const SizedBox(height: 12),
                const Icon(Icons.shield_outlined, size: 64, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Welcome to TruthLens AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login or create an account to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          indicatorColor: _kAccent2,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(text: 'Login'),
                            Tab(text: 'Signup'),
                          ],
                        ),
                        SizedBox(
                          height: 420,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              Form(
                                key: _loginFormKey,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _emailController,
                                        validator: _validateEmail,
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: Icon(Icons.alternate_email),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscureLoginPassword,
                                        validator: (value) =>
                                            (value == null || value.length < 6)
                                                ? 'Password must be at least 6 characters'
                                                : null,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            onPressed: () => setState(
                                              () => _obscureLoginPassword =
                                                  !_obscureLoginPassword,
                                            ),
                                            icon: Icon(
                                              _obscureLoginPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _authBusy ? null : _handleForgotPassword,
                                          child: const Text(
                                            'Forgot password?',
                                            style: TextStyle(color: Colors.white70),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: _kAccent2,
                                          ),
                                          onPressed: _authBusy
                                              ? null
                                              : () async {
                                                  if (!_loginFormKey.currentState!.validate()) {
                                                    return;
                                                  }
                                                  setState(() => _authBusy = true);
                                                  final context = this.context;
                                                  final response = await _authService.login(
                                                    email: _emailController.text.trim(),
                                                    password: _passwordController.text.trim(),
                                                  );
                                                  if (!mounted) {
                                                    return;
                                                  }
                                                  setState(() => _authBusy = false);
                                                  // ignore: use_build_context_synchronously
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(response.message)),
                                                  );
                                                  if (response.success) {
                                                    _continueToApp();
                                                  }
                                                },
                                          child: const Text('Login'),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'By continuing, you agree to Terms & Privacy.',
                                        style: TextStyle(fontSize: 12, color: Colors.white54),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Form(
                                key: _signupFormKey,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _signupNameController,
                                        validator: (value) =>
                                            (value == null || value.trim().isEmpty)
                                                ? 'Name is required'
                                                : null,
                                        decoration: const InputDecoration(
                                          labelText: 'Full Name',
                                          prefixIcon: Icon(Icons.person_outline),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _signupEmailController,
                                        validator: _validateEmail,
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: Icon(Icons.alternate_email),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _signupPasswordController,
                                        obscureText: _obscureSignupPassword,
                                        validator: (value) =>
                                            (value == null || value.length < 6)
                                                ? 'Create a stronger password'
                                                : null,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            onPressed: () => setState(
                                              () => _obscureSignupPassword =
                                                  !_obscureSignupPassword,
                                            ),
                                            icon: Icon(
                                              _obscureSignupPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: _obscureConfirmPassword,
                                        validator: (value) =>
                                            value != _signupPasswordController.text
                                                ? 'Passwords do not match'
                                                : null,
                                        decoration: InputDecoration(
                                          labelText: 'Confirm Password',
                                          prefixIcon: const Icon(Icons.verified_user_outlined),
                                          suffixIcon: IconButton(
                                            onPressed: () => setState(
                                              () => _obscureConfirmPassword =
                                                  !_obscureConfirmPassword,
                                            ),
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: _kAccent1,
                                          ),
                                          onPressed: _authBusy
                                              ? null
                                              : () async {
                                                  if (!_signupFormKey.currentState!.validate()) {
                                                    return;
                                                  }
                                                  setState(() => _authBusy = true);
                                                  final context = this.context;
                                                  final email =
                                                      _signupEmailController.text.trim();
                                                  final response = await _authService.signUp(
                                                    name: _signupNameController.text.trim(),
                                                    email: email,
                                                    password:
                                                        _signupPasswordController.text.trim(),
                                                  );
                                                  if (!mounted) {
                                                    return;
                                                  }
                                                  setState(() => _authBusy = false);
                                                  // ignore: use_build_context_synchronously
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(response.message)),
                                                  );
                                                  if (response.success) {
                                                    _tabController.animateTo(0);
                                                  }
                                                },
                                          child: const Text('Create Account'),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'Your account helps personalize scam alerts.',
                                        style: TextStyle(fontSize: 12, color: Colors.white54),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white24)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('OR', style: TextStyle(color: Colors.white54)),
                            ),
                            Expanded(child: Divider(color: Colors.white24)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(color: Colors.white38),
                          ),
                          onPressed: _authBusy ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
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