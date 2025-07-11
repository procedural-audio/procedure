
import 'package:flutter/material.dart';
import 'package:metasampler/style/colors.dart';

class TitleBar extends StatefulWidget {
  const TitleBar({
    super.key,
    required this.child,
    this.color = AppColors.background,
    this.dividerColor = AppColors.backgroundBorder,
    this.showProjectControls = false,
  });

  final Widget child;
  final Color color;
  final Color dividerColor;
  final bool showProjectControls;

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> with TickerProviderStateMixin {
  bool _isModuleBrowserOpen = false;
  bool _isSampleBrowserOpen = false;
  
  late AnimationController _moduleBrowserController;
  late AnimationController _sampleBrowserController;
  late Animation<double> _moduleBrowserAnimation;
  late Animation<double> _sampleBrowserAnimation;

  @override
  void initState() {
    super.initState();
    
    _moduleBrowserController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sampleBrowserController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _moduleBrowserAnimation = CurvedAnimation(
      parent: _moduleBrowserController,
      curve: Curves.easeInOut,
    );
    _sampleBrowserAnimation = CurvedAnimation(
      parent: _sampleBrowserController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _moduleBrowserController.dispose();
    _sampleBrowserController.dispose();
    super.dispose();
  }


  void _toggleModuleBrowser() {
    setState(() {
      _isModuleBrowserOpen = !_isModuleBrowserOpen;
      if (_isModuleBrowserOpen) {
        _moduleBrowserController.forward();
        // Close sample browser if open
        if (_isSampleBrowserOpen) {
          _isSampleBrowserOpen = false;
          _sampleBrowserController.reverse();
        }
      } else {
        _moduleBrowserController.reverse();
      }
    });
  }

  void _toggleSampleBrowser() {
    setState(() {
      _isSampleBrowserOpen = !_isSampleBrowserOpen;
      if (_isSampleBrowserOpen) {
        _sampleBrowserController.forward();
        // Close module browser if open
        if (_isModuleBrowserOpen) {
          _isModuleBrowserOpen = false;
          _moduleBrowserController.reverse();
        }
      } else {
        _sampleBrowserController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.color,
      ),
      child: Column(
        children: [
          // Title bar with controls
          Container(
            height: 28,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: widget.showProjectControls ? _buildProjectTitleBar() : Container(),
          ),
          
          // Expandable panels
          AnimatedBuilder(
            animation: _moduleBrowserAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _moduleBrowserAnimation,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: widget.dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: const ModuleBrowserPlaceholder(),
                ),
              );
            },
          ),
          
          AnimatedBuilder(
            animation: _sampleBrowserAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _sampleBrowserAnimation,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: widget.dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: const SampleBrowserPlaceholder(),
                ),
              );
            },
          ),
          
          // Main content
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildProjectTitleBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          const Spacer(),
          // Module browser toggle
          _buildTitleBarButton(
            icon: Icons.widgets,
            isActive: _isModuleBrowserOpen,
            onTap: _toggleModuleBrowser,
            tooltip: 'Module Browser',
          ),
          const SizedBox(width: 4),
          // Sample browser toggle
          _buildTitleBarButton(
            icon: Icons.graphic_eq,
            isActive: _isSampleBrowserOpen,
            onTap: _toggleSampleBrowser,
            tooltip: 'Sample Browser',
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBarButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}

// Placeholder widgets for module and sample browsers
class ModuleBrowserPlaceholder extends StatelessWidget {
  const ModuleBrowserPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.widgets,
                size: 16,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Module Browser',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.backgroundBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Module browser placeholder\n\nThis will show available modules\nthat can be added to the project.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SampleBrowserPlaceholder extends StatelessWidget {
  const SampleBrowserPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.library_music,
                size: 16,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Sample Browser',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.backgroundBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Sample browser placeholder\n\nThis will show available audio samples\nthat can be used in the project.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
