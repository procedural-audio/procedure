import 'dart:io';
import 'package:flutter/material.dart';

import 'plugin.dart';
import 'info.dart'; // Import PluginInfo

Future<void> showPluginConfig(BuildContext context, List<PluginInfo> initialPluginInfos, Function(List<PluginInfo>) updatePluginInfos) {
  return showDialog<void>(
    context: context,
    routeSettings: const RouteSettings(name: "/config"),
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: EdgeInsets.all(0),
        content: PluginConfig(
          initialPluginInfos: initialPluginInfos,
          updatePluginInfos: updatePluginInfos,
        ),
      );
    },
  );
}

class PluginConfig extends StatefulWidget {
  PluginConfig({required this.initialPluginInfos, required this.updatePluginInfos, super.key});

  final List<PluginInfo> initialPluginInfos;
  final Function(List<PluginInfo>) updatePluginInfos;

  @override
  State<PluginConfig> createState() => _PluginConfig();
}

class _PluginConfig extends State<PluginConfig> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController repositoryController = TextEditingController();
  String selectedTag = "";
  late List<PluginInfo> pluginInfos;

  @override
  void initState() {
    super.initState();
    pluginInfos = List.from(widget.initialPluginInfos);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 500, // Increased height to accommodate new UI elements
      decoration: BoxDecoration(
        color: const Color.fromRGBO(30, 30, 30, 1.0),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text("Plugins",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Username",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: repositoryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Repository",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (usernameController.text.isNotEmpty && repositoryController.text.isNotEmpty) {
                      try {
                        var newPluginInfo = await PluginInfo.create(usernameController.text, repositoryController.text);
                        if (newPluginInfo.tags.isNotEmpty) { // Check if tags were successfully retrieved
                          setState(() {
                            pluginInfos.add(newPluginInfo);
                          });
                        } else {
                          // Handle the case where no tags were retrieved
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to retrieve tags for the repository.')),
                          );
                        }
                      } catch (e) {
                        // Handle any errors during the creation of PluginInfo
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error adding plugin: $e')),
                        );
                      }
                    }
                  },
                  child: const Text("Add Plugin"),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pluginInfos.length,
              itemBuilder: (context, i) {
                return ListTile(
                  title: Text(
                    pluginInfos[i].repository,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        value: pluginInfos[i].tag,
                        hint: const Text("Select Tag", style: TextStyle(color: Colors.white)),
                        dropdownColor: const Color.fromRGBO(30, 30, 30, 1.0),
                        items: pluginInfos[i].tags.map((String tag) {
                          return DropdownMenuItem<String>(
                            value: tag,
                            child: Text(tag, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            pluginInfos[i].tag = newValue ?? "";
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh),
                        color: Colors.white,
                        onPressed: () {
                          pluginInfos[i].refreshTags();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () {
                          setState(() {
                            pluginInfos.removeAt(i);
                          });
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    print("Tapped");
                  },
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.updatePluginInfos(pluginInfos);
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Save",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}