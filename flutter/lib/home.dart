import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:metasampler/style/colors.dart';
import 'package:metasampler/bindings/api/io.dart';
import 'style/text.dart';
import 'style/buttons.dart';
import 'project/browser.dart';
import 'project/audio_config.dart';
import 'plugin/config.dart';
import 'settings/settings.dart';

class HomeWidget extends StatelessWidget {
  const HomeWidget({
    super.key, 
    required this.child,
    this.audioManager, 
  });
  
  final AudioManager? audioManager;
  final Widget child;

  void showAudioConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AudioConfigDialog(audioManager: audioManager);
      },
    );
  }

  void showPluginConfigDialog(BuildContext context) {
    showPluginConfig(
      context,
      [], // Empty plugin list for now
      (updatedPluginInfos) {
        // Handle plugin updates
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    
    return Row(
      children: [
        // Sidebar
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.sidebar,
            border: Border(
              right: BorderSide(
                color: AppColors.backgroundBorder,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 10),
                child: Text(
                  'Procedure',
                  style: AppTextStyles.headingLarge,
                ),
              ),
              // Top section with main icons
              Expanded(
                child: Column(
                  children: [
                    IconTextButtonLarge(
                      icon: Icons.folder,
                      label: 'Projects',
                      isSelected: currentRoute == '/projects',
                      onTap: () {
                        context.go('/projects');
                      },
                    ),
                    IconTextButtonLarge(
                      icon: Icons.task,
                      label: 'Modules',
                      isSelected: currentRoute == '/modules',
                      onTap: () {
                        context.go('/modules');
                      },
                    ),
                    IconTextButtonLarge(
                      icon: Icons.graphic_eq,
                      label: 'Samples',
                      isSelected: currentRoute == '/samples',
                      onTap: () {
                        context.go('/samples');
                      },
                    ),
                    IconTextButtonLarge(
                      icon: Icons.web,
                      label: 'Community',
                      isSelected: currentRoute == '/community',
                      onTap: () {
                        context.go('/community');
                      },
                    ),
                    IconTextButtonLarge(
                      icon: Icons.settings,
                      label: 'Settings',
                      isSelected: currentRoute == '/settings',
                      onTap: () {
                        context.go('/settings');
                      },
                    ),
                  ],
                ),
              ),
              // Bottom section with additional icons
              Column(
                children: [
                  const Divider(
                    color: AppColors.backgroundBorder,
                    height: 1,
                  ),
                  IconTextButtonLarge(
                    icon: Icons.audiotrack,
                    label: 'Audio',
                    isSelected: false,
                    onTap: () {
                      showAudioConfigDialog(context);
                    },
                  ),
                  IconTextButtonLarge(
                    icon: Icons.settings,
                    label: 'Plugins',
                    isSelected: false,
                    onTap: () {
                      showPluginConfigDialog(context);
                    },
                  ),
                  IconTextButtonLarge(
                    icon: Icons.account_circle,
                    label: 'Account',
                    isSelected: false,
                    onTap: () {
                      // Handle account tap
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        // Main content area
        Expanded(
          child: Container(
            color: AppColors.background,
            child: child,
          ),
        ),
      ],
    );
  }

  String _getRouteDisplayName(String route) {
    switch (route) {
      case '/projects':
        return 'Projects';
      case '/modules':
        return 'Modules';
      case '/samples':
        return 'Samples';
      case '/community':
        return 'Community';
      case '/settings':
        return 'Settings';
      default:
        return 'Unknown';
    }
  }
}
