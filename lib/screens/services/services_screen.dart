import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/booking.dart';
import '../../models/service_category.dart';
import '../../models/service_item.dart';
import '../../models/service_package.dart';
import '../../services/service_discovery_service.dart';
import '../../widgets/booking/booking_details_sheet.dart';
import '../../widgets/booking/booking_flow_sheet.dart';
import '../../widgets/common/custom_search_bar.dart';
import '../../widgets/common/rating_badge.dart';
import '../../widgets/service/service_detail_sheet.dart';
import '../../widgets/service/service_package_card.dart';

enum ServiceSortOption {
  recommended('Recommended'),
  priceLowToHigh('Price: Low to High'),
  priceHighToLow('Price: High to Low'),
  rating('Rating: High to Low'),
  duration('Duration: Fastest First');

  final String label;
  const ServiceSortOption(this.label);
}

class ServicesScreen extends StatefulWidget {
  final VoidCallback onNavigateToBookings;
  final String? initialCategoryId;
  final String? initialSearchQuery;
  final bool autoFocusSearch;
  final ServiceDiscoveryService? serviceDiscoveryService;

  const ServicesScreen({
    super.key,
    required this.onNavigateToBookings,
    this.initialCategoryId,
    this.initialSearchQuery,
    this.autoFocusSearch = false,
    this.serviceDiscoveryService,
  });

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late String _selectedCategoryId;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  String _searchQuery = '';
  ServiceSortOption _selectedSort = ServiceSortOption.recommended;
  int _selectedTabIndex = 0; // 0: Services, 1: Packages

  late final ServiceDiscoveryService _discoveryService;
  bool _isLoading = false;
  String? _errorMessage;
  List<ServiceCategory> _categories = [];
  List<ServiceItem> _services = [];

