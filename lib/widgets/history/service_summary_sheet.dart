import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/booking.dart';
import '../../models/vehicle.dart';
import '../booking/booking_flow_sheet.dart';
import '../booking/rating_sheet.dart';

class ServiceSummarySheet extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onBookingUpdated;
  final void Function(Vehicle vehicle)? onViewVehicle;

  const ServiceSummarySheet({
    super.key,
    required this.booking,
    this.onBookingUpdated,
    this.onViewVehicle,
  });

  static Future<void> show({
    required BuildContext context,
    required Booking booking,
    VoidCallback? onBookingUpdated,
    void Function(Vehicle vehicle)? onViewVehicle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceSummarySheet(
        booking: booking,
        onBookingUpdated: onBookingUpdated,
        onViewVehicle: onViewVehicle,
      ),
    );
  }

  @override
  State<ServiceSummarySheet> createState() => _ServiceSummarySheetState();
}

class _ServiceSummarySheetState extends State<ServiceSummarySheet> {
  late Booking _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = _getLatestBooking();
    MockData.bookingsNotifier.addListener(_onBookingsChanged);
  }

  @override
  void dispose() {
    MockData.bookingsNotifier.removeListener(_onBookingsChanged);
    super.dispose();
  }

  void _onBookingsChanged() {
    if (mounted) {
      setState(() {
        _currentBooking = _getLatestBooking();
      });
    }
  }

  Booking _getLatestBooking() {
    return MockData.bookings.firstWhere(
      (b) => b.id == widget.booking.id,
      orElse: () => widget.booking,
    );
  }

  Vehicle _getMatchingVehicle() {
    final cleanReg = _currentBooking.vehicleNumber.replaceAll(' ', '').toUpperCase();
    return MockData.vehicles.firstWhere(
      (v) => v.registrationNumber.replaceAll(' ', '').toUpperCase() == cleanReg,
      orElse: () => MockData.activeVehicle,
    );
  }

  void _openBookAgain() {
    final vehicle = _getMatchingVehicle();
    Navigator.pop(context); // Close summary sheet
    BookingFlowSheet.show(
      context: context,
      serviceTitle: _currentBooking.serviceTitle,
      serviceDescription: _currentBooking.serviceDescription,
      price: _currentBooking.servicePrice > 0
          ? _currentBooking.servicePrice
          : _currentBooking.totalAmount,
      durationText: _currentBooking.duration ?? '3 Hours',
      warrantyPeriod: _currentBooking.warrantyPeriod,
      initialVehicle: vehicle,
      onBookingConfirmed: (newBooking) {
        widget.onBookingUpdated?.call();
      },
    );
  }

  void _openRatingSheet() {
    if (_currentBooking.isRated || MockData.isBookingRated(_currentBooking.id)) {
      return;
    }
    RatingSheet.show(
      context: context,
      booking: _currentBooking,
      onSubmitted: () {
        final updated = _getLatestBooking();
        setState(() {
          _currentBooking = updated;
        });
        widget.onBookingUpdated?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _getMatchingVehicle();
    final isRated = _currentBooking.isRated || _currentBooking.rating != null;

    final dateFormatted =
        '${_currentBooking.dateTime.day} ${_getMonthName(_currentBooking.dateTime.month)} ${_currentBooking.dateTime.year}';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service Summary', style: AppTypography.titleLarge),
                  Text(
                    _currentBooking.bookingNumber,
                    style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Booking Information Card
                  _buildSectionCard(
                    title: 'BOOKING INFORMATION',
                    icon: Icons.confirmation_number_outlined,
                    child: Column(
                      children: [
                        _buildRow('Booking ID', _currentBooking.bookingNumber),
                        _buildRow('Service Date', dateFormatted),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Completion Status', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _currentBooking.status == BookingStatus.completed
                                      ? AppColors.successBg
                                      : AppColors.errorBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _currentBooking.statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _currentBooking.status == BookingStatus.completed
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_currentBooking.pickupType.isNotEmpty)
                          _buildRow('Pickup / Delivery Type', _currentBooking.pickupType),
                        _buildRow('Workshop', _currentBooking.workshopName),
                        _buildRow('Lead Technician', _currentBooking.assignedMechanic),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Vehicle Details Card
                  _buildSectionCard(
                    title: 'VEHICLE INFORMATION',
                    icon: Icons.directions_car_rounded,
                    child: Column(
                      children: [
                        _buildRow('Car Make', vehicle.brand),
                        _buildRow('Car Model', vehicle.model),
                        _buildRow('Variant', vehicle.variant.isNotEmpty ? vehicle.variant : 'Standard'),
                        _buildRow('Registration Plate', vehicle.registrationNumber),
                        _buildRow('Fuel Type', vehicle.fuelType),
                        _buildRow('Model Year', '${vehicle.year}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Service Details Card
                  _buildSectionCard(
                    title: 'SERVICE DETAILS',
                    icon: Icons.build_circle_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentBooking.serviceTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        if (_currentBooking.packageName != null && _currentBooking.packageName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Package: ${_currentBooking.packageName}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                        ],
                        if (_currentBooking.serviceDescription != null && _currentBooking.serviceDescription!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(_currentBooking.serviceDescription!, style: AppTypography.bodySmall),
                        ],
                        const SizedBox(height: 8),
                        _buildRow('Estimated Duration', _currentBooking.duration ?? '3 Hours'),
                        _buildRow('Warranty Cover', _currentBooking.warrantyPeriod ?? '6 Months Network Warranty'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Service Work (Inclusions, Checklist, Exclusions)
                  _buildSectionCard(
                    title: 'SERVICE WORK & CHECKLIST',
                    icon: Icons.checklist_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentBooking.includedItems.isNotEmpty) ...[
                          const Text('Included Spares & Labour:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const SizedBox(height: 6),
                          ..._currentBooking.includedItems.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.success),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(item, style: const TextStyle(fontSize: 12))),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 10),
                        ],
                        if (_currentBooking.checklist.isNotEmpty) ...[
                          const Text('Service Inspection Checklist:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const SizedBox(height: 6),
                          ..._currentBooking.checklist.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.task_alt_rounded, size: 15, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(item, style: const TextStyle(fontSize: 12))),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 10),
                        ],
                        if (_currentBooking.exclusions.isNotEmpty) ...[
                          const Text('Exclusions / Additional Items:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const SizedBox(height: 6),
                          ..._currentBooking.exclusions.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.remove_circle_outline_rounded, size: 15, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(item, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. Price Breakdown
                  _buildSectionCard(
                    title: 'PRICE BREAKDOWN',
                    icon: Icons.receipt_long_rounded,
                    child: Column(
                      children: [
                        _buildRow('Base Service Price', '${AppConstants.currencySymbol}${(_currentBooking.servicePrice > 0 ? _currentBooking.servicePrice : _currentBooking.totalAmount).toInt()}'),
                        if (_currentBooking.pickupFee > 0)
                          _buildRow('Pickup & Drop Fee', '${AppConstants.currencySymbol}${_currentBooking.pickupFee.toInt()}'),
                        if (_currentBooking.discountAmount > 0)
                          _buildRow('Discount Applied', '-${AppConstants.currencySymbol}${_currentBooking.discountAmount.toInt()}', isDiscount: true),
                        _buildRow('GST & Taxes', '${AppConstants.currencySymbol}${(_currentBooking.taxAmount > 0 ? _currentBooking.taxAmount : ((_currentBooking.totalAmount * 0.18) / 1.18)).round()}'),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Final Amount Paid', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text(
                              '${AppConstants.currencySymbol}${_currentBooking.totalAmount.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Rating preview if already rated
                  if (isRated) ...[
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      title: 'SERVICE RATING & FEEDBACK',
                      icon: Icons.star_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ...List.generate(5, (idx) {
                                final isFill = idx < (_currentBooking.rating ?? 5);
                                return Icon(
                                  isFill ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Rated',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success),
                                ),
                              ),
                            ],
                          ),
                          if (_currentBooking.ratingFeedback != null && _currentBooking.ratingFeedback!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('"${_currentBooking.ratingFeedback}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (widget.onViewVehicle != null) {
                      Navigator.pop(context);
                      widget.onViewVehicle!(vehicle);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vehicle: ${vehicle.fullName} (${vehicle.registrationNumber})'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.directions_car_rounded, size: 16),
                  label: const Text('View Vehicle'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isRated ? null : _openRatingSheet,
                  icon: Icon(
                    isRated ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: isRated ? Colors.amber : AppColors.primary,
                  ),
                  label: Text(
                    isRated ? 'Rated ★${_currentBooking.rating ?? 5}' : 'Give Rating',
                    style: TextStyle(
                      color: isRated ? Colors.amber.shade900 : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    disabledForegroundColor: Colors.amber.shade900,
                    disabledIconColor: Colors.amber,
                    side: BorderSide(color: isRated ? Colors.amber.shade300 : AppColors.border),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _openBookAgain,
            icon: const Icon(Icons.repeat_rounded, size: 18),
            label: const Text('Book Again', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDiscount ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
