import 'package:flutter/material.dart';

/// Top Action Cards row on Home Screen:
/// - Left: Miles (Free Road Side Assistance)
/// - Right: Challan (Govt Authorised Records, 1 Click Discovery)
class TopActionCards extends StatelessWidget {
  final VoidCallback onRoadsideAssistanceTap;
  final VoidCallback onChallanTap;

  const TopActionCards({
    super.key,
    required this.onRoadsideAssistanceTap,
    required this.onChallanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Row(
        children: [
          // Left Card: Miles (Free Road Side Assistance)
          Expanded(
            child: _buildActionCard(
              title: 'Miles',
              titleBadge: 'ASSIST',
              subtitle: 'Free Road Side Assistance',
              icon: Icons.car_repair_rounded,
              gradientColors: const [
                Color(0xFFE53935),
                Color(0xFFFF5252),
              ],
              onTap: onRoadsideAssistanceTap,
            ),
          ),
          const SizedBox(width: 12),
          // Right Card: Challan (Govt Authorised Records)
          Expanded(
            child: _buildActionCard(
              title: 'Challan',
              titleBadge: '1 CLICK',
              subtitle: 'Govt Authorised Records',
              icon: Icons.receipt_long_rounded,
              gradientColors: const [
                Color(0xFF512DA8),
                Color(0xFF7E57C2),
              ],
              onTap: onChallanTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String titleBadge,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background decorative icon watermark
              Positioned(
                right: -6,
                bottom: -10,
                child: Icon(
                  icon,
                  size: 54,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              // Foreground Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          titleBadge,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
