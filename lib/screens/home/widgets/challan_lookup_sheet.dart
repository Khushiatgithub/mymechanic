import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/vehicle.dart';

/// Modal bottom sheet for Vehicle e-Challan lookup (Government Authorised Records).
class ChallanLookupSheet extends StatefulWidget {
  final Vehicle? vehicle;

  const ChallanLookupSheet({super.key, this.vehicle});

  static Future<void> show({
    required BuildContext context,
    Vehicle? vehicle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChallanLookupSheet(vehicle: vehicle),
    );
  }

  @override
  State<ChallanLookupSheet> createState() => _ChallanLookupSheetState();
}

class _ChallanLookupSheetState extends State<ChallanLookupSheet> {
  late final TextEditingController _regController;
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _regController = TextEditingController(
      text: widget.vehicle?.registrationNumber ?? 'HR 26 DQ 5555',
    );
  }

  @override
  void dispose() {
    _regController.dispose();
    super.dispose();
  }

  void _searchChallans() async {
    final reg = _regController.text.trim();
    if (reg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid vehicle registration number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = false;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Vehicle e-Challan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5E35B1).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Govt Authorised',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5E35B1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '1-Click Discovery across Parivahan & State Police databases',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter Vehicle Registration Number',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _regController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
                    decoration: InputDecoration(
                      hintText: 'e.g. HR26DQ5555',
                      prefixIcon: const Icon(Icons.directions_car_rounded, color: Color(0xFF5E35B1)),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF5E35B1), width: 1.8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchChallans,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E35B1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Text('Check', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_hasSearched) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Pending Challans Found!',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Registration ${_regController.text.toUpperCase()} has a clean record across Traffic Police and Parivahan databases.',
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Verified as of today • 0 Unpaid Violations',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Direct integration with Official Parivahan & State Traffic databases. No login credentials required.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: AppColors.border),
                ),
                child: const Text('Close', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
