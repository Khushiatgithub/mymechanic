import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Banner item model for Promotional Carousel.
class PromoBannerItem {
  final String tag;
  final String title;
  final String subtitle;
  final String? code;
  final String? priceText;
  final String actionLabel;
  final List<Color> gradientColors;
  final IconData icon;
  final String? imageAsset;
  final VoidCallback onTap;

  const PromoBannerItem({
    required this.tag,
    required this.title,
    required this.subtitle,
    this.code,
    this.priceText,
    required this.actionLabel,
    required this.gradientColors,
    required this.icon,
    this.imageAsset,
    required this.onTap,
  });
}

/// Promotional Banner Carousel for MyMechanic Home Screen.
///
/// Features:
/// - Horizontally scrollable PageView with viewportFraction for a modern peek preview.
/// - Rounded card corners with subtle shadow.
/// - Dynamic page indicator dots with smooth animations.
/// - MyMechanic original branding:
///   1. MyMechanic Service Fest (Flat ₹500 OFF with MYFIRST500)
///   2. Periodic Car Service (10,000 km Warranty, starting ₹1,499)
///   3. Car Spa & Deep Cleaning (High-Pressure Foam Wash, 25% OFF with COOLCHILL25)
///   4. 24x7 Roadside Assistance (30-min quick reach, Towing & Battery Jumpstart)
class PromoBannerCarousel extends StatefulWidget {
  final VoidCallback onBookServiceFest;
  final VoidCallback onBookPeriodicService;
  final VoidCallback onBookCarSpa;
  final VoidCallback onRoadsideAssistance;

  const PromoBannerCarousel({
    super.key,
    required this.onBookServiceFest,
    required this.onBookPeriodicService,
    required this.onBookCarSpa,
    required this.onRoadsideAssistance,
  });

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  late final List<PromoBannerItem> _banners;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);

    _banners = [
      PromoBannerItem(
        tag: 'LIMITED TIME FEST',
        title: 'MyMechanic Service Fest',
        subtitle: 'Flat ₹500 OFF + Free 40-Point Car Health Scan',
        priceText: 'Flat ₹500 OFF',
        actionLabel: 'Book Now',
        gradientColors: const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
        icon: Icons.car_repair_rounded,
        imageAsset: AppConstants.bannerServiceFest,
        onTap: widget.onBookServiceFest,
      ),
      PromoBannerItem(
        tag: '10,000 KM WARRANTY',
        title: 'Periodic Car Service',
        subtitle: '100% Genuine OEM Spares • Free Doorstep Pickup',
        priceText: 'From ₹1,499/-',
        actionLabel: 'View Packages',
        gradientColors: const [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
        icon: Icons.verified_rounded,
        imageAsset: AppConstants.bannerPeriodicService,
        onTap: widget.onBookPeriodicService,
      ),
      PromoBannerItem(
        tag: '25% DISCOUNT',
        title: 'Car Spa & Cleaning',
        subtitle: 'High-Pressure Foam Wash + UV Steam Sanitization',
        priceText: 'Flat 25% OFF',
        actionLabel: 'Explore Spa',
        gradientColors: const [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
        icon: Icons.local_car_wash_rounded,
        imageAsset: AppConstants.bannerCarSpa,
        onTap: widget.onBookCarSpa,
      ),
      PromoBannerItem(
        tag: 'FAST 30-MIN REACH',
        title: 'Roadside Assistance',
        subtitle: 'Flat Tyre, Battery Jumpstart & Flatbed Towing 24x7',
        priceText: 'Helpline: +91 88269 91028',
        actionLabel: 'Get Help',
        gradientColors: const [Color(0xFF7F1D1D), Color(0xFFB91C1C), Color(0xFFDC2626)],
        icon: Icons.emergency_rounded,
        imageAsset: AppConstants.bannerRoadsideAssist,
        onTap: widget.onRoadsideAssistance,
      ),
    ];

    // Optional gentle auto-advance that does not fight user interactions
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 165,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return _buildBannerCard(banner);
            },
          ),
        ),
        const SizedBox(height: 10),

        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBannerCard(PromoBannerItem banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: banner.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: banner.gradientColors.first.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: banner.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Text details
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tag pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          banner.tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Title & Subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            banner.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 11.5,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Bottom action row: Code/Price + CTA button
                      Row(
                        children: [
                          if (banner.code != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                banner.code!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          else if (banner.priceText != null)
                            Text(
                              banner.priceText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  banner.actionLabel,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Car / Mechanic Picture Container
                const SizedBox(width: 10),
                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: banner.imageAsset != null
                          ? Image.asset(
                              banner.imageAsset!,
                              width: 82,
                              height: 82,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.white.withValues(alpha: 0.15),
                                child: Icon(
                                  banner.icon,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.white.withValues(alpha: 0.15),
                              child: Icon(
                                banner.icon,
                                size: 38,
                                color: Colors.white,
                              ),
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
