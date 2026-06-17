import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() => runApp(const MasterProApp());

class MasterProApp extends StatelessWidget {
  const MasterProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EXHXX Master Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF151515)),
        colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent, secondary: Colors.orangeAccent),
      ),
      home: const MainScreen(),
    );
  }
}

class NetworkLog {
  final String id, type, method, url, payload, response;
  NetworkLog(this.id, this.type, this.method, this.url, this.payload, this.response);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://kd1s.com');
  final List<NetworkLog> _netLogs = [];
  
  // مفاتيح الأدوات
  bool _sniffer = true, _mediaBlock = false, _autoClick = false, _debugShield = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('LogChannel', onMessageReceived: (msg) {
        var data = jsonDecode(msg.message);
        setState(() {
          int idx = _netLogs.indexWhere((l) => l.id == data['id']);
          if(idx != -1) _netLogs[idx] = NetworkLog(data['id'], data['type'], data['method'], data['url'], data['payload'], data['response']);
          else _netLogs.insert(0, NetworkLog(data['id'], data['type'], data['method'], data['url'], data['payload'], data['response']));
        });
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => _injectRadar(),
        onPageFinished: (url) => _applyTools(),
      ))
      ..loadRequest(Uri.parse(_urlController.text));
  }

  void _injectRadar() {
    if (!_sniffer) return;
    _controller.runJavaScript(r'''
      if(!window.__hooked){
        window.__hooked = true;
        const send = (id, type, method, url, p, r) => LogChannel.postMessage(JSON.stringify({id,type,method,url,payload:p,response:r}));
        
        document.addEventListener('submit', async (e) => {
          let form = e.target;
          let id = 'req_' + Date.now();
          let payload = new URLSearchParams(new FormData(form)).toString();
          send(id, 'نموذج (Form)', form.method.toUpperCase(), form.action, payload, 'جاري التنفيذ...');
          // اختطاف الطلب
          try {
            let res = await fetch(form.action, {method: form.method, body: payload, headers: {'Content-Type': 'application/x-www-form-urlencoded'}});
            let text = await res.text();
            send(id, 'نموذج (Form)', form.method.toUpperCase(), form.action, payload, text.substring(0,2000));
            document.open(); document.write(text); document.close();
          } catch(err) { send(id, 'خطأ', 'ERR', form.action, payload, err.toString()); }
        }, true);
      }
    ''');
  }

  void _applyTools() {
    _injectRadar();
    if (_mediaBlock) _controller.runJavaScript("var s=document.createElement('style');s.innerHTML='img,video{display:none!important}';document.head.appendChild(s);");
    if (_debugShield) _controller.runJavaScript("console.log=console.warn=console.error=()=>{};");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EXHXX MASTER PRO 🚀")),
      body: IndexedStack(
        index: _tabIndex,
        children: [_buildBrowser(), _buildArsenal(), _buildRadar(), _buildSystem()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.public), label: "متصفح"),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: "ترسانة"),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: "رادار"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "نظام"),
        ],
      ),
    );
  }

  Widget _buildBrowser() => Column(children: [
    Padding(padding: const EdgeInsets.all(8), child: TextField(controller: _urlController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "أدخل الرابط..."))),
    Expanded(child: WebViewWidget(controller: _controller))
  ]);

  Widget _buildArsenal() => ListView(children: [
    SwitchListTile(title: const Text("تفعيل الرادار الشامل"), value: _sniffer, onChanged: (v) => setState(() => _sniffer = v)),
    SwitchListTile(title: const Text("حجب الصور والوسائط"), value: _mediaBlock, onChanged: (v) => setState(() => _mediaBlock = v)),
    ListTile(title: const Text("تنظيف الكاش والبيانات"), leading: const Icon(Icons.delete), onTap: () => _controller.clearCache().then((_) => _controller.reload())),
  ]);

  Widget _buildRadar() => ListView.builder(
    itemCount: _netLogs.length,
    itemBuilder: (ctx, i) => Card(child: ListTile(
      title: Text(_netLogs[i].url, style: const TextStyle(fontSize: 12)),
      subtitle: Text("${_netLogs[i].method} - ${_netLogs[i].type}"),
      onTap: () => showDialog(context: context, builder: (_) => AlertDialog(content: SelectableText("البيانات:\n${_netLogs[i].payload}\n\nالرد:\n${_netLogs[i].response}"))),
    )),
  );

  Widget _buildSystem() => const Center(child: Text("نظام متكامل - EXHXX MASTER PRO"));
}
