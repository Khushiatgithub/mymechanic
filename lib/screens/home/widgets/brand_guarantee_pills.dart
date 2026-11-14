import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Clean guarantee pills strip matching GoMechanic/MyMechanic standard guarantees:
/// - Free Doorstep Pick-up & Drop
/// - 100% Genuine Spares
/// - Network Warranty Assured
class BrandGuaranteePills extends StatelessWidget {
  const BrandGuaranteePills({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPill(
            icon: Icons.local_shipping_outlined,
            title: 'Free Doorstep',
            subtitle: 'Pick & Drop',
          ),
          Container(
            height: 24,
            width: 1,
            color: AppColors.border,
          ),
          _buildPill(
            icon: Icons.verified_outlined,
            title: '100% Genuine',
            subtitle: 'OEM/OES Spares',
          ),
          Container(
            height: 24,
            width: 1,
            color: AppColors.border,
          ),
          _buildPill(
            icon: Icons.shield_outlined,
            title: 'Network Warranty',
            subtitle: 'Assurance',
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textSecondary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
