import 'dart:io';

import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:metasampler/bindings/api/graph.dart';
import 'package:metasampler/plugins.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/views/presets.dart';

import 'package:metasampler/bindings/frb_generated.dart';
import 'package:metasampler/bindings/api.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'chat.dart';
import 'codeEditor.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

class CodeEditor extends StatefulWidget {
  const CodeEditor({Key? key}) : super(key: key);

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 300,
      ),
      curve: Curves.linearToEaseOut,
      width: _isSidebarCollapsed ? 60 : 600,
      color: Colors.blue,
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
            child: Container(
              color: Colors.blueGrey,
              child: MonacoEditorMacOSWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

class MonacoEditorMacOSWidget extends StatefulWidget {
  const MonacoEditorMacOSWidget({Key? key}) : super(key: key);

  @override
  State<MonacoEditorMacOSWidget> createState() =>
      _MonacoEditorMacOSWidgetState();
}

class _MonacoEditorMacOSWidgetState extends State<MonacoEditorMacOSWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    if (Platform.isMacOS || Platform.isIOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    loadMonacoHtml();
  }

  void loadMonacoHtml() async {
    // Load the HTML file as a string
    final html = await rootBundle.loadString('assets/monaco/monaco.html');

    // Convert to base64
    final base64Content = base64Encode(const Utf8Encoder().convert(html));

    _controller.loadRequest(
      Uri.parse('data:text/html;base64,$base64Content'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: _controller,
    );
  }
}
