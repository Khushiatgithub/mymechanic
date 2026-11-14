import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';

class AddAddressSheet extends StatefulWidget {
  final ValueChanged<Map<String, String>> onAddressAdded;

  const AddAddressSheet({
    super.key,
    required this.onAddressAdded,
  });

  static Future<void> show({
    required BuildContext context,
    required ValueChanged<Map<String, String>> onAddressAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAddressSheet(onAddressAdded: onAddressAdded),
    );
  }

  @override
  State<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();

  String _selectedTag = 'Home';
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Bengaluru');
  final _pincodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final newAddr = {
      'tag': _selectedTag,
      'address': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'pincode': _pincodeCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'isDefault': 'false',
    };

    MockData.addAddress(newAddr);
    widget.onAddressAdded(newAddr);
    Navigator.pop(context);
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
              width: 40,
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
                    child: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Add New Address', style: AppTypography.titleLarge),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Form fields
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Tag (Home, Office, Other)
                    Text('Address Type', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                      Row(
                        children: ['Home', 'Office', 'Other'].map((tag) {
                          final isSelected = _selectedTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(tag),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimary),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              side: isDark
                                  ? BorderSide(color: isSelected ? AppColors.primary : AppColors.darkBorder)
                                  : BorderSide.none,
                              onSelected: (val) {
                                if (val) setState(() => _selectedTag = tag);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),

                    // House / Street Address
                    Text('Street / Flat / Area Address *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Flat 301, Brigade Metropolis, Whitefield',
                          prefixIcon: const Icon(Icons.home_outlined, size: 20),
                          filled: true,
                          fillColor: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter the street/flat address';
                        }
                        if (val.trim().length < 6) {
                          return 'Address is too short (min 6 chars)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // City & PIN Code Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('City *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                                TextFormField(
                                  controller: _cityCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Bengaluru',
                                    prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
                                    filled: true,
                                    fillColor: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter city';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PIN Code *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                                TextFormField(
                                  controller: _pincodeCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 560103',
                                    prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
                                    filled: true,
                                    fillColor: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Enter PIN code';
                                  }
                                  if (val.trim().length != 6) {
                                    return 'Enter 6-digit PIN';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Contact Phone Number
                    Text('Contact Phone Number *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'e.g. +91 98765 43210',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          filled: true,
                          fillColor: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter contact number';
                        }
                        if (val.trim().length < 10) {
                          return 'Enter valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Docked Save Button
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Address', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
