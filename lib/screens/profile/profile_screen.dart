import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/notification_item.dart';
import '../../models/vehicle.dart';
import '../favorites/favorites_screen.dart';
import '../garage/garage_screen.dart';
import '../history/service_history_screen.dart';
import '../notifications/notifications_screen.dart';
import '../offers/offers_screen.dart';
import '../../models/auth_user.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToBookings;
  final VoidCallback? onNavigateToServices;

  const ProfileScreen({
    super.key,
    this.onNavigateToBookings,
    this.onNavigateToServices,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Rohit Sharma';
  String _userPhone = '+91 98765 43210';
  String _userEmail = 'rohit.sharma@example.com';

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _userName);
    final phoneCtrl = TextEditingController(text: _userPhone);
    final emailCtrl = TextEditingController(text: _userEmail);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit Profile', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _userName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _userName;
                    _userPhone = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : _userPhone;
                    _userEmail = emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : _userEmail;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!'), behavior: SnackBarBehavior.floating),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('App Settings', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService.instance.themeModeNotifier,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: isDark ? const Color(0xFFFACC15) : AppColors.primary,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: Text(isDark ? 'Dark theme enabled' : 'Light theme enabled'),
                  value: isDark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    ThemeService.instance.toggleDarkMode();
                  },
                );
              },
            ),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Updates on car servicing & technician dispatch'),
              value: true,
              activeThumbColor: AppColors.primary,
              onChanged: (val) {},
            ),
            SwitchListTile(
              title: const Text('WhatsApp Service Updates'),
              subtitle: const Text('Receive live job-card photos & video inspection'),
              value: true,
              activeThumbColor: AppColors.primary,
              onChanged: (val) {},
            ),
            ListTile(
              title: const Text('App Language'),
              subtitle: const Text('English (India)'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language set to English'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.categoryAmberBg, shape: BoxShape.circle),
              child: const Icon(Icons.monetization_on_rounded, color: AppColors.categoryAmber, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('MyMechanic Coins', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Balance: 450 Coins (Value: ₹450)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            const Text('• Earn 50 coins on every periodic service completion.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            const Text('• Redeem coins during checkout for instant discounts on labour charges.', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showInvoicesSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Service Invoices', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Text('GST-compliant invoices for your car servicing', style: AppTypography.bodySmall),
            const SizedBox(height: 16),
            ...MockData.invoices.map((inv) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inv['service'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('${inv['invoiceNo']} • ${inv['date']}', style: AppTypography.bodySmall),
                          Text('${AppConstants.currencySymbol}${inv['amount'].toInt()} • Paid', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Downloading ${inv['invoiceNo']} PDF...'), behavior: SnackBarBehavior.floating),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAddressesSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saved Addresses', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Text('Locations used for doorstep pickup & drop', style: AppTypography.bodySmall),
            const SizedBox(height: 16),
            ...MockData.savedAddresses.map((addr) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(addr['tag']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(addr['address']!, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New address picker opened'), behavior: SnackBarBehavior.floating),
                );
              },
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add New Address'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            ),
          ],
        ),
      ),
    );
  }

  void _showShieldSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.success, size: 28),
                    const SizedBox(width: 8),
                    Text('MyMechanic Shield', style: AppTypography.titleLarge),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            _buildShieldPoint(Icons.check_circle_rounded, '100% Genuine OEM / OES Spares', 'Every part installed is authenticated with hologram barcode tracking.'),
            const SizedBox(height: 12),
            _buildShieldPoint(Icons.verified_rounded, 'Network Warranty Coverage', 'Up to 10,000 Kms or 6 Months unconditional warranty across all partner hubs.'),
            const SizedBox(height: 12),
            _buildShieldPoint(Icons.local_shipping_rounded, 'Free Doorstep Transit Insurance', 'Your car is fully covered during pickup and drop transit.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShieldPoint(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.success, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  void _showFaqSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
            ),
            padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Help & FAQs', style: AppTypography.titleLarge),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              const ExpansionTile(
                title: Text('How does doorstep car pickup work?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text('Our certified driver arrives at your address at the selected time slot, performs a digital inventory check with photos, and brings your car safely to the service hub.', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const ExpansionTile(
                title: Text('What payment methods are supported?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text('You only pay after the service is completed and delivered. We support UPI, Debit/Credit cards, NetBanking, and Cash on Delivery.', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const ExpansionTile(
                title: Text('What warranty is provided on parts?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text('All genuine parts carry up to 6 Months / 10,000 Kms network warranty against defects, backed by MyMechanic Shield.', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support line: ${AppConstants.helplineNumber}'), behavior: SnackBarBehavior.floating),
                  );
                },
                icon: const Icon(Icons.support_agent_rounded),
                label: const Text('Contact Customer Support'),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  void _showRoadsideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.emergency_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('24x7 Roadside Assistance'),
          ],
        ),
        content: const Text('Dial ${AppConstants.helplineNumber} for instant towing, jumpstart, or flat tyre assistance anywhere in the city.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling 24x7 Emergency Helpline...'), backgroundColor: AppColors.error),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );
  }

  void _openGarageScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GarageScreen(
          onVehicleUpdated: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openServiceHistoryScreen({String? vehicleFilter}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceHistoryScreen(
          initialVehicleFilter: vehicleFilter,
          onExploreServices: widget.onNavigateToServices,
        ),
      ),
    );
  }

  void _openFavoritesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoritesScreen(
          onExploreServices: widget.onNavigateToServices,
        ),
      ),
    );
  }

  void _openNotificationsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  void _openOffersScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OffersScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _userName.split(' ').map((e) => e[0]).take(2).join(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: ValueListenableBuilder<AuthUser?>(
                      valueListenable: AuthService.instance.currentUserNotifier,
                      builder: (context, authUser, _) {
                        final displayName = authUser?.name ?? _userName;
                        final displayPhone = (authUser?.phone != null && authUser!.phone!.isNotEmpty)
                            ? authUser.phone!
                            : _userPhone;
                        final displayEmail = authUser?.email ?? _userEmail;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (authUser != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Verified',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayPhone,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              displayEmail,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Edit Profile
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                    onPressed: _showEditProfileSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Stats Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ValueListenableBuilder<List<Vehicle>>(
                    valueListenable: MockData.vehiclesNotifier,
                    builder: (context, vehicles, _) {
                      return InkWell(
                        onTap: _openGarageScreen,
                        child: _buildStatItem('${vehicles.length}', 'Vehicles'),
                      );
                    },
                  ),
                  Container(width: 1, height: 32, color: isDark ? AppColors.darkBorder : AppColors.border),
                  InkWell(
                    onTap: () => _openServiceHistoryScreen(),
                    child: _buildStatItem('8', 'Services Done'),
                  ),
                  Container(width: 1, height: 32, color: isDark ? AppColors.darkBorder : AppColors.border),
                  InkWell(
                    onTap: _showRewardsDialog,
                    child: _buildStatItem('450', 'Coins'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Menu Section: Customer Activity & Offers
            _buildSectionHeader('MY ACTIVITY & OFFERS'),
            _buildMenuCard([
              ValueListenableBuilder<Set<String>>(
                valueListenable: MockData.favoriteServiceIdsNotifier,
                builder: (context, favIds, _) {
                  final totalFavs = favIds.length + MockData.favoritePackageIdsNotifier.value.length;
                  return _buildMenuItem(
                    icon: Icons.favorite_rounded,
                    iconColor: AppColors.error,
                    title: 'Favorites',
                    subtitle: 'Saved services & packages',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (totalFavs > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$totalFavs',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                    onTap: _openFavoritesScreen,
                  );
                },
              ),
              ValueListenableBuilder<List<NotificationItem>>(
                valueListenable: MockData.notificationsNotifier,
                builder: (context, notifications, _) {
                  final unreadCount = notifications.where((n) => !n.isRead).length;
                  return _buildMenuItem(
                    icon: Icons.notifications_rounded,
                    iconColor: AppColors.accent,
                    title: 'Notifications',
                    subtitle: 'Booking updates & service reminders',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                    onTap: _openNotificationsScreen,
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.local_offer_rounded,
                iconColor: AppColors.categoryAmber,
                title: 'Offers & Deals',
                subtitle: 'Coupons, promotions & seasonal discounts',
                onTap: _openOffersScreen,
              ),
              _buildMenuItem(
                icon: Icons.calendar_today_rounded,
                iconColor: AppColors.categoryTeal,
                title: 'My Bookings',
                subtitle: 'Active, completed & past service bookings',
                onTap: () {
                  if (widget.onNavigateToBookings != null) {
                    widget.onNavigateToBookings!();
                  }
                },
                isLast: true,
              ),
            ]),
            const SizedBox(height: 20),

            // Menu Section: Garage & Servicing
            _buildSectionHeader('VEHICLE & SERVICES'),
            _buildMenuCard([
              _buildMenuItem(
                icon: Icons.garage_rounded,
                title: 'My Garage',
                subtitle: 'Manage saved cars & fuel preferences',
                onTap: _openGarageScreen,
              ),
              _buildMenuItem(
                icon: Icons.history_rounded,
                title: 'Service History',
                subtitle: 'Vehicle service records, warranties & summaries',
                onTap: () => _openServiceHistoryScreen(),
              ),
              _buildMenuItem(
                icon: Icons.receipt_long_rounded,
                title: 'Service Invoices',
                subtitle: 'Download GST compliant service bills',
                onTap: _showInvoicesSheet,
              ),
              _buildMenuItem(
                icon: Icons.location_on_rounded,
                title: 'Saved Addresses',
                subtitle: 'Home, office and service pickup locations',
                onTap: _showAddressesSheet,
                isLast: true,
              ),
            ]),
            const SizedBox(height: 20),

            // Menu Section: Support & Safety
            _buildSectionHeader('SAFETY & SUPPORT'),
            _buildMenuCard([
              _buildMenuItem(
                icon: Icons.shield_rounded,
                iconColor: AppColors.success,
                title: 'MyMechanic Shield',
                subtitle: 'Warranty cover, genuine spares guarantee',
                onTap: _showShieldSheet,
              ),
              _buildMenuItem(
                icon: Icons.emergency_rounded,
                iconColor: AppColors.error,
                title: '24x7 Roadside Assistance',
                subtitle: 'Emergency breakdown hotline',
                onTap: _showRoadsideDialog,
              ),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & FAQs',
                subtitle: 'Frequently asked questions & customer support',
                onTap: _showFaqSheet,
                isLast: true,
              ),
            ]),
            const SizedBox(height: 20),

            // Menu Section: Preferences & Appearance
            _buildSectionHeader('PREFERENCES & APPEARANCE'),
            _buildMenuCard([
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeService.instance.themeModeNotifier,
                builder: (context, mode, _) {
                  final isDark = mode == ThemeMode.dark;
                  return _buildMenuItem(
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    iconColor: isDark ? const Color(0xFFFACC15) : AppColors.primary,
                    title: 'Dark Mode',
                    subtitle: isDark ? 'Dark theme is currently active' : 'Light theme is currently active',
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        ThemeService.instance.toggleDarkMode();
                      },
                    ),
                    onTap: () {
                      ThemeService.instance.toggleDarkMode();
                    },
                    isLast: true,
                  );
                },
              ),
            ]),
            const SizedBox(height: 20),

            // Menu Section: Account & Session
            _buildSectionHeader('ACCOUNT & SESSION'),
            ValueListenableBuilder<bool>(
              valueListenable: AuthService.instance.isAuthenticatedNotifier,
              builder: (context, isAuthenticated, _) {
                if (isAuthenticated) {
                  return _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.error,
                      title: 'Log Out',
                      subtitle: 'Sign out of your MyMechanic account',
                      onTap: _showLogoutConfirmationDialog,
                      isLast: true,
                    ),
                  ]);
                } else {
                  return _buildMenuCard([
                    _buildMenuItem(
                      icon: Icons.login_rounded,
                      iconColor: AppColors.primary,
                      title: 'Log In or Register',
                      subtitle: 'Sign in to access your garage and bookings',
                      onTap: _openLoginScreen,
                      isLast: true,
                    ),
                  ]);
                }
              },
            ),
            const SizedBox(height: 24),

            // App Version Branding Footer
            Center(
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AppConstants.logoAsset,
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppConstants.appName} Mobile v1.0.0',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Crafted with pride for Indian car owners',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
          ),
          title: Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : null,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : null,
            ),
          ),
          trailing: trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                size: 20,
              ),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 60,
            color: isDark ? AppColors.darkBorder : null,
          ),
      ],
    );
  }

  void _openLoginScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your MyMechanic account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await AuthService.instance.logout();
              if (mounted) {
                if (result.serverRevoked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully.'),
                      backgroundColor: AppColors.textPrimary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Signed out locally. Server-side session revocation could not be confirmed (${result.serverError ?? "connection error"}).',
                      ),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
