import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

void main() => runApp(const CommanderApp());

class CommanderApp extends StatelessWidget {
  const CommanderApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const CommanderScreen(),
      );
}

class CommanderScreen extends StatefulWidget {
  const CommanderScreen({super.key});
  @override
  State<CommanderScreen> createState() => _CommanderScreenState();
}

class _CommanderScreenState extends State<CommanderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late WebViewController _webController;
  TextEditingController _urlController = TextEditingController(text: 'https://www.virustotal.com/gui/domain/tiktokcdn.com/relations');
  List<String> logs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (req) {
          setState(() { logs.add(req.url); });
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(_urlController.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(controller: _urlController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "اكتب الرابط هنا...")),
        actions: [IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => _webController.loadRequest(Uri.parse(_urlController.text)))],
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: "المتصفح"), Tab(text: "Logs & Copy")]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          WebViewWidget(controller: _webController),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                  icon: const Icon(Icons.copy), 
                  label: const Text("نسخ الكل", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: logs.join('\n')));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم نسخ جميع الروابط!")));
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, i) => ListTile(title: Text(logs[i], style: const TextStyle(fontSize: 12, color: Colors.greenAccent))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
