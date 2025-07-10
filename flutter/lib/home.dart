import 'package:flutter/material.dart';
import 'package:metasampler/theme/colors.dart';
import 'dart:io';
import 'theme/text.dart';
import 'theme/buttons.dart';
import 'project/browser.dart';
import 'project/project.dart';
import 'project/audio_config.dart';
import 'plugin/config.dart';
import 'settings.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  int selectedIndex = 0;

  void showAudioConfigDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AudioConfigDialog(audioManager: null);
      },
    );
  }

  void showPluginConfigDialog() {
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
                color: AppColors.border,
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
                      isSelected: selectedIndex == 0,
                      onTap: () {
                        setState(() {
                          selectedIndex = 0;
                        });
                      },
                    ),
                    IconTextButtonLarge(
                      icon: Icons.task,
                      label: 'Modules',
                      isSelected: selectedIndex == 1,
                      onTap: () {
                        setState(() {
                          selectedIndex = 1;
                        });
                      },
                    ),
                    IconTextButtonLarge(
                      icon: Icons.graphic_eq,
                      label: 'Samples',
                      isSelected: selectedIndex == 2,
                      onTap: () {
                        setState(() {
                          selectedIndex = 2;
                        });
                      },
                    ),
                    IconTextButtonLarge(
                      icon: Icons.web,
                      label: 'Community',
                      isSelected: selectedIndex == 3,
                      onTap: () {
                        setState(() {
                          selectedIndex = 3;
                        });
                      },
                    ),
                    IconTextButtonLarge(
                      icon: Icons.settings,
                      label: 'Settings',
                      isSelected: selectedIndex == 4,
                      onTap: () {
                        setState(() {
                          selectedIndex = 4;
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Bottom section with additional icons
              Column(
                children: [
                  const Divider(
                    color: AppColors.border,
                    height: 1,
                  ),
                  IconTextButtonLarge(
                    icon: Icons.audiotrack,
                    label: 'Audio',
                    isSelected: false,
                    onTap: () {
                      showAudioConfigDialog();
                    },
                  ),
                  IconTextButtonLarge(
                    icon: Icons.settings,
                    label: 'Plugins',
                    isSelected: false,
                    onTap: () {
                      showPluginConfigDialog();
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
            color: AppColors.surface,
            child: selectedIndex == 0 
              ? ProjectsBrowser(
                  MainDirectory(Directory("/Users/chase/Music/Procedural Audio")),
                  audioManager: null,
                )
              : Center(
                  child: Text(
                    'Selected: ${getSelectedLabel()}',
                    style: AppTextStyles.headingLarge,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  String getSelectedLabel() {
    switch (selectedIndex) {
      case 0:
        return 'Projects';
      case 1:
        return 'Modules';
      case 2:
        return 'Samples';
      case 3:
        return 'Community';
      case 4:
        return 'Settings';
      default:
        return 'Unknown';
    }
  }
}
