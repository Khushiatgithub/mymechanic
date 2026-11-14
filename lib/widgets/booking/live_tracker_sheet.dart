import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/booking.dart';
import '../../data/mock_data.dart';
import '../../services/booking_service.dart';
import 'booking_flow_sheet.dart';

class LiveTrackerSheet extends StatefulWidget {
  final Booking booking;
  final BookingService? bookingService;

  const LiveTrackerSheet({
    super.key,
    required this.booking,
    this.bookingService,
  });

  static Future<void> show({
    required BuildContext context,
    required Booking booking,
    BookingService? bookingService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, scrollController) => LiveTrackerSheet(
          booking: booking,
          bookingService: bookingService,
        ),
      ),
    );
  }

  @override
  State<LiveTrackerSheet> createState() => _LiveTrackerSheetState();
}

class _LiveTrackerSheetState extends State<LiveTrackerSheet> {
  late Booking _currentBooking;
  late final BookingService _bookingService;
  bool _isRefreshing = false;
  bool _isAdvancingStatus = false;

  static const List<String> _statusOrder = [
    'confirmed',
    'vehicle_received',
    'inspection',
    'service_in_progress',
    'quality_check',
    'ready_for_delivery',
    'completed',
  ];

  Future<void> _advanceDemoStatus() async {
    final currentBackendStatus = (_currentBooking.backendStatus != null && _currentBooking.backendStatus!.isNotEmpty)
        ? _currentBooking.backendStatus!
        : (_currentBooking.status == BookingStatus.confirmed ? 'confirmed' : 'service_in_progress');

    final currentIndex = _statusOrder.indexOf(currentBackendStatus);
    if (currentIndex == -1 || currentIndex >= _statusOrder.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service has reached the final stage (Completed).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final nextStatus = _statusOrder[currentIndex + 1];

    setState(() => _isAdvancingStatus = true);

    try {
      final isRealId = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(_currentBooking.id);
      if (isRealId) {
        final updated = await _bookingService.updateBookingStatus(_currentBooking.id, nextStatus);
        MockData.updateBooking(updated);
        if (mounted) {
          setState(() {
            _currentBooking = updated;
            _isAdvancingStatus = false;
          });
        }
      } else {
        BookingStatus newStatus;
        switch (nextStatus) {
          case 'vehicle_received':
          case 'inspection':
          case 'service_in_progress':
          case 'quality_check':
          case 'ready_for_delivery':
            newStatus = BookingStatus.inProgress;
            break;
          case 'completed':
            newStatus = BookingStatus.completed;
            break;
          default:
            newStatus = BookingStatus.confirmed;
        }

        final updated = _currentBooking.copyWith(
          status: newStatus,
          backendStatus: nextStatus,
        );
        MockData.updateBooking(updated);
        if (mounted) {
          setState(() {
            _currentBooking = updated;
            _isAdvancingStatus = false;
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo: Advanced stage to "${nextStatus.replaceAll('_', ' ').toUpperCase()}"'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdvancingStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not advance status: ${BookingService.getErrorMessage(e)}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _bookingService = widget.bookingService ?? BookingService.instance;
  }

  Future<void> _refreshStatus() async {
    final isRealId = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(_currentBooking.id);
    if (!isRealId) {
      final latest = MockData.bookings.firstWhere(
        (b) => b.id == _currentBooking.id,
        orElse: () => _currentBooking,
      );
      if (mounted) setState(() => _currentBooking = latest);
      return;
    }

    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final updated = await _bookingService.getBookingById(_currentBooking.id);
      if (!mounted) return;
      setState(() {
        _currentBooking = updated;
        _isRefreshing = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  int _getStageIndex(Booking b) {
    final status = b.backendStatus ?? '';
    switch (status) {
      case 'confirmed':
        return 0;
      case 'vehicle_received':
        return 1;
      case 'inspection':
        return 2;
      case 'service_in_progress':
        return 3;
      case 'quality_check':
        return 4;
      case 'ready_for_delivery':
        return 5;
      case 'completed':
        return 6;
    }
    if (b.status == BookingStatus.completed) return 6;
    if (b.status == BookingStatus.inProgress) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = _currentBooking.status == BookingStatus.cancelled;
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
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Service Tracker', style: AppTypography.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '${_currentBooking.bookingNumber} • ${_currentBooking.vehicleName}',
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRefreshing)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 22, color: AppColors.primary),
                        tooltip: 'Refresh Status',
                        onPressed: _refreshStatus,
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Body
          Expanded(
            child: isCancelled
                ? _buildCancelledView(context)
                : _buildActiveTimeline(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.errorBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.cancel_rounded, size: 54, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Booking Cancelled',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This booking was cancelled and does not have an active service timeline.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),
              Text(
                'Booking ID: ${_currentBooking.bookingNumber}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            final vehicle = MockData.vehicles.firstWhere(
              (v) => v.registrationNumber.replaceAll(' ', '').toUpperCase() ==
                  _currentBooking.vehicleNumber.replaceAll(' ', '').toUpperCase(),
              orElse: () => MockData.activeVehicle,
            );
            BookingFlowSheet.show(
              context: context,
              serviceTitle: _currentBooking.serviceTitle,
              serviceDescription: _currentBooking.serviceDescription,
              price: _currentBooking.servicePrice > 0 ? _currentBooking.servicePrice : _currentBooking.totalAmount,
              durationText: _currentBooking.duration ?? '3 Hours',
              warrantyPeriod: _currentBooking.warrantyPeriod,
              initialVehicle: vehicle,
            );
          },
          icon: const Icon(Icons.repeat_rounded, size: 18),
          label: const Text('Book Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTimeline(BuildContext context) {
    final currentStage = _getStageIndex(_currentBooking);
    final isCompleted = _currentBooking.status == BookingStatus.completed || currentStage == 6;

    // 7 STAGES DEFINED IN PHASE 2 STEP 4 & BACKEND STATUSES:
    // 0. Booking Confirmed (confirmed)
    // 1. Vehicle Pickup / Vehicle Received (vehicle_received)
    // 2. Inspection Started (inspection)
    // 3. Service In Progress (service_in_progress)
    // 4. Quality Check (quality_check)
    // 5. Ready for Delivery (ready_for_delivery)
    // 6. Completed (completed)

    final stages = [
      _StageData(
        title: 'Booking Confirmed',
        description: 'Technician assigned & service slot reserved',
        icon: Icons.check_circle_rounded,
        timestamp: '10:00 AM',
        isCompleted: true,
        isCurrent: currentStage == 0,
      ),
      _StageData(
        title: 'Vehicle Pickup / Vehicle Received',
        description: 'Vehicle Picked Up & received at workshop facility',
        icon: Icons.local_shipping_rounded,
        timestamp: '10:35 AM',
        isCompleted: currentStage >= 1 || isCompleted,
        isCurrent: currentStage == 1,
      ),
      _StageData(
        title: 'Inspection Started',
        description: 'Inspection / Service Started & 50-point diagnostics check',
        icon: Icons.fact_check_outlined,
        timestamp: '11:15 AM',
        isCompleted: currentStage >= 2 || isCompleted,
        isCurrent: currentStage == 2,
      ),
      _StageData(
        title: 'Service In Progress',
        description: 'Scheduled maintenance, fluid replacements & repairs underway',
        icon: Icons.build_rounded,
        timestamp: '12:00 PM',
        isCompleted: currentStage >= 3 || isCompleted,
        isCurrent: currentStage == 3,
      ),
      _StageData(
        title: 'Quality Check',
        description: 'Supervisor multi-point road test & electronic sensor scan',
        icon: Icons.verified_outlined,
        timestamp: '01:30 PM',
        isCompleted: currentStage >= 4 || isCompleted,
        isCurrent: currentStage == 4,
      ),
      _StageData(
        title: 'Ready for Delivery',
        description: 'Service Completed / Ready for Delivery & vehicle sanitization done',
        icon: Icons.check_box_rounded,
        timestamp: '02:15 PM',
        isCompleted: currentStage >= 5 || isCompleted,
        isCurrent: currentStage == 5,
      ),
      _StageData(
        title: 'Completed',
        description: 'Delivered safely back to customer with warranty certificate',
        icon: Icons.celebration_rounded,
        timestamp: '02:45 PM',
        isCompleted: isCompleted,
        isCurrent: isCompleted,
      ),
    ];

    return RefreshIndicator(
      onRefresh: _refreshStatus,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          // Service overview card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Theme.of(context).brightness == Brightness.dark
                  ? Border.all(color: AppColors.darkBorder)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.build_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentBooking.serviceTitle,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currentBooking.workshopName,
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Demo Hub',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
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
          ),
          const SizedBox(height: 20),

          // 7 Stages
          for (int i = 0; i < stages.length; i++)
            _buildTimelineStep(
              stage: stages[i],
              isLast: i == stages.length - 1,
            ),

          const SizedBox(height: 16),

          // Dedicated Technician Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentBooking.assignedMechanic,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const Text('Dedicated Service Technician', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling technician ${_currentBooking.assignedMechanic}...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Demo Stage Transition Simulator Button
          if (_currentBooking.status != BookingStatus.completed &&
              _currentBooking.backendStatus != 'completed')
            OutlinedButton.icon(
              onPressed: _isAdvancingStatus ? null : _advanceDemoStatus,
              icon: _isAdvancingStatus
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.fast_forward_rounded, size: 16),
              label: Text(
                _isAdvancingStatus ? 'Advancing Stage...' : 'Simulate Next Stage (Demo)',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size.fromHeight(40),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required _StageData stage,
    required bool isLast,
  }) {
    Color iconBg;
    Widget iconWidget;

    if (stage.isCompleted && !stage.isCurrent) {
      iconBg = AppColors.success;
      iconWidget = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (stage.isCurrent) {
      iconBg = AppColors.primary;
      iconWidget = const Icon(Icons.sync_rounded, size: 14, color: Colors.white);
    } else {
      iconBg = Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkInputSurface
          : AppColors.surfaceVariant;
      iconWidget = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.textMuted,
          shape: BoxShape.circle,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator & line
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stage.isCurrent ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(child: iconWidget),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: stage.isCompleted ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stage.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: stage.isCurrent ? FontWeight.w800 : FontWeight.w700,
                            color: stage.isCurrent
                                ? AppColors.primary
                                : stage.isCompleted
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (stage.isCompleted || stage.isCurrent)
                        Text(
                          stage.timestamp,
                          style: TextStyle(
                            fontSize: 11,
                            color: stage.isCurrent ? AppColors.primary : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stage.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: stage.isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  if (stage.isCurrent)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'IN PROGRESS NOW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.4,
                          ),
                        ),
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
}

class _StageData {
  final String title;
  final String description;
  final IconData icon;
  final String timestamp;
  final bool isCompleted;
  final bool isCurrent;

  _StageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.timestamp,
    required this.isCompleted,
    required this.isCurrent,
  });
}
