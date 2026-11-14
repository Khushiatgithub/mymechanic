import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/vehicle.dart';
import '../../screens/garage/garage_screen.dart';
import 'vehicle_form_sheet.dart';

/// Catalog entry for popular vehicles shown in vehicle selection.
class PopularVehicleModel {
  final String brand;
  final String model;
  final String variant;
  final String fuelType;
  final Color carColor;

  const PopularVehicleModel({
    required this.brand,
    required this.model,
    required this.variant,
    required this.fuelType,
    required this.carColor,
  });

  String get displayName => '$brand $model';
}

/// Popular vehicles list exactly matching target specification.
const List<PopularVehicleModel> kPopularVehicles = [
  PopularVehicleModel(
    brand: 'Honda',
    model: 'City IVTEC',
    variant: '1.5 V i-VTEC',
    fuelType: 'Petrol',
    carColor: Color(0xFFDC2626), // Red
  ),
  PopularVehicleModel(
    brand: 'Hyundai',
    model: 'Grand i10',
    variant: '1.2 Kappa Magna',
    fuelType: 'Petrol',
    carColor: Color(0xFF94A3B8), // Silver/White
  ),
  PopularVehicleModel(
    brand: 'Hyundai',
    model: 'i10',
    variant: 'Era 1.1',
    fuelType: 'Petrol',
    carColor: Color(0xFF64748B), // Slate Grey
  ),
  PopularVehicleModel(
    brand: 'Hyundai',
    model: 'i20',
    variant: 'Asta (O) 1.2',
    fuelType: 'Petrol',
    carColor: Color(0xFFEF4444), // Crimson Red
  ),
  PopularVehicleModel(
    brand: 'Hyundai',
    model: 'Santro Xing',
    variant: 'GLS',
    fuelType: 'Petrol',
    carColor: Color(0xFFB45309), // Warm Gold
  ),
  PopularVehicleModel(
    brand: 'Maruti Suzuki',
    model: 'Alto',
    variant: 'LXi',
    fuelType: 'Petrol',
    carColor: Color(0xFF94A3B8), // Silver
  ),
  PopularVehicleModel(
    brand: 'Maruti Suzuki',
    model: 'Ertiga',
    variant: 'ZXi 1.5 Smart Hybrid',
    fuelType: 'Petrol',
    carColor: Color(0xFF2563EB), // Prime Blue
  ),
  PopularVehicleModel(
    brand: 'Maruti Suzuki',
    model: 'Swift',
    variant: 'ZXi AMT',
    fuelType: 'Petrol',
    carColor: Color(0xFFDC2626), // Solid Red
  ),
  PopularVehicleModel(
    brand: 'Maruti Suzuki',
    model: 'Swift Dzire',
    variant: 'VXi',
    fuelType: 'Petrol',
    carColor: Color(0xFFCBD5E1), // Silky Silver
  ),
  // Additional popular models for live search
  PopularVehicleModel(
    brand: 'Tata',
    model: 'Nexon',
    variant: 'Fearless+ 1.2',
    fuelType: 'Petrol',
    carColor: Color(0xFF0284C7), // Blue
  ),
  PopularVehicleModel(
    brand: 'Tata',
    model: 'Punch',
    variant: 'Accomplished',
    fuelType: 'Petrol',
    carColor: Color(0xFFEA580C), // Orange
  ),
  PopularVehicleModel(
    brand: 'Kia',
    model: 'Seltos',
    variant: 'HTX 1.5',
    fuelType: 'Petrol',
    carColor: Color(0xFF0F172A), // Dark Grey
  ),
  PopularVehicleModel(
    brand: 'Mahindra',
    model: 'XUV700',
    variant: 'AX7 L',
    fuelType: 'Diesel',
    carColor: Color(0xFF1E3A8A), // Midnight Blue
  ),
  PopularVehicleModel(
    brand: 'Mahindra',
    model: 'Thar',
    variant: 'LX 4x4',
    fuelType: 'Diesel',
    carColor: Color(0xFF1E293B), // Black
  ),
  PopularVehicleModel(
    brand: 'Toyota',
    model: 'Innova Crysta',
    variant: '2.4 GX',
    fuelType: 'Diesel',
    carColor: Color(0xFFE2E8F0), // White
  ),
  PopularVehicleModel(
    brand: 'Toyota',
    model: 'Fortuner',
    variant: '2.8 4x4 AT',
    fuelType: 'Diesel',
    carColor: Color(0xFF334155), // Dark Brown
  ),
];

