import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metasampler/style/colors.dart';
import 'package:metasampler/style/text.dart';

import '../plugin/config.dart';
import '../views/settings.dart';
import '../plugin/plugin.dart';
import 'module.dart';

const int INDENT_SIZE = 10;

void add_module_to_category(
  Module module,
  double indent,
  String searchText,
  List<String> categoryNames,
  List<RightClickCategory> categories,
  void Function(Module) onAddModule,
) {
  if (categoryNames.length == 0) {
    categoryNames = ["Uncategorized"];
  }

  for (var category in categories) {
    if (category.name == categoryNames[0]) {
      if (categoryNames.length == 1) {
        // Add new element to the category
        category.elements.add(
          RightClickElement(
            module,
            indent + INDENT_SIZE,
            searchText,
            onAddModule,
          ),
        );

        // Sort elements of the added category
        category.elements.sort(
          (a, b) => a.module.name.compareTo(b.module.name),
        );

        return;
      } else {
        add_module_to_category(
          module,
          indent + INDENT_SIZE,
          searchText,
          categoryNames.sublist(1),
          category.categories,
          onAddModule,
        );
        return;
      }
    }
  }

  RightClickCategory newCategory = RightClickCategory(
    categoryNames[0],
    indent,
    searchText,
  );

  if (categoryNames.length == 1) {
    newCategory.elements.add(
      RightClickElement(
        module,
        indent + INDENT_SIZE,
        searchText,
        onAddModule,
      ),
    );
  } else {
    add_module_to_category(
      module,
      indent + INDENT_SIZE,
      searchText,
      categoryNames.sublist(1),
      newCategory.categories,
      onAddModule,
    );
  }

  // Add the new category to the list
  categories.add(newCategory);

  // Sort categories of the new category
  categories.sort((a, b) => a.name.compareTo(b.name));
}

class RightClickView extends StatefulWidget {
  RightClickView({super.key, required this.plugins, required this.onAddModule});

  List<Plugin> plugins;
  void Function(Module) onAddModule;

  @override
  State<RightClickView> createState() => _RightClickView();
}

