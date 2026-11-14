import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/booking.dart';
import '../../models/vehicle.dart';
import '../vehicle/vehicle_form_sheet.dart';
import 'add_address_sheet.dart';
import 'coupon_selection_sheet.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/offer_service.dart';
import '../../models/workshop.dart';
import '../../services/workshop_service.dart';

class BookingFlowSheet extends StatefulWidget {
  final String? serviceId;
  final BookingService? bookingService;
  final String serviceTitle;
  final String? serviceDescription;
  final double price;
  final double? originalPrice;
  final String durationText;
  final String? warrantyPeriod;
  final Vehicle? initialVehicle;
  final String? initialCouponCode;
  final void Function(Booking newBooking)? onBookingConfirmed;
  final VoidCallback? onNavigateToBookings;

  const BookingFlowSheet({
    super.key,
    this.serviceId,
    this.bookingService,
    required this.serviceTitle,
    this.serviceDescription,
    required this.price,
    this.originalPrice,
    this.durationText = '3 Hours',
    this.warrantyPeriod,
    this.initialVehicle,
    this.initialCouponCode,
    this.onBookingConfirmed,
    this.onNavigateToBookings,
  });

  static Future<Booking?> show({
    required BuildContext context,
    String? serviceId,
    BookingService? bookingService,
    required String serviceTitle,
    String? serviceDescription,
    required double price,
    double? originalPrice,
    String durationText = '3 Hours',
    String? warrantyPeriod,
    Vehicle? initialVehicle,
    String? initialCouponCode,
    void Function(Booking newBooking)? onBookingConfirmed,
    VoidCallback? onNavigateToBookings,
  }) {
    return showModalBottomSheet<Booking?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingFlowSheet(
        serviceId: serviceId,
        bookingService: bookingService,
        serviceTitle: serviceTitle,
        serviceDescription: serviceDescription,
        price: price,
        originalPrice: originalPrice,
        durationText: durationText,
        warrantyPeriod: warrantyPeriod,
        initialVehicle: initialVehicle,
        initialCouponCode: initialCouponCode,
        onBookingConfirmed: onBookingConfirmed,
        onNavigateToBookings: onNavigateToBookings,
      ),
    );
  }

  @override
  State<BookingFlowSheet> createState() => _BookingFlowSheetState();
}

class _BookingFlowSheetState extends State<BookingFlowSheet> {
  int _currentStep = 0; // 0: Service & Vehicle, 1: Date & Time, 2: Pickup & Address, 3: Summary & Coupon, 4: Confirmed
  bool _isSubmitting = false;
  late final BookingService _bookingService;

  late Vehicle _selectedVehicle;
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = 1;
  bool _doorstepPickup = true;
  int _selectedAddressIndex = 0;

  // Coupons
  final TextEditingController _couponController = TextEditingController();
  bool _couponApplied = false;
  String _appliedCouponCode = '';
  double _serverCouponDiscount = 0.0;
  String? _couponError;
  String _selectedPaymentMethod = 'pay_on_delivery';

  // Workshops (Demo Seed Data)
  List<Workshop> _workshops = MockData.workshops;
  int _selectedWorkshopIndex = 0;

  Booking? _createdBooking;

  late final List<Map<String, dynamic>> _upcomingDates;
  static const List<String> _timeSlots = [
    '09:00 AM',
    '10:30 AM',
    '12:00 PM',
    '02:00 PM',
    '04:00 PM',
    '06:00 PM',
  ];

  static const double _doorstepPickupFee = 149.0;

  @override
  void initState() {
    super.initState();
    _bookingService = widget.bookingService ?? BookingService.instance;
    _selectedVehicle = widget.initialVehicle ?? MockData.activeVehicle;

    // Generate next 14 days (no past dates)
    _upcomingDates = List.generate(14, (i) {
      final date = DateTime.now().add(Duration(days: i + 1));
      final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
      return {
        'display': '$weekday, ${date.day} $month',
        'date': date,
      };
    });

    if (widget.initialCouponCode != null && widget.initialCouponCode!.isNotEmpty) {
      _applyCoupon(widget.initialCouponCode!);
    }

    _loadWorkshops();
  }