/// Full-screen "Select your vehicle" experience matching reference screenshot.
class SelectVehicleScreen extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Vehicle activeVehicle;
  final ValueChanged<Vehicle> onSelectVehicle;
  final VoidCallback onAddVehicle;

  const SelectVehicleScreen({
    super.key,
    required this.vehicles,
    required this.activeVehicle,
    required this.onSelectVehicle,
    required this.onAddVehicle,
  });

  @override
  State<SelectVehicleScreen> createState() => _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends State<SelectVehicleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectVehicleModel(PopularVehicleModel item) {
    // 1. Check if user already has this vehicle model in their list
    final existing = widget.vehicles.cast<Vehicle?>().firstWhere(
      (v) =>
          v != null &&
          v.brand.toLowerCase() == item.brand.toLowerCase() &&
          v.model.toLowerCase().contains(
                item.model.toLowerCase().split(' ').first,
              ),
      orElse: () => null,
    );

    final selectedVehicle = existing ??
        Vehicle(
          id: 'v_${item.brand.toLowerCase().replaceAll(' ', '_')}_${item.model.toLowerCase().replaceAll(' ', '_')}',
          brand: item.brand,
          model: item.model,
          variant: item.variant,
          fuelType: item.fuelType,
          registrationNumber:
              'HR 26 ${item.brand.substring(0, 2).toUpperCase()} ${1000 + (DateTime.now().millisecondsSinceEpoch % 8999)}',
          year: 2023,
          serviceDueStatus: 'Due in 45 days',
          isPrimary: true,
        );

    if (existing == null) {
      MockData.addVehicle(selectedVehicle);
    }
    MockData.setActiveVehicle(selectedVehicle.id);
    widget.onSelectVehicle(selectedVehicle);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Switched active vehicle to ${selectedVehicle.brand} ${selectedVehicle.model}',
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openManageGarage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GarageScreen()),
    );
  }

  void _openAddCustomCar() {
    Navigator.pop(context);
    VehicleFormSheet.show(
      context: context,
      onSave: (newVehicle) {
        MockData.addVehicle(newVehicle);
        widget.onSelectVehicle(newVehicle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${newVehicle.brand} ${newVehicle.model} to garage',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Widget _buildVehicleAvatar(PopularVehicleModel item, bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputSurface : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.directions_car_filled_rounded,
              size: 25,
              color: item.carColor,
            ),
            Positioned(
              bottom: 6,
              child: Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleRow(PopularVehicleModel item, bool isDark) {
    final isSelected = widget.activeVehicle.brand.toLowerCase() ==
            item.brand.toLowerCase() &&
        widget.activeVehicle.model
            .toLowerCase()
            .contains(item.model.toLowerCase().split(' ').first);

    return InkWell(
      onTap: () => _selectVehicleModel(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildVehicleAvatar(item, isDark),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.displayName,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredList = kPopularVehicles.where((v) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return v.displayName.toLowerCase().contains(query) ||
          v.brand.toLowerCase().contains(query) ||
          v.model.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select your vehicle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar matching reference screenshot
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkInputSurface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                    style: TextStyle(
                      fontSize: 14.5,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by Car Model or Brand',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.darkSearchPlaceholder : const Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // Section Header: POPULAR VEHICLES
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'POPULAR VEHICLES',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // White Card List Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: filteredList.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 40,
                                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No vehicles found for "$_searchQuery"',
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < filteredList.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: isDark ? AppColors.darkDivider : const Color(0xFFF1F5F9),
                                  ),
                                _buildVehicleRow(filteredList[i], isDark),
                              ],
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Options: Add Custom Car or Manage Garage
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _openAddCustomCar,
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          size: 16, color: AppColors.primary),
                      label: Text(
                        'Add Custom Car',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '•',
                      style: TextStyle(color: isDark ? AppColors.darkBorder : Colors.grey.shade400),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: _openManageGarage,
                      icon: Icon(Icons.garage_rounded,
                          size: 16,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      label: Text(
                        'My Garage',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backwards-compatible VehicleSwitchSheet that opens the SelectVehicleScreen.
class VehicleSwitchSheet extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Vehicle activeVehicle;
  final ValueChanged<Vehicle> onSelectVehicle;
  final VoidCallback onAddVehicle;

  const VehicleSwitchSheet({
    super.key,
    required this.vehicles,
    required this.activeVehicle,
    required this.onSelectVehicle,
    required this.onAddVehicle,
  });

  /// Opens the "Select your vehicle" screen matching the target screenshot.
  static Future<void> show({
    required BuildContext context,
    required List<Vehicle> vehicles,
    required Vehicle activeVehicle,
    required ValueChanged<Vehicle> onSelectVehicle,
    required VoidCallback onAddVehicle,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectVehicleScreen(
          vehicles: vehicles,
          activeVehicle: activeVehicle,
          onSelectVehicle: onSelectVehicle,
          onAddVehicle: onAddVehicle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectVehicleScreen(
      vehicles: vehicles,
      activeVehicle: activeVehicle,
      onSelectVehicle: onSelectVehicle,
      onAddVehicle: onAddVehicle,
    );
  }
}
