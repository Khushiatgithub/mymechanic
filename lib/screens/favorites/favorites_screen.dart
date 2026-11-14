import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/service_item.dart';
import '../../models/service_package.dart';
import '../../widgets/booking/booking_flow_sheet.dart';
import '../../widgets/service/service_detail_sheet.dart';

class FavoritesScreen extends StatefulWidget {
  final VoidCallback? onExploreServices;

  const FavoritesScreen({
    super.key,
    this.onExploreServices,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openBookingForService(ServiceItem service) {
    BookingFlowSheet.show(
      context: context,
      serviceTitle: service.title,
      serviceDescription: service.description,
      price: service.price,
      originalPrice: service.originalPrice,
      durationText: service.durationText,
      warrantyPeriod: service.warrantyPeriod,
      initialVehicle: MockData.activeVehicle,
    );
  }

  void _openBookingForPackage(ServicePackage pkg) {
    BookingFlowSheet.show(
      context: context,
      serviceTitle: pkg.title,
      serviceDescription: '${pkg.checklist.length} services: ${pkg.intervalText}',
      price: pkg.price,
      originalPrice: pkg.originalPrice,
      durationText: pkg.timeTakenText,
      warrantyPeriod: pkg.warranty,
      initialVehicle: MockData.activeVehicle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        MockData.favoriteServiceIdsNotifier,
        MockData.favoritePackageIdsNotifier,
      ]),
      builder: (context, _) {
        final favServices = MockData.getFavoriteServices();
        final favPackages = MockData.getFavoritePackages();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('My Favorites & Wishlist'),
            elevation: 0,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Services (${favServices.length})'),
                Tab(text: 'Packages (${favPackages.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Services Tab
              favServices.isEmpty
                  ? _buildEmptyState('No favorite services yet', 'Save services you like for quick booking.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favServices.length,
                      itemBuilder: (context, index) {
                        final service = favServices[index];
                        return _buildServiceCard(service);
                      },
                    ),

              // Packages Tab
              favPackages.isEmpty
                  ? _buildEmptyState('No favorite packages yet', 'Save maintenance packages tailored to your car.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favPackages.length,
                      itemBuilder: (context, index) {
                        final pkg = favPackages[index];
                        return _buildPackageCard(pkg);
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onExploreServices?.call();
              },
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Explore Services', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceItem service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Title + Remove Favorite Heart
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.description,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_rounded, color: AppColors.error),
                  onPressed: () => MockData.toggleServiceFavorite(service.id),
                  tooltip: 'Remove from favorites',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Price & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${AppConstants.currencySymbol}${service.price.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${AppConstants.currencySymbol}${service.originalPrice.toInt()}',
                          style: AppTypography.priceStrike,
                        ),
                      ],
                    ),
                    Text(
                      service.durationText,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        ServiceDetailSheet.show(
                          context: context,
                          service: service,
                          onBookNow: () => _openBookingForService(service),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _openBookingForService(service),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Book Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(ServicePackage pkg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pkg.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pkg.intervalText} • ${pkg.checklist.length} Included Items',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_rounded, color: AppColors.error),
                  onPressed: () => MockData.togglePackageFavorite(pkg.id),
                  tooltip: 'Remove from favorites',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Inclusions summary
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: pkg.checklist.take(3).map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(f, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${AppConstants.currencySymbol}${pkg.price.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${AppConstants.currencySymbol}${pkg.originalPrice.toInt()}',
                      style: AppTypography.priceStrike,
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _openBookingForPackage(pkg),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Book Package', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
