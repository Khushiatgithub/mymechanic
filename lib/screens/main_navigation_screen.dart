import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/vehicle_service.dart';
import 'home/home_screen.dart';
import 'help/help_screen.dart';
import 'offers/offers_screen.dart';
import 'garage/garage_screen.dart';
import 'profile/profile_screen.dart';
import 'services/services_screen.dart';
import 'bookings/bookings_screen.dart';

/// Main navigation shell for MyMechanic.
///
/// Features a redesigned 5-destination bottom navigation bar matching the target specification:
/// 1. Home
/// 2. Help
/// 3. GoStore
/// 4. My Vehicles
/// 5. Account
///
/// Preserves existing navigation architecture, routing, and programmatic access to
/// [ServicesScreen] and [BookingsScreen].
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final VehicleService? vehicleService;
  final AuthService? authService;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.vehicleService,
    this.authService,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _navigateToServices({
    String? categoryId,
    String? searchQuery,
    bool autoFocus = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServicesScreen(
          onNavigateToBookings: () => _navigateToBookings(),
          initialCategoryId: categoryId,
          initialSearchQuery: searchQuery,
          autoFocusSearch: autoFocus,
        ),
      ),
    );
  }

  void _navigateToBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingsScreen(
          onExploreServices: () => _navigateToServices(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      // 0: Home
      HomeScreen(
        onNavigateToServices: () => _navigateToServices(),
        onNavigateToServicesWithCategory: (catId) =>
            _navigateToServices(categoryId: catId),
        onNavigateToServicesWithSearch: (query) =>
            _navigateToServices(searchQuery: query, autoFocus: true),
        onNavigateToBookings: _navigateToBookings,
        onNavigateToHelp: () => _onTabSelected(1),
        onNavigateToGoStore: () => _onTabSelected(2),
        onNavigateToMyVehicles: () => _onTabSelected(3),
        vehicleService: widget.vehicleService,
        authService: widget.authService,
      ),

      // 1: Help (24x7 Roadside & SOS Support)
      const HelpScreen(),

      // 2: GoStore (Offers & Deals Hub)
      const OffersScreen(),

      // 3: My Vehicles (Garage Screen)
      GarageScreen(
        vehicleService: widget.vehicleService,
        authService: widget.authService,
      ),

      // 4: Account (Profile & Settings Screen)
      ProfileScreen(
        onNavigateToBookings: _navigateToBookings,
        onNavigateToServices: () => _navigateToServices(),
      ),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          _onTabSelected(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBottomNavBg
                : Theme.of(context).colorScheme.surface,
            border: Theme.of(context).brightness == Brightness.dark
                ? const Border(top: BorderSide(color: AppColors.darkBorder, width: 0.8))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabSelected,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBottomNavBg
                  : Theme.of(context).colorScheme.surface,
              elevation: 0,
              indicatorColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.primary.withValues(alpha: 0.12),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              height: 64,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon:
                      Icon(Icons.home_rounded, color: AppColors.primary),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.support_agent_outlined),
                  selectedIcon: Icon(Icons.support_agent_rounded,
                      color: AppColors.primary),
                  label: 'Help',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront_rounded,
                      color: AppColors.primary),
                  label: 'GoStore',
                ),
                NavigationDestination(
                  icon: Icon(Icons.directions_car_outlined),
                  selectedIcon: Icon(Icons.directions_car_rounded,
                      color: AppColors.primary),
                  label: 'My Vehicles',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon:
                      Icon(Icons.person_rounded, color: AppColors.primary),
                  label: 'Account',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
