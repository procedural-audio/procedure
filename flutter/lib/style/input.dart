import 'package:flutter/material.dart';
import 'colors.dart';
import 'text.dart';

class InputBox extends StatefulWidget {
  final String? hintText;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final IconData? icon;
  final double? width;
  final double iconSize;
  final double borderRadius;
  final double horizontalPadding;
  final double verticalPadding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  const InputBox({
    super.key,
    this.hintText,
    this.initialValue,
    this.onChanged,
    this.autofocus = false,
    this.icon,
    this.width = 200,
    this.iconSize = 16,
    this.borderRadius = 6,
    this.horizontalPadding = 12,
    this.verticalPadding = 12,
    this.textStyle,
    this.hintStyle,
  });

  @override
  State<InputBox> createState() => _InputBoxState();
}

class _InputBoxState extends State<InputBox> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding,
        vertical: widget.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: AppColors.backgroundBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: widget.iconSize,
              color: AppColors.textMuted,
            ),
            SizedBox(width: widget.horizontalPadding),
          ],
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              style: widget.textStyle,
              cursorColor: Colors.white,
              cursorWidth: 1,
              cursorHeight: widget.textStyle?.fontSize,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search...',
                hintStyle: widget.hintStyle,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBarLarge extends StatelessWidget {
  final String? hintText;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final double? width;

  const SearchBarLarge({
    super.key,
    this.hintText,
    this.initialValue,
    this.onChanged,
    this.autofocus = false,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    return InputBox(
      hintText: hintText ?? 'Search...',
      initialValue: initialValue,
      onChanged: onChanged,
      autofocus: autofocus,
      icon: Icons.search,
      width: width,
      iconSize: 18,
      borderRadius: 5,
      horizontalPadding: 12,
      verticalPadding: 6,
      textStyle: AppTextStyles.body,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
    );
  }
}
