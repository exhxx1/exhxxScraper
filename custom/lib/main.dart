import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() => runApp(const ExhxxWorldClassApp());

class ExhxxWorldClassApp extends StatelessWidget {
  const ExhxxWorldClassApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EXHXX Omni Commander',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF111111)),
        colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent, secondary: Colors.amberAccent),
      ),
      home: const MainScreen(),
    );
  }
}

class NetworkLog {
  final String type, method, url, payload, response, cookies;
  NetworkLog(this.type, this.method, this.url, this.payload, this.response, this.cookies);
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

  bool _optOmniSniffer = false;
  bool _optMediaBlocker = false;
  bool _optAutoScroll = false;
  bool _optShadowClicker = false;
  String _currentCookies = "";

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('ExhxxLog', onMessageReceived: (msg) {
        try {
          var data = jsonDecode(msg.message);
          if (data['type'] != null) {
            setState(() {
              _netLogs.insert(0, NetworkLog(data['type'], data['method'], data['url'], data['payload'] ?? '', data['response'] ?? '', _currentCookies));
            });
          }
        } catch(e) {
          setState(() { _sysLogs.insert(0, msg.message); });
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) { _injectCoreRadar(); },
        onPageFinished: (url) async { 
          _currentCookies = (await _controller.runJavaScriptReturningResult("document.cookie;")).toString().replaceAll('"', '');
          _applyAllTools(); 
        },
      ))
      ..loadRequest(Uri.parse(_urlController.text));
  }

  // ==========================================
  // النواة: الرادار الشامل (صيد הـ Raw + اختطاف הـ Form Response)
  // ==========================================
  void _injectCoreRadar() {
    if (!_optOmniSniffer) return;

    _controller.runJavaScript(r'''
      if(!window.__exhxxCoreHooked) {
        window.__exhxxCoreHooked = true;

        function sendToFlutter(type, method, url, payload, response) {
          if(url.includes('google-analytics') || url.includes('g/collect')) return; 
          let fullUrl = url;
          if(url.startsWith('/')) fullUrl = window.location.origin + url;

          let msg = {
             type: type, method: method, url: fullUrl, 
             payload: payload ? String(payload) : '', 
             response: response ? String(response) : ''
          };
          try { ExhxxLog.postMessage(JSON.stringify(msg)); } catch(e){}
        }

        // 1. اختطاف النماذج (Forms) لمنع الـ Refresh وسحب الرد (Response) بقوة!
        document.addEventListener('submit', async function(e) {
          if(e.target && e.target.tagName === 'FORM') {
            e.preventDefault(); // إيقاف الرفرش
            let form = e.target;
            let formData = new FormData(form);
            let formProps = new URLSearchParams(formData).toString(); 
            
            sendToFlutter('FORM_REQ', form.method.toUpperCase() || 'POST', form.action || window.location.href, formProps, 'Wait for response...');
            
            try {
               let res = await fetch(form.action || window.location.href, {
                  method: form.method || 'POST',
                  body: formProps,
                  headers: {'Content-Type': 'application/x-www-form-urlencoded'}
               });
               let text = await res.text();
               sendToFlutter('FORM_RES', form.method.toUpperCase(), form.action || window.location.href, formProps, text.substring(0,2500));
               
               // تعويض الصفحة بالرد حتى ما يعلق المستخدم
               document.open(); document.write(text); document.close();
            } catch(err) {
               sendToFlutter('FORM_ERR', form.method, form.action, formProps, err.toString());
               form.submit(); // السماح بالرفرش كحل أخير
            }
          }
        }, true);

        // 2. صيد Fetch
        const origFetch = window.fetch;
        window.fetch = async function(...args) {
          let url = typeof args[0] === 'string' ? args[0] : (args[0] && args[0].url ? args[0].url : 'Unknown');
          let method = (args[1] && args[1].method) ? args[1].method : 'GET';
          let body = (args[1] && args[1].body) ? args[1].body : '';
          
          try {
            let res = await origFetch.apply(this, args);
            let clone = res.clone();
            clone.text().then(text => {
              sendToFlutter('FETCH', method, url, typeof body === 'string' ? body : 'Binary', text.substring(0,2500));
            }).catch(e => {
              sendToFlutter('FETCH', method, url, 'Binary', 'Unreadable');
            });
            return res;
          } catch(err) {
             throw err;
          }
        };

        // 3. صيد XHR
        const origOpen = XMLHttpRequest.prototype.open;
        const origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url) {
          this._exMethod = method;
          this._exUrl = url;
          origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function(body) {
          this.addEventListener('load', function() {
            sendToFlutter('XHR', this._exMethod, this._exUrl, typeof body === 'string' ? body : 'Binary', this.responseText ? this.responseText.substring(0,2500) : '');
          });
          origSend.apply(this, arguments);
        };
      }
    ''');
  }

  void _applyAllTools() {
    _injectCoreRadar();
    if (_optMediaBlocker) {
      _controller.runJavaScript("var s=document.createElement('style');s.innerHTML='img,video,iframe,canvas{display:none !important;}';document.head.appendChild(s);");
    }
  }

  // ==========================================
  // تحويل الـ URL Encoded إلى قاموس Python نظيف (Raw Dictionary)
  // ==========================================
  String _formatPayloadForPython(String rawPayload) {
    if (!rawPayload.contains('=') || !rawPayload.contains('&')) return '"""$rawPayload"""';
    
    var parts = rawPayload.split('&');
    String dict = "{\n";
    for (var part in parts) {
      var kv = part.split('=');
      if (kv.length >= 2) {
        var key = Uri.decodeComponent(kv[0]);
        var val = Uri.decodeComponent(kv.sublist(1).join('='));
        dict += '    "$key": "$val",\n';
      }
    }
    dict += "}";
    return dict;
  }

  // ==========================================
  // مولد سكربت بايثون الاحترافي (Python Scripter)
  // ==========================================
  void _openAdvancedRepeater(NetworkLog log) {
    String rawPythonDict = _formatPayloadForPython(log.payload);
    
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF111111),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("تصدير السكربت 🚀", style: TextStyle(fontSize: 18, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 50)),
              icon: const Icon(Icons.code, color: Colors.black), label: const Text("نسخ كود Python الخام 🐍", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: () {
                String pyCode = '''
import requests
import re

print("⏳ جاري تهيئة الجلسة...")
session = requests.Session()
url = "${log.url}"

# 1. الدخول للموقع لسحب الـ Cookies الخاصة بالجلسة (تتخطى الحماية)
try:
    res_get = session.get(url)
    
    # محاولة سحب التوكن من الـ HTML إن وجد
    csrf_token = ""
    match = re.search(r'name="_csrf"\\s+value="([^"]+)"', res_get.text)
    if not match:
        match = re.search(r'name="csrf-token"\\s+content="([^"]+)"', res_get.text)
    
    if match:
        csrf_token = match.group(1)
        print(f"✅ تم سحب التوكن السري: {csrf_token[:15]}...")
except:
    pass

# 2. البيانات الخام (مفصلة ونظيفة للتعديل)
payload = $rawPythonDict

# تحديث التوكن بالقاموس إذا كان موجود
if '_csrf' in payload and 'csrf_token' in locals() and csrf_token:
    payload['_csrf'] = csrf_token

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}

print("🚀 جاري إرسال الطلب للسيرفر...")
response = session.request("${log.method}", url, headers=headers, data=payload)

print("✅ رد السيرفر:")
print(response.text[:2000])
''';
                Clipboard.setData(ClipboardData(text: pyCode));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🐍 تم نسخ السكربت الخام والمطور!")));
              },
            ),
            const SizedBox(height: 15),
          ],
        ),
      )
    );
  }

  Widget _buildBrowserTab() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF111111), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(child: TextField(
                controller: _urlController, style: const TextStyle(fontSize: 14, color: Colors.white),
                decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 15), filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                onSubmitted: (val) { if(!val.startsWith("http")) val = "https://" + val; _controller.loadRequest(Uri.parse(val)); },
              )),
              IconButton(icon: const Icon(Icons.rocket_launch, color: Colors.cyanAccent), onPressed: () {
                String val = _urlController.text; if(!val.startsWith("http")) val = "https://" + val; _controller.loadRequest(Uri.parse(val));
              }),
            ],
          ),
        ),
        Expanded(child: WebViewWidget(controller: _controller)),
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
              const Text("RAW RADAR 📡", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.cyanAccent)),
              Switch(value: _optOmniSniffer, activeColor: Colors.cyanAccent, onChanged: (v){ setState(() { _optOmniSniffer=v; _injectCoreRadar(); });}),
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
                  title: Text("[${log.method}] ${log.url}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12), maxLines: 1),
                  subtitle: Text("Type: ${log.type}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), width: double.infinity, color: const Color(0xFF0A0A0A),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("RAW PAYLOAD:", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                          SelectableText(_formatPayloadForPython(log.payload), style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
                          const Divider(color: Colors.white24),
                          const Text("RESPONSE:", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                          SelectableText(log.response.isEmpty ? "No Response" : log.response, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                              icon: const Icon(Icons.code), label: const Text("تصدير Python الخام 🐍"),
                              onPressed: () => _openAdvancedRepeater(log),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [_buildBrowserTab(), _buildNetworkTab()],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.cyanAccent, 
        unselectedItemColor: Colors.grey[700], 
        backgroundColor: const Color(0xFF111111),
        onTap: (idx) => setState(() { _currentIndex = idx; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.public), label: "Browser"),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: "Raw Radar"),
        ],
      ),
    );
  }
}
