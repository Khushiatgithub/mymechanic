import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

/// Customer login screen for MyMechanic.
///
/// Phase 3 Step 4.4: Login, Registration & Authentication Service.
/// Provides responsive email/password authentication, client-side validation,
/// loading state management, double-submit prevention, and user-friendly error feedback.
class LoginScreen extends StatefulWidget {
  final AuthService? authService;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.authService,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  AuthService get _authService => widget.authService ?? AuthService.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) return; // Prevent double submit

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${user.name}!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthService.getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterScreen(
          authService: widget.authService,
          onRegisterSuccess: widget.onLoginSuccess,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const Key('login_back_button'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header & Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.car_repair_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Screen Title
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in to access your garage, track active services, and sync bookings.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Message Banner
                  if (_errorMessage != null) ...[
                    Container(
                      key: const Key('login_error_banner'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Input Field
                  Text(
                    'Email Address',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('login_email_input'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'e.g. rohit.sharma@example.com',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (value) {
                      final clean = value?.trim() ?? '';
                      if (clean.isEmpty) {
                        return 'Please enter your email address.';
                      }
                      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                      if (!emailRegex.hasMatch(clean)) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password Input Field
                  Text(
                    'Password',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('login_password_input'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    enabled: !_isLoading,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      hintText: 'Enter your account password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        key: const Key('login_password_visibility_toggle'),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('login_submit_button'),
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Log In',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Switch to Registration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        key: const Key('login_register_link'),
                        onPressed: _isLoading ? null : _navigateToRegister,
                        child: Text(
                          'Register here',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
