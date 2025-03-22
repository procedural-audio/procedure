import 'dart:io';

import 'package:flutter/material.dart';

import '../project/browser.dart';
import 'info.dart';

class PresetsBrowser extends StatefulWidget {
  final List<PresetInfo> presets;
  final Directory directory;
  final void Function(PresetInfo) onLoad;
  final void Function(PresetInfo) onAddInterface;
  final void Function(PresetInfo) onRemoveInterface;
  final void Function() onNewPreset; // Callback for creating a new preset
  final void Function(PresetInfo) onDuplicatePreset; // Callback for duplicating a preset
  final void Function(PresetInfo) onDeletePreset; // Callback for deleting a preset
  final void Function(PresetInfo, String) onRenamePreset; // Add rename preset callback

  PresetsBrowser({
    required this.presets,
    required this.directory,
    required this.onLoad,
    required this.onAddInterface,
    required this.onRemoveInterface,
    required this.onNewPreset,
    required this.onDuplicatePreset,
    required this.onDeletePreset,
    required this.onRenamePreset,
  });

  @override
  _PresetsBrowserState createState() => _PresetsBrowserState();
}

class _PresetsBrowserState extends State<PresetsBrowser> {
  String searchText = "";
  String? selectedTag;

  List<String> getUniqueTags() {
    final tags = <String>{};
    for (var preset in widget.presets) {
      tags.addAll(preset.tags);
    }
    return tags.toList();
  }

  void refreshPresets() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Sort presets alphabetically by name
    List<PresetInfo> filteredPresets = widget.presets.where((preset) {
      return (selectedTag == null || preset.tags.contains(selectedTag)) &&
             preset.name.toLowerCase().contains(searchText.toLowerCase());
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Get and sort unique tags alphabetically
    List<String> uniqueTags = getUniqueTags()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Container(
      width: 400,
      height: 400,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(20, 20, 20, 1.0),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 35,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(30, 30, 30, 1.0),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color.fromRGBO(220, 220, 220, 1.0),
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                      prefixIconColor: Colors.grey,
                      prefixIcon: Icon(
                        Icons.search,
                      ),
                    ),
                    onChanged: (text) {
                      setState(() {
                        searchText = text;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(30, 30, 30, 1.0),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  color: const Color.fromRGBO(200, 200, 200, 1.0),
                  onPressed: widget.onNewPreset,
                  hoverColor: const Color.fromRGBO(40, 40, 40, 1.0),
                ),
              ),
            ],
          ),
          Container(
            height: uniqueTags.length > 0 ? 40 : 0, // Set a fixed height for the row of tags
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: uniqueTags.map((tag) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: TagWidget(
                    isFiltered: selectedTag == tag,
                    backgroundColor: Colors.blue,
                    text: tag,
                    onTap: () {
                      setState(() {
                        if (selectedTag == tag) {
                          selectedTag = null; // Deselect if already selected
                        } else {
                          selectedTag = tag; // Select the tag
                        }
                      });
                    },
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPresets.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 1.0), // Add 1 pixel of padding
                  child: PresetItem(
                    info: filteredPresets[index],
                    onLoad: () {
                      widget.onLoad(filteredPresets[index]);
                    },
                    onDuplicate: () {
                      widget.onDuplicatePreset(filteredPresets[index]);
                    },
                    onAddInterface: () {
                      widget.onAddInterface(filteredPresets[index]);
                    },
                    onRemoveInterface: () {
                      widget.onRemoveInterface(filteredPresets[index]);
                    },
                    onDelete: () {
                      widget.onDeletePreset(filteredPresets[index]);
                    },
                    onRename: (newName) {
                      widget.onRenamePreset(filteredPresets[index], newName);
                    },
                    selectedTag: selectedTag,
                    onRefresh: refreshPresets, // Use refreshPresets method
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PresetItem extends StatefulWidget {
  const PresetItem({
    super.key,
    required this.info,
    required this.onLoad,
    required this.onDuplicate,
    required this.onAddInterface,
    required this.onRemoveInterface,
    required this.onDelete,
    required this.onRename,
    required this.selectedTag,
    required this.onRefresh, // Add refresh callback
  });

  final PresetInfo info;
  final void Function() onLoad;
  final void Function() onDuplicate;
  final void Function() onAddInterface;
  final void Function() onRemoveInterface;
  final void Function() onDelete;
  final void Function(String) onRename;
  final String? selectedTag;
  final void Function() onRefresh; // Define refresh callback

  @override
  State<PresetItem> createState() => _PresetItem();
}

class _PresetItem extends State<PresetItem> {
  bool hovering = false;

  void _showEditDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: widget.info.name);
    TextEditingController tagsController = TextEditingController(text: widget.info.tags.join(", "));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Preset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                // Update the preset info
                String newName = nameController.text;
                if (newName != widget.info.name) {
                  String newPath = widget.info.directory.parent.path + "/" + newName;
                  if (!await Directory(newPath).exists()) {
                    try {
                      await widget.info.directory.rename(newPath);
                      setState(() {
                        widget.info.directory = Directory(newPath);
                      });
                    } catch (e) {
                      print("Error renaming directory: $e");
                    }
                  }
                }
                setState(() {
                  widget.info.tags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty) // Filter out empty tags
                    .toList();
                });
                await widget.info.save(); // Save the updated PresetInfo
                widget.onRefresh(); // Call refresh callback
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) {
        setState(() {
          hovering = true;
        });
      },
      onExit: (e) {
        setState(() {
          hovering = false;
        });
      },
      child: GestureDetector(
        /*onDoubleTap: () {
          widget.onLoad();
        },*/
        child: Padding(
          padding: EdgeInsets.zero,
          child: Container(
            height: 40,
            padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
            decoration: BoxDecoration(
              color: hovering
                  ? const Color.fromRGBO(40, 40, 40, 1.0)
                  : const Color.fromRGBO(30, 30, 30, 1.0),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
              SizedBox(
                height: 30,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.info.name,
                        style: TextStyle(
                          color: hovering
                              ? Colors.white
                              : const Color.fromRGBO(200, 200, 200, 1.0),
                        ),
                      ),
                    ),
                    Row(
                      children: widget.info.tags.map((tag) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TagWidget(
                          isFiltered: widget.selectedTag == tag,
                          backgroundColor: Colors.blue,
                          text: tag,
                          onTap: () {},
                        ),
                      )).toList(),
                    ),
                    MoreDropdown(
                      items: [
                        "Load",
                        "Edit",
                        "Duplicate",
                        "Delete"
                      ],
                      onAction: (s) {
                        if (s == "Load") {
                          widget.onLoad();
                        } else if (s == "Edit") {
                          _showEditDialog(context);
                        } else if (s == "Duplicate") {
                          widget.onDuplicate();
                        } else if (s == "Delete") {
                          widget.onDelete();
                        }
                      },
                      color: const Color.fromRGBO(40, 40, 40, 1.0),
                      hoverColor: const Color.fromRGBO(30, 30, 30, 1.0),
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class TagWidget extends StatelessWidget {
  final bool isFiltered;
  final Color backgroundColor;
  final String text;
  final VoidCallback onTap;

  const TagWidget({
    super.key,
    required this.isFiltered,
    required this.backgroundColor,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 24, // Set a fixed height for the tag
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: isFiltered
              ? const Color.fromRGBO(40, 40, 40, 1.0) // Active color
              : backgroundColor,
          borderRadius: BorderRadius.circular(5),
          border: isFiltered
              ? Border.all(color: Colors.white, width: 1.0)
              : Border.all(color: Colors.transparent),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}