import 'package:flutter/material.dart';

/// Strip displaying trusted OEM/OES original spare parts partner brands matching reference screenshot.
class SparePartsStrip extends StatelessWidget {
  const SparePartsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Original Spare Parts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Extended Warranty with MyMechanic',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Brand Logos Strip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBoschLogo(),
                _buildValeoLogo(),
                _buildMahleLogo(),
                _buildNtnLogo(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoschLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFDC2626), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.flash_on_rounded, color: Color(0xFFDC2626), size: 12),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'BOSCH',
          style: TextStyle(
            color: Color(0xFFDC2626),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildValeoLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Valeo',
          style: TextStyle(
            color: Color(0xFF16A34A),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        Container(
          width: 42,
          height: 2.5,
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildMahleLogo() {
    return const Text(
      'MAHLE',
      style: TextStyle(
        color: Color(0xFF1E3A8A),
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildNtnLogo() {
    return const Text(
      'NTN',
      style: TextStyle(
        color: Color(0xFF0284C7),
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}
