import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/booking.dart';
import '../../widgets/booking/booking_flow_sheet.dart';
import '../../widgets/history/service_summary_sheet.dart';

class ServiceHistoryScreen extends StatefulWidget {
  final String? initialVehicleFilter;
  final VoidCallback? onExploreServices;

  const ServiceHistoryScreen({
    super.key,
    this.initialVehicleFilter,
    this.onExploreServices,
  });

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedVehicleNumber; // null means 'All Vehicles'
  String _selectedCategory = 'All';
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicleFilter != null) {
      _selectedVehicleNumber = widget.initialVehicleFilter;
    }
    MockData.bookingsNotifier.addListener(_onBookingsChanged);
  }

  void _onBookingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    MockData.bookingsNotifier.removeListener(_onBookingsChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<Booking> get _filteredHistory {
    // Past bookings include completed and cancelled
    var list = MockData.bookings.where((b) {
      return b.status == BookingStatus.completed || b.status == BookingStatus.cancelled;
    }).toList();

    // 1. Vehicle Filter
    if (_selectedVehicleNumber != null && _selectedVehicleNumber != 'All') {
      final cleanTarget = _selectedVehicleNumber!.replaceAll(' ', '').toUpperCase();
      list = list.where((b) {
        final cleanB = b.vehicleNumber.replaceAll(' ', '').toUpperCase();
        return cleanB == cleanTarget;
      }).toList();
    }

    // 2. Category Filter
    if (_selectedCategory != 'All') {
      list = list.where((b) {
        if (_selectedCategory == 'Periodic Services') {
          return b.serviceTitle.toLowerCase().contains('periodic');
        } else if (_selectedCategory == 'Car Spa & Detailing') {
          return b.serviceTitle.toLowerCase().contains('spa') ||
              b.serviceTitle.toLowerCase().contains('interior');
        } else if (_selectedCategory == 'Batteries') {
          return b.serviceTitle.toLowerCase().contains('battery');
        } else if (_selectedCategory == 'Inspection') {
          return b.serviceTitle.toLowerCase().contains('inspection');
        }
        return true;
      }).toList();
    }

    // 3. Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((b) {
        return b.serviceTitle.toLowerCase().contains(q) ||
            b.vehicleName.toLowerCase().contains(q) ||
            b.vehicleNumber.toLowerCase().contains(q) ||
            b.bookingNumber.toLowerCase().contains(q);
      }).toList();
    }

    // 4. Date Sorting
    list.sort((a, b) {
      if (_sortNewestFirst) {
        return b.dateTime.compareTo(a.dateTime);
      } else {
        return a.dateTime.compareTo(b.dateTime);
      }
    });

    return list;
  }

  void _openBookingSummary(Booking booking) {
    ServiceSummarySheet.show(
      context: context,
      booking: booking,
      onBookingUpdated: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyList = _filteredHistory;
    final vehicles = MockData.vehicles;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service History'),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            tooltip: _sortNewestFirst ? 'Sort: Newest First' : 'Sort: Oldest First',
            icon: Icon(
              _sortNewestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                _sortNewestFirst = !_sortNewestFirst;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_sortNewestFirst ? 'Sorted by Newest First' : 'Sorted by Oldest First'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by service, car model or reg plate...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Vehicle Filter Chips
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('All Vehicles'),
                        selected: _selectedVehicleNumber == null || _selectedVehicleNumber == 'All',
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceVariant,
                        labelStyle: TextStyle(
                          color: (_selectedVehicleNumber == null || _selectedVehicleNumber == 'All')
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedVehicleNumber = null);
                        },
                      ),
                      ...vehicles.map((v) {
                        final isSel = _selectedVehicleNumber == v.registrationNumber;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text('${v.brand} ${v.model}'),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceVariant,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              setState(() {
                                _selectedVehicleNumber = val ? v.registrationNumber : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Category Filter Chips
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      'All',
                      'Periodic Services',
                      'Car Spa & Detailing',
                      'Batteries',
                      'Inspection',
                    ].map((cat) {
                      final isSel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceVariant,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedCategory = val ? cat : 'All';
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content List
          Expanded(
            child: historyList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    itemCount: historyList.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryCard(historyList[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Booking b) {
    final isCancelled = b.status == BookingStatus.cancelled;
    final dateFormatted = '${b.dateTime.day} ${_getMonthName(b.dateTime.month)} ${b.dateTime.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openBookingSummary(b),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Booking ID & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    b.bookingNumber,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCancelled ? AppColors.errorBg : AppColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      b.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isCancelled ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Service Title
              Text(
                b.serviceTitle,
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),

              // Vehicle Plate & Name
              Row(
                children: [
                  const Icon(Icons.directions_car_rounded, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${b.vehicleName} (${b.vehicleNumber})',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Workshop
              Row(
                children: [
                  const Icon(Icons.store_rounded, size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b.workshopName,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Bottom Row: Date & Amount & CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(dateFormatted, style: AppTypography.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppConstants.currencySymbol}${b.totalAmount.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Text(
                        'View Details',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: const Icon(Icons.history_rounded, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No service history yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedVehicleNumber != null
                  ? 'No completed services found matching the active filters.'
                  : 'You have not completed any car servicing with MyMechanic yet.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if (widget.onExploreServices != null) {
                  widget.onExploreServices!();
                } else {
                  BookingFlowSheet.show(
                    context: context,
                    serviceTitle: 'Standard Periodic Service',
                    price: 3699,
                    initialVehicle: MockData.activeVehicle,
                  );
                }
              },
              icon: const Icon(Icons.build_circle_rounded, size: 18),
              label: const Text('Book Your First Service', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