  @override
  void initState() {
    super.initState();
    _discoveryService =
        widget.serviceDiscoveryService ?? ServiceDiscoveryService.instance;
    _selectedCategoryId = widget.initialCategoryId ?? 'all';
    _searchQuery = widget.initialSearchQuery ?? '';
    _searchController = TextEditingController(text: _searchQuery);
    _searchFocusNode = FocusNode();

    // Default to mock data only if no explicit custom discovery service was injected
    _categories = widget.serviceDiscoveryService != null
        ? []
        : List<ServiceCategory>.from(MockData.categories);
    _services = widget.serviceDiscoveryService != null
        ? []
        : List<ServiceItem>.from(MockData.allServices);

    _loadDiscoveryData();

    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _loadDiscoveryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    List<ServiceCategory>? loadedCats;
    List<ServiceItem>? loadedSrvs;
    Object? errorToReport;

    try {
      loadedCats = await _discoveryService.getCategories(activeOnly: true);
    } catch (e) {
      errorToReport = e;
    }

    try {
      loadedSrvs = await _discoveryService.getServices(activeOnly: true);
    } catch (e) {
      errorToReport ??= e;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (loadedCats != null && loadedCats.isNotEmpty) {
        _categories = loadedCats;
      }
      if (loadedSrvs != null) {
        _services = loadedSrvs;
      }

      if (errorToReport != null) {
        _errorMessage = ServiceDiscoveryService.getErrorMessage(errorToReport);
        if (widget.serviceDiscoveryService != null && loadedSrvs == null) {
          _services = [];
        } else {
          if (_services.isEmpty) {
            _services = List<ServiceItem>.from(MockData.allServices);
          }
          if (_categories.isEmpty) {
            _categories = List<ServiceCategory>.from(MockData.categories);
          }
        }
      } else {
        _errorMessage = null;
      }
    });
  }

  @override
  void didUpdateWidget(ServicesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != null &&
        widget.initialCategoryId != oldWidget.initialCategoryId) {
      setState(() {
        _selectedCategoryId = widget.initialCategoryId!;
      });
    }
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery != oldWidget.initialSearchQuery) {
      setState(() {
        _searchQuery = widget.initialSearchQuery!;
        _searchController.text = _searchQuery;
      });
    }
    if (widget.autoFocusSearch && !oldWidget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  int _parseDurationMinutes(String durationText) {
    final text = durationText.toLowerCase();
    int minutes = 0;
    final hourMatch = RegExp(r'(\d+(\.\d+)?)\s*h').firstMatch(text);
    if (hourMatch != null) {
      minutes += (double.parse(hourMatch.group(1)!) * 60).round();
    }
    final minMatch = RegExp(r'(\d+)\s*m').firstMatch(text);
    if (minMatch != null) {
      minutes += int.parse(minMatch.group(1)!);
    }
    return minutes > 0 ? minutes : 180;
  }

  List<ServiceItem> get _filteredServices {
    var items = List<ServiceItem>.from(_services);

    // 1. Category Filter
    if (_selectedCategoryId != 'all') {
      items = items.where((s) => s.categoryId == _selectedCategoryId).toList();
    }

    // 2. Local Search Filter (by title, description, category, or features)
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      items = items.where((s) {
        final matchesTitle = s.title.toLowerCase().contains(query);
        final matchesDesc = s.description.toLowerCase().contains(query);
        final matchesFeature =
            s.allIncludedItems.any((f) => f.toLowerCase().contains(query));
        final category = _categories.firstWhere(
          (c) => c.id == s.categoryId,
          orElse: () => _categories.isNotEmpty
              ? _categories.first
              : const ServiceCategory(
                  id: '',
                  name: 'General',
                  description: '',
                  icon: Icons.miscellaneous_services_rounded,
                  tintColor: AppColors.categoryRed,
                  backgroundColor: AppColors.categoryRedBg,
                ),
        );
        final matchesCategory = category.name.toLowerCase().contains(query) ||
            (s.categoryName != null &&
                s.categoryName!.toLowerCase().contains(query));
        return matchesTitle || matchesDesc || matchesFeature || matchesCategory;
      }).toList();
    }

    // 3. Sorting
    switch (_selectedSort) {
      case ServiceSortOption.recommended:
        items.sort((a, b) {
          if (a.isPopular && !b.isPopular) return -1;
          if (!a.isPopular && b.isPopular) return 1;
          return b.rating.compareTo(a.rating);
        });
        break;
      case ServiceSortOption.priceLowToHigh:
        items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ServiceSortOption.priceHighToLow:
        items.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ServiceSortOption.rating:
        items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ServiceSortOption.duration:
        items.sort((a, b) => _parseDurationMinutes(a.durationText)
            .compareTo(_parseDurationMinutes(b.durationText)));
        break;
    }

    return items;
  }

  List<ServicePackage> get _filteredPackages {
    var pkgs = List<ServicePackage>.from(MockData.servicePackages);
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      pkgs = pkgs.where((p) {
        final matchesTitle = p.title.toLowerCase().contains(query);
        final matchesDesc = p.description.toLowerCase().contains(query);
        final matchesChecklist =
            p.checklist.any((c) => c.toLowerCase().contains(query));
        return matchesTitle || matchesDesc || matchesChecklist;
      }).toList();
    }
    return pkgs;
  }

  void _openBookingFlow(ServiceItem service) {
    BookingFlowSheet.show(
      context: context,
      serviceId: service.id,
      serviceTitle: service.title,
      serviceDescription: service.description,
      price: service.price,
      originalPrice: service.originalPrice,
      durationText: service.durationText,
      warrantyPeriod: service.warrantyPeriod,
      initialVehicle: MockData.activeVehicle,
      onNavigateToBookings: widget.onNavigateToBookings,
      onBookingConfirmed: (Booking newBooking) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Service "${newBooking.serviceTitle}" booked successfully!'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    ).then((confirmedBooking) {
      if (confirmedBooking != null && mounted) {
        BookingDetailsSheet.show(
          context: context,
          booking: confirmedBooking,
        );
      }
    });
  }

  void _openBookingForPackage(ServicePackage package) {
    BookingFlowSheet.show(
      context: context,
      serviceTitle: package.title,
      serviceDescription: package.checklist.take(3).join(' • '),
      price: package.price,
      originalPrice: package.originalPrice,
      durationText: package.timeTakenText,
      warrantyPeriod: package.warranty,
      initialVehicle: MockData.activeVehicle,
      onNavigateToBookings: widget.onNavigateToBookings,
      onBookingConfirmed: (Booking booking) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Package "${booking.serviceTitle}" booked!'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    ).then((booking) {
      if (booking != null && mounted) {
        BookingDetailsSheet.show(
          context: context,
          booking: booking,
        );
      }
    });
  }

  void _showSortFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter & Sort Services',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.w800)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedSort = ServiceSortOption.recommended;
                          _selectedCategoryId = 'all';
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset All',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),

                // Sort Options
                Text('SORT BY',
                    style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ServiceSortOption.values.map((sort) {
                    final isSelected = _selectedSort == sort;
                    return ChoiceChip(
                      label: Text(sort.label),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setModalState(() {});
                          setState(() {
                            _selectedSort = sort;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Category Filter
                Text('FILTER BY CATEGORY',
                    style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All Categories'),
                      selected: _selectedCategoryId == 'all',
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: _selectedCategoryId == 'all'
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _selectedCategoryId == 'all'
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      onSelected: (val) {
                        setModalState(() {});
                        setState(() => _selectedCategoryId = 'all');
                      },
                    ),
                    ..._categories.map((cat) {
                      final isSelected = _selectedCategoryId == cat.id;
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceVariant,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        onSelected: (val) {
                          setModalState(() {});
                          setState(() => _selectedCategoryId = cat.id);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Filters',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredServices;
    final filteredPkgs = _filteredPackages;
    final isFilteringActive = _searchQuery.isNotEmpty ||
        _selectedCategoryId != 'all' ||
        _selectedSort != ServiceSortOption.recommended;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Car Services & Repairs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: CustomSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hintText: 'Search services, parts, e.g. "AC", "Periodic"',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Mode Tabs (All Services vs Service Packages)
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedTabIndex == 0
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Individual Services (${filtered.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _selectedTabIndex == 0
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedTabIndex == 1
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Service Packages (${filteredPkgs.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _selectedTabIndex == 1
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Category Filter Chips (when on Services tab)
          if (_selectedTabIndex == 0) ...[
            Container(
              height: 48,
              color: AppColors.surface,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  _buildFilterChip('all', 'All Services'),
                  ..._categories.map(
                    (c) => _buildFilterChip(c.id, c.name),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1),

          // Offline / Cached Warning Ribbon (if network failed but cached services exist)
          if (_errorMessage != null && _services.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.warningBg,
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing local services. ${_errorMessage!}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  InkWell(
                    onTap: _loadDiscoveryData,
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

          // Filter, Sort Bar & Results Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _selectedTabIndex == 0
                          ? '${filtered.length} service${filtered.length == 1 ? '' : 's'} found'
                          : '${filteredPkgs.length} package${filteredPkgs.length == 1 ? '' : 's'} available',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_selectedSort != ServiceSortOption.recommended &&
                        _selectedTabIndex == 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• ${_selectedSort.label}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: _showSortFilterModal,
                      child: Row(
                        children: [
                          const Icon(Icons.sort_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Sort & Filter',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isFilteringActive) ...[
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = 'all';
                            _searchQuery = '';
                            _searchController.clear();
                            _selectedSort = ServiceSortOption.recommended;
                          });
                        },
                        child: Text(
                          'Clear Filters',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildServicesList(filtered)
                : _buildPackagesList(filteredPkgs),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(List<ServiceItem> filtered) {
    if (_isLoading && _services.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading services...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _services.isEmpty) {
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
                'Unable to Load Services',
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadDiscoveryData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No services found',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No results for "$_searchQuery" matching your active filters.'
                    : 'No services in this category currently.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategoryId = 'all';
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedSort = ServiceSortOption.recommended;
                  });
                },
                child: const Text('Show All Services'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDiscoveryData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final service = filtered[index];
          return _buildServiceCard(service);
        },
      ),
    );
  }

  Widget _buildPackagesList(List<ServicePackage> packages) {
    if (packages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('No packages found', style: AppTypography.titleMedium),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                child: const Text('Show All Packages'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        return ServicePackageCard(
          package: pkg,
          onBook: () => _openBookingForPackage(pkg),
        );
      },
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceVariant,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategoryId = id;
          });
        },
      ),
    );
  }

  Widget _buildServiceCard(ServiceItem service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = _categories.firstWhere(
      (c) => c.id == service.categoryId,
      orElse: () => _categories.isNotEmpty
          ? _categories.first
          : ServiceCategory(
              id: service.categoryId,
              name: service.categoryName ?? 'Service',
              description: '',
              icon: Icons.miscellaneous_services_rounded,
              tintColor: AppColors.categoryRed,
              backgroundColor: AppColors.categoryRedBg,
            ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ServiceDetailSheet.show(
              context: context,
              service: service,
              onBookNow: () => _openBookingFlow(service),
              onBookPackage: (pkg) => _openBookingForPackage(pkg),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category tag + Popular badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: category.tintColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: category.tintColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (service.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2E2210) : AppColors.warningBg,
                          borderRadius: BorderRadius.circular(4),
                          border: isDark
                              ? Border.all(color: const Color(0xFFB45309).withValues(alpha: 0.5), width: 0.8)
                              : null,
                        ),
                        child: Text(
                          'POPULAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFFBBF24) : AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title and Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        service.title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RatingBadge(
                        rating: service.rating,
                        reviewsCount: service.reviewsCount),
                  ],
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),

                // Duration & Warranty tags
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      service.durationText,
                      style: AppTypography.labelSmall
                          .copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.shield_outlined,
                        size: 13, color: AppColors.success),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        service.warrantyPeriod,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Divider(
                  color: isDark ? AppColors.darkBorder : null,
                ),
                const SizedBox(height: 8),

                // Price & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                '${AppConstants.currencySymbol}${service.price.toInt()}',
                                style: AppTypography.priceLarge.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '${AppConstants.currencySymbol}${service.originalPrice.toInt()}',
                                style: AppTypography.priceStrike,
                              ),
                            ],
                          ),
                          if (service.discountPercentage > 0)
                            Text(
                              'Save ${service.discountPercentage}%',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            ServiceDetailSheet.show(
                              context: context,
                              service: service,
                              onBookNow: () => _openBookingFlow(service),
                              onBookPackage: (pkg) =>
                                  _openBookingForPackage(pkg),
                            );
                          },
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () => _openBookingFlow(service),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
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
