import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Help & 24x7 Roadside Support Screen for MyMechanic.
///
/// Features:
/// - Prominent 24x7 Emergency SOS Roadside Assistance banner with instant call button.
/// - Live Chat / WhatsApp certified mechanic advisor support.
/// - Interactive FAQ directory with expandable questions.
/// - Request a Call Back / Service Inquiry option.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<Map<String, String>> _faqs = [
    {
      'question': 'How does Free Doorstep Pickup & Drop work?',
      'answer':
          'A certified MyMechanic valet arrives at your address at your scheduled time slot, inspects your car with an initial digital job card, and drives or flatbed-tows it securely to the designated MyMechanic hub. Once service and quality checks are completed, it is returned gleaming fresh to your doorstep.',
    },
    {
      'question': 'Are the spare parts 100% genuine OEM/OES?',
      'answer':
          'Yes. We source all engine oils, filters, brake pads, and mechanical components directly from authorized OEM/OES manufacturers (e.g. Bosch, Mobil, Castrol, Valeo, Brembo). All replacements are backed by official warranty.',
    },
    {
      'question': 'What warranty is provided on services?',
      'answer':
          'Periodic maintenance packages include up to 10,000 Kms / 6 Months network warranty. Denting & painting services come with a 2-Year unconditional paint shine & peeling warranty.',
    },
    {
      'question': 'Can I track my car during the service?',
      'answer':
          'Yes! Open the "Bookings" section or tap "Track Live" on the Home screen to view our real-time 7-stage service progression from pickup to final quality check and delivery.',
    },
    {
      'question': 'What are the accepted payment methods?',
      'answer':
          'You can pay on delivery (Cash or UPI upon receiving your car) or use our simulated online checkout supporting Instant UPI, Credit/Debit Cards, and Net Banking.',
    },
    {
      'question': 'How do I reschedule or cancel my booking?',
      'answer':
          'Navigate to your active booking details card. Tap "Reschedule" to select a new date and time slot, or tap "Cancel Booking" if your plans have changed. No cancellation fees are charged.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _callHelpline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Connecting to MyMechanic Helpline: +91 88269 91028...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startLiveChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Connecting to Certified Service Advisor on WhatsApp...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Help & 24x7 Support'),
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency SOS Roadside Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            AppConstants.logoAsset,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.emergency_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '24x7 Roadside Assistance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Fast 30-min on-site technician reach',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Stranded with a flat tyre, dead battery, or mechanical breakdown? Our nearest support vehicle will dispatch immediately.',
                    style: TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _callHelpline(context),
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                      label: const Text(
                        'Call Emergency Helpline (Toll-Free)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Support Action Cards
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.chat_rounded,
                    iconColor: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                    title: 'Chat with Advisor',
                    subtitle: 'Instant WhatsApp Help',
                    onTap: () => _startLiveChat(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.headset_mic_rounded,
                    iconColor: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                    title: 'Request Callback',
                    subtitle: 'We call back in 15 min',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Callback request submitted! Our service team will call you shortly.'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Search FAQs
            Text(
              'Frequently Asked Questions',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search help topics, warranty, pickup...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkSearchPlaceholder : AppColors.textSecondary,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? AppColors.darkSearchPlaceholder : AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: isDark ? AppColors.darkTextSecondary : null,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkInputSurface : AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 14),

            // FAQ Expansion List
            if (filteredFaqs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No help topics found matching "$_searchQuery".',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...filteredFaqs.map((faq) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      iconColor: isDark ? AppColors.darkTextPrimary : null,
                      collapsedIconColor: isDark ? AppColors.darkTextSecondary : null,
                      title: Text(
                        faq['question']!,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Text(
                            faq['answer']!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
