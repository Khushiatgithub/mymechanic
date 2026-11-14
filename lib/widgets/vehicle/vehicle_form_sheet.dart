import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';

class VehicleFormSheet extends StatefulWidget {
  final Vehicle? vehicleToEdit;
  final ValueChanged<Vehicle>? onSave;
  final Future<void> Function(Vehicle vehicle)? onSaveAsync;

  const VehicleFormSheet({
    super.key,
    this.vehicleToEdit,
    this.onSave,
    this.onSaveAsync,
  });

  static Future<void> show({
    required BuildContext context,
    Vehicle? vehicleToEdit,
    ValueChanged<Vehicle>? onSave,
    Future<void> Function(Vehicle vehicle)? onSaveAsync,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VehicleFormSheet(
        vehicleToEdit: vehicleToEdit,
        onSave: onSave,
        onSaveAsync: onSaveAsync,
      ),
    );
  }

  @override
  State<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedBrand;
  late TextEditingController _modelController;
  late TextEditingController _variantController;
  late TextEditingController _regNumberController;
  late String _selectedFuel;
  late int _selectedYear;
  late bool _isPrimary;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<String> _popularBrands = [
    'Maruti Suzuki',
    'Hyundai',
    'Tata',
    'Mahindra',
    'Honda',
    'Toyota',
    'Kia',
    'Volkswagen',
    'Skoda',
    'MG',
    'Renault',
    'Ford',
    'BMW',
    'Mercedes-Benz',
    'Audi',
    'Other',
  ];

  static const List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'CNG',
    'Hybrid',
  ];

  late final List<int> _availableYears;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _availableYears = List.generate(25, (index) => currentYear - index);

    final v = widget.vehicleToEdit;
    if (v != null) {
      _selectedBrand = _popularBrands.contains(v.brand) ? v.brand : 'Other';
      _modelController = TextEditingController(text: v.model);
      _variantController = TextEditingController(text: v.variant);
      _regNumberController = TextEditingController(text: v.registrationNumber);
      _selectedFuel = _fuelTypes.contains(v.fuelType) ? v.fuelType : _fuelTypes.first;
      _selectedYear = _availableYears.contains(v.year) ? v.year : currentYear;
      _isPrimary = v.isPrimary;
    } else {
      _selectedBrand = _popularBrands.first;
      _modelController = TextEditingController();
      _variantController = TextEditingController();
      _regNumberController = TextEditingController();
      _selectedFuel = _fuelTypes.first;
      _selectedYear = currentYear;
      _isPrimary = false;
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _variantController.dispose();
    _regNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return; // Prevent duplicate submissions
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final id = widget.vehicleToEdit?.id ??
        'v_${DateTime.now().millisecondsSinceEpoch}';

    final vehicle = Vehicle(
      id: id,
      brand: _selectedBrand,
      model: _modelController.text.trim(),
      variant: _variantController.text.trim().isEmpty
          ? 'Standard'
          : _variantController.text.trim(),
      fuelType: _selectedFuel,
      registrationNumber: _regNumberController.text.trim().toUpperCase(),
      year: _selectedYear,
      serviceDueStatus: widget.vehicleToEdit?.serviceDueStatus ?? 'Up to date',
      isPrimary: _isPrimary,
    );

    if (widget.onSaveAsync != null) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      try {
        await widget.onSaveAsync!(vehicle);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = VehicleService.getErrorMessage(e);
          });
        }
      }
    } else {
      widget.onSave?.call(vehicle);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicleToEdit != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit Vehicle' : 'Add New Vehicle',
                    style: AppTypography.titleLarge,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isEditing
                  ? 'Update your car details and servicing specs'
                  : 'Enter car details to customize services & maintenance',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),

          // Optional Error Banner
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Scrollable Form
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand / Make Dropdown
                    _buildLabel('Vehicle Make / Brand *'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBrand,
                      decoration: _inputDecoration(
                        prefixIcon: Icons.directions_car_rounded,
                        hintText: 'Select Car Make',
                      ),
                      items: _popularBrands.map((brand) {
                        return DropdownMenuItem<String>(
                          value: brand,
                          child: Text(brand, style: AppTypography.bodyMedium),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedBrand = val);
                        }
                      },
                      validator: (val) =>
                          (val == null || val.isEmpty) ? 'Please select a car make' : null,
                    ),
                    const SizedBox(height: 16),

                    // Model Field
                    _buildLabel('Car Model *'),
                    TextFormField(
                      controller: _modelController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        prefixIcon: Icons.commute_rounded,
                        hintText: 'e.g. Creta, Swift, Nexon, City',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter the car model';
                        }
                        if (val.trim().length < 2) {
                          return 'Model name is too short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Variant Field
                    _buildLabel('Variant / Trim (Optional)'),
                    TextFormField(
                      controller: _variantController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        prefixIcon: Icons.tune_rounded,
                        hintText: 'e.g. 1.5 SX(O), ZXi+, Fearless+',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Registration Number Field
                    _buildLabel('Registration Number *'),
                    TextFormField(
                      controller: _regNumberController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                      ],
                      decoration: _inputDecoration(
                        prefixIcon: Icons.pin_rounded,
                        hintText: 'e.g. KA 01 MJ 4521',
                        helperText: 'Indian standard plate format (State + District + Number)',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Registration number cannot be blank';
                        }
                        final clean = val.replaceAll(' ', '');
                        if (clean.length < 5) {
                          return 'Please enter a valid registration number (min 5 chars)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Row: Fuel Type & Manufacturing Year
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fuel Type
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Fuel Type *'),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedFuel,
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.local_gas_station_rounded,
                                ),
                                items: _fuelTypes.map((fuel) {
                                  return DropdownMenuItem<String>(
                                    value: fuel,
                                    child: Text(fuel, style: AppTypography.bodySmall),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedFuel = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Year
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Model Year *'),
                              DropdownButtonFormField<int>(
                                initialValue: _selectedYear,
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.calendar_today_rounded,
                                ),
                                items: _availableYears.map((year) {
                                  return DropdownMenuItem<int>(
                                    value: year,
                                    child: Text('$year', style: AppTypography.bodySmall),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedYear = val);
                                  }
                                },
                                validator: (val) {
                                  if (val == null) return 'Select year';
                                  if (val < 1990 || val > DateTime.now().year + 1) {
                                    return 'Year must be reasonable';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Set as Primary Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: _isPrimary ? AppColors.warning : AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set as Active Vehicle',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Default car for services & pricing quotes',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPrimary,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() => _isPrimary = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Docked Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Add Vehicle',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required IconData prefixIcon,
    String? hintText,
    String? helperText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? AppColors.darkSearchPlaceholder : null,
      ),
      helperText: helperText,
      prefixIcon: Icon(
        prefixIcon,
        size: 20,
        color: isDark ? AppColors.darkSearchPlaceholder : AppColors.textSecondary,
      ),
      filled: true,
      fillColor: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.error),
      ),
    );
  }
}
