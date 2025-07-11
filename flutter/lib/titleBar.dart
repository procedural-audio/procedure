
import 'package:flutter/material.dart';
import 'package:metasampler/style/colors.dart';

class TitleBarNavigatorObserver extends NavigatorObserver {
  static TitleBarNavigatorObserver? _instance;
  void Function(String?, Map<String, dynamic>?)? _onRouteChanged;
  NavigatorState? _navigatorState;
  
  static TitleBarNavigatorObserver get instance {
    _instance ??= TitleBarNavigatorObserver._();
    return _instance!;
  }
  
  TitleBarNavigatorObserver._();
  
  void setCallback(void Function(String?, Map<String, dynamic>?) callback) {
    _onRouteChanged = callback;
  }
  
  NavigatorState? get navigatorState => _navigatorState;
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _navigatorState = navigator;
    _updateRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _updateRoute(previousRoute);
    } else {
      _onRouteChanged?.call(null, null);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _updateRoute(newRoute);
    }
  }

  void _updateRoute(Route<dynamic> route) {
    final routeName = route.settings.name;
    final arguments = route.settings.arguments;
    final argumentsMap = arguments is Map<String, dynamic> ? arguments : <String, dynamic>{};
    
    _onRouteChanged?.call(routeName, argumentsMap);
  }
}

class TitleBar extends StatefulWidget {
  const TitleBar({
    super.key,
    required this.child,
    this.color = AppColors.background,
    this.dividerColor = AppColors.backgroundBorder,
  });

  final Widget child;
  final Color color;
  final Color dividerColor;

  static TitleBarNavigatorObserver get navigatorObserver => TitleBarNavigatorObserver.instance;

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> with TickerProviderStateMixin {
  bool _isModuleBrowserOpen = false;
  bool _isSampleBrowserOpen = false;
  String? _currentRoute;
  String? _projectName;
  
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
    
    // Connect to the navigator observer
    TitleBarNavigatorObserver.instance.setCallback(_onRouteChanged);
  }

  @override
  void dispose() {
    _moduleBrowserController.dispose();
    _sampleBrowserController.dispose();
    super.dispose();
  }
  
  void _onRouteChanged(String? routeName, Map<String, dynamic>? arguments) {
    // Defer setState to avoid calling it during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentRoute = routeName;
          _projectName = arguments?['projectName'];
        });
        
        // If we exit the project, close all browsers
        if (routeName != "/project") {
          if (_isModuleBrowserOpen) {
            setState(() {
              _isModuleBrowserOpen = false;
              _moduleBrowserController.reverse();
            });
          }
          if (_isSampleBrowserOpen) {
            setState(() {
              _isSampleBrowserOpen = false;
              _sampleBrowserController.reverse();
            });
          }
        }
      }
    });
  }


  String _getRouteDisplayName() {
    if (_currentRoute == null) {
      return "Home";
    }
    
    switch (_currentRoute) {
      case "/project":
        return _projectName ?? "Project";
      case "/":
      case null:
        return "Home";
      default:
        return _currentRoute!.startsWith("/") ? _currentRoute!.substring(1) : _currentRoute!;
    }
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
            child: _buildTitleBar(),
          ),
          
          // Module browser (expands from top)
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
          
          // Main content
          Expanded(
            child: Stack(
              children: [
                widget.child,
                // Sample browser (expands from bottom)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _sampleBrowserAnimation,
                    builder: (context, child) {
                      return SizeTransition(
                        sizeFactor: _sampleBrowserAnimation,
                        axisAlignment: -1.0, // Align to bottom
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              top: BorderSide(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    final navigator = TitleBarNavigatorObserver.instance.navigatorState;
    final canGoBack = navigator?.canPop() ?? false;
    final isInProject = _currentRoute == "/project";
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Back button (show if we can go back)
          if (canGoBack) ...[
            _buildTitleBarButton(
              icon: Icons.arrow_back,
              isActive: false,
              onTap: () {
                if (navigator != null && navigator.canPop()) {
                  navigator.pop();
                }
              },
              tooltip: 'Back',
            ),
            const SizedBox(width: 8),
          ],
          
          // Centered route text (always show)
          Expanded(
            child: Center(
              child: Text(
                _getRouteDisplayName(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Project controls (only show when in project)
          if (isInProject) ...[
            const SizedBox(width: 8),
            
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
