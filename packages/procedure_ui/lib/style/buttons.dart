import 'package:flutter/material.dart';
import 'text.dart';
import 'colors.dart';

class IconTextButtonLarge extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const IconTextButtonLarge({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<IconTextButtonLarge> createState() => _IconTextButtonLargeState();
}

class _IconTextButtonLargeState extends State<IconTextButtonLarge> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.transparent;
    Color textColor = AppColors.textMuted;
    
    if (widget.isSelected) {
      backgroundColor = AppColors.hover;
      textColor = AppColors.textPrimary;
    } else if (isHovered) {
      textColor = AppColors.textPrimary;
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovered) {
          setState(() {
            isHovered = hovered;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: AppTextStyles.headingSmall.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
