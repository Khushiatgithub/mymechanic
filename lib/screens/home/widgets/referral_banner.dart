import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// Referral promotion banner: "Earn ₹ 1000 for every Friend you Refer".
class ReferralBanner extends StatelessWidget {
  const ReferralBanner({super.key});

  void _openReferralSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const referralCode = 'MYMECH1000';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refer & Earn ₹ 1000',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Share with car owners & earn credits',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'How it works:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildStep('1', 'Share your referral code or link with friends & family.', isDark),
            _buildStep('2', 'Your friend gets ₹500 instant discount on their first service.', isDark),
            _buildStep('3', 'You get ₹1,000 wallet credits deposited once their car is delivered!', isDark),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR REFERRAL CODE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        referralCode,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral code copied to clipboard!'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(
                      text: 'Hey! Use my referral code $referralCode on MyMechanic to get ₹500 off on your car service: https://www.mymechanicpremiumcarservice.com',
                    ),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invite message copied! Share it on WhatsApp or SMS.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Invite Link', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  static Widget _buildStep(String number, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header matching screenshot
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Earn ₹ 1000 for every Friend you Refer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Banner Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [
                      Color(0xFF1B1A1E),
                      Color(0xFF221A16),
                    ]
                  : const [
                      Color(0xFFFFF7ED),
                      Color(0xFFFFEDD5),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFFDBA74),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFFEA580C).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Megaphone Icon container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),

                // Text Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Refer & Earn ₹ 1000',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF9A3412),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Friend gets ₹500 off • You earn ₹1000 credits',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Beautiful, un-squished REFER NOW button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openReferralSheet(context),
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        child: Text(
                          'REFER NOW',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
