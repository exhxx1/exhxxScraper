import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() => runApp(const ExhxxFlawlessApp());

class ExhxxFlawlessApp extends StatelessWidget {
  const ExhxxFlawlessApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EXHXX Command Center v11',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050505),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF111111)),
        colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent, secondary: Colors.pinkAccent),
      ),
      home: const MainScreen(),
    );
  }
}

// كلاس تخزين سجلات الشبكة المتكامل
class NetworkLog {
  final String id, type, method, url, payload, response, cookies;
  NetworkLog(this.id, this.type, this.method, this.url, this.payload, this.response, this.cookies);
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

  // ترسانة الميزات (جميع الأدوات السابقة بدون حذف)
  bool _optOmniSniffer = true; // تفعيل الرادار افتراضياً بطلبك
  bool _optMediaBlocker = false;
  bool _optAutoScroll = false;
  bool _optShadowClicker = false;
  bool _optConsoleHijack = false;
  bool _optUnlockRightClick = false;
  bool _optAntiDebug = false;
  bool _optSpoofer = false;

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
              // التحقق إذا كان الطلب موجود مسبقاً لتحديث الرد (Response) بدل التكرار
              int existingIdx = _netLogs.indexWhere((element) => element.id == data['id']);
              if (existingIdx != -1) {
                _netLogs[existingIdx] = NetworkLog(
                  data['id'], data['type'], data['method'], data['url'], 
                  data['payload'] ?? _netLogs[existingIdx].payload, 
                  data['response'] ?? '', _currentCookies
                );
              } else {
                _netLogs.insert(0, NetworkLog(
                  data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  data['type'], data['method'], data['url'], data['payload'] ?? '', 
                  data['response'] ?? '', _currentCookies
                ));
              }
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
  // محرك الرادار المتطور (يصيد العودة والذهاب والخام)
  // ==========================================
  void _injectCoreRadar() {
    if (!_optOmniSniffer) return;

    _controller.runJavaScript(r'''
      if(!window.__exhxxCoreHooked) {
        window.__exhxxCoreHooked = true;

        function sendToFlutter(id, type, method, url, payload, response) {
          if(url.includes('google-analytics') || url.includes('g/collect')) return; 
          let fullUrl = url;
          if(url.startsWith('/')) fullUrl = window.location.origin + url;

          let msg = {
             id: id, type: type, method: method, url: fullUrl, 
             payload: payload ? String(payload) : '', 
             response: response ? String(response) : ''
          };
          try { ExhxxLog.postMessage(JSON.stringify(msg)); } catch(e){}
        }

        // 1. اختطاف وتأمين الـ Forms (الرشق والدخول) وسحب الرد حياً بالخلفية
        document.addEventListener('submit', async function(e) {
          if(e.target && e.target.tagName === 'FORM') {
            e.preventDefault(); 
            let form = e.target;
            let formData = new FormData(form);
            let formProps = new URLSearchParams(formData).toString(); 
            let reqId = 'form_' + Date.now();
            
            sendToFlutter(reqId, 'FORM', form.method.toUpperCase() || 'POST', form.action || window.location.href, formProps, 'جاري جلب رد السيرفر...');
            
            try {
               let res = await fetch(form.action || window.location.href, {
                  method: form.method || 'POST',
                  body: formProps,
                  headers: {'Content-Type': 'application/x-www-form-urlencoded'}
               });
               let text = await res.text();
               sendToFlutter(reqId, 'FORM', form.method.toUpperCase(), form.action || window.location.href, formProps, text.substring(0,3000));
               document.open(); document.write(text); document.close();
            } catch(err) {
               sendToFlutter(reqId, 'FORM', form.method, form.action, formProps, 'Error: ' + err.toString());
               form.submit(); 
            }
          }
        }, true);

        // 2. صيد Fetch مع الردود
        const origFetch = window.fetch;
        window.fetch = async function(...args) {
          let url = typeof args[0] === 'string' ? args[0] : (args[0] && args[0].url ? args[0].url : 'Unknown');
          let method = (args[1] && args[1].method) ? args[1].method : 'GET';
          let body = (args[1] && args[1].body) ? args[1].body : '';
          let reqId = 'fetch_' + Date.now() + Math.random();
          
          sendToFlutter(reqId, 'FETCH', method, url, typeof body === 'string' ? body : 'Data Payload', 'Pending...');
          
          try {
            let res = await origFetch.apply(this, args);
            let clone = res.clone();
            clone.text().then(text => {
              sendToFlutter(reqId, 'FETCH', method, url, typeof body === 'string' ? body : 'Data Payload', text.substring(0,3000));
            }).catch(e => {
              sendToFlutter(reqId, 'FETCH', method, url, 'Binary', 'Unreadable');
            });
            return res;
          } catch(err) {
             throw err;
          }
        };

        // 3. صيد XHR مع الردود
        const origOpen = XMLHttpRequest.prototype.open;
        const origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url) {
          this._exMethod = method;
          this._exUrl = url;
          this._exId = 'xhr_' + Date.now() + Math.random();
          origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function(body) {
          sendToFlutter(this._exId, 'XHR', this._exMethod, this._exUrl, typeof body === 'string' ? body : '', 'Waiting...');
          this.addEventListener('load', function() {
            sendToFlutter(this._exId, 'XHR', this._exMethod, this._exUrl, typeof body === 'string' ? body : '', this.responseText ? this.responseText.substring(0,3000) : '');
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
  // فك التشكيل وتحويل الداتا إلى قاموس بايثون نظيف ومفصل
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
  // العمليات السريعة (Quick Arsenal Actions)
  // ==========================================
  void _harvestCookies() async {
    final result = await _controller.runJavaScriptReturningResult("document.cookie;");
    setState(() { _sysLogs.insert(0, "[COOKIE] " + result.toString().replaceAll('"', '')); });
    _currentIndex = 3; 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🍪 تم سحب الكوكيز للكونسول!")));
  }

  void _extractLiveDOM() async {
    final result = await _controller.runJavaScriptReturningResult("document.documentElement.outerHTML;");
    setState(() { _sysLogs.insert(0, "[DOM SOURCE] " + result.toString().substring(0, 500) + "..."); });
    _currentIndex = 3;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📄 تم سحب الكود الحي للكونسول!")));
  }

  void _nukeStorage() async {
    await _controller.clearCache();
    await _controller.clearLocalStorage();
    setState(() { _sysLogs.insert(0, "[SYSTEM] ☢️ تم تصفير الكاش وبيانات المتصفح!"); });
    _controller.reload();
    _currentIndex = 0;
  }

  void _injectCustomJs() {
    TextEditingController jsCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("حقن كود JavaScript مخصص"),
      content: TextField(controller: jsCtrl, maxLines: 4, decoration: const InputDecoration(hintText: "alert('EXHXX V11');", border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("إلغاء")),
        ElevatedButton(onPressed: (){ _controller.runJavaScript(jsCtrl.text); Navigator.pop(ctx); }, child: const Text("حقن وتنفيذ 💉"))
      ],
    ));
  }

  // ميزة التعديل وتوليد الأكواد (MITM HUB)
  void _openAdvancedRepeater(NetworkLog log) {
    TextEditingController urlCtrl = TextEditingController(text: log.url);
    TextEditingController payloadCtrl = TextEditingController(text: log.payload);
    String rawPythonDict = _formatPayloadForPython(log.payload);

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF111111),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("مركز التحكم واستخراج الأكواد 🔁", style: TextStyle(fontSize: 16, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: urlCtrl, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(labelText: "الرابط URL", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: payloadCtrl, maxLines: 3, style: const TextStyle(fontSize: 11, color: Colors.amberAccent), decoration: const InputDecoration(labelText: "البيانات Payload الخام", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  icon: const Icon(Icons.terminal), label: const Text("نسخ cURL"),
                  onPressed: () {
                    String curl = "curl -X ${log.method} '${urlCtrl.text}' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Cookie: ${log.cookies}' --data-raw '${payloadCtrl.text}'";
                    Clipboard.setData(ClipboardData(text: curl)); Navigator.pop(ctx);
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  icon: const Icon(Icons.code, color: Colors.black), label: const Text("بايثون خام 🐍", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    String pyCode = '''import requests\nimport re\nsession = requests.Session()\nurl = "${urlCtrl.text}"\npayload = $rawPythonDict\nheaders = {'Content-Type': 'application/x-www-form-urlencoded','User-Agent': 'Mozilla/5.0'}\n# التوكن يتحدث تلقائياً إذا وجد\ntry:\n    res = session.get(url)\n    token = re.search(r'name="_csrf"\\\\s+value="([^"]+)"', res.text).group(1)\n    if '_csrf' in payload: payload['_csrf'] = token\nexcept: pass\nresponse = session.request("${log.method}", url, headers=headers, data=payload)\nprint(response.text[:2000])''';
                    Clipboard.setData(ClipboardData(text: pyCode)); Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🐍 تم نسخ السكربت الخام للبايثون!")));
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                  icon: const Icon(Icons.send, color: Colors.black), label: const Text("إرسال من التطبيق"),
                  onPressed: () {
                    String p = payloadCtrl.text.replaceAll("'", "\\'");
                    String code = "fetch('${urlCtrl.text}', {method: '${log.method}', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: '$p'}).then(r=>r.text()).then(t=>ExhxxLog.postMessage(JSON.stringify({type: 'REPEATER', method: '${log.method}', url: '${urlCtrl.text}', payload: '$p', response: t.substring(0,1000)})));";
                    _controller.runJavaScript(code); Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      )
    );
  }

