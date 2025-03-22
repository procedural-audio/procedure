import 'package:flutter/material.dart';

import 'plugin.dart';

Future<List<Plugin>?> showPluginConfig(BuildContext context, List<Plugin> plugins) async {
  showDialog<void>(
    context: context,
    routeSettings: const RouteSettings(name: "/config"),
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: EdgeInsets.all(0),
        content: PluginConfig(
          plugins: plugins,
        ),
      );
    },
  );

  return null;
}

class PluginConfig extends StatefulWidget {
  PluginConfig({required this.plugins, super.key});

  List<Plugin> plugins;

  @override
  State<PluginConfig> createState() => _PluginConfig();
}

class _PluginConfig extends State<PluginConfig> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 400,
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
          Expanded(
            child: ListView.builder(
              itemCount: widget.plugins.length,
              itemBuilder: (context, i) {
                return ListTile(
                  leading: Checkbox(
                    value: true,
                    onChanged: (bool? checked) {
                      print("Changing");
                    }
                  ),
                  title: Text(
                    widget.plugins[i].info.repository,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.refresh),
                    color: Colors.white,
                    onPressed: () {
                      widget.plugins[i].info.refreshTags();
                    },
                  ),
                  onTap: () {
                    print("Tapped");
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}