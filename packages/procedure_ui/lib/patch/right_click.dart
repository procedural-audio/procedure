
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:procedure_bindings/bindings/api/module.dart';
import 'package:procedure_ui/project/theme.dart';

import 'package:cloud_functions/cloud_functions.dart';

import '../views/settings.dart';
import '../plugin/plugin.dart';

const int INDENT_SIZE = 10;

Future<String> generateModule(String searchText) async {
  print("Generate module: $searchText");

  try {
    // Call the Firebase function with authentication and rate limiting
    final callable = FirebaseFunctions.instance.httpsCallable('menuSuggestion');
    final result = await callable.call({'task': searchText});
    
    // Extract the result from the response - the function returns { result: string }
    final data = result.data as Map<String, dynamic>;
    final resultMap = data['result'];
    final codeString = resultMap['result'].toString();
    
    print("Generated module: $codeString");
    return codeString;
    
  } catch (e) {
    print("Error calling Firebase function: $e");
    
    // Handle specific error types with more detailed messages
    if (e.toString().contains('unauthenticated')) {
      print("User must be logged in to generate modules");
      return "Please log in to generate modules";
    } else if (e.toString().contains('resource-exhausted')) {
      print("Rate limit exceeded");
      return "Rate limit exceeded. Please try again later";
    } else if (e.toString().contains('internal')) {
      print("Internal server error - this might be a permissions issue");
      return "Server error: The AI service is not properly configured. Please contact support.";
    } else if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
      print("Permission denied error");
      return "Permission error: The AI service needs to be configured. Please contact support.";
    } else if (e.toString().contains('INVALID_ARGUMENT')) {
      print("Invalid argument error");
      return "Invalid request: Please try a different search term.";
    } else if (e.toString().contains('timeout')) {
      print("Request timeout");
      return "Request timed out. Please try again.";
    } else {
      print("Unknown error occurred: $e");
      return "Error generating module: ${e.toString().split(']').last.trim()}";
    }
  }
}

class NoResultsWidget extends StatelessWidget {
  final VoidCallback? onGenerate;
  final String searchText;

  const NoResultsWidget({super.key, this.onGenerate, required this.searchText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            color: Colors.grey.shade600,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            "No modules found",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try a different search or generate a new module",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onGenerate ?? () {
              generateModule(searchText);
            },
            icon: const Icon(Icons.auto_fix_high, size: 16),
            label: const Text("Generate"),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.grey40,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
          (a, b) => (a.module.name ?? '').compareTo(b.module.name ?? ''),
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

class _RightClickView extends State<RightClickView> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    // Build the module list
    List<RightClickCategory> categories = [];

    String lowerSearchText = searchText.toLowerCase();

    for (var plugin in widget.plugins) {
      for (var module in plugin.modules) {
        bool matchesSearch =
            (module.name ?? '').toLowerCase().contains(lowerSearchText);

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

    return MouseRegion(
      onEnter: (event) {
        // widget.app.patchingScaleEnabled = false;
      },
      onExit: (event) {
        // widget.app.patchingScaleEnabled = true;
      },
      child: Container(
        width: 300,
        child: Column(
          children: [
            /* Title */
            Row(
              children: [
                Container(
                  height: 35,
                  padding: const EdgeInsets.all(10.0),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Modules",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                Expanded(child: SizedBox()),
                IconButton(
                  icon: Icon(
                    Icons.code,
                    color: Colors.grey.shade600,
                    size: 14,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    print("Should open editor");
                    // Plugins.openEditor();
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: Colors.grey.shade600,
                    size: 14,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    /*showPluginConfig(context, widget.plugins, () {
                      // Define the updatePlugins function here
                      // This function should update the plugins list as needed
                    });*/
                  },
                ),
              ],
            ),

            /* Search bar */
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
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

            /* List */
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 300,
              ),
              child: SingleChildScrollView(
                controller: ScrollController(),
                child: categories.isEmpty
                    ? NoResultsWidget(searchText: searchText)
                    : Column(
                        children: categories,
                      ),
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
    String name = widget.module.name ?? '';

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
                if ((widget.module.menuIcon ?? '').isNotEmpty)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: SvgPicture.string(
                      widget.module.menuIcon!,
                      width: 16,
                      height: 16,
                      color: colorFromString(widget.module.color ?? "grey"),
                    ),
                  )
                else
                  Container(
                    width: 15,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorFromString(widget.module.color ?? "grey"),
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