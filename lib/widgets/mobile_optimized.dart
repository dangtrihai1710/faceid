import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MobileOptimizedWidgets {
  // Touch-optimized button with haptic feedback
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool enabled = true,
    IconData? icon,
    double? width,
    double? height,
    bool enableHapticFeedback = true,
    Color? backgroundColor,
    TextStyle? textStyle,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 48, // Touch-friendly height
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? () {
          if (enableHapticFeedback) {
            HapticFeedback.lightImpact();
          }
          onPressed();
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 2,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: textStyle ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  // Touch-optimized text field
  static Widget textField({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? errorText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    VoidCallback? onEditingComplete,
    FocusNode? focusNode,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines = 1,
    bool autofocus = false,
    TextInputAction? textInputAction,
    bool enableHapticFeedback = true,
    EdgeInsets? contentPadding,
  }) {
    return MobileTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      onTap: onTap,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      focusNode: focusNode,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      maxLines: maxLines,
      autofocus: autofocus,
      textInputAction: textInputAction,
      enableHapticFeedback: enableHapticFeedback,
      contentPadding: contentPadding,
    );
  }

  // Optimized card with proper touch targets
  static Widget card({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    double? elevation,
    VoidCallback? onTap,
    bool enableHapticFeedback = true,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: backgroundColor,
        elevation: elevation ?? 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap != null ? () {
            if (enableHapticFeedback) {
              HapticFeedback.lightImpact();
            }
            onTap!();
          } : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  // Optimized list tile for mobile
  static Widget listTile({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool enableHapticFeedback = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null ? () {
          if (enableHapticFeedback) {
            HapticFeedback.lightImpact();
          }
          onTap!();
        } : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: contentPadding ?? const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    title,
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      subtitle!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Bottom sheet optimized for mobile
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    double? height,
    bool enableDragHandle = true,
    bool enableHapticFeedback = true,
  }) {
    if (enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: height ?? MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              if (enableDragHandle) ...[
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  // Optimized chip widget
  static Widget chip({
    required Widget label,
    Widget? avatar,
    VoidCallback? onDeleted,
    VoidCallback? onTap,
    bool enableHapticFeedback = true,
    Color? backgroundColor,
    Color? textColor,
    EdgeInsetsGeometry? padding,
    VisualDensity? visualDensity,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null ? () {
          if (enableHapticFeedback) {
            HapticFeedback.lightImpact();
          }
          onTap!();
        } : null,
        borderRadius: BorderRadius.circular(20),
        child: Chip(
          label: label,
          avatar: avatar,
          deleteIcon: onDeleted != null
              ? Icon(Icons.close, size: 16, color: textColor)
              : null,
          onDeleted: onDeleted,
          backgroundColor: backgroundColor,
          labelStyle: TextStyle(color: textColor),
          padding: padding,
          visualDensity: visualDensity,
        ),
      ),
    );
  }

  // Loading indicator with message
  static Widget loadingIndicator({
    String? message,
    Color? color,
    double? size,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size ?? 24,
          height: size ?? 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Colors.blue,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  // Optimized error dialog
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
    bool enableHapticFeedback = true,
  }) {
    if (enableHapticFeedback) {
      HapticFeedback.heavyImpact();
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              child: Text(actionText!),
            ),
        ],
      ),
    );
  }

  // Optimized success dialog
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
    bool enableHapticFeedback = true,
  }) {
    if (enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              child: Text(actionText!),
            ),
        ],
      ),
    );
  }
}

class MobileTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool enabled;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final bool enableHapticFeedback;
  final EdgeInsets? contentPadding;

  const MobileTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.autofocus = false,
    this.textInputAction,
    this.enableHapticFeedback = true,
    this.contentPadding,
  }) : super(key: key);

  @override
  State<MobileTextField> createState() => _MobileTextFieldState();
}

class _MobileTextFieldState extends State<MobileTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused && widget.enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.labelText!,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          textInputAction: widget.textInputAction,
          maxLines: widget.maxLines,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: widget.prefixIcon,
                  )
                : null,
            suffixIcon: widget.suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: widget.suffixIcon,
                  )
                : null,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.errorText != null
                    ? theme.colorScheme.error
                    : _isFocused
                        ? theme.colorScheme.primary
                        : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            filled: true,
            fillColor: widget.enabled
                ? (_isFocused ? Colors.white : Colors.grey.shade50)
                : Colors.grey.shade100,
          ),
        ),
      ],
    );
  }
}