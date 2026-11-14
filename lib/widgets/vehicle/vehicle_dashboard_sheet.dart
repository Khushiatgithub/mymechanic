import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/booking.dart';
import '../../models/vehicle.dart';
import '../booking/booking_flow_sheet.dart';
import '../history/service_summary_sheet.dart';
import 'vehicle_form_sheet.dart';

class VehicleDashboardSheet extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback? onVehicleUpdated;

  const VehicleDashboardSheet({
    super.key,
    required this.vehicle,
    this.onVehicleUpdated,
  });

  static Future<void> show({
    required BuildContext context,
    required Vehicle vehicle,
    VoidCallback? onVehicleUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => VehicleDashboardSheet(
          vehicle: vehicle,
          onVehicleUpdated: onVehicleUpdated,
        ),
      ),
    );
  }

  @override
  State<VehicleDashboardSheet> createState() => _VehicleDashboardSheetState();
}

class _VehicleDashboardSheetState extends State<VehicleDashboardSheet> {
  late Vehicle _vehicle;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  List<Booking> get _vehicleHistory {
    return MockData.getServiceHistoryForVehicle(_vehicle.registrationNumber);
  }

  void _openBookService() {
    Navigator.pop(context); // Close dashboard sheet
    BookingFlowSheet.show(
      context: context,
      serviceTitle: _vehicle.nextServiceTitle ?? 'Standard Periodic Service',
      serviceDescription: 'Scheduled maintenance tailored for ${_vehicle.fullName}',
      price: 3699,
      durationText: '4 Hours',
      warrantyPeriod: '5000 Kms / 3 Months Warranty',
      initialVehicle: _vehicle,
      onBookingConfirmed: (newBooking) {
        widget.onVehicleUpdated?.call();
      },
    );
  }

  void _openEditVehicle() {
    VehicleFormSheet.show(
      context: context,
      vehicleToEdit: _vehicle,
      onSave: (updated) {
        MockData.updateVehicle(updated);
        setState(() {
          _vehicle = updated;
        });
        widget.onVehicleUpdated?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = _vehicleHistory;
    final daysRemaining = _vehicle.daysUntilNextService ?? 12;
    final reminderStatus = _vehicle.reminderStatus ?? 'Due Soon';

    Color reminderColor = AppColors.warning;
    Color reminderBg = AppColors.warningBg;
    if (reminderStatus == 'Overdue') {
      reminderColor = AppColors.error;
      reminderBg = AppColors.errorBg;
    } else if (reminderStatus == 'Scheduled' || reminderStatus == 'Up to date') {
      reminderColor = AppColors.success;
      reminderBg = AppColors.successBg;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vehicle Dashboard', style: AppTypography.titleLarge),
                    Text(
                      _vehicle.fullName,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // Vehicle Overview Card
                _buildVehicleOverviewCard(),
                const SizedBox(height: 16),

                // Upcoming Service Reminder Card
                _buildReminderCard(daysRemaining, reminderStatus, reminderColor, reminderBg),
                const SizedBox(height: 16),

                // Last Service & Stats
                _buildLastServiceCard(),
                const SizedBox(height: 20),

                // Vehicle-Specific Service History Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SERVICE HISTORY (${history.length})',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Vehicle: ${_vehicle.registrationNumber}',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Service History List for this Vehicle
                if (history.isEmpty)
                  _buildEmptyHistory()
                else
                  ...history.map((booking) => _buildHistoryItem(booking)),

                const SizedBox(height: 20),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openEditVehicle,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Vehicle'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openBookService,
                        icon: const Icon(Icons.build_circle_rounded, size: 16),
                        label: const Text('Book Service', style: TextStyle(fontWeight: FontWeight.w700)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleOverviewCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_vehicle.brand} ${_vehicle.model}',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              if (_vehicle.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, size: 12, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'Active Vehicle',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _vehicle.variant.isNotEmpty ? _vehicle.variant : 'Standard Trim',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // License Plate
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.grey.shade400, width: 0.8),
                ),
                child: Text(
                  _vehicle.registrationNumber,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                ),
              ),
              _buildBadge(Icons.local_gas_station_rounded, _vehicle.fuelType),
              _buildBadge(Icons.calendar_today_rounded, '${_vehicle.year}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(
    int daysRemaining,
    String reminderStatus,
    Color reminderColor,
    Color reminderBg,
  ) {
    final nextTitle = _vehicle.nextServiceTitle ?? 'Periodic Service';
    final mileage = _vehicle.nextServiceMileage ?? '30,000 km';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reminderBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: reminderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: reminderColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Service Reminder',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: reminderColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: reminderColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  reminderStatus,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: reminderColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$nextTitle due in $daysRemaining days',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Recommended interval: $mileage or scheduled calendar inspection.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openBookService,
              icon: const Icon(Icons.calendar_month_rounded, size: 16),
              label: const Text('Book Service Now', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: reminderColor == AppColors.error ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastServiceCard() {
    final lastTitle = _vehicle.lastServiceTitle ?? 'Standard Periodic Service';
    final lastDateFormatted = _vehicle.lastServiceDate != null
        ? '${_vehicle.lastServiceDate!.day} ${_getMonthName(_vehicle.lastServiceDate!.month)} ${_vehicle.lastServiceDate!.year}'
        : '14 Sep 2026';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LAST SERVICE COMPLETED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(lastTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(lastDateFormatted, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Booking b) {
    final isCancelled = b.status == BookingStatus.cancelled;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormatted = '${b.dateTime.day} ${_getMonthName(b.dateTime.month)} ${b.dateTime.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          ServiceSummarySheet.show(
            context: context,
            booking: b,
            onBookingUpdated: () {
              if (mounted) setState(() {});
            },
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(b.bookingNumber, style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCancelled ? AppColors.errorBg : AppColors.successBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      b.statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isCancelled ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(b.serviceTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              if (b.packageName != null && b.packageName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Package: ${b.packageName}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(dateFormatted, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Icon(
                    b.pickupType == 'Drop at Workshop' ? Icons.store_rounded : Icons.home_rounded,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    b.pickupType == 'Drop at Workshop' ? 'Workshop Drop' : 'Doorstep Pickup',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppConstants.currencySymbol}${b.totalAmount.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  Row(
                    children: const [
                      Text('View Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_rounded, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 10),
          const Text('No service history yet for this vehicle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Completed services and inspection records will appear here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
