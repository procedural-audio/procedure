
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:procedure_ui/style/colors.dart';
import 'package:procedure_ui/preset/browser.dart';
import 'dart:io';

class TitleBarNavigatorObserver extends NavigatorObserver {
  static TitleBarNavigatorObserver? _instance;
  NavigatorState? _navigatorState;
  
  static TitleBarNavigatorObserver get instance {
    _instance ??= TitleBarNavigatorObserver._();
    return _instance!;
  }
  
  TitleBarNavigatorObserver._();
  
  NavigatorState? get navigatorState => _navigatorState;
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _navigatorState = navigator;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
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
  static const double height = 28;

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> with TickerProviderStateMixin {
  bool _isModuleBrowserOpen = false;
  bool _isSampleBrowserOpen = false;
  bool _isPresetBrowserOpen = false;
  OverlayEntry? _presetBrowserOverlay;
  
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
    _presetBrowserOverlay?.remove();
    _moduleBrowserController.dispose();
    _sampleBrowserController.dispose();
    super.dispose();
  }
  
  void _togglePresetBrowser() {
    if (_isPresetBrowserOpen) {
      _closePresetBrowser();
    } else {
      _openPresetBrowser();
    }
  }
  
  void _openPresetBrowser() {
    final routerState = GoRouterState.of(context);
    final currentRoute = routerState.uri.path;
    final projectName = routerState.pathParameters['projectName'];
    
    if (!currentRoute.startsWith("/project/") || projectName == null) return;
    
    setState(() {
      _isPresetBrowserOpen = true;
    });
    
    // Create overlay entry
    _presetBrowserOverlay = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          // Barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: _closePresetBrowser,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),
          // Preset browser
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
              margin: const EdgeInsets.all(40),
              child: PresetsBrowser(
                presets: [], // TODO: Load actual presets
                directory: Directory(""), // TODO: Get actual preset directory
                onLoad: (preset) {
                  // TODO: Implement preset loading
                  _closePresetBrowser();
                },
                onAddInterface: (preset) {
                  // TODO: Implement interface adding
                },
                onRemoveInterface: (preset) {
                  // TODO: Implement interface removal
                },
                onNewPreset: () {
                  // TODO: Implement new preset creation
                },
                onDuplicatePreset: (preset) {
                  // TODO: Implement preset duplication
                },
                onDeletePreset: (preset) {
                  // TODO: Implement preset deletion
                },
                onRenamePreset: (preset, newName) {
                  // TODO: Implement preset renaming
                },
              ),
            ),
          ),
        ],
      ),
    );
    
    // Insert overlay
    Overlay.of(context).insert(_presetBrowserOverlay!);
  }
  
  void _closePresetBrowser() {
    _presetBrowserOverlay?.remove();
    _presetBrowserOverlay = null;
    setState(() {
      _isPresetBrowserOpen = false;
    });
  }
  
  String _getRouteDisplayName() {
    final routerState = GoRouterState.of(context);
    final currentRoute = routerState.uri.path;
    final pathParameters = routerState.pathParameters;
    
    // Handle RESTful routes
    if (currentRoute.startsWith("/project/") && currentRoute.contains("/preset/")) {
      final projectName = pathParameters['projectName'];
      final presetName = pathParameters['presetName'];
      
      if (projectName != null && presetName != null) {
        return "${Uri.decodeComponent(projectName)} / ${Uri.decodeComponent(presetName)}";
      }
      // Extract from route if parameters are missing
      final parts = currentRoute.split('/');
      if (parts.length >= 5) {
        return "${Uri.decodeComponent(parts[2])} / ${Uri.decodeComponent(parts[4])}";
      }
    }
    
    // Handle simple routes
    switch (currentRoute) {
      case "/":
      case "/projects":
        return "Projects";
      case "/modules":
        return "Modules";
      case "/samples":
        return "Samples";
      case "/community":
        return "Community";
      case "/settings":
        return "Settings";
      default:
        // Clean up the route for display
        if (currentRoute.startsWith("/")) {
          return currentRoute.substring(1).replaceAll('/', ' / ');
        }
        return currentRoute;
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
    final routerState = GoRouterState.of(context);
    final currentRoute = routerState.uri.path;
    final isInProject = currentRoute.startsWith("/project/");
    
    // Close browsers when not in project
    if (!isInProject) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isPresetBrowserOpen) {
          _closePresetBrowser();
        }
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
      });
    }
    
    return Container(
      decoration: BoxDecoration(
        color: widget.color,
      ),
      child: Column(
        children: [
          // Title bar with controls
          Container(
            height: TitleBar.height,
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
    final routerState = GoRouterState.of(context);
    final currentRoute = routerState.uri.path;
    final isInProject = currentRoute.startsWith("/project/");
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Left spacer to balance the layout
          const Spacer(),
          
          // Centered group with back button and route text
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Back button (show if in project)
              if (isInProject) ...[
                _buildTitleBarButton(
                  icon: Icons.arrow_back,
                  isActive: false,
                  onTap: () {
                    context.go('/projects');
                  },
                  tooltip: 'Back',
                ),
                const SizedBox(width: 8),
              ],
              
              // Route text (clickable if in project)
              GestureDetector(
                onTap: isInProject ? _togglePresetBrowser : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isInProject && _isPresetBrowserOpen 
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getRouteDisplayName(),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isInProject) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _isPresetBrowserOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Right spacer to balance the layout
          const Spacer(),
          
          // Project controls (only show when in project)
          if (isInProject) ...[
            const SizedBox(width: 8),
            
            // Undo button
            _buildTitleBarButton(
              icon: Icons.undo,
              isActive: false,
              onTap: () {
                // TODO: Access patch state for undo
              },
              tooltip: 'Undo',
            ),
            const SizedBox(width: 4),
            // Redo button
            _buildTitleBarButton(
              icon: Icons.redo,
              isActive: false,
              onTap: () {
                // TODO: Access patch state for redo
              },
              tooltip: 'Redo',
            ),
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