  Future<void> _loadWorkshops() async {
    try {
      final hubs = await WorkshopService.instance.getWorkshops();
      if (mounted && hubs.isNotEmpty) {
        setState(() {
          _workshops = hubs;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  // Pricing calculations
  double get _serviceBasePrice => widget.price;
  double get _pickupFee => _doorstepPickup ? _doorstepPickupFee : 0.0;

  double get _couponDiscount {
    if (!_couponApplied) return 0.0;
    if (_serverCouponDiscount > 0) return _serverCouponDiscount;
    return MockData.calculateDiscount(_appliedCouponCode, _serviceBasePrice);
  }

  double get _subtotal => (_serviceBasePrice - _couponDiscount + _pickupFee).clamp(0.0, double.infinity);
  double get _taxAmount => (_subtotal * 0.18).roundToDouble();
  double get _finalTotal => _subtotal + _taxAmount;

  Future<void> _applyCoupon(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      setState(() {
        _couponError = 'Please enter a coupon code';
      });
      return;
    }

    final validation = await OfferService.instance.validateCoupon(
      code: cleanCode,
      orderAmount: _serviceBasePrice,
      category: widget.serviceTitle,
      serviceId: widget.serviceId,
    );

    if (!mounted) return;

    if (validation.isValid) {
      setState(() {
        _couponApplied = true;
        _appliedCouponCode = cleanCode;
        _serverCouponDiscount = validation.discountAmount;
        _couponController.text = cleanCode;
        _couponError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coupon "$cleanCode" applied! (Saved ₹${validation.discountAmount.toInt()})'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _couponError = validation.errorMessage ?? 'Invalid coupon code';
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponApplied = false;
      _appliedCouponCode = '';
      _serverCouponDiscount = 0.0;
      _couponController.clear();
      _couponError = null;
    });
  }

  Future<void> _confirmBooking() async {
    if (_isSubmitting) return;

    final selectedDate = _upcomingDates[_selectedDateIndex]['date'] as DateTime;
    final timeSlot = _timeSlots[_selectedTimeIndex];

    final selectedWorkshop = _workshops.isNotEmpty && _selectedWorkshopIndex < _workshops.length
        ? _workshops[_selectedWorkshopIndex]
        : null;
    final workshopName = selectedWorkshop?.name ?? 'My Mechanic Premium Car Service';
    final workshopMechanic = selectedWorkshop?.leadMechanic ?? 'Assigned upon arrival';
    final workshopId = selectedWorkshop?.id;

    final addresses = MockData.savedAddresses;
    final chosenAddress = _doorstepPickup && addresses.isNotEmpty
        ? (_selectedAddressIndex < addresses.length
            ? '${addresses[_selectedAddressIndex]['address']}, ${addresses[_selectedAddressIndex]['city']} - ${addresses[_selectedAddressIndex]['pincode']}'
            : addresses.first['address'])
        : (selectedWorkshop != null ? '${selectedWorkshop.name}, ${selectedWorkshop.address}' : 'Drop-off at Workshop');

    final isAuth = AuthService.instance.isAuthenticated || widget.bookingService != null;
    final isRealVehicle = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(_selectedVehicle.id);
    final isRealService = widget.serviceId != null && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(widget.serviceId!);

    final isOnlineSimulated = _selectedPaymentMethod != 'pay_on_delivery';
    final paymentStatus = isOnlineSimulated ? 'paid' : 'pending';
    final paymentRef = isOnlineSimulated
        ? 'SIM-${_selectedPaymentMethod.toUpperCase()}-${Random().nextInt(899999) + 100000}'
        : null;
    final paidAt = isOnlineSimulated ? DateTime.now() : null;

    if (widget.bookingService != null || (isAuth && isRealVehicle && isRealService)) {
      setState(() => _isSubmitting = true);
      try {
        final serverBooking = await _bookingService.createBooking(
          vehicleId: _selectedVehicle.id,
          serviceId: widget.serviceId ?? '67b8a1000000000000000001',
          scheduledDate: selectedDate,
          scheduledTime: timeSlot,
          serviceMode: _doorstepPickup ? 'doorstep' : 'workshop',
          address: _doorstepPickup ? chosenAddress : null,
          couponCode: _couponApplied ? _appliedCouponCode : null,
          subtotal: _serviceBasePrice,
          discount: _couponDiscount,
          pickupFee: _pickupFee,
          gst: _taxAmount,
          totalAmount: _finalTotal,
          paymentMethod: _selectedPaymentMethod,
          paymentStatus: paymentStatus,
          paymentReference: paymentRef,
          workshopId: !_doorstepPickup ? workshopId : null,
          workshopName: workshopName,
          assignedMechanic: workshopMechanic,
        );

        MockData.addBooking(serverBooking);

        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _createdBooking = serverBooking;
          _currentStep = 4;
        });

        widget.onBookingConfirmed?.call(serverBooking);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BookingService.getErrorMessage(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Local / Guest booking fallback
    final randomId = 1000 + Random().nextInt(9000);
    final bookingNumber = 'MM-2026-$randomId';

    final newBooking = Booking(
      id: 'b_$randomId',
      bookingNumber: bookingNumber,
      serviceTitle: widget.serviceTitle,
      serviceDescription: widget.serviceDescription ?? 'Multi-point service checkup with genuine spares',
      vehicleName: '${_selectedVehicle.brand} ${_selectedVehicle.model} ${_selectedVehicle.variant}',
      vehicleNumber: _selectedVehicle.registrationNumber,
      dateTime: selectedDate,
      timeSlot: timeSlot,
      servicePrice: _serviceBasePrice,
      pickupFee: _pickupFee,
      discountAmount: _couponDiscount,
      taxAmount: _taxAmount,
      totalAmount: _finalTotal,
      pickupType: _doorstepPickup ? 'Doorstep Pickup & Drop' : 'Drop at Workshop',
      address: chosenAddress,
      couponCode: _couponApplied ? _appliedCouponCode : null,
      status: BookingStatus.confirmed,
      workshopName: workshopName,
      assignedMechanic: workshopMechanic,
      serviceId: widget.serviceId,
      vehicleId: _selectedVehicle.id,
      serviceMode: _doorstepPickup ? 'doorstep' : 'workshop',
      paymentMethod: _selectedPaymentMethod,
      paymentStatus: paymentStatus,
      paymentReference: paymentRef,
      paidAt: paidAt,
    );

    MockData.addBooking(newBooking);

    setState(() {
      _createdBooking = newBooking;
      _currentStep = 4;
    });

    widget.onBookingConfirmed?.call(newBooking);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
          const SizedBox(height: 12),

          // Header with Stepper
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentStep == 4 ? 'Booking Status' : 'Book a Service',
                  style: AppTypography.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Stepper indicator (visible during steps 0-3)
          if (_currentStep < 4) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildProgressStepper(),
            ),
            const SizedBox(height: 12),
          ],

          // Step Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCurrentStepContent(),
            ),
          ),
          const SizedBox(height: 12),

          // Footer Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildFooterButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStepper() {
    final stepLabels = ['Service', 'Schedule', 'Pickup', 'Summary'];

    return Row(
      children: List.generate(stepLabels.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepBefore = index ~/ 2;
          final isCompleted = _currentStep > stepBefore;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: isCompleted ? AppColors.success : AppColors.border,
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isCompleted = _currentStep > stepIndex;
        final isCurrent = _currentStep == stepIndex;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isCurrent
                        ? AppColors.primary
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkInputSurface
                            : AppColors.surfaceVariant),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isCurrent
                              ? Colors.white
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              stepLabels[stepIndex],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0ServiceAndVehicle();
      case 1:
        return _buildStep1Schedule();
      case 2:
        return _buildStep2PickupAndAddress();
      case 3:
        return _buildStep3SummaryAndCoupon();
      case 4:
        return _buildStep4Confirmation();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 0: Service Preview + Vehicle Picker
  Widget _buildStep0ServiceAndVehicle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service details card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECTED SERVICE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (widget.originalPrice != null && widget.originalPrice! > widget.price)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SAVE ${AppConstants.currencySymbol}${(widget.originalPrice! - widget.price).toInt()}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.serviceTitle,
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              if (widget.serviceDescription != null && widget.serviceDescription!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(widget.serviceDescription!, style: AppTypography.bodySmall),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(widget.durationText, style: AppTypography.bodySmall),
                  if (widget.warrantyPeriod != null) ...[
                    const SizedBox(width: 14),
                    const Icon(Icons.shield_outlined, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      widget.warrantyPeriod!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.success),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${AppConstants.currencySymbol}${widget.price.toInt()}',
                    style: AppTypography.priceLarge.copyWith(color: AppColors.primary),
                  ),
                  if (widget.originalPrice != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${AppConstants.currencySymbol}${widget.originalPrice!.toInt()}',
                      style: const TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Vehicle Selector Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Select Vehicle for this Service: *',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                VehicleFormSheet.show(
                  context: context,
                  onSave: (newVehicle) {
                    MockData.addVehicle(newVehicle);
                    setState(() {
                      _selectedVehicle = newVehicle;
                    });
                  },
                );
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('Add Car', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 6),

        ValueListenableBuilder<List<Vehicle>>(
          valueListenable: MockData.vehiclesNotifier,
          builder: (context, vehicles, _) {
            if (vehicles.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No vehicles found. Tap "Add Car" above.', style: AppTypography.bodySmall),
                ),
              );
            }

            return Column(
              children: vehicles.map((v) {
                final isSelected = v.id == _selectedVehicle.id;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.05)
                        : (isDark ? AppColors.darkSurface : AppColors.surface),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : (isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${v.brand} ${v.model} (${v.variant})',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (v.isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${v.fuelType} • ${v.year} • ${v.registrationNumber}',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : const Icon(Icons.radio_button_off_rounded, color: AppColors.border),
                    onTap: () {
                      setState(() {
                        _selectedVehicle = v;
                      });
                      MockData.setActiveVehicle(v.id);
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // STEP 1: Date & Time Slot
  Widget _buildStep1Schedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Service Date:',
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text('Available over the next 14 business days', style: AppTypography.bodySmall),
        const SizedBox(height: 12),

        // 14-day date chips grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_upcomingDates.length, (index) {
            final isSelected = _selectedDateIndex == index;
            final item = _upcomingDates[index];
            return ChoiceChip(
              label: Text(item['display'] as String),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedDateIndex = index);
              },
            );
          }),
        ),
        const SizedBox(height: 20),

        Text(
          'Select Time Slot:',
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text('Our certified technician will arrive within this window', style: AppTypography.bodySmall),
        const SizedBox(height: 12),

        // Time slots
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_timeSlots.length, (index) {
            final isSelected = _selectedTimeIndex == index;
            return ChoiceChip(
              label: Text(_timeSlots[index]),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedTimeIndex = index);
              },
            );
          }),
        ),
      ],
    );
  }

  // STEP 2: Pickup / Drop & Address Selection
  Widget _buildStep2PickupAndAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Delivery Option:', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),

        // Choice 1: Doorstep Pickup & Drop
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _doorstepPickup
                ? AppColors.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.05)
                : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _doorstepPickup
                  ? AppColors.primary
                  : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.border),
              width: _doorstepPickup ? 1.6 : 1,
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.local_shipping_outlined,
              color: _doorstepPickup
                  ? AppColors.primary
                  : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Doorstep Pickup & Drop', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(
                  '+${AppConstants.currencySymbol}${_doorstepPickupFee.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 12),
                ),
              ],
            ),
            subtitle: const Text('Driver picks up car, delivers post-service with live GPS tracking', style: TextStyle(fontSize: 11)),
            trailing: _doorstepPickup
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                : Icon(Icons.radio_button_off_rounded,
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.border),
            onTap: () => setState(() => _doorstepPickup = true),
          ),
        ),

        // Choice 2: Drop at Workshop
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: !_doorstepPickup
                ? AppColors.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.05)
                : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: !_doorstepPickup
                  ? AppColors.primary
                  : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.border),
              width: !_doorstepPickup ? 1.6 : 1,
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.store_rounded,
              color: !_doorstepPickup ? AppColors.primary : AppColors.textSecondary,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Self Drop at Workshop', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('FREE', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.success, fontSize: 12)),
              ],
            ),
            subtitle: const Text('Bring car to My Mechanic Premium Car Service, Gurugram and relax in our customer lounge', style: TextStyle(fontSize: 11)),
            trailing: !_doorstepPickup
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                : const Icon(Icons.radio_button_off_rounded, color: AppColors.border),
            onTap: () => setState(() => _doorstepPickup = false),
          ),
        ),

        // If Doorstep Pickup chosen, show address picker
        if (_doorstepPickup) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Pickup Address: *', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                onPressed: () {
                  AddAddressSheet.show(
                    context: context,
                    onAddressAdded: (newAddr) {
                      setState(() {
                        _selectedAddressIndex = MockData.savedAddresses.length - 1;
                      });
                    },
                  );
                },
                icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                label: const Text('Add Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),

          ValueListenableBuilder<List<Map<String, String>>>(
            valueListenable: MockData.addressesNotifier,
            builder: (context, addresses, _) {
              if (addresses.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('No address found. Tap "Add Address" above.', style: AppTypography.bodySmall),
                  ),
                );
              }

              return Column(
                children: List.generate(addresses.length, (idx) {
                  final addr = addresses[idx];
                  final isSel = _selectedAddressIndex == idx;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.border,
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        addr['tag'] == 'Office' ? Icons.business_rounded : Icons.home_rounded,
                        color: isSel ? AppColors.primary : AppColors.textSecondary,
                      ),
                      title: Text(
                        addr['tag'] ?? 'Address',
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                          color: isSel ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                      subtitle: Text(
                        '${addr['address']}, ${addr['city']} - ${addr['pincode']}',
                        style: AppTypography.bodySmall,
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : const Icon(Icons.radio_button_off_rounded, color: AppColors.border),
                      onTap: () => setState(() => _selectedAddressIndex = idx),
                    ),
                  );
                }),
              );
            },
          ),
        ],

        // Choice 2: Drop at Workshop Hubs (Demo Seed Data)
        if (!_doorstepPickup) ...[
          if (_workshops.any((w) => w.isDemoSeedData))
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notice: Workshop addresses and details are for evaluation purposes.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Select Workshop Location:',
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...List.generate(_workshops.length, (idx) {
            final hub = _workshops[idx];
            final isSel = _selectedWorkshopIndex == idx;
            return InkWell(
              onTap: () => setState(() => _selectedWorkshopIndex = idx),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel ? AppColors.primary : AppColors.border,
                    width: isSel ? 1.6 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hub.area,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Demo Seed Data',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          '${hub.rating}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSel ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                          color: isSel ? AppColors.primary : AppColors.border,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hub.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hub.address,
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Lead: ${hub.leadMechanic}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                        Text(
                          hub.operatingHours,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // STEP 3: Summary & Coupon Application
  Widget _buildStep3SummaryAndCoupon() {
    final selectedDateStr = _upcomingDates[_selectedDateIndex]['display'] as String;
    final selectedTimeStr = _timeSlots[_selectedTimeIndex];

    final selectedWorkshop = _workshops.isNotEmpty && _selectedWorkshopIndex < _workshops.length
        ? _workshops[_selectedWorkshopIndex]
        : null;

    final addresses = MockData.savedAddresses;
    final addressDisplay = _doorstepPickup && addresses.isNotEmpty
        ? (_selectedAddressIndex < addresses.length
            ? '${addresses[_selectedAddressIndex]['tag']}: ${addresses[_selectedAddressIndex]['address']}'
            : addresses.first['address']!)
        : '${selectedWorkshop?.name ?? "Workshop Hub"} [Demo Seed Data]';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Booking Summary Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Service', widget.serviceTitle),
              const Divider(height: 14),
              _buildSummaryRow('Vehicle', '${_selectedVehicle.brand} ${_selectedVehicle.model} ${_selectedVehicle.variant}'),
              const Divider(height: 14),
              _buildSummaryRow('Reg No.', _selectedVehicle.registrationNumber),
              const Divider(height: 14),
              _buildSummaryRow('Date & Slot', '$selectedDateStr at $selectedTimeStr'),
              const Divider(height: 14),
              _buildSummaryRow('Pickup Mode', _doorstepPickup ? 'Doorstep Pickup & Drop' : 'Self Drop at Workshop'),
              if (_doorstepPickup) ...[
                const Divider(height: 14),
                _buildSummaryRow('Address', addressDisplay),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Coupon Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Offers & Promo Code', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            TextButton.icon(
              onPressed: () {
                CouponSelectionSheet.show(
                  context: context,
                  orderAmount: _serviceBasePrice,
                  serviceTitle: widget.serviceTitle,
                  serviceCategory: widget.serviceTitle,
                  currentCouponCode: _appliedCouponCode,
                  onCouponSelected: (coupon) {
                    _applyCoupon(coupon.code);
                  },
                );
              },
              icon: const Icon(Icons.percent_rounded, size: 14),
              label: const Text('View All Coupons', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (!_couponApplied) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code (e.g. MYFIRST500)',
                    prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _applyCoupon(_couponController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
          if (_couponError != null) ...[
            const SizedBox(height: 4),
            Text(_couponError!, style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 8),

          // Quick Tap Coupon Pills
          Wrap(
            spacing: 8,
            children: [
              _buildCouponPill('MYFIRST500', 'Flat ₹500 OFF'),
              _buildCouponPill('COOLCHILL25', '25% OFF'),
            ],
          ),
        ] else ...[
          // Applied Coupon Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Coupon "$_appliedCouponCode" Applied', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.success)),
                        Text('You saved ${AppConstants.currencySymbol}${_couponDiscount.toInt()}', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _removeCoupon,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error, padding: EdgeInsets.zero),
                  child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Price Breakdown
        Text('Price Breakdown', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              _buildPriceRow('Service Price', '${AppConstants.currencySymbol}${_serviceBasePrice.toInt()}'),
              if (_doorstepPickup)
                _buildPriceRow('Doorstep Pickup & Drop', '${AppConstants.currencySymbol}${_pickupFee.toInt()}'),
              if (_couponApplied)
                _buildPriceRow('Coupon Discount ($_appliedCouponCode)', '-${AppConstants.currencySymbol}${_couponDiscount.toInt()}', isDiscount: true),
              _buildPriceRow('GST & Taxes (18%)', '${AppConstants.currencySymbol}${_taxAmount.toInt()}'),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Final Payable Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(
                    '${AppConstants.currencySymbol}${_finalTotal.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Payment Options Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Payment Option', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Demo Mode',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.info,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Disclaimer alert
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Simulated online payments are for demo purposes only. No real money will be charged.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        _buildPaymentOptionTile(
          id: 'pay_on_delivery',
          title: 'Pay on Service Completion',
          subtitle: 'Cash, UPI, or Card upon vehicle delivery',
          icon: Icons.handshake_outlined,
        ),
        const SizedBox(height: 8),
        _buildPaymentOptionTile(
          id: 'online_upi',
          title: 'Simulated Online UPI',
          subtitle: 'Instant demo confirmation via virtual UPI ID',
          icon: Icons.qr_code_2_rounded,
          badge: 'Simulated',
        ),
        const SizedBox(height: 8),
        _buildPaymentOptionTile(
          id: 'online_card',
          title: 'Simulated Credit / Debit Card',
          subtitle: 'Instant demo confirmation via virtual card',
          icon: Icons.credit_card_rounded,
          badge: 'Simulated',
        ),
      ],
    );
  }

  Widget _buildPaymentOptionTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badge,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.05)
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, fontSize: 13)),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.info),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // STEP 4: Confirmation Screen
  Widget _buildStep4Confirmation() {
    final b = _createdBooking;
    if (b == null) return const SizedBox.shrink();

    final dateFormatted = '${b.dateTime.day} ${_getMonthName(b.dateTime.month)} ${b.dateTime.year}';
    final timeFormatted = b.timeSlot ?? '10:30 AM';

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 44),
        ),
        const SizedBox(height: 12),
        Text('Booking Confirmed!', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Booking ID: ${b.bookingNumber}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 14)),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Service', b.serviceTitle),
              const Divider(height: 12),
              _buildSummaryRow('Vehicle', b.vehicleName),
              const Divider(height: 12),
              _buildSummaryRow('Date & Time', '$dateFormatted at $timeFormatted'),
              const Divider(height: 12),
              _buildSummaryRow('Pickup Option', b.pickupType),
              const Divider(height: 12),
              _buildSummaryRow('Payment Option', b.paymentMethodTitle),
              const Divider(height: 12),
              _buildSummaryRow(
                'Payment Status',
                b.isPaid ? 'PAID (Demo Simulation)' : 'DUE ON DELIVERY',
                valueColor: b.isPaid ? AppColors.success : AppColors.warning,
              ),
              if (b.paymentReference != null) ...[
                const Divider(height: 12),
                _buildSummaryRow('Transaction Ref', b.paymentReference!),
              ],
              const Divider(height: 12),
              _buildSummaryRow('Total Paid / Due', '${AppConstants.currencySymbol}${b.totalAmount.toInt()}', valueColor: AppColors.primary),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFooterButtons() {
    if (_currentStep == 4) {
      final b = _createdBooking;
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go to Home'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, b);
                widget.onNavigateToBookings?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Booking', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }

    final isLastStep = _currentStep == 3;

    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (isLastStep) {
                      _confirmBooking();
                    } else {
                      setState(() => _currentStep++);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isLastStep ? 'Confirm Booking' : 'Continue',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
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
              color: isDiscount ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponPill(String code, String desc) {
    return ActionChip(
      avatar: const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.primary),
      label: Text('$code ($desc)'),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      onPressed: () => _applyCoupon(code),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
