import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/offer.dart';
import '../../services/offer_service.dart';
import '../../widgets/booking/booking_flow_sheet.dart';
import '../../widgets/offer/offer_detail_sheet.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  String _selectedCategory = 'All Deals';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Offer> _allOffers = MockData.offers;
  bool _isLoading = false;

  final List<String> _categories = [
    'All Deals',
    'Periodic Services',
    'AC Service & Repair',
    'Car Spa & Detailing',
    'Batteries',
  ];

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    if (_allOffers.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final fetched = await OfferService.instance.getOffers();
      if (!mounted) return;
      if (fetched.isNotEmpty) {
        setState(() {
          _allOffers = fetched;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyCoupon(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Coupon code "$code" copied to clipboard!',
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

  void _applyOffer(BuildContext context, Offer offer) {
    if (offer.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This offer has expired and cannot be applied.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

  List<Offer> get _filteredOffers {
    return _allOffers.where((offer) {
      if (_selectedCategory != 'All Deals') {
        if (offer.eligibleCategory == null ||
            !offer.eligibleCategory!.toLowerCase().contains(_selectedCategory.toLowerCase())) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = offer.title.toLowerCase().contains(query);
        final matchCode = offer.couponCode.toLowerCase().contains(query);
        final matchSubtitle = offer.subtitle.toLowerCase().contains(query);
        if (!matchTitle && !matchCode && !matchSubtitle) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final offers = _filteredOffers;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Exclusive Offers & Deals'),
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search coupons, deals or services...',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkSearchPlaceholder : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? AppColors.darkSearchPlaceholder : AppColors.textSecondary,
                      size: 20,
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
                const SizedBox(height: 12),

                // Category Chips
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = cat);
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimary),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: isDark
                              ? BorderSide(color: isSelected ? AppColors.primary : AppColors.darkBorder)
                              : BorderSide.none,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Offers List
          Expanded(
            child: _isLoading && _allOffers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadOffers,
                    child: offers.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.4,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.local_offer_outlined, size: 60, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        Text('No offers found', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Try selecting a different category or clearing search.',
                                          style: AppTypography.bodySmall,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: offers.length,
                            itemBuilder: (context, index) {
                              final offer = offers[index];
                              return _buildOfferCard(offer);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Offer offer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient Top Header
          InkWell(
            onTap: () => OfferDetailSheet.show(context: context, offer: offer),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: offer.gradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                            fontSize: 11,
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
                  const SizedBox(height: 10),
                  Text(
                    offer.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    offer.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details & Action Row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (offer.minOrderValue > 0)
                      _buildChip(Icons.shopping_bag_outlined, 'Min: ₹${offer.minOrderValue.toInt()}'),
                    if (offer.maxDiscount != null)
                      _buildChip(Icons.savings_outlined, 'Max: ₹${offer.maxDiscount!.toInt()}'),
                    if (offer.eligibleCategory != null)
                      _buildChip(Icons.build_outlined, offer.eligibleCategory!),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? AppColors.darkDivider : null),
                const SizedBox(height: 12),

                // Bottom Row: Coupon Code Pill + Apply Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Coupon Code Box with Copy action
                    InkWell(
                      onTap: () => _copyCoupon(context, offer.couponCode),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              offer.couponCode,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Apply Button
                    ElevatedButton.icon(
                      onPressed: () => _applyOffer(context, offer),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                      label: const Text('Apply Offer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: isDark ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
