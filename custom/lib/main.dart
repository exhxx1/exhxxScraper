import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() => runApp(const ExhxxGodModeApp());

class ExhxxGodModeApp extends StatelessWidget {
  const ExhxxGodModeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EXHXX God Mode',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F0F0F)),
        colorScheme: const ColorScheme.dark(primary: Colors.blueAccent, secondary: Colors.pinkAccent),
      ),
      home: const MainScreen(),
    );
  }
}

// كلاس لتخزين الطلبات بشكل احترافي
class NetworkLog {
  final String type, method, url, payload, response;
  NetworkLog(this.type, this.method, this.url, this.payload, this.response);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://kd1s.com');
  
  final List<NetworkLog> _netLogs = [];
  final List<String> _sysLogs = [];

  bool _optStealth = true; // تخطي Cloudflare الافتراضي
  bool _optMediaBlocker = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('ExhxxLog', onMessageReceived: (msg) {
        try {
          var data = jsonDecode(msg.message);
          setState(() {
            _netLogs.insert(0, NetworkLog(data['type'], data['method'], data['url'], data['payload'] ?? '', data['response'] ?? ''));
          });
        } catch(e) {
          setState(() { _sysLogs.insert(0, msg.message); });
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) { _injectGodModeCore(); },
        onPageFinished: (url) { _applyTools(); },
      ))
      ..loadRequest(Uri.parse(_urlController.text));
  }

  // ==========================================
  // النواة: صائد الردود والطلبات (Response & Request Catcher)
  // ==========================================
  void _injectGodModeCore() {
    // استخدمت r''' حتى ما تصير مشاكل ويا الفلاتر والرموز
    _controller.runJavaScript(r'''
      if(!window.__exhxxGodMode) {
        window.__exhxxGodMode = true;

        // 1. تخطي Cloudflare و Anonymization
        Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
        
        function sendLog(type, method, url, payload, response) {
          if(url.includes('google-analytics') || url.includes('google.com/g/collect')) return;
          try {
            ExhxxLog.postMessage(JSON.stringify({
              type: type, method: method, url: url, payload: payload, response: response
            }));
          } catch(e){}
        }

        // 2. اعتراض FETCH مع الردود (Responses)
        const origFetch = window.fetch;
        window.fetch = async function(...args) {
          let url = typeof args[0] === 'string' ? args[0] : (args[0] && args[0].url ? args[0].url : 'Unknown URL');
          let method = (args[1] && args[1].method) ? args[1].method : 'GET';
          let body = (args[1] && args[1].body) ? args[1].body : '';
          
          try {
            let response = await origFetch.apply(this, args);
            let clone = response.clone();
            clone.text().then(text => {
              sendLog('FETCH', method, url, typeof body === 'string' ? body : 'Binary', text.substring(0,2000));
            }).catch(e => {
              sendLog('FETCH', method, url, typeof body === 'string' ? body : 'Binary', 'Cannot read response');
            });
            return response;
          } catch(err) {
             sendLog('FETCH', method, url, 'Error', err.toString());
             throw err;
          }
        };

        // 3. اعتراض XHR مع الردود
        const origOpen = XMLHttpRequest.prototype.open;
        const origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url) {
          this._exMethod = method;
          this._exUrl = url;
          origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function(body) {
          this.addEventListener('load', function() {
            sendLog('XHR', this._exMethod, this._exUrl, typeof body === 'string' ? body : 'Binary', this.responseText ? this.responseText.substring(0,2000) : '');
          });
          origSend.apply(this, arguments);
        };
      }
    ''');
  }

  void _applyTools() {
    _injectGodModeCore();
    if (_optMediaBlocker) {
      _controller.runJavaScript("var s=document.createElement('style');s.innerHTML='img,video,iframe,canvas{display:none !important;}';document.head.appendChild(s);");
    }
  }

  // ==========================================
  // مدفع الإعادة (Request Repeater & Modifier)
  // ==========================================
  void _openRepeaterDialog(NetworkLog log) {
    TextEditingController urlCtrl = TextEditingController(text: log.url);
    TextEditingController payloadCtrl = TextEditingController(text: log.payload);

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF151515),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("مدفع الطلبات 🔁 (MITM Editor)", style: TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: urlCtrl, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(labelText: "URL الرابط", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: payloadCtrl, maxLines: 4, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(labelText: "Payload البيانات", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                  icon: const Icon(Icons.code, color: Colors.white), label: const Text("نسخ cURL", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    String curl = "curl -X ${log.method} '${urlCtrl.text}' --data '${payloadCtrl.text}'";
                    Clipboard.setData(ClipboardData(text: curl));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم نسخ كود cURL!")));
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  icon: const Icon(Icons.send, color: Colors.white), label: const Text("إرسال الهجوم 🚀", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    // إرسال الطلب المعدل من داخل المتصفح
                    String p = payloadCtrl.text.replaceAll("'", "\\'");
                    String code = "fetch('${urlCtrl.text}', {method: '${log.method}', body: '$p'}).then(r=>r.text()).then(t=>ExhxxLog.postMessage('[REPEATER RESPONSE] ' + t.substring(0,500)));";
                    _controller.runJavaScript(code);
                    Navigator.pop(ctx);
                    setState(() { _currentIndex = 2; }); // الذهاب للسجلات لرؤية الرد
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 تم إطلاق الطلب المعدل!")));
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ),
      )
    );
  }

  // ==========================================
  // القائمة العائمة (Floating HUD)
  // ==========================================
  void _showFloatingHUD() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: const Text("لوحة التحكم السريعة 🛸", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.cookie, color: Colors.orange), title: const Text("نسخ الكوكيز"), onTap: () async {
            final res = await _controller.runJavaScriptReturningResult("document.cookie;");
            Clipboard.setData(ClipboardData(text: res.toString().replaceAll('"', '')));
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم نسخ الكوكيز")));
          }),
          ListTile(leading: const Icon(Icons.speed, color: Colors.redAccent), title: const Text("تصفير الجلسة (تبديل حساب)"), onTap: () async {
            await _controller.clearCache();
            await _controller.clearLocalStorage();
            _controller.reload();
            Navigator.pop(ctx);
          }),
        ],
      ),
    ));
  }

  // ==========================================
  // الواجهات (UI)
  // ==========================================
  Widget _buildBrowserTab() {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              color: const Color(0xFF111111), padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: TextField(
                    controller: _urlController, style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 15), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                    onSubmitted: (val) { if(!val.startsWith("http")) val = "https://" + val; _controller.loadRequest(Uri.parse(val)); },
                  )),
                  IconButton(icon: const Icon(Icons.rocket_launch, color: Colors.blueAccent), onPressed: () {
                    String val = _urlController.text; if(!val.startsWith("http")) val = "https://" + val; _controller.loadRequest(Uri.parse(val));
                  }),
                ],
              ),
            ),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
        Positioned(
          bottom: 20, right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.blueAccent.withOpacity(0.8),
            onPressed: _showFloatingHUD,
            child: const Icon(Icons.dashboard_customize, color: Colors.white),
          ),
        )
      ],
    );
  }

  Widget _buildNetworkTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10), color: const Color(0xFF111111),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("NETWORK RADAR 📡", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.blueAccent)),
              IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: () => setState((){ _netLogs.clear(); })),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _netLogs.length,
            itemBuilder: (ctx, i) {
              var log = _netLogs[i];
              return Card(
                color: Colors.black, margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  title: Text("[${log.method}] ${log.url}", style: const TextStyle(color: Colors.greenAccent, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("Type: ${log.type}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), width: double.infinity, color: const Color(0xFF0A0A0A),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("PAYLOAD:", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                          SelectableText(log.payload.isEmpty ? "None" : log.payload, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          const Divider(color: Colors.white24),
                          const Text("RESPONSE:", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                          SelectableText(log.response.isEmpty ? "None" : log.response, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                              icon: const Icon(Icons.edit), label: const Text("تعديل وإرسال (MITM)"),
                              onPressed: () => _openRepeaterDialog(log),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildSysLogsTab() {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(10), color: const Color(0xFF111111), child: const Center(child: Text("SYSTEM & CONSOLE LOGS", style: TextStyle(color: Colors.grey)))),
        Expanded(
          child: ListView.builder(
            itemCount: _sysLogs.length,
            itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.all(8), child: SelectableText("> ${_sysLogs[i]}", style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace', fontSize: 12))),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [_buildBrowserTab(), _buildNetworkTab(), _buildSysLogsTab()],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent, unselectedItemColor: Colors.grey[700], backgroundColor: const Color(0xFF111111),
        onTap: (idx) => setState(() { _currentIndex = idx; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.public), label: "Browser"),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: "Network"),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: "Console"),
        ],
      ),
    );
  }
}
