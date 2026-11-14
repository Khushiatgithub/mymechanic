import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/booking.dart';
import '../../models/vehicle.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../history/service_summary_sheet.dart';
import 'booking_flow_sheet.dart';
import 'live_tracker_sheet.dart';
import 'rating_sheet.dart';

class BookingDetailsSheet extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onTrackLive;
  final VoidCallback? onBookingUpdated;
  final BookingService? bookingService;

  const BookingDetailsSheet({
    super.key,
    required this.booking,
    this.onTrackLive,
    this.onBookingUpdated,
    this.bookingService,
  });

  static Future<void> show({
    required BuildContext context,
    required Booking booking,
    VoidCallback? onTrackLive,
    VoidCallback? onBookingUpdated,
    BookingService? bookingService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingDetailsSheet(
        booking: booking,
        onTrackLive: onTrackLive,
        onBookingUpdated: onBookingUpdated,
        bookingService: bookingService,
      ),
    );
  }

  @override
  State<BookingDetailsSheet> createState() => _BookingDetailsSheetState();
}

class _BookingDetailsSheetState extends State<BookingDetailsSheet> {
  late Booking _currentBooking;
  late final BookingService _bookingService;

  @override
  void initState() {
    super.initState();
    _bookingService = widget.bookingService ?? BookingService.instance;
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

  void _confirmCancelBooking() {
    bool isCancelling = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.cancel_outlined, color: AppColors.error),
              SizedBox(width: 8),
              Text('Cancel Booking?'),
            ],
          ),
          content: Text(
            'Are you sure you want to cancel booking ${_currentBooking.bookingNumber} for ${_currentBooking.serviceTitle}? This appointment slot will be released.',
          ),
          actions: [
            TextButton(
              onPressed: isCancelling ? null : () => Navigator.pop(ctx),
              child: const Text('Keep Booking', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isCancelling
                  ? null
                  : () async {
                      setDialogState(() => isCancelling = true);
                      final isAuth = AuthService.instance.isAuthenticated || widget.bookingService != null;
                      final isRealId = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(_currentBooking.id);

                      if (isAuth && isRealId) {
                        try {
                          final updated = await _bookingService.cancelBooking(_currentBooking.id);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (!mounted) return;
                          setState(() {
                            _currentBooking = updated;
                          });
                          MockData.cancelBooking(_currentBooking.id);
                          widget.onBookingUpdated?.call();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Booking ${_currentBooking.bookingNumber} has been cancelled'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          if (ctx.mounted) {
                            setDialogState(() => isCancelling = false);
                            Navigator.pop(ctx);
                          }
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(BookingService.getErrorMessage(e)),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        MockData.cancelBooking(_currentBooking.id);
                        setState(() {
                          _currentBooking = _currentBooking.copyWith(status: BookingStatus.cancelled);
                        });
                        widget.onBookingUpdated?.call();
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Booking ${_currentBooking.bookingNumber} has been cancelled'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Yes, Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _openRescheduleDialog() {
    int selectedDateIdx = 0;
    int selectedTimeIdx = 1;
    bool isSubmitting = false;

    final dates = List.generate(14, (i) {
      final d = DateTime.now().add(Duration(days: i + 1));
      final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
      final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1];
      return {'display': '$weekday, ${d.day} $month', 'date': d};
    });

    final slots = [
      '09:00 AM',
      '10:30 AM',
      '12:00 PM',
      '02:00 PM',
      '04:00 PM',
      '06:00 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? AppColors.darkElevatedSurface
                : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Theme.of(ctx).brightness == Brightness.dark
                ? const Border(top: BorderSide(color: AppColors.darkBorder))
                : null,
          ),
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Reschedule Booking', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a new appointment date & time slot for your vehicle servicing.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),

              Text('New Service Date', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  itemBuilder: (ctx, idx) {
                    final isSel = selectedDateIdx == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(dates[idx]['display'] as String),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceVariant,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedDateIdx = idx);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              Text('New Time Slot', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(slots.length, (idx) {
                  final isSel = selectedTimeIdx == idx;
                  return ChoiceChip(
                    label: Text(slots[idx]),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setModalState(() => selectedTimeIdx = idx);
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final newDate = dates[selectedDateIdx]['date'] as DateTime;
                        final newSlot = slots[selectedTimeIdx];

                        final isAuth = AuthService.instance.isAuthenticated || widget.bookingService != null;
                        final isRealId = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(_currentBooking.id);

                        if (isAuth && isRealId) {
                          setModalState(() => isSubmitting = true);
                          try {
                            final updated = await _bookingService.rescheduleBooking(
                              _currentBooking.id,
                              scheduledDate: newDate,
                              scheduledTime: newSlot,
                            );
                            if (!mounted) return;
                            setState(() {
                              _currentBooking = updated;
                            });
                            MockData.rescheduleBooking(_currentBooking.id, newDate, newSlot);
                            widget.onBookingUpdated?.call();
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(BookingService.getErrorMessage(e)),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            if (ctx.mounted) {
                              setModalState(() => isSubmitting = false);
                            }
                          }
                        } else {
                          MockData.rescheduleBooking(_currentBooking.id, newDate, newSlot);
                          setState(() {
                            _currentBooking = _currentBooking.copyWith(
                              dateTime: newDate,
                              timeSlot: newSlot,
                            );
                          });
                          widget.onBookingUpdated?.call();
                          Navigator.pop(ctx);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirm Reschedule', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
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
    Navigator.pop(context);
    BookingFlowSheet.show(
      context: context,
      serviceTitle: _currentBooking.serviceTitle,
      serviceDescription: _currentBooking.serviceDescription,
      price: _currentBooking.servicePrice > 0 ? _currentBooking.servicePrice : _currentBooking.totalAmount,
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

  void _openServiceSummary() {
    ServiceSummarySheet.show(
      context: context,
      booking: _currentBooking,
      onBookingUpdated: () {
        final updated = MockData.bookings.firstWhere(
          (b) => b.id == _currentBooking.id,
          orElse: () => _currentBooking,
        );
        setState(() {
          _currentBooking = updated;
        });
        widget.onBookingUpdated?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusBg = AppColors.infoBg;
    Color statusColor = AppColors.info;

    if (_currentBooking.status == BookingStatus.completed) {
      statusBg = AppColors.successBg;
      statusColor = AppColors.success;
    } else if (_currentBooking.status == BookingStatus.inProgress) {
      statusBg = AppColors.warningBg;
      statusColor = AppColors.warning;
    } else if (_currentBooking.status == BookingStatus.cancelled) {
      statusBg = AppColors.errorBg;
      statusColor = AppColors.error;
    }

    final isCompleted = _currentBooking.status == BookingStatus.completed;
    final isCancelled = _currentBooking.status == BookingStatus.cancelled;
    final isRated = _currentBooking.isRated || _currentBooking.rating != null;

    final dateFormatted =
        '${_currentBooking.dateTime.day} ${_getMonthName(_currentBooking.dateTime.month)} ${_currentBooking.dateTime.year}';
    final timeFormatted = _currentBooking.timeSlot ?? '10:30 AM';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
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
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Details', style: AppTypography.titleLarge),
                  Text(_currentBooking.bookingNumber, style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentBooking.statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cancelled banner if cancelled
                  if (isCancelled) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This booking was cancelled. You can easily book this service again below.',
                              style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Service Card
                  _buildSectionCard(
                    title: 'SERVICE BOOKED',
                    icon: Icons.build_circle_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentBooking.serviceTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        if (_currentBooking.packageName != null && _currentBooking.packageName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Package: ${_currentBooking.packageName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                        if (_currentBooking.serviceDescription != null && _currentBooking.serviceDescription!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_currentBooking.serviceDescription!, style: AppTypography.bodySmall),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(_currentBooking.duration ?? '3 Hours', style: AppTypography.bodySmall),
                            const SizedBox(width: 14),
                            const Icon(Icons.shield_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(_currentBooking.warrantyPeriod ?? 'Network Warranty Covered', style: AppTypography.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Vehicle Card
                  _buildSectionCard(
                    title: 'ASSIGNED VEHICLE',
                    icon: Icons.directions_car_rounded,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_currentBooking.vehicleName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(_currentBooking.vehicleNumber, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade400, width: 0.8),
                          ),
                          child: Text(
                            _currentBooking.vehicleNumber,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Appointment Schedule
                  _buildSectionCard(
                    title: 'APPOINTMENT SCHEDULE',
                    icon: Icons.calendar_today_rounded,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(dateFormatted, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Time Slot', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(timeFormatted, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pickup / Drop & Location
                  _buildSectionCard(
                    title: 'PICKUP & WORKSHOP',
                    icon: Icons.local_shipping_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _currentBooking.pickupType == 'Drop at Workshop'
                                   ? Icons.store_rounded
                                  : Icons.home_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(_currentBooking.pickupType, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                        if (_currentBooking.address != null && _currentBooking.address!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(_currentBooking.address!, style: AppTypography.bodySmall),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Workshop: ${_currentBooking.workshopName}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Demo Hub', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Technician: ${_currentBooking.assignedMechanic}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Demo Seed Data', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price Breakdown
                  _buildSectionCard(
                    title: 'PRICE BREAKDOWN',
                    icon: Icons.receipt_long_rounded,
                    child: Column(
                      children: [
                        _buildRow('Service Base Price', '${AppConstants.currencySymbol}${(_currentBooking.servicePrice > 0 ? _currentBooking.servicePrice : _currentBooking.totalAmount).toInt()}'),
                        if (_currentBooking.pickupFee > 0)
                          _buildRow('Pickup & Drop Fee', '${AppConstants.currencySymbol}${_currentBooking.pickupFee.toInt()}'),
                        if (_currentBooking.discountAmount > 0)
                          _buildRow('Coupon Discount (${_currentBooking.couponCode ?? "PROMO"})', '-${AppConstants.currencySymbol}${_currentBooking.discountAmount.toInt()}', isDiscount: true),
                        _buildRow('GST & Taxes', '${AppConstants.currencySymbol}${(_currentBooking.taxAmount > 0 ? _currentBooking.taxAmount : ((_currentBooking.totalAmount * 0.18) / 1.18)).round()}'),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text(
                              '${AppConstants.currencySymbol}${_currentBooking.totalAmount.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const Divider(height: 14),
                        _buildRow('Payment Option', _currentBooking.paymentMethodTitle),
                        _buildRow(
                          'Payment Status',
                          _currentBooking.isPaid ? 'PAID (Demo Simulation)' : 'DUE ON DELIVERY',
                          color: _currentBooking.isPaid ? AppColors.success : AppColors.warning,
                        ),
                        if (_currentBooking.paymentReference != null)
                          _buildRow('Transaction Ref', _currentBooking.paymentReference!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Actions
          if (!isCompleted && !isCancelled) ...[
            // Active booking actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openRescheduleDialog,
                    icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                    label: const Text('Reschedule'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _confirmCancelBooking,
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                    label: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if (widget.onTrackLive != null) {
                  widget.onTrackLive!();
                } else {
                  LiveTrackerSheet.show(context: context, booking: _currentBooking);
                }
              },
              icon: const Icon(Icons.navigation_outlined, size: 16),
              label: const Text('Track Service', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else if (isCompleted) ...[
            // Completed booking actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openServiceSummary,
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                    label: const Text('View Service Summary'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
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
                      isRated ? 'Rated ★${_currentBooking.rating ?? 5}' : 'Rate Service',
                      style: TextStyle(
                        color: isRated ? Colors.amber.shade900 : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: Colors.amber.shade900,
                      disabledIconColor: Colors.amber,
                      side: BorderSide(color: isRated ? Colors.amber.shade300 : AppColors.border),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
          ] else ...[
            // Cancelled booking actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viewing booking details for ${_currentBooking.bookingNumber}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('View Booking'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openBookAgain,
                    icon: const Icon(Icons.repeat_rounded, size: 18),
                    label: const Text('Book Again', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
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

  Widget _buildRow(String label, String value, {bool isDiscount = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? (isDiscount ? AppColors.success : AppColors.textPrimary),
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
