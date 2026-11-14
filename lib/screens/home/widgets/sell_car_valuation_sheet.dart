import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/vehicle.dart';

/// Interactive modal sheet to value and sell a car with Best Price Assurance.
class SellCarValuationSheet extends StatefulWidget {
  final Vehicle? initialVehicle;

  const SellCarValuationSheet({
    super.key,
    this.initialVehicle,
  });

  static Future<void> show({
    required BuildContext context,
    Vehicle? vehicle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SellCarValuationSheet(initialVehicle: vehicle),
    );
  }

  @override
  State<SellCarValuationSheet> createState() => _SellCarValuationSheetState();
}

class _SellCarValuationSheetState extends State<SellCarValuationSheet> {
  final _regController = TextEditingController();
  final _kmController = TextEditingController();
  String _selectedFuel = 'Petrol';
  String _selectedYear = '2020';
  int? _estimatedValuationMin;
  int? _estimatedValuationMax;
  bool _isCalculating = false;

  final List<String> _fuelOptions = ['Petrol', 'Diesel', 'CNG', 'Electric'];
  final List<String> _yearOptions = [
    '2024', '2023', '2022', '2021', '2020', '2019', '2018', '2017', '2016'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicle != null) {
      _regController.text = widget.initialVehicle!.registrationNumber;
      final rawMileage = widget.initialVehicle!.nextServiceMileage?.replaceAll(RegExp(r'[^0-9]'), '') ?? '42000';
      _kmController.text = rawMileage.isNotEmpty ? rawMileage : '42000';
      _selectedFuel = widget.initialVehicle!.fuelType;
      _selectedYear = widget.initialVehicle!.year.toString();
    } else {
      _regController.text = 'HR 26 DQ 5521';
      _kmController.text = '38000';
    }
  }

  @override
  void dispose() {
    _regController.dispose;
    _kmController.dispose;
    super.dispose();
  }

  void _calculateValuation() {
    setState(() => _isCalculating = true);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final year = int.tryParse(_selectedYear) ?? 2020;
      final km = int.tryParse(_kmController.text.trim()) ?? 40000;

      // Realistic valuation algorithm
      int baseVal = 550000;
      baseVal += (year - 2018) * 45000;
      baseVal -= (km ~/ 10000) * 12000;
      if (_selectedFuel == 'Diesel') baseVal += 25000;
      if (_selectedFuel == 'CNG') baseVal += 15000;
      if (baseVal < 180000) baseVal = 180000;

      setState(() {
        _isCalculating = false;
        _estimatedValuationMin = (baseVal * 0.95).round();
        _estimatedValuationMax = (baseVal * 1.08).round();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 14,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2185B),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC2185B).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sell Your Car for Best Price',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'MyMechanic & Spinny Assured • Instant Payment',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Benefits Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E1065), Color(0xFF4C1D95)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBenefitItem(Icons.verified_rounded, 'Best Price\nAssurance'),
                  Container(width: 1, height: 26, color: Colors.white24),
                  _buildBenefitItem(Icons.account_balance_wallet_rounded, 'Same Day\nPayment'),
                  Container(width: 1, height: 26, color: Colors.white24),
                  _buildBenefitItem(Icons.assignment_turned_in_rounded, 'Free RC\nTransfer'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Input Fields
            const Text(
              'Vehicle Registration Number',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _regController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary),
                hintText: 'e.g. DL 01 AB 1234',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Year of Mfg',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedYear,
                        items: _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                        onChanged: (val) => setState(() => _selectedYear = val ?? '2020'),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fuel Type',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFuel,
                        items: _fuelOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (val) => setState(() => _selectedFuel = val ?? 'Petrol'),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Text(
              'Odometer Reading (Kms)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _kmController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.speed_rounded, color: AppColors.primary),
                hintText: 'e.g. 45000',
                suffixText: 'km',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Valuation result card if calculated
            if (_estimatedValuationMin != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.stars_rounded, color: Color(0xFF16A34A), size: 22),
                        SizedBox(width: 6),
                        Text(
                          'Estimated Market Valuation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${_formatCurrency(_estimatedValuationMin!)} - ₹${_formatCurrency(_estimatedValuationMax!)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF15803D),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Free Doorstep Inspection included • Guaranteed instant transfer',
                      style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                    ),
                  ],
                ),
              ),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isCalculating
                    ? null
                    : () {
                        if (_estimatedValuationMin == null) {
                          _calculateValuation();
                        } else {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.check_circle_rounded, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Doorstep inspection scheduled! Our agent will call you shortly.'),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCalculating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _estimatedValuationMin == null
                            ? 'Get Instant Valuation'
                            : 'Book Free Doorstep Inspection',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFACC15), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 100000) {
      final lakhs = amount / 100000;
      return '${lakhs.toStringAsFixed(2)} Lakh';
    }
    return amount.toString();
  }
}
