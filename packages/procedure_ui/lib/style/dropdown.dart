import 'package:flutter/material.dart';
import 'colors.dart';
import 'text.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final String Function(T)? itemBuilder;
  final String? hint;
  final bool isExpanded;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemBuilder,
    this.hint,
    this.isExpanded = true,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? (isExpanded ? 200 : null),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      child: DropdownButton<T>(
        value: value,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        isExpanded: isExpanded,
        dropdownColor: AppColors.surface,
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        underline: Container(),
        hint: hint != null ? Text(hint!, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)) : null,
        icon: const Icon(Icons.keyboard_arrow_down, size: 16),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemBuilder?.call(item) ?? item.toString(),
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class AppDropdownWithLabel<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final String Function(T)? itemBuilder;
  final String? hint;
  final bool isExpanded;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const AppDropdownWithLabel({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemBuilder,
    this.hint,
    this.isExpanded = true,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: 8),
        AppDropdown<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          itemBuilder: itemBuilder,
          hint: hint,
          isExpanded: isExpanded,
          width: width,
          padding: padding,
        ),
      ],
    );
  }
}
