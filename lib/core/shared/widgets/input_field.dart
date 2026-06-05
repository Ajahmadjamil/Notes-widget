import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/app_dimensions.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:flutter/material.dart';

/// Reusable glass-styled text input used across the app.
class InputField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final bool? isFocused;
  final bool isPassword;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final int? maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const InputField({
    super.key,
    required this.hint,
    required this.controller,
    this.isFocused,
    this.isPassword = false,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
    this.prefixIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.isPassword;
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.inputFieldHeight,
      child: AppContainer(
        borderRadius: 16,
        blur: _isFocused ? 14 : 10,
        isFocused: _isFocused,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            if (widget.prefixIcon != null) ...[
              Icon(
                widget.prefixIcon,
                size: 20,
                color: _isFocused
                    ? AppColors.selectedColor.withValues(alpha: 0.7)
                    : AppColors.iconColorGrey,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: TextFormField(
                enabled: widget.enabled,
                obscureText: widget.isPassword ? _obscureText : false,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                textInputAction:
                    widget.textInputAction ??
                    (widget.nextFocusNode != null ? TextInputAction.next : TextInputAction.done),
                onFieldSubmitted: (value) {
                  if (widget.onSubmitted != null) {
                    widget.onSubmitted!(value);
                  } else if (widget.nextFocusNode != null) {
                    widget.nextFocusNode!.requestFocus();
                  } else {
                    _focusNode.unfocus();
                  }
                },
                onChanged: widget.onChanged,
                validator: widget.validator,
                decoration: InputDecoration.collapsed(
                  hintText: widget.hint,
                  hintStyle: getRegularStyle(color: AppColors.textFieldHintColor),
                ),
                controller: widget.controller,
                maxLines: 1,
                style: getRegularStyle(color: AppColors.textFieldTextColor, fontSize: 14),
                cursorColor: AppColors.selectedColor,
              ),
            ),
            if (widget.isPassword)
              IconButton(
                onPressed: () => setState(() => _obscureText = !_obscureText),
                icon: Icon(
                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: _isFocused
                      ? AppColors.selectedColor.withValues(alpha: 0.7)
                      : AppColors.iconColorGrey,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 18,
              ),
          ],
        ),
      ),
    );
  }
}
