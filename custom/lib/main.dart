import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const SnifferApp());

class SnifferApp extends StatelessWidget {
  const SnifferApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const SnifferScreen(),
        theme: ThemeData.dark(),
      );
}

class SnifferScreen extends StatefulWidget {
  const SnifferScreen({super.key});
  @override
  State<SnifferScreen> createState() => _SnifferScreenState();
}

class _SnifferScreenState extends State<SnifferScreen> {
  late final WebViewController _controller;
  List<String> networkLogs = [];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // حل مشكلة request.method عن طريق استخدام request.url مباشرة
            setState(() {
              networkLogs.add("🔗 ${request.url}");
            });
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.virustotal.com/gui/domain/tiktokcdn.com/relations'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EXHXX Sniffer v2 🕵️‍♂️")),
      body: Column(
        children: [
          Expanded(flex: 2, child: WebViewWidget(controller: _controller)),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                itemCount: networkLogs.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(networkLogs[index], style: const TextStyle(fontSize: 10, color: Colors.greenAccent)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
