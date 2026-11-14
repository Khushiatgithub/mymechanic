import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_data.dart';
import '../../models/booking.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';

class RatingSheet extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onSubmitted;

  const RatingSheet({
    super.key,
    required this.booking,
    this.onSubmitted,
  });

  static Future<void> show({
    required BuildContext context,
    required Booking booking,
    VoidCallback? onSubmitted,
  }) {
    if (booking.isRated || MockData.isBookingRated(booking.id)) {
      return Future.value();
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingSheet(
        booking: booking,
        onSubmitted: onSubmitted,
      ),
    );
  }

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  int _selectedRating = 5;
  final List<String> _selectedCategories = ['Service Quality'];
  final TextEditingController _feedbackController = TextEditingController();
  late bool _alreadyRated;
  bool _isSubmitting = false;

  static const List<String> _availableCategories = [
    'Service Quality',
    'Staff Behaviour',
    'Timeliness',
    'Value for Money',
    'Vehicle Handling',
  ];

  @override
  void initState() {
    super.initState();
    _alreadyRated = widget.booking.isRated || widget.booking.rating != null;
    if (_alreadyRated && widget.booking.rating != null) {
      _selectedRating = widget.booking.rating!;
      if (widget.booking.ratingCategories.isNotEmpty) {
        _selectedCategories.clear();
        _selectedCategories.addAll(widget.booking.ratingCategories);
      }
      if (widget.booking.ratingFeedback != null) {
        _feedbackController.text = widget.booking.ratingFeedback!;
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor Experience';
      case 2:
        return 'Fair / Average';
      case 3:
        return 'Good Service';
      case 4:
        return 'Very Good!';
      case 5:
        return 'Excellent! Outstanding';
      default:
        return 'Tap a star to rate';
    }
  }

  Future<void> _submitRating() async {
    if (_alreadyRated || MockData.isBookingRated(widget.booking.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already submitted feedback for this service.'),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (_selectedRating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 star to rate.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedbackText = _feedbackController.text.trim();
      final isAuthenticated = AuthService.instance.isAuthenticated;
      final isMongoId = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(widget.booking.id);

      if (isAuthenticated && isMongoId) {
        await BookingService.instance.submitRating(
          bookingId: widget.booking.id,
          rating: _selectedRating,
          ratingCategories: _selectedCategories,
          ratingFeedback: feedbackText.isNotEmpty ? feedbackText : null,
        );
      }

      // Also record in MockData for seamless fallback and UI immediate feedback
      MockData.rateBooking(
        widget.booking.id,
        _selectedRating,
        _selectedCategories,
        feedbackText,
      );

      if (!mounted) return;

      widget.onSubmitted?.call();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Thank you! Your rating and feedback have been recorded.'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = BookingService.getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevatedSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark ? const Border(top: BorderSide(color: AppColors.darkBorder)) : null,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _alreadyRated ? 'Service Rating & Feedback' : 'Rate Your Service',
                      style: AppTypography.titleLarge,
                    ),
                    Text(
                      '${widget.booking.serviceTitle} • ${widget.booking.bookingNumber}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            if (_alreadyRated)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This service has already been rated during this session.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Star Rating Section
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      final isFilled = starVal <= _selectedRating;
                      return IconButton(
                        iconSize: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        icon: Icon(
                          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isFilled ? Colors.amber : Colors.grey.shade400,
                        ),
                        onPressed: _alreadyRated
                            ? null
                            : () {
                                setState(() {
                                  _selectedRating = starVal;
                                });
                              },
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRatingLabel(_selectedRating),
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Feedback Categories
            Text(
              'What went well? (Select categories)',
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: isDark ? AppColors.darkInputSurface : AppColors.surfaceVariant,
                  checkmarkColor: Colors.white,
                  side: isDark
                      ? BorderSide(color: isSelected ? AppColors.primary : AppColors.darkBorder)
                      : null,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimary),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: _alreadyRated
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Optional Feedback text
            Text(
              'Additional Comments (Optional)',
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              enabled: !_alreadyRated,
              maxLines: 3,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Tell us more about the service quality, technician advice, or vehicle handling...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkSearchPlaceholder : Colors.grey.shade500,
                ),
                filled: isDark,
                fillColor: isDark ? AppColors.darkInputSurface : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (!_alreadyRated) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Feedback',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
