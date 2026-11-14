import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/vehicle.dart';
import 'sell_car_valuation_sheet.dart';

/// Full-width "Sell your car for the Best Price" promo banner card with dot indicators.
class SellCarPromoBanner extends StatelessWidget {
  final Vehicle? activeVehicle;
  final VoidCallback? onSellCarTap;

  const SellCarPromoBanner({
    super.key,
    this.activeVehicle,
    this.onSellCarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Banner Card
          InkWell(
            onTap: () {
              if (onSellCarTap != null) {
                onSellCarTap!();
              } else {
                SellCarValuationSheet.show(
                  context: context,
                  vehicle: activeVehicle,
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 148,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF28114E),
                    Color(0xFF3B156E),
                    Color(0xFF1E0D38),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF28114E).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    // Left image (car seller with sunflowers beside parked cars)
                    SizedBox(
                      width: 135,
                      height: double.infinity,
                      child: Image.asset(
                        AppConstants.bannerSellCar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF381B6D),
                          child: const Icon(
                            Icons.directions_car_filled_rounded,
                            color: Colors.white30,
                            size: 48,
                          ),
                        ),
                      ),
                    ),

                    // Right content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Spinny / Partner Logo Row
                            Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E63),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'S',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Spinny',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),

                            // Main Headline
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Sell your car\n',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'for the ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Best Price',
                                    style: TextStyle(
                                      color: Color(0xFFFACC15),
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Benefits Bullets
                            Row(
                              children: [
                                _buildFeatureBadge(
                                  Icons.verified_outlined,
                                  'Best Price\nAssurance',
                                ),
                                const SizedBox(width: 10),
                                _buildFeatureBadge(
                                  Icons.currency_rupee_rounded,
                                  'Same Day\nPayment',
                                ),
                              ],
                            ),

                            // Bottom Row (SELL NOW button + Brand Logo)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1.5),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'SELL NOW',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.directions_car_filled_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 14,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'MyMechanic',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
          const SizedBox(height: 10),

          // 3 Indicator dots (matching screenshot)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 0.8),
          ),
          child: Icon(icon, color: Colors.white, size: 9),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
