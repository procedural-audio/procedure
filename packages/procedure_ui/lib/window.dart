import 'package:flutter/material.dart';
import 'package:procedure_ui/style/colors.dart';
import 'titleBar.dart';

class Window extends StatelessWidget {
  const Window({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: TitleBar(child: child),
    );
  }
} 