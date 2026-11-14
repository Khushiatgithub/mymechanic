import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/offer.dart';
import '../booking/booking_flow_sheet.dart';

class OfferDetailSheet extends StatelessWidget {
  final Offer offer;

  const OfferDetailSheet({
    super.key,
    required this.offer,
  });

  static Future<void> show({
    required BuildContext context,
    required Offer offer,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferDetailSheet(offer: offer),
    );
  }

  void _copyCoupon(BuildContext context) {
    Clipboard.setData(ClipboardData(text: offer.couponCode));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Coupon code "${offer.couponCode}" copied to clipboard!',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _applyOffer(BuildContext context) {
    Navigator.pop(context);

    // Pick an appropriate service based on eligible category
    final service = MockData.allServices.firstWhere(
      (s) {
        if (offer.eligibleCategory != null && offer.eligibleCategory!.isNotEmpty) {
          final cat = MockData.categories.firstWhere(
            (c) => c.name.toLowerCase().contains(offer.eligibleCategory!.toLowerCase()) ||
                   offer.eligibleCategory!.toLowerCase().contains(c.name.toLowerCase()),
            orElse: () => MockData.categories.first,
          );
          return s.categoryId == cat.id;
        }
        return s.price >= offer.minOrderValue;
      },
      orElse: () => MockData.allServices.first,
    );

    BookingFlowSheet.show(
      context: context,
      serviceTitle: service.title,
      serviceDescription: service.description,
      price: service.price,
      originalPrice: service.originalPrice,
      durationText: service.durationText,
      warrantyPeriod: service.warrantyPeriod,
      initialVehicle: MockData.activeVehicle,
      initialCouponCode: offer.couponCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header title and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Offer Details',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Header with Gradient Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: offer.gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        offer.discountTag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      offer.validTill,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  offer.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Coupon Code Box with Copy Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COUPON CODE',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.couponCode,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyCoupon(context),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable details section
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OFFER DETAILS', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),

                  _buildDetailRow(
                    Icons.currency_rupee_rounded,
                    'Minimum Order Value',
                    offer.minOrderValue > 0
                        ? '${AppConstants.currencySymbol}${offer.minOrderValue.toInt()}'
                        : 'No minimum order required',
                  ),
                  if (offer.maxDiscount != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.savings_outlined,
                      'Maximum Discount',
                      '${AppConstants.currencySymbol}${offer.maxDiscount!.toInt()}',
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.category_outlined,
                    'Eligible Services',
                    offer.eligibleCategory != null ? offer.eligibleCategory! : 'All Services & Maintenance Packages',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.event_available_rounded,
                    'Validity',
                    offer.validTill,
                  ),

                  const SizedBox(height: 16),
                  Text('TERMS & CONDITIONS', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),

                  if (offer.terms.isNotEmpty)
                    ...offer.terms.map((term) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4, right: 8),
                                child: Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
                              ),
                              Expanded(
                                child: Text(term, style: AppTypography.bodySmall),
                              ),
                            ],
                          ),
                        ))
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(top: 4, right: 8),
                            child: Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
                          ),
                          Expanded(
                            child: Text(
                              'Valid on bookings placed through MyMechanic mobile application. Cannot be clubbed with other promos.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _copyCoupon(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Copy Code', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _applyOffer(context),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Apply Offer', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
