import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool readOnly;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search services, e.g. "AC service", "Brake pads"',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onClear,
    this.readOnly = false,
    this.controller,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  bool _internalController = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _internalController = true;
    }
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleControllerChange);
  }

  void _handleControllerChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      if (mounted) {
        setState(() {
          _hasText = hasText;
        });
      }
    }
  }

  @override
  void didUpdateWidget(CustomSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_internalController) {
        _controller.removeListener(_handleControllerChange);
        _controller.dispose();
        _internalController = false;
      } else {
        _controller.removeListener(_handleControllerChange);
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
      } else {
        _controller = TextEditingController();
        _internalController = true;
      }
      _controller.addListener(_handleControllerChange);
      _hasText = _controller.text.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: AppTypography.bodyLarge.copyWith(
          color: isDark ? AppColors.darkTextPrimary : null,
        ),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkSearchPlaceholder : AppColors.textMuted,
            fontSize: 13,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            size: 22,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                    widget.onClear?.call();
                  },
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 20,
                      width: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.divider,
                      margin: const EdgeInsets.only(right: 6),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic_none_rounded, size: 20),
                      color: AppColors.primary,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Voice search: Say "Periodic Service" or "AC Gas"'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
