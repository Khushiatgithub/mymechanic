import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/booking.dart';
import '../../models/service_package.dart';
import '../../models/vehicle.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/booking/booking_details_sheet.dart';
import '../../widgets/booking/booking_flow_sheet.dart';
import '../../widgets/booking/live_tracker_sheet.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/service/service_package_card.dart';
import '../../widgets/vehicle/vehicle_form_sheet.dart';
import '../../widgets/vehicle/vehicle_switch_sheet.dart';
import '../garage/garage_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../models/offer.dart';
import '../../widgets/offer/offer_detail_sheet.dart';
import '../offers/offers_screen.dart';
import 'widgets/top_location_row.dart';
import 'widgets/search_vehicle_row.dart';
import 'widgets/active_vehicle_bar.dart';
import 'widgets/promo_banner_carousel.dart';
import 'widgets/main_service_categories.dart';
import 'widgets/secondary_service_grid.dart';
import 'widgets/top_action_cards.dart';
import 'widgets/challan_lookup_sheet.dart';
import 'widgets/designer_combos_section.dart';
import 'widgets/brand_guarantee_pills.dart';
import 'widgets/summer_ready_grid.dart';
import 'widgets/miles_membership_banner.dart';
import 'widgets/blog_articles_section.dart';
import 'widgets/spare_parts_strip.dart';
import 'widgets/referral_banner.dart';
import 'widgets/curated_custom_services.dart';
import 'widgets/sell_car_promo_banner.dart';
import 'widgets/sell_car_valuation_sheet.dart';
import '../chatbot/gia_chatbot_screen.dart';

