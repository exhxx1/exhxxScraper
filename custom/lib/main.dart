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
  bool _optConsoleHijack = false;
  bool _optSpoofer = false;
  bool _optAntiDebug = false;
  bool _optUnlockRightClick = false;

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
  // النواة: الرادار الشامل (بالبيانات الخام Raw Data)
  // ==========================================
  void _injectCoreRadar() {
    if (!_optOmniSniffer) return;

    _controller.runJavaScript(r'''
      if(!window.__exhxxCoreHooked) {
        window.__exhxxCoreHooked = true;

        function sendToFlutter(type, method, url, payload, response) {
          if(url.includes('google-analytics') || url.includes('g/collect')) return; // تجاهل تتبع جوجل
          let fullUrl = url;
          if(url.startsWith('/')) fullUrl = window.location.origin + url;

          let msg = {
             type: type, method: method, url: fullUrl, 
             payload: payload ? String(payload) : '', 
             response: response ? String(response) : ''
          };
          try { ExhxxLog.postMessage(JSON.stringify(msg)); } catch(e){}
        }

        // 1. صيد النماذج وإرسالها خام (URL Encoded)
        document.addEventListener('submit', function(e) {
          if(e.target && e.target.tagName === 'FORM') {
            let formData = new FormData(e.target);
            let formProps = new URLSearchParams(formData).toString(); // سحب البيانات الخام!
            sendToFlutter('FORM', e.target.method.toUpperCase() || 'POST', e.target.action || window.location.href, formProps, 'Page Reloaded...');
          }
        }, true);

        // 2. صيد Fetch مع الردود
        const origFetch = window.fetch;
        window.fetch = async function(...args) {
          let url = typeof args[0] === 'string' ? args[0] : (args[0] && args[0].url ? args[0].url : 'Unknown');
          let method = (args[1] && args[1].method) ? args[1].method : 'GET';
          let body = (args[1] && args[1].body) ? args[1].body : '';
          
          try {
            let res = await origFetch.apply(this, args);
            let clone = res.clone();
            clone.text().then(text => {
              sendToFlutter('FETCH', method, url, typeof body === 'string' ? body : 'BinaryData', text.substring(0,2000));
            }).catch(e => {
              sendToFlutter('FETCH', method, url, typeof body === 'string' ? body : 'BinaryData', 'Unreadable');
            });
            return res;
          } catch(err) {
             sendToFlutter('FETCH', method, url, typeof body === 'string' ? body : 'BinaryData', 'Error: ' + err.message);
             throw err;
          }
        };

        // 3. صيد XHR مع الردود
        const origOpen = XMLHttpRequest.prototype.open;
        const origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url) {
          this._exMethod = method;
          this._exUrl = url;
          origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function(body) {
          this.addEventListener('load', function() {
            sendToFlutter('XHR', this._exMethod, this._exUrl, typeof body === 'string' ? body : 'BinaryData', this.responseText ? this.responseText.substring(0,2000) : '');
          });
          origSend.apply(this, arguments);
        };
      }
    ''');
  }

  void _applyAllTools() {
    _injectCoreRadar();

    if (_optMediaBlocker) {
      _controller.runJavaScript("var s=document.createElement('style');s.innerHTML='img,video,iframe,canvas{display:none !important;} *{background-image:none !important;}';document.head.appendChild(s);");
    }
    if (_optConsoleHijack) {
      _controller.runJavaScript('''
        if(!window.__exhxXConsole) {
          window.__exhxXConsole = true;
          const origLog = console.log;
          console.log = function() {
            ExhxxLog.postMessage('[CONSOLE] ' + Array.from(arguments).join(' '));
            origLog.apply(console, arguments);
          };
        }
      ''');
    }
    if (_optUnlockRightClick) {
      _controller.runJavaScript('''
        document.addEventListener('contextmenu', e => e.stopPropagation(), true);
        document.addEventListener('selectstart', e => e.stopPropagation(), true);
        var s=document.createElement('style');s.innerHTML='*{user-select: auto !important; -webkit-user-select: auto !important;}';document.head.appendChild(s);
      ''');
    }
    if (_optAntiDebug) {
      _controller.runJavaScript("console.warn=function(){}; console.error=function(){};");
    }
    if (_optAutoScroll) {
      _controller.runJavaScript("if(!window.vtSc) window.vtSc = setInterval(()=>window.scrollBy({top:500, behavior:'smooth'}), 800);");
    } else {
      _controller.runJavaScript("if(window.vtSc) clearInterval(window.vtSc); window.vtSc=null;");
    }
    if (_optShadowClicker) {
      _controller.runJavaScript('''
        if(!window.vtClk) window.vtClk = setInterval(()=>{
          function traverse(n) {
            let res=[];
            if(!n) return res;
            if(n.nodeType===1) res.push(n);
            if(n.shadowRoot) res.push(...traverse(n.shadowRoot));
            let c = n.shadowRoot ? n.shadowRoot.childNodes : n.childNodes;
            if(c) for(let i=0; i<c.length; i++) res.push(...traverse(c[i]));
            return res;
          }
          let all = traverse(document.documentElement);
          let btns = all.filter(x => (x.tagName==='VT-UI-BUTTON'||x.tagName==='BUTTON') && (x.textContent||'').trim()==='...');
          if(btns.length>0) { btns[0].scrollIntoView({block:'center'}); setTimeout(()=>btns[0].click(), 200); }
        }, 1500);
      ''');
    } else {
      _controller.runJavaScript("if(window.vtClk) clearInterval(window.vtClk); window.vtClk=null;");
    }
  }

  // ==========================================
  // مولدات الأكواد (Script Generators)
  // ==========================================
  void _openAdvancedRepeater(NetworkLog log) {
    TextEditingController urlCtrl = TextEditingController(text: log.url);
    TextEditingController payloadCtrl = TextEditingController(text: log.payload);

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF151515),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("تعديل واستخراج الطلبات 🚀", style: TextStyle(fontSize: 18, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: urlCtrl, style: const TextStyle(fontSize: 12, color: Colors.white), decoration: const InputDecoration(labelText: "الرابط (URL)", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: payloadCtrl, maxLines: 4, style: const TextStyle(fontSize: 12, color: Colors.amberAccent), decoration: const InputDecoration(labelText: "البيانات (Raw Payload)", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            
            // أزرار توليد الأكواد
            Wrap(
              spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  icon: const Icon(Icons.terminal, color: Colors.white), label: const Text("cURL", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    String curl = "curl -X ${log.method} '${urlCtrl.text}' \\\n     -H 'Content-Type: application/x-www-form-urlencoded' \\\n     -H 'Cookie: ${log.cookies}' \\\n     --data-raw '${payloadCtrl.text}'";
                    Clipboard.setData(ClipboardData(text: curl));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم نسخ كود cURL!")));
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  icon: const Icon(Icons.code, color: Colors.black), label: const Text("Python 🐍", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    // توليد كود بايثون متكامل!
                    String pyCode = '''
import requests

url = "${urlCtrl.text}"
payload = "${payloadCtrl.text}"
headers = {
  'Content-Type': 'application/x-www-form-urlencoded',
  'Cookie': '${log.cookies}'
}

response = requests.request("${log.method}", url, headers=headers, data=payload)
print(response.text)
''';
                    Clipboard.setData(ClipboardData(text: pyCode));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🐍 تم نسخ كود Python جاهز للتشغيل!")));
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                  icon: const Icon(Icons.send, color: Colors.black), label: const Text("إرسال من التطبيق", style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    String p = payloadCtrl.text.replaceAll("'", "\\'");
                    String code = "fetch('${urlCtrl.text}', {method: '${log.method}', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: '$p'}).then(r=>r.text()).then(t=>ExhxxLog.postMessage(JSON.stringify({type: 'REPEATER', method: '${log.method}', url: '${urlCtrl.text}', payload: '$p', response: t.substring(0,1000)})));";
                    _controller.runJavaScript(code);
                    Navigator.pop(ctx);
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
  // الواجهات (UI)
  // ==========================================
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
              IconButton(icon: const Icon(Icons.refresh, color: Colors.amberAccent), onPressed: () => _controller.reload()),
            ],
          ),
        ),
        Expanded(child: WebViewWidget(controller: _controller)),
      ],
    );
  }

  Widget _buildToolsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text("أنظمة الاستخبارات والأتمتة 🎛️", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
        const Divider(color: Colors.white24),
        SwitchListTile(activeColor: Colors.cyanAccent, title: const Text("📡 الرادار الشامل (Omni-Sniffer)"), subtitle: const Text("تشغيل اعتراض الطلبات (Forms, Fetch, XHR)"), value: _optOmniSniffer, onChanged: (v){ setState(() { _optOmniSniffer=v; _applyAllTools(); });}),
        SwitchListTile(activeColor: Colors.cyanAccent, title: const Text("🎙️ مختطف الكونسول (Console Hijack)"), value: _optConsoleHijack, onChanged: (v){ setState(() { _optConsoleHijack=v; _applyAllTools(); });}),
        SwitchListTile(activeColor: Colors.cyanAccent, title: const Text("🔓 فك حظر النسخ (Unlock Copy)"), value: _optUnlockRightClick, onChanged: (v){ setState(() { _optUnlockRightClick=v; _applyAllTools(); });}),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("🚀 تيربو بلوكر (Media Blocker)"), value: _optMediaBlocker, onChanged: (v){ setState(() { _optMediaBlocker=v; _applyAllTools(); });}),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("📜 التمرير السريع (Fast Scroll)"), value: _optAutoScroll, onChanged: (v){ setState(() { _optAutoScroll=v; _applyAllTools(); });}),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("🤖 النقار الجذري (Shadow Clicker)"), value: _optShadowClicker, onChanged: (v){ setState(() { _optShadowClicker=v; _applyAllTools(); });}),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("💻 مزيف الجهاز (Desktop Spoofer)"), value: _optSpoofer, onChanged: (v){ 
          setState(() { _optSpoofer=v; });
          _controller.setUserAgent(_optSpoofer ? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" : "");
          _controller.reload();
        }),
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
              const Text("NETWORK RADAR 📡", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.cyanAccent)),
              IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: () => setState((){ _netLogs.clear(); })),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _netLogs.length,
            itemBuilder: (ctx, i) {
              var log = _netLogs[i];
              Color typeColor = log.type == 'FORM' ? Colors.pinkAccent : (log.type == 'FETCH' ? Colors.greenAccent : Colors.cyanAccent);
              return Card(
                color: Colors.black, margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  title: Text("[${log.method}] ${log.url}", style: TextStyle(color: typeColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("Type: ${log.type}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), width: double.infinity, color: const Color(0xFF0A0A0A),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("RAW PAYLOAD:", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                          SelectableText(log.payload.isEmpty ? "None" : log.payload, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          const Divider(color: Colors.white24),
                          const Text("RESPONSE:", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                          SelectableText(log.response.isEmpty ? "Pending/None" : log.response, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                              icon: const Icon(Icons.settings_ethernet), label: const Text("خيارات التصدير (Python/cURL)"),
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

  Widget _buildSysLogsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10), color: const Color(0xFF111111), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("SYSTEM CONSOLE 💻", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
              IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: () => setState((){ _sysLogs.clear(); })),
            ]
          )
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _sysLogs.length,
            itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.all(8), child: SelectableText("> ${_sysLogs[i]}", style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12))),
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
          children: [_buildBrowserTab(), _buildToolsTab(), _buildNetworkTab(), _buildSysLogsTab()],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.cyanAccent, 
        unselectedItemColor: Colors.grey[700], 
        backgroundColor: const Color(0xFF111111),
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() { _currentIndex = idx; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.public), label: "Browser"),
          BottomNavigationBarItem(icon: Icon(Icons.construction), label: "Tools"),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: "Network"),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: "Console"),
        ],
      ),
    );
  }
}