class _RightClickView extends State<RightClickView> with SingleTickerProviderStateMixin {
  String searchText = "";
  late TabController _tabController;
  String currentTitle = "Modules"; // Default title

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            currentTitle = "Modules";
            break;
          case 1:
            currentTitle = "Samples";
            break;
          case 2:
            currentTitle = "Variables";
            break;
          case 3:
            currentTitle = "Plugins";
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        // widget.app.patchingScaleEnabled = false;
      },
      onExit: (event) {
        // widget.app.patchingScaleEnabled = true;
      },
      child: Container(
        width: 300,
        height: 240,
        child: Column(
          children: [
            /* Title and Tab Bar */
            SizedBox(
              height: 30,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 5),
                    child: Text(
                      currentTitle,
                      style: AppTextStyles.body,
                    ),
                  ),
                  Expanded(child: SizedBox()),
                  /* Tab Bar */
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.blueGrey,
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textMuted,
                    unselectedLabelStyle: TextStyle(fontSize: 12),
                    labelPadding: EdgeInsets.only(left: 4, right: 4, top: 6),
                    indicatorPadding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    dividerHeight: 0,
                    tabs: [
                      Tab(icon: Icon(Icons.widgets, size: 14), iconMargin: EdgeInsets.zero),
                      Tab(icon: Icon(Icons.audiotrack, size: 14), iconMargin: EdgeInsets.zero),
                      Tab(icon: Icon(Icons.data_usage, size: 14), iconMargin: EdgeInsets.zero),
                      Tab(icon: Icon(Icons.extension, size: 14), iconMargin: EdgeInsets.zero),
                    ],
                  ),
                ],
              ),
            ),

            /* Tab Content */
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Modules Tab
                  _buildModulesTab(),
                  
                  // Samples Tab
                  _buildSamplesTab(),
                  
                  // Variables Tab
                  _buildVariablesTab(),
                  
                  // Plugins Tab
                  _buildPluginsTab(),
                ],
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          color: MyTheme.grey20,
          border: Border.all(color: MyTheme.grey40),
        ),
      ),
    );
  }

  Widget _buildModulesTab() {
    // Build the module list
    List<RightClickCategory> categories = [];

    String lowerSearchText = searchText.toLowerCase();

    for (var plugin in widget.plugins) {
      for (var module in plugin.modules) {
        bool matchesSearch =
            module.name.toLowerCase().contains(lowerSearchText);

        for (var category in module.category) {
          if (category.toLowerCase().contains(lowerSearchText)) {
            matchesSearch = true;
            break;
          }
        }

        if (matchesSearch) {
          add_module_to_category(
            module,
            4,
            lowerSearchText,
            module.category,
            categories,
            widget.onAddModule,
          );
        }
      }
    }

    return Column(
      children: [
        /* Search bar */
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          child: Container(
            height: 25,
            child: TextField(
              maxLines: 1,
              cursorHeight: 14,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(5.0),
                  ),
                  borderSide: BorderSide(
                    width: 2,
                    color: Colors.blueGrey,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(5.0),
                  ),
                  borderSide: BorderSide(
                    width: 2,
                    color: Colors.blueGrey,
                  ),
                ),
                contentPadding: EdgeInsets.fromLTRB(10, 10, 0, 3),
              ),
              onChanged: (data) {
                setState(() {
                  searchText = data;
                });
              },
            ),
            decoration: const BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.all(
                Radius.circular(5.0),
              ),
            ),
          ),
        ),

        /* Module List */
        Expanded(
          child: SingleChildScrollView(
            controller: ScrollController(),
            child: Column(
              children: categories,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSamplesTab() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.audiotrack,
            size: 48,
            color: Colors.grey.shade600,
          ),
          SizedBox(height: 16),
          Text(
            "Samples",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Sample library coming soon",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVariablesTab() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.data_usage,
            size: 48,
            color: Colors.grey.shade600,
          ),
          SizedBox(height: 16),
          Text(
            "Variables",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Variable management coming soon",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPluginsTab() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.extension,
            size: 48,
            color: Colors.grey.shade600,
          ),
          SizedBox(height: 16),
          Text(
            "Plugins",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Plugin management coming soon",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class RightClickCategory extends StatefulWidget {
  final String name;
  final double indent;
  final String searchText;
  final List<RightClickCategory> categories = [];
  final List<RightClickElement> elements = [];

  RightClickCategory(
    this.name,
    this.indent,
    this.searchText, {
    super.key,
  });

  @override
  State<RightClickCategory> createState() => _RightClickCategoryState();
}

class _RightClickCategoryState extends State<RightClickCategory> {
  bool hovering = false;
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    bool searched = widget.searchText.length > 0;

    return Column(
      children: <Widget>[
            MouseRegion(
              hitTestBehavior: HitTestBehavior.opaque,
              onEnter: (event) {
                setState(() {
                  hovering = true;
                });
              },
              onExit: (event) {
                setState(() {
                  hovering = false;
                });
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                onSecondaryTap: () {},
                onPanStart: (e) {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                onLongPress: () {},
                child: Container(
                  padding: EdgeInsets.fromLTRB(widget.indent, 0, 0, 0),
                  height: 24,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          expanded
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: MyTheme.textColorLight,
                          size: 20,
                        ),
                        Text(
                          widget.name,
                          style: const TextStyle(
                            color: MyTheme.textColorLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: hovering ? MyTheme.grey40 : MyTheme.grey20,
                  ),
                ),
              ),
            ),
          ] +
          (expanded || searched
              ? <Widget>[] + widget.elements + widget.categories
              : []),
    );
  }
}

class RightClickElement extends StatefulWidget {
  final Module module;
  final double indent;
  final String searchText;
  final void Function(Module info) onAddModule;

  const RightClickElement(
    this.module,
    this.indent,
    this.searchText,
    this.onAddModule, {
    super.key,
  });

  @override
  State<RightClickElement> createState() => _RightClickElementState();
}

class _RightClickElementState extends State<RightClickElement> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    String name = widget.module.name;

    return MouseRegion(
      onEnter: (event) {
        setState(() {
          hovering = true;
        });
      },
      onExit: (event) {
        if (mounted) {
          setState(() {
            hovering = false;
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          widget.onAddModule(widget.module);
        },
        child: Container(
          padding: EdgeInsets.fromLTRB(widget.indent, 0, 0, 0),
          height: 22,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 15,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.module.color ??
                        widget.module.titleColor ??
                        widget.module.iconColor ??
                        Colors.grey,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(5.0),
                    ),
                  ),
                ),
                Container(
                  width: 6,
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          decoration: BoxDecoration(
            color: hovering ? MyTheme.grey40 : MyTheme.grey20,
          ),
        ),
      ),
    );
  }
}
