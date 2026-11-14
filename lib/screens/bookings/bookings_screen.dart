import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/booking.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/booking/booking_details_sheet.dart';
import '../../widgets/booking/live_tracker_sheet.dart';

class BookingsScreen extends StatefulWidget {
  final VoidCallback onExploreServices;
  final BookingService? bookingService;

  const BookingsScreen({
    super.key,
    required this.onExploreServices,
    this.bookingService,
  });

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final BookingService _bookingService;

  bool _isLoading = false;
  String? _errorMessage;
  List<Booking> _serverBookings = [];
  bool _hasLoadedFromServer = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bookingService = widget.bookingService ?? BookingService.instance;

    MockData.bookingsNotifier.addListener(_onBookingsChanged);
    AuthService.instance.isAuthenticatedNotifier.addListener(_onAuthChanged);
    _loadBookings();
  }

  int _loadSequence = 0;

  void _onBookingsChanged() {
    if (!mounted) return;
    if (AuthService.instance.isAuthenticatedNotifier.value) {
      _loadBookings();
    } else {
      setState(() {});
    }
  }

  void _onAuthChanged() {
    if (!mounted) return;
    _loadSequence++;
    if (AuthService.instance.isAuthenticatedNotifier.value) {
      _loadBookings();
    } else {
      MockData.resetToGuestBookings();
      setState(() {
        _serverBookings = [];
        _hasLoadedFromServer = false;
        _errorMessage = null;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    MockData.bookingsNotifier.removeListener(_onBookingsChanged);
    AuthService.instance.isAuthenticatedNotifier.removeListener(_onAuthChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final currentSeq = ++_loadSequence;
    final isAuth = AuthService.instance.isAuthenticatedNotifier.value || widget.bookingService != null;
    if (!isAuth) {
      // Guest mode: do not call server
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _hasLoadedFromServer = false;
        _serverBookings = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _bookingService.getBookings();
      if (!mounted) return;
      // Stale response protection: drop if session sequence changed or user logged out
      if (currentSeq != _loadSequence || (!AuthService.instance.isAuthenticatedNotifier.value && widget.bookingService == null)) {
        return;
      }
      setState(() {
        _isLoading = false;
        _serverBookings = items;
        _hasLoadedFromServer = true;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (currentSeq != _loadSequence) return;
      setState(() {
        _isLoading = false;
        _errorMessage = BookingService.getErrorMessage(e);
        if (widget.bookingService != null) {
          // Explicit mock service injected in test
          _serverBookings = [];
        }
      });
    }
  }

  List<Booking> get _activeBookings {
    final source = _hasLoadedFromServer
        ? _serverBookings
        : MockData.bookings;

    return source
        .where((b) =>
            b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.inProgress)
        .toList();
  }

  List<Booking> get _pastBookings {
    final source = _hasLoadedFromServer
        ? _serverBookings
        : MockData.bookings;

    return source
        .where((b) =>
            b.status == BookingStatus.completed ||
            b.status == BookingStatus.cancelled)
        .toList();
  }

  void _showTrackStatusSheet(Booking booking) {
    LiveTrackerSheet.show(context: context, booking: booking);
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = !AuthService.instance.isAuthenticated && widget.bookingService == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: isDark ? AppColors.darkSurface : null,
        foregroundColor: isDark ? AppColors.darkTextPrimary : null,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.titleSmall,
          tabs: [
            Tab(text: 'Active (${_activeBookings.length})'),
            Tab(text: 'History (${_pastBookings.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Non-blocking Guest Mode informational banner
          if (isGuest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.infoBg,
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Browsing as Guest. Sign in to view and track your verified appointments.',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Non-blocking Error / Offline notice if cached bookings exist
          if (_errorMessage != null && _serverBookings.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.warningBg,
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing local bookings. ${_errorMessage!}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  InkWell(
                    onTap: _loadBookings,
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _buildBodyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    final isAuth = AuthService.instance.isAuthenticated || widget.bookingService != null;

    if (isAuth && _isLoading && _serverBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading bookings...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (isAuth && _errorMessage != null && _serverBookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.errorBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to Load Bookings',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildBookingsList(_activeBookings, isActive: true),
        _buildBookingsList(_pastBookings, isActive: false),
      ],
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, {required bool isActive}) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBookings,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkInputSurface
                      : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 48,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                isActive ? 'No Active Bookings' : 'No Past Bookings',
                style: AppTypography.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book scheduled servicing, AC repair, or a car spa to see your appointments here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: widget.onExploreServices,
                child: const Text('Explore Services'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, isActive: isActive);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, {required bool isActive}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusBg = AppColors.infoBg;
    Color statusColor = AppColors.info;

    if (booking.status == BookingStatus.completed) {
      statusBg = AppColors.successBg;
      statusColor = AppColors.success;
    } else if (booking.status == BookingStatus.inProgress) {
      statusBg = AppColors.warningBg;
      statusColor = AppColors.warning;
    } else if (booking.status == BookingStatus.cancelled) {
      statusBg = AppColors.errorBg;
      statusColor = AppColors.error;
    }

    if (isDark) {
      statusBg = statusColor.withValues(alpha: 0.16);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            BookingDetailsSheet.show(
              context: context,
              booking: booking,
              bookingService: _bookingService,
              onTrackLive: () => _showTrackStatusSheet(booking),
              onBookingUpdated: () {
                _loadBookings();
                if (mounted) setState(() {});
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Booking Number + Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking.bookingNumber,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Service Title
                Text(
                  booking.serviceTitle,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),

                // Vehicle Info
                Row(
                  children: [
                    Icon(Icons.directions_car_rounded,
                        size: 16,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${booking.vehicleName} (${booking.vehicleNumber})',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Workshop / Mode Info
                Row(
                  children: [
                    Icon(
                      booking.pickupType.contains('Doorstep')
                          ? Icons.home_repair_service_rounded
                          : Icons.store_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.pickupType.contains('Doorstep')
                            ? (booking.address ?? 'Doorstep Service')
                            : '${booking.workshopName} [Demo Hub]',
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Divider(color: isDark ? AppColors.darkDivider : null),
                const SizedBox(height: 10),

                // Bottom Row: Amount + Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: AppTypography.bodySmall,
                        ),
                        Text(
                          '${AppConstants.currencySymbol}${booking.totalAmount.toInt()}',
                          style: AppTypography.priceLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (isActive)
                      ElevatedButton.icon(
                        onPressed: () => _showTrackStatusSheet(booking),
                        icon: const Icon(Icons.navigation_outlined, size: 16),
                        label: const Text('Track Live'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () {
                          BookingDetailsSheet.show(
                            context: context,
                            booking: booking,
                            bookingService: _bookingService,
                            onTrackLive: () => _showTrackStatusSheet(booking),
                            onBookingUpdated: () {
                              _loadBookings();
                              if (mounted) setState(() {});
                            },
                          );
                        },
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: const Text('View Summary'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
