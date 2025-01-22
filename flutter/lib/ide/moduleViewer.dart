import 'package:flutter/material.dart';

class ModuleViewer extends StatefulWidget {
  const ModuleViewer({Key? key}) : super(key: key);

  @override
  _ModuleViewerState createState() => _ModuleViewerState();
}

class _ModuleViewerState extends State<ModuleViewer> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(
          "Far left has tree of plugins and modules. Center is large display of module being edited. Right is a chat and code editor."),
      color: Colors.grey,
    );
    /*return AnimatedContainer(
      duration: const Duration(
        milliseconds: 300,
      ),
      curve: Curves.linearToEaseOut,
      width: _isSidebarCollapsed ? 60 : 400,
      color: Colors.blueGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(
              _isSidebarCollapsed
                  ? Icons.arrow_forward_ios
                  : Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),
          Expanded(
            child: ModuleViewer(),
          ),
        ],
      ),
    );*/
  }
}
