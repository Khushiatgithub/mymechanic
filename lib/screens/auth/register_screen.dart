import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/auth_service.dart';

/// Customer registration screen for MyMechanic.
///
/// Phase 3 Step 4.4: Login, Registration & Authentication Service.
/// Implements required fields (name, email, password) and optional phone matching the backend schema,
/// client-side confirmation check, loading states, and error handling.
class RegisterScreen extends StatefulWidget {
  final AuthService? authService;
  final VoidCallback? onRegisterSuccess;

  const RegisterScreen({
    super.key,
    this.authService,
    this.onRegisterSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  AuthService get _authService => widget.authService ?? AuthService.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
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
      final user = await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully! Welcome, ${user.name}.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (widget.onRegisterSuccess != null) {
        widget.onRegisterSuccess!();
      } else {
        // Pop register screen back to previous screen
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const Key('register_back_button'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Header
                  Text(
                    'Create Account',
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join MyMechanic for genuine parts, doorstep pickup, and expert car care.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message Banner
                  if (_errorMessage != null) ...[
                    Container(
                      key: const Key('register_error_banner'),
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

                  // Full Name
                  Text(
                    'Full Name *',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('register_name_input'),
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'e.g. Rohit Sharma',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (value) {
                      final clean = value?.trim() ?? '';
                      if (clean.isEmpty) {
                        return 'Please enter your full name.';
                      }
                      if (clean.length > 100) {
                        return 'Name cannot exceed 100 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Address
                  Text(
                    'Email Address *',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('register_email_input'),
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
                        return 'Please provide a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Number (Optional)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phone Number',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Optional',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('register_phone_input'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'e.g. 9876543210',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (value) {
                      final clean = value?.trim() ?? '';
                      if (clean.isEmpty) return null; // Optional
                      final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
                      if (!phoneRegex.hasMatch(clean.replaceAll(RegExp(r'[-\s]'), ''))) {
                        return 'Please enter a valid 10-15 digit phone number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  Text(
                    'Password * (Min 8 characters)',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('register_password_input'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'At least 8 characters',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        key: const Key('register_password_visibility_toggle'),
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
                        return 'Please enter a password.';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters long.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  Text(
                    'Confirm Password *',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('register_confirm_password_input'),
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !_isLoading,
                    onFieldSubmitted: (_) => _handleRegister(),
                    decoration: InputDecoration(
                      hintText: 'Re-enter your password',
                      prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                      suffixIcon: IconButton(
                        key: const Key('register_confirm_password_visibility_toggle'),
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
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
                        return 'Please confirm your password.';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('register_submit_button'),
                      onPressed: _isLoading ? null : _handleRegister,
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
                              'Create My Account',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Link back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        key: const Key('register_login_link'),
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        child: Text(
                          'Log In',
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
