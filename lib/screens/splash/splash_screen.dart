import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/auth_service.dart';
import '../main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Trigger startup session restoration concurrently on app launch
    AuthService.instance.initialize();

    // Auto-navigate to MainNavigationScreen after splash duration
    Future.delayed(AppConstants.splashDuration, () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainNavigationScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Stack(
        children: [
          // Subtle radial glow background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Central Logo and Branding
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Icon Mark (Official MyMechanic Logo)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          AppConstants.logoAsset,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.car_repair_rounded,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Title
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'My',
                            style: AppTypography.displayLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Mechanic',
                            style: AppTypography.displayLarge.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      AppConstants.appTagline,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Version / Quality Mark
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '100% Genuine OEM Spares • Transparent Pricing',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'v1.0.0',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
