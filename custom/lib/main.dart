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
      title: 'EXHXX Ultimate Radar',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F0F0F)),
        colorScheme: const ColorScheme.dark(primary: Colors.blueAccent, secondary: Colors.pinkAccent),
      ),
      home: const MainScreen(),
    );
  }
}

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

  // حالات الأدوات
  bool _optOmniSniffer = false;
  bool _optMediaBlocker = false;
  bool _optAutoScroll = false;
  bool _optShadowClicker = false;
  bool _optConsoleHijack = false;
  bool _optSpoofer = false;
  bool _optAntiDebug = false;
  bool _optUnlockRightClick = false;

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
              _netLogs.insert(0, NetworkLog(data['type'], data['method'], data['url'], data['payload'] ?? '', data['response'] ?? ''));
            });
          }
        } catch(e) {
          setState(() { _sysLogs.insert(0, msg.message); });
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) { _injectCoreRadar(); },
        onPageFinished: (url) { _applyAllTools(); },
      ))
      ..loadRequest(Uri.parse(_urlController.text));
  }

  // ==========================================
  // النواة: الرادار الشامل (صيد النماذج، الروابط، والردود)
  // ==========================================
  void _injectCoreRadar() {
    if (!_optOmniSniffer) return;

    _controller.runJavaScript(r'''
      if(!window.__exhxxCoreHooked) {
        window.__exhxxCoreHooked = true;

        // دالة آمنة لإرسال البيانات للفلاتر
        function sendToFlutter(type, method, url, payload, response) {
          if(url.includes('google-analytics') || url.includes('g/collect')) return; // تجاهل تتبع جوجل
          
          let fullUrl = url;
          if(url.startsWith('/')) fullUrl = window.location.origin + url; // إكمال الروابط الناقصة

          let msg = {
             type: type, method: method, url: fullUrl, 
             payload: payload ? String(payload) : '', 
             response: response ? String(response) : ''
          };
          try { ExhxxLog.postMessage(JSON.stringify(msg)); } catch(e){}
        }

        // 1. صيد النماذج (Forms - تسجيل الدخول والرشق)
        document.addEventListener('submit', function(e) {
          if(e.target && e.target.tagName === 'FORM') {
            let formData = new FormData(e.target);
            let obj = {};
            formData.forEach((value, key) => { obj[key] = value; });
            sendToFlutter('FORM', e.target.method.toUpperCase() || 'POST', e.target.action || window.location.href, JSON.stringify(obj, null, 2), 'Pending...');
          }
        }, true);

        // 2. صيد Fetch (مع الردود)
        const origFetch = window.fetch;
        window.fetch = async function(...args) {
          let url = typeof args[0] === 'string' ? args[0] : (args[0] && args[0].url ? args[0].url : 'Unknown');
          let method = (args[1] && args[1].method) ? args[1].method : 'GET';
          let body = (args[1] && args[1].body) ? args[1].body : '';
          
          try {
            let res = await origFetch.apply(this, args);
            let clone = res.clone();
            clone.text().then(text => {
              sendToFlutter('FETCH', method, url, typeof body === 'string' ? body : 'Binary/JSON', text.substring(0,2000));
            }).catch(e => {
              sendToFlutter('FETCH', method, url, typeof body === 'string' ? body : 'Binary', 'Unreadable Response');
            });
            return res;
          } catch(err) {
             sendToFlutter('FETCH', method, url, typeof body === 'string' ? body : 'Binary', 'Error: ' + err.message);
             throw err;
          }
        };

        // 3. صيد XHR (مع الردود)
        const origOpen = XMLHttpRequest.prototype.open;
        const origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url) {
          this._exMethod = method;
          this._exUrl = url;
          origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function(body) {
          this.addEventListener('load', function() {
            sendToFlutter('XHR', this._exMethod, this._exUrl, typeof body === 'string' ? body : 'Binary', this.responseText ? this.responseText.substring(0,2000) : '');
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
  // أدوات الاستخراج المباشر (Quick Extraction)
  // ==========================================
  void _harvestCookies() async {
    final result = await _controller.runJavaScriptReturningResult("document.cookie;");
    setState(() { _sysLogs.insert(0, "[COOKIE] " + result.toString().replaceAll('"', '')); });
    _currentIndex = 3; // الذهاب للكونسول
  }

  void _extractLiveDOM() async {
    final result = await _controller.runJavaScriptReturningResult("document.documentElement.outerHTML;");
    setState(() { _sysLogs.insert(0, "[DOM SOURCE] " + result.toString().substring(0, 500) + "..."); });
    _currentIndex = 3;
  }

  void _nukeStorage() async {
    await _controller.clearCache();
    await _controller.clearLocalStorage();
    setState(() { _sysLogs.insert(0, "[SYSTEM] ☢️ تم تدمير الكاش والبيانات! المتصفح نظيف."); });
    _controller.reload();
    _currentIndex = 3;
  }

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
                    String p = payloadCtrl.text.replaceAll("'", "\\'");
                    String code = "fetch('${urlCtrl.text}', {method: '${log.method}', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: '$p'}).then(r=>r.text()).then(t=>ExhxxLog.postMessage(JSON.stringify({type: 'REPEATER', method: '${log.method}', url: '${urlCtrl.text}', payload: '$p', response: t.substring(0,1000)})));";
                    _controller.runJavaScript(code);
                    Navigator.pop(ctx);
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
          ListTile(leading: const Icon(Icons.delete, color: Colors.redAccent), title: const Text("تصفير الجلسة (تبديل حساب)"), onTap: () async {
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
  // صفحات التطبيق الـ 4 (Tabs)
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
        const SizedBox(height: 15),
        const Text("عمليات السحب النووية ⚡", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
        const Divider(color: Colors.white24),
        ListTile(leading: const Icon(Icons.cookie, color: Colors.orange), title: const Text("سحب الكوكيز (Harvest Cookies)"), onTap: _harvestCookies),
        ListTile(leading: const Icon(Icons.html, color: Colors.green), title: const Text("سحب الكود الحي (Live DOM)"), onTap: _extractLiveDOM),
        ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text("المسح النووي (Nuke Data)"), onTap: _nukeStorage),
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
                          const Text("PAYLOAD:", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                          SelectableText(log.payload.isEmpty ? "None" : log.payload, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          const Divider(color: Colors.white24),
                          const Text("RESPONSE:", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                          SelectableText(log.response.isEmpty ? "Pending/None" : log.response, style: const TextStyle(color: Colors.white, fontSize: 11)),
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
        Container(
          padding: const EdgeInsets.all(10), color: const Color(0xFF111111), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("SYSTEM & CONSOLE 💻", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
              IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: () => setState((){ _sysLogs.clear(); })),
            ]
          )
        ),
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
          children: [_buildBrowserTab(), _buildToolsTab(), _buildNetworkTab(), _buildSysLogsTab()],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent, 
        unselectedItemColor: Colors.grey[700], 
        backgroundColor: const Color(0xFF111111),
        type: BottomNavigationBarType.fixed, // ضروري حتى تظهر الـ 4 أزرار بشكل صحيح
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
