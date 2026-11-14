import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/vehicle.dart';
import '../../services/auth_service.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/booking/booking_flow_sheet.dart';
import '../../widgets/vehicle/vehicle_dashboard_sheet.dart';
import '../../widgets/vehicle/vehicle_form_sheet.dart';

class GarageScreen extends StatefulWidget {
  final VoidCallback? onVehicleUpdated;
  final VehicleService? vehicleService;
  final AuthService? authService;

  const GarageScreen({
    super.key,
    this.onVehicleUpdated,
    this.vehicleService,
    this.authService,
  });

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  VehicleService get _vehicleService => widget.vehicleService ?? VehicleService.instance;
  AuthService get _authService => widget.authService ?? AuthService.instance;

  bool _isLoading = false;
  String? _errorMessage;
  List<Vehicle>? _apiVehicles;

  bool get _isAuthenticated => _authService.isAuthenticated;

  @override
  void initState() {
    super.initState();
    _authService.authStatusNotifier.addListener(_onAuthChanged);
    if (_isAuthenticated) {
      _loadVehicles();
    }
  }

  @override
  void dispose() {
    _authService.authStatusNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      if (_isAuthenticated) {
        _loadVehicles();
      } else {
        setState(() {
          _apiVehicles = null;
          _errorMessage = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicles = await _vehicleService.getVehicles();
      if (mounted) {
        setState(() {
          _apiVehicles = vehicles;
          _isLoading = false;
        });
        MockData.vehicles = List.from(vehicles);
        MockData.vehiclesNotifier.value = List.from(vehicles);
        _vehicleService.markSynced();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = VehicleService.getErrorMessage(e);
        });
      }
    }
  }

  void _openAddVehicle() {
    if (_isAuthenticated) {
      VehicleFormSheet.show(
        context: context,
        onSaveAsync: (newVehicle) async {
          final created = await _vehicleService.createVehicle(newVehicle);
          if (mounted) {
            setState(() {
              final current = List<Vehicle>.from(_apiVehicles ?? []);
              if (created.isPrimary) {
                for (int i = 0; i < current.length; i++) {
                  current[i] = current[i].copyWith(isPrimary: false);
                }
              }
              current.add(created);
              _apiVehicles = current;
            });
            MockData.vehicles = List.from(_apiVehicles!);
            MockData.vehiclesNotifier.value = List.from(_apiVehicles!);
            widget.onVehicleUpdated?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Added ${created.brand} ${created.model} to your garage!',
                      ),
                    ),
                  ],
                ),
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
          widget.onVehicleUpdated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Added ${newVehicle.brand} ${newVehicle.model} to your garage!',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    }
  }

