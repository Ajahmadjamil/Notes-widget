import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:flutter/material.dart';

class InputField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final bool? isFocused;
  final bool isPassword;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction? textInputAction;

  InputField({
    super.key,
    required this.hint,
    required this.controller,
    this.isFocused,
    this.isPassword = false,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
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
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        FocusScope.of(context).requestFocus(_focusNode);
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _isFocused ? AppColors.textFieldBorderColorSlct : AppColors.textFieldBorderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: TextField(
                  obscureText: widget.isPassword ? _obscureText : false,
                  focusNode: _focusNode,
                  textInputAction:
                      widget.textInputAction ??
                      (widget.nextFocusNode != null ? TextInputAction.next : TextInputAction.done),
                  onSubmitted: (_) {
                    if (widget.nextFocusNode != null) {
                      widget.nextFocusNode!.requestFocus();
                    } else {
                      _focusNode.unfocus();
                    }
                  },
                  decoration: InputDecoration.collapsed(
                    hintText: widget.hint,
                    hintStyle: getRegularStyle(color: AppColors.textFieldHintColor),
                  ),
                  controller: widget.controller,
                  maxLines: 1,
                  style: getRegularStyle(color: AppColors.textFieldTextColor, fontSize: 14),
                ),
              ),
            ),
            if (widget.isPassword)
              InkWell(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: AppColors.iconColorGrey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