  // ==========================================
  // تصميم غرف العمليات الأربعة (UI Tabs)
  // ==========================================
  Widget _buildBrowserTab() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF111111), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
        const Text("أدوات الاستخبارات والشبكات (الرادار الأساسي) 📡", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
        const Divider(color: Colors.white24),
        SwitchListTile(activeColor: Colors.cyanAccent, title: const Text("📡 الرادار الشامل (Omni-Sniffer)"), subtitle: const Text("يسجل عمليات الرشق، الـ Forms والـ API والردود"), value: _optOmniSniffer, onChanged: (v){ setState(() { _optOmniSniffer=v; _injectCoreRadar(); });}),
        SwitchListTile(activeColor: Colors.cyanAccent, title: const Text("🎙️ مختطف الكونسول (Console Hijack)"), value: _optConsoleHijack, onChanged: (v){ setState(() { _optConsoleHijack=v; _applyAllTools(); });}),
        SwitchListTile(activeColor: Colors.cyanAccent, title: const Text("🔓 فك حظر النسخ (Unlock Copy)"), value: _optUnlockRightClick, onChanged: (v){ setState(() { _optUnlockRightClick=v; _applyAllTools(); });}),
        
        const SizedBox(height: 15),
        const Text("أدوات التحكم والأتمتة (Automation) 🤖", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
        const Divider(color: Colors.white24),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("🚀 تيربو بلوكر (Media Blocker)"), value: _optMediaBlocker, onChanged: (v){ setState(() { _optMediaBlocker=v; _applyAllTools(); });}),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("📜 التمرير السريع (Fast Scroll)"), value: _optAutoScroll, onChanged: (v){ setState(() { _optAutoScroll=v; _applyAllTools(); });}),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("🤖 النقار الجذري (Shadow Clicker)"), value: _optShadowClicker, onChanged: (v){ setState(() { _optShadowClicker=v; _applyAllTools(); });}),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("💻 مزيف الجهاز (Desktop Spoofer)"), value: _optSpoofer, onChanged: (v){ 
          setState(() { _optSpoofer=v; });
          _controller.setUserAgent(_optSpoofer ? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" : "");
          _controller.reload();
        }),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("🛡️ قاتل الحمايات (Anti-Debug)"), value: _optAntiDebug, onChanged: (v){ setState(() { _optAntiDebug=v; _applyAllTools(); });}),

        const SizedBox(height: 15),
        const Text("عمليات التدخل واستخراج البيانات ⚡", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
        const Divider(color: Colors.white24),
        ListTile(leading: const Icon(Icons.cookie, color: Colors.orange), title: const Text("سحب كل الكوكيز (Harvest Cookies)"), onTap: _harvestCookies),
        ListTile(leading: const Icon(Icons.html, color: Colors.green), title: const Text("سحب كود الـ HTML الحي (Live DOM)"), onTap: _extractLiveDOM),
        ListTile(leading: const Icon(Icons.code, color: Colors.purpleAccent), title: const Text("حقن سكربت JS مخصص (Inject Code)"), onTap: _injectCustomJs),
        ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text("المسح النووي وتصفير الهوية (Nuke Data)"), onTap: _nukeStorage),
        const SizedBox(height: 40),
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
              const Text("RAW RADAR TRAFFIC 📡", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.cyanAccent)),
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
                  title: Text("[${log.method}] ${log.url}", style: TextStyle(color: typeColor, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("Source: ${log.type}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), width: double.infinity, color: const Color(0xFF0A0A0A),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("RAW PAYLOAD (البيانات الخام):", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                          SelectableText(_formatPayloadForPython(log.payload), style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
                          const Divider(color: Colors.white24),
                          const Text("SERVER RESPONSE (رد السيرفر):", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                          SelectableText(log.response, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                              icon: const Icon(Icons.code), label: const Text("خيارات التصدير والتعديل (Python/cURL)"),
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
              const Text("SYSTEM & CONSOLE LOGS 💻", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
              IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: () => setState((){ _sysLogs.clear(); })),
            ]
          )
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _sysLogs.length,
            itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.all(8), child: SelectableText("> ${_sysLogs[i]}", style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11))),
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
        selectedItemColor: Colors.cyanAccent, unselectedItemColor: Colors.grey[700], backgroundColor: const Color(0xFF111111),
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