  void _openEditVehicle(Vehicle vehicle) {
    if (_isAuthenticated) {
      VehicleFormSheet.show(
        context: context,
        vehicleToEdit: vehicle,
        onSaveAsync: (updatedVehicle) async {
          final saved = await _vehicleService.updateVehicle(updatedVehicle);
          if (mounted) {
            setState(() {
              final current = List<Vehicle>.from(_apiVehicles ?? []);
              final idx = current.indexWhere((v) => v.id == saved.id);
              if (idx != -1) {
                current[idx] = saved;
              }
              _apiVehicles = current;
            });
            MockData.vehicles = List.from(_apiVehicles!);
            MockData.vehiclesNotifier.value = List.from(_apiVehicles!);
            widget.onVehicleUpdated?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Updated details for ${saved.brand} ${saved.model}',
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.secondary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    } else {
      VehicleFormSheet.show(
        context: context,
        vehicleToEdit: vehicle,
        onSave: (updatedVehicle) {
          MockData.updateVehicle(updatedVehicle);
          widget.onVehicleUpdated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Updated details for ${updatedVehicle.brand} ${updatedVehicle.model}',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    }
  }

  void _confirmDeleteVehicle(Vehicle vehicle) {
    final currentList = _isAuthenticated ? (_apiVehicles ?? []) : MockData.vehicles;
    if (currentList.length <= 1) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Cannot Delete'),
            ],
          ),
          content: const Text(
            'You must keep at least one vehicle in your garage to receive service quotes and book maintenance.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.delete_outline_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Remove Vehicle?'),
            ],
          ),
          content: Text(
            'Are you sure you want to remove ${vehicle.brand} ${vehicle.model} (${vehicle.registrationNumber}) from your garage? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      if (_isAuthenticated) {
                        try {
                          await _vehicleService.deleteVehicle(vehicle.id);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (mounted) {
                            setState(() {
                              final current = List<Vehicle>.from(_apiVehicles ?? []);
                              current.removeWhere((v) => v.id == vehicle.id);
                              if (vehicle.isPrimary && current.isNotEmpty && !current.any((v) => v.isPrimary)) {
                                current[0] = current[0].copyWith(isPrimary: true);
                              }
                              _apiVehicles = current;
                            });
                            MockData.vehicles = List.from(_apiVehicles!);
                            MockData.vehiclesNotifier.value = List.from(_apiVehicles!);
                            widget.onVehicleUpdated?.call();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${vehicle.brand} ${vehicle.model} removed from garage',
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setDialogState(() => isDeleting = false);
                            Navigator.pop(ctx);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(VehicleService.getErrorMessage(e)),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      } else {
                        final deleted = MockData.deleteVehicle(vehicle.id);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (deleted) {
                          widget.onVehicleUpdated?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${vehicle.brand} ${vehicle.model} removed from garage',
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setActiveVehicle(Vehicle vehicle) async {
    if (_isAuthenticated) {
      try {
        final active = await _vehicleService.setActiveVehicle(vehicle.id);
        if (mounted) {
          setState(() {
            final current = List<Vehicle>.from(_apiVehicles ?? []);
            for (int i = 0; i < current.length; i++) {
              current[i] = current[i].copyWith(isPrimary: current[i].id == active.id);
            }
            _apiVehicles = current;
          });
          MockData.vehicles = List.from(_apiVehicles!);
          MockData.vehiclesNotifier.value = List.from(_apiVehicles!);
          widget.onVehicleUpdated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Active vehicle set to ${active.brand} ${active.model}',
              ),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(VehicleService.getErrorMessage(e)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      MockData.setActiveVehicle(vehicle.id);
      widget.onVehicleUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Active vehicle set to ${vehicle.brand} ${vehicle.model}',
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Garage'),
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        actions: [
          IconButton(
            tooltip: 'Add Vehicle',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: _openAddVehicle,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddVehicle,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildBody() {
    if (_isAuthenticated) {
      if (_isLoading) {
        return _buildLoadingState();
      }
      if (_errorMessage != null) {
        return _buildErrorState(_errorMessage!);
      }
      if (_apiVehicles != null && _apiVehicles!.isEmpty) {
        return _buildEmptyState();
      }
      if (_apiVehicles != null) {
        return _buildGarageListView(_apiVehicles!);
      }
      return _buildLoadingState();
    }

    // Guest mode
    return ValueListenableBuilder<List<Vehicle>>(
      valueListenable: MockData.vehiclesNotifier,
      builder: (context, vehicles, child) {
        if (vehicles.isEmpty) {
          return _buildEmptyState();
        }
        return _buildGarageListView(vehicles);
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Loading your garage...',
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Garage',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVehicles,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGarageListView(List<Vehicle> vehicles) {
    final activeVehicle = vehicles.firstWhere(
      (v) => v.isPrimary,
      orElse: () => vehicles.first,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        _buildGarageSummaryCard(vehicles.length, activeVehicle),
        const SizedBox(height: 16),
        Text(
          'YOUR SAVED VEHICLES (${vehicles.length})',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...vehicles.map((v) => _buildVehicleCard(v)),
      ],
    );
  }

  Widget _buildGarageSummaryCard(int totalCount, Vehicle activeVehicle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.darkCardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.garage_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE: ${activeVehicle.brand} ${activeVehicle.model}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCount saved ${totalCount == 1 ? "car" : "cars"} in your garage',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openVehicleDashboard(Vehicle vehicle) {
    VehicleDashboardSheet.show(
      context: context,
      vehicle: vehicle,
      onVehicleUpdated: () {
        widget.onVehicleUpdated?.call();
        if (mounted) setState(() {});
      },
    );
  }

  void _openBookServiceForVehicle(Vehicle vehicle) {
    BookingFlowSheet.show(
      context: context,
      serviceTitle: vehicle.nextServiceTitle ?? 'Standard Periodic Service',
      serviceDescription: 'Scheduled maintenance for ${vehicle.fullName}',
      price: 3699,
      durationText: '4 Hours',
      warrantyPeriod: '5000 Kms / 3 Months Warranty',
      initialVehicle: vehicle,
      onBookingConfirmed: (newBooking) {
        widget.onVehicleUpdated?.call();
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildVehicleCard(Vehicle v) {
    final isActive = v.isPrimary;
    final history = MockData.getServiceHistoryForVehicle(v.registrationNumber);
    final reminderText = v.nextServiceTitle != null
        ? '${v.nextServiceTitle} ${v.serviceDueStatus.toLowerCase()}'
        : 'Periodic Service ${v.serviceDueStatus.toLowerCase()}';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
          width: isActive ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : (isActive ? 0.06 : 0.02)),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Active Badge + Actions (Edit, Delete)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Active status badge / tag
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                        SizedBox(width: 5),
                        Text(
                          'ACTIVE VEHICLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Inactive',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),

                // Edit & Delete Icon Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: AppColors.textSecondary,
                      tooltip: 'Edit Vehicle',
                      onPressed: () => _openEditVehicle(v),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: AppColors.error,
                      tooltip: 'Delete Vehicle',
                      onPressed: () => _confirmDeleteVehicle(v),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Vehicle Details
          InkWell(
            onTap: () => _openVehicleDashboard(v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${v.brand} ${v.model}',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    v.variant.isNotEmpty ? v.variant : 'Standard Trim',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  // Specs Badges: Reg Number, Fuel Type, Year
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Indian License Plate Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.grey.shade400, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade900,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text(
                                'IND',
                                style: TextStyle(
                                  fontSize: 7,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              v.registrationNumber,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Fuel Type Chip
                      _buildSpecChip(
                        icon: Icons.local_gas_station_rounded,
                        label: v.fuelType,
                        color: v.fuelType.toLowerCase() == 'electric'
                            ? AppColors.success
                            : AppColors.primary,
                      ),

                      // Year Chip
                      _buildSpecChip(
                        icon: Icons.calendar_today_rounded,
                        label: '${v.year}',
                        color: AppColors.textSecondary,
                      ),

                      // Service Status Chip
                      _buildSpecChip(
                        icon: Icons.build_circle_outlined,
                        label: v.serviceDueStatus,
                        color: v.serviceDueStatus.contains('Due')
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Compact Dashboard Box: Reminder, Last Service, History count
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkElevatedSurface : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Next service reminder banner
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                reminderText,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                            if (v.reminderStatus != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  v.reminderStatus!,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.warning),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Last service & history count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                v.lastServiceTitle != null ? 'Last: ${v.lastServiceTitle}' : 'Last: Standard Periodic Service',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${history.length} ${history.length == 1 ? "Service" : "Services"}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openVehicleDashboard(v),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Service History', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openBookServiceForVehicle(v),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Book Service', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Action: If not active, "Set as Active" full-width button
          if (!isActive)
            InkWell(
              onTap: () => _setActiveVehicle(v),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevatedSurface : AppColors.surfaceVariant,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Set as Active Vehicle',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Vehicles in Garage',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your car to receive customized service packages and periodic maintenance alerts.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openAddVehicle,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Car'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
