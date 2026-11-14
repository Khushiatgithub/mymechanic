import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/coupon.dart';

class CouponSelectionSheet extends StatefulWidget {
  final double orderAmount;
  final String? serviceTitle;
  final String? serviceCategory;
  final String? currentCouponCode;
  final ValueChanged<Coupon> onCouponSelected;

  const CouponSelectionSheet({
    super.key,
    required this.orderAmount,
    this.serviceTitle,
    this.serviceCategory,
    this.currentCouponCode,
    required this.onCouponSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required double orderAmount,
    String? serviceTitle,
    String? serviceCategory,
    String? currentCouponCode,
    required ValueChanged<Coupon> onCouponSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CouponSelectionSheet(
        orderAmount: orderAmount,
        serviceTitle: serviceTitle,
        serviceCategory: serviceCategory,
        currentCouponCode: currentCouponCode,
        onCouponSelected: onCouponSelected,
      ),
    );
  }

  @override
  State<CouponSelectionSheet> createState() => _CouponSelectionSheetState();
}

class _CouponSelectionSheetState extends State<CouponSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Coupon> get _filteredCoupons {
    return MockData.coupons.where((coupon) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return coupon.code.toLowerCase().contains(q) ||
          coupon.title.toLowerCase().contains(q) ||
          coupon.description.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final coupons = _filteredCoupons;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Coupons', style: AppTypography.titleLarge),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Field
          TextField(
            controller: _searchController,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search coupons by code or name...',
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkSearchPlaceholder : AppColors.textSecondary,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: isDark ? AppColors.darkSearchPlaceholder : AppColors.textSecondary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: isDark ? AppColors.darkTextSecondary : null,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark ? const BorderSide(color: AppColors.darkBorder) : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark ? const BorderSide(color: AppColors.darkBorder) : BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val.trim());
            },
          ),
          const SizedBox(height: 14),

          // Subtotal Banner for reference
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Subtotal',
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${AppConstants.currencySymbol}${widget.orderAmount.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Coupon List
          Expanded(
            child: coupons.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No coupons match "$_searchQuery"', style: AppTypography.bodyMedium),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      final validation = coupon.validate(
                        orderAmount: widget.orderAmount,
                        category: widget.serviceCategory,
                      );
                      final isCurrent = widget.currentCouponCode?.toUpperCase() == coupon.code.toUpperCase();

                      return _buildCouponCard(coupon, validation, isCurrent);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Coupon coupon, CouponValidationResult validation, bool isCurrent) {
    final isValid = validation.isValid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? AppColors.success
              : (isValid
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.border)),
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Code Badge + Apply Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isValid
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkInputSurface : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isValid
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : Colors.grey.shade400),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Text(
                    coupon.code,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isValid ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'APPLIED',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: isValid
                        ? () {
                            Navigator.pop(context);
                            widget.onCouponSelected(coupon);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Title & Description
            Text(
              coupon.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              coupon.description,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            // Invalidation explanation if not valid
            if (!isValid && validation.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        validation.errorMessage!,
                        style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Terms / Conditions bullets
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (coupon.minOrderValue > 0)
                  Text(
                    'Min order ₹${coupon.minOrderValue.toInt()}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                if (coupon.maxDiscount != null)
                  Text(
                    'Max saving ₹${coupon.maxDiscount!.toInt()}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                if (coupon.eligibleCategory != null)
                  Text(
                    'Category: ${coupon.eligibleCategory}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