/// Redesigned Home Screen for MyMechanic.
///
/// Closely matches the reference layout, visual hierarchy, spacing, and styling:
/// 1. Top Location Row with pin icon, address, dropdown chevron, and notifications bell.
/// 2. Search + Vehicle Row with rounded search field `Search "Periodic Services"` and outlined `Select Vehicle` button.
/// 3. Active Vehicle Status Bar with registration number and service reminder.
/// 4. Promotional Banner Carousel with MyMechanic branding and dot indicators.
/// 5. Main Service Categories (2-column cards: Car Services, Denting, AC, Spa with green badges).
/// 6. Secondary Service Grid (4-column compact cards: Detailing, Batteries, Tyres, Inspections, etc.).
/// 7. Floating 24x7 Help / Support Button in lower-right content area.
/// 8. Preserved dynamic sections: Active Booking Tracker, Popular Services, Service Packages, Trust Points.
class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToServices;
  final ValueChanged<String> onNavigateToServicesWithCategory;
  final ValueChanged<String> onNavigateToServicesWithSearch;
  final VoidCallback onNavigateToBookings;
  final VoidCallback? onNavigateToHelp;
  final VoidCallback? onNavigateToGoStore;
  final VoidCallback? onNavigateToMyVehicles;
  final VehicleService? vehicleService;
  final AuthService? authService;

  const HomeScreen({
    super.key,
    required this.onNavigateToServices,
    required this.onNavigateToServicesWithCategory,
    required this.onNavigateToServicesWithSearch,
    required this.onNavigateToBookings,
    this.onNavigateToHelp,
    this.onNavigateToGoStore,
    this.onNavigateToMyVehicles,
    this.vehicleService,
    this.authService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VehicleService get _vehicleService =>
      widget.vehicleService ?? VehicleService.instance;
  AuthService get _authService => widget.authService ?? AuthService.instance;

  String _currentLocation = 'Atul Kataria Chowk, Gurugram';
  late Vehicle _activeVehicle;
  late List<Vehicle> _vehicles;

  @override
  void initState() {
    super.initState();
    _vehicles = MockData.vehicles;
    _activeVehicle = MockData.activeVehicle;
    MockData.vehiclesNotifier.addListener(_onVehiclesChanged);
    _authService.authStatusNotifier.addListener(_onAuthChanged);

    if (_authService.isAuthenticated) {
      _syncVehicles();
    }
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (_authService.isAuthenticated) {
      _syncVehicles();
    } else if (_authService.isGuest) {
      _vehicleService.resetVehicles();
    }
  }

  Future<void> _syncVehicles() async {
    await _vehicleService.syncUserVehicles(authService: _authService);
  }

  void _onVehiclesChanged() {
    if (mounted) {
      setState(() {
        _vehicles = MockData.vehicles;
        _activeVehicle = MockData.activeVehicle;
      });
    }
  }

  @override
  void dispose() {
    MockData.vehiclesNotifier.removeListener(_onVehiclesChanged);
    _authService.authStatusNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onSwitchVehicle(Vehicle vehicle) {
    MockData.setActiveVehicle(vehicle.id);
    if (_authService.isAuthenticated) {
      _vehicleService.setActiveVehicle(vehicle.id).catchError((_) => vehicle);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched active vehicle to ${vehicle.brand} ${vehicle.model}'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openVehicleSwitcher() {
    VehicleSwitchSheet.show(
      context: context,
      vehicles: _vehicles,
      activeVehicle: _activeVehicle,
      onSelectVehicle: _onSwitchVehicle,
      onAddVehicle: _onAddVehicle,
    );
  }

  void _onAddVehicle() {
    if (_authService.isAuthenticated) {
      VehicleFormSheet.show(
        context: context,
        onSaveAsync: (newVehicle) async {
          final created = await _vehicleService.createVehicle(newVehicle);
          if (mounted) {
            MockData.addVehicle(created);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${created.brand} ${created.model} to your garage!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    } else {
      VehicleFormSheet.show(
        context: context,
        onSave: (newVehicle) {
          MockData.addVehicle(newVehicle);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${newVehicle.brand} ${newVehicle.model} to your garage!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    }
  }

  void _openManageGarage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GarageScreen(
          vehicleService: _vehicleService,
          authService: _authService,
          onVehicleUpdated: () {
            if (mounted) {
              setState(() {
                _vehicles = MockData.vehicles;
                _activeVehicle = MockData.activeVehicle;
              });
            }
          },
        ),
      ),
    );
  }


  void _openBookingForPackage(ServicePackage package) {
    BookingFlowSheet.show(
      context: context,
      serviceTitle: package.title,
      serviceDescription: package.checklist.take(3).join(' • '),
      price: package.price,
      originalPrice: package.originalPrice,
      durationText: package.timeTakenText,
      warrantyPeriod: package.tag,
      initialVehicle: _activeVehicle,
      onNavigateToBookings: widget.onNavigateToBookings,
      onBookingConfirmed: (Booking booking) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Package "${booking.serviceTitle}" booked!'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    ).then((booking) {
      if (booking != null && mounted) {
        BookingDetailsSheet.show(
          context: context,
          booking: booking,
        );
      }
    });
  }

  void _openBookingForCombo(ComboPackageItem combo) {
    BookingFlowSheet.show(
      context: context,
      serviceTitle: combo.title,
      serviceDescription: combo.highlights.join(' • '),
      price: combo.price.toDouble(),
      originalPrice: combo.originalPrice.toDouble(),
      durationText: combo.durationText,
      warrantyPeriod: combo.warrantyPeriod,
      initialVehicle: _activeVehicle,
      onNavigateToBookings: widget.onNavigateToBookings,
      onBookingConfirmed: (Booking booking) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Combo "${booking.serviceTitle}" booked!'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    ).then((booking) {
      if (booking != null && mounted) {
        BookingDetailsSheet.show(
          context: context,
          booking: booking,
        );
      }
    });
  }

  void _openBookingForSummerItem(SummerReadyItem item) {
    BookingFlowSheet.show(
      context: context,
      serviceTitle: item.title,
      serviceDescription: item.description,
      price: item.price.toDouble(),
      originalPrice: item.originalPrice.toDouble(),
      durationText: item.durationText,
      warrantyPeriod: item.warrantyPeriod,
      initialVehicle: _activeVehicle,
      onNavigateToBookings: widget.onNavigateToBookings,
      onBookingConfirmed: (Booking booking) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Service "${booking.serviceTitle}" booked!'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    ).then((booking) {
      if (booking != null && mounted) {
        BookingDetailsSheet.show(
          context: context,
          booking: booking,
        );
      }
    });
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  void _openChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GiaChatbotScreen(
          onNavigateToServices: widget.onNavigateToServices,
          onNavigateToBookings: widget.onNavigateToBookings,
        ),
      ),
    );
  }

  void _openHelpSupport() {
    if (widget.onNavigateToHelp != null) {
      widget.onNavigateToHelp!();
      return;
    }
    _showHelpDialog();
  }

  void _showHelpDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark ? Border.all(color: AppColors.darkBorder) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      AppConstants.logoAsset,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'MyMechanic 24x7 Help Desk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Need immediate assistance with your booking, vehicle breakdown, or service estimate?',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.error),
              ),
              title: Text(
                '24x7 Emergency Roadside Helpline',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : null,
                ),
              ),
              subtitle: Text(
                '+91 88269 91028 (24x7 Roadside & Service Helpline)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : null,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dialing Helpline: +91 88269 91028...'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: AppColors.success),
              ),
              title: Text(
                'Chat with Certified Advisor',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : null,
                ),
              ),
              subtitle: Text(
                'Instant support on WhatsApp',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : null,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connecting to service advisor...'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.45 : 0.3),
              blurRadius: isDark ? 14 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'home_floating_support_fab',
          onPressed: _openChatbot,
          backgroundColor: isDark ? AppColors.darkElevatedSurface : Colors.white,
          elevation: 0,
          shape: CircleBorder(
            side: BorderSide(color: AppColors.primary, width: 2.2),
          ),
          tooltip: 'Ask GIA - AI Car Assistant',
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.directions_car_filled_rounded,
                color: AppColors.primary,
                size: 26,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkInputSurface : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.headset_mic_rounded,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Location Row (Pin + Address + Dropdown + Notifications)
              TopLocationRow(
                currentLocation: _currentLocation,
                onLocationChanged: (newLoc) {
                  setState(() => _currentLocation = newLoc);
                },
                onNotificationsTap: _openNotifications,
              ),

              // 2. Search + Vehicle Row (Large rounded search field + Select Vehicle button)
              SearchVehicleRow(
                onSearchTap: () => widget.onNavigateToServicesWithSearch(''),
                onSearchSubmitted: (q) => widget.onNavigateToServicesWithSearch(q),
                onSelectVehicleTap: _openVehicleSwitcher,
                activeVehicle: _activeVehicle,
              ),
              const SizedBox(height: 14),

              // 3. Curated Custom Services (2-row horizontally scrollable matching reference screenshot)
              CuratedCustomServices(
                activeVehicle: _activeVehicle,
                onCategoryTap: (keyword) {
                  widget.onNavigateToServicesWithSearch(keyword);
                },
              ),
              const SizedBox(height: 18),

              // 4. Sell your car for the Best Price Banner with dot indicators
              SellCarPromoBanner(
                activeVehicle: _activeVehicle,
                onSellCarTap: () => SellCarValuationSheet.show(
                  context: context,
                  vehicle: _activeVehicle,
                ),
              ),
              const SizedBox(height: 18),

              // 5. Designer Service Combos
              DesignerCombosSection(
                onBookCombo: _openBookingForCombo,
              ),
              const SizedBox(height: 20),

              // Top Action Cards: Miles (Free Roadside Assistance) & Challan (Govt Authorised Records)
              TopActionCards(
                onRoadsideAssistanceTap: _openHelpSupport,
                onChallanTap: () => ChallanLookupSheet.show(
                  context: context,
                  vehicle: _activeVehicle,
                ),
              ),
              const SizedBox(height: 6),

              // 3. Promotional Banner Carousel (Directly below Search, matching reference layout)
              PromoBannerCarousel(
                onBookServiceFest: () {
                  final service = MockData.popularServices.first;
                  BookingFlowSheet.show(
                    context: context,
                    serviceTitle: service.title,
                    serviceDescription: service.description,
                    price: service.price,
                    originalPrice: service.originalPrice,
                    durationText: service.durationText,
                    warrantyPeriod: service.warrantyPeriod,
                    initialVehicle: _activeVehicle,
                    initialCouponCode: 'MYFIRST500',
                    onNavigateToBookings: widget.onNavigateToBookings,
                  );
                },
                onBookPeriodicService: () {
                  widget.onNavigateToServicesWithCategory('srv_cat_periodic');
                },
                onBookCarSpa: () {
                  widget.onNavigateToServicesWithCategory('srv_cat_spa');
                },
                onRoadsideAssistance: _openHelpSupport,
              ),
              const SizedBox(height: 18),

              // 5. Main Service Categories Header & 2-Column Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Book a Service',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    InkWell(
                      onTap: widget.onNavigateToServices,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Services',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              MainServiceCategories(
                onCategoryTap: (catId) {
                  widget.onNavigateToServicesWithCategory(catId);
                },
              ),
              const SizedBox(height: 18),

              // 6. Secondary Service Grid (4-Column Compact Cards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'More Services',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SecondaryServiceGrid(
                onCategoryTap: (catId) {
                  widget.onNavigateToServicesWithCategory(catId);
                },
              ),
              const SizedBox(height: 18),

              // Active Vehicle Status Bar & Garage Management
              ActiveVehicleBar(
                activeVehicle: _activeVehicle,
                onChangeVehicle: _openVehicleSwitcher,
                onManageGarage: _openManageGarage,
              ),
              const SizedBox(height: 18),

              // Standard Guarantees Strip
              const BrandGuaranteePills(),
              const SizedBox(height: 18),

              // Get Summer Ready With MyMechanic 2x2 Grid
              SummerReadyGrid(
                onBookItem: _openBookingForSummerItem,
              ),
              const SizedBox(height: 18),



              // 7. Active Booking Quick Tracker (if present)
              ValueListenableBuilder<List<Booking>>(
                valueListenable: MockData.bookingsNotifier,
                builder: (context, bookings, _) {
                  final activeBooking = bookings.cast<Booking?>().firstWhere(
                        (b) => b != null && (b.status == BookingStatus.confirmed ||
                            b.status == BookingStatus.inProgress),
                        orElse: () => null,
                      );

                  if (activeBooking == null) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.primary.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Service In Progress',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeBooking.serviceTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            LiveTrackerSheet.show(
                              context: context,
                              booking: activeBooking,
                            );
                          },
                          icon: const Icon(Icons.timeline_rounded, size: 14),
                          label: const Text('Track Live', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),



              // 9. Service Packages & Recommendations
              SectionHeader(
                title: 'Service Packages',
                subtitle: 'Scheduled maintenance tailored to your mileage',
              ),
              const SizedBox(height: 6),
              ...MockData.servicePackages.map(
                (pkg) => ServicePackageCard(
                  package: pkg,
                  onBook: () => _openBookingForPackage(pkg),
                ),
              ),
              const SizedBox(height: 24),

              // 10. Exclusive Offers Section
              SectionHeader(
                title: 'Exclusive Offers',
                subtitle: 'Limited-time discounts & partner deals',
                actionText: 'View All',
                onActionTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OffersScreen()),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 135,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: MockData.offers.length,
                  itemBuilder: (context, index) {
                    final offer = MockData.offers[index];
                    return _buildHomeOfferCard(offer);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Miles Membership Banner
              const MilesMembershipBanner(),
              const SizedBox(height: 20),

              // Blog Posts & Car Care Articles
              BlogArticlesSection(
                onBookService: widget.onNavigateToServices,
              ),
              const SizedBox(height: 20),

              // Original Spare Parts (OEM/OES Partner Brands)
              const SparePartsStrip(),
              const SizedBox(height: 20),

              // Refer & Earn ₹1000 Promotion Banner
              const ReferralBanner(),
              const SizedBox(height: 24),

              // 10. Why MyMechanic Trust Points
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why Choose MyMechanic?',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTrustPoint(
                      icon: Icons.local_shipping_outlined,
                      title: 'Free Doorstep Pickup & Drop',
                      subtitle: 'We collect your vehicle and return it gleaming fresh.',
                    ),
                    const SizedBox(height: 12),
                    _buildTrustPoint(
                      icon: Icons.shield_outlined,
                      title: '100% Genuine OEM Spares',
                      subtitle: 'Directly sourced from manufacturer-approved suppliers.',
                    ),
                    const SizedBox(height: 12),
                    _buildTrustPoint(
                      icon: Icons.verified_outlined,
                      title: 'Network Warranty Assured',
                      subtitle: 'Up to 10,000 Kms / 6 Months unconditional warranty.',
                    ),
                    const SizedBox(height: 12),
                    _buildTrustPoint(
                      icon: Icons.price_check_rounded,
                      title: 'Transparent & Upfront Estimates',
                      subtitle: 'No hidden charges. Real-time digital job card approval.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildTrustPoint({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeOfferCard(Offer offer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          OfferDetailSheet.show(
            context: context,
            offer: offer,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        offer.couponCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    offer.discountTag,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                offer.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                offer.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      offer.validTill,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
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
