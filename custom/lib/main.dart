import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';

void main() => runApp(const ExhxxEmperorApp());

class ExhxxEmperorApp extends StatelessWidget {
  const ExhxxEmperorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EXHXX Emperor',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070913), 
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0B0F1C), elevation: 0),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF00F0FF), secondary: Color(0xFFB026FF)),
        cardColor: const Color(0xFF111625),
        dividerColor: Colors.white10,
      ),
      home: const MainScreen(),
    );
  }
}

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
  
  // الخزانة السريعة
  final List<NetworkLog> _savedPayloads = [];
  final Map<String, String> _savedSessions = {};

  // مفاتيح ترسانة الأدوات
  bool _optOmniSniffer = true;
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
              int existingIdx = _netLogs.indexWhere((element) => element.id == data['id']);
              if (existingIdx != -1) {
                _netLogs[existingIdx] = NetworkLog(data['id'], data['type'], data['method'], data['url'], data['payload'] ?? _netLogs[existingIdx].payload, data['response'] ?? '', _currentCookies);
              } else {
                _netLogs.insert(0, NetworkLog(data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(), data['type'], data['method'], data['url'], data['payload'] ?? '', data['response'] ?? '', _currentCookies));
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
  // النواة: رادار الاعتراض الشامل (مستحيل يفوت طلب)
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
          try { ExhxxLog.postMessage(JSON.stringify({id: id, type: type, method: method, url: fullUrl, payload: payload ? String(payload) : '', response: response ? String(response) : ''})); } catch(e){}
        }

        document.addEventListener('submit', async function(e) {
          if(e.target && e.target.tagName === 'FORM') {
            e.preventDefault(); 
            let form = e.target;
            let formData = new FormData(form);
            let formProps = new URLSearchParams(formData).toString(); 
            let reqId = 'form_' + Date.now();
            sendToFlutter(reqId, 'نموذج (FORM)', form.method.toUpperCase() || 'POST', form.action || window.location.href, formProps, '⏳ جاري جلب رد السيرفر...');
            try {
               let res = await fetch(form.action || window.location.href, { method: form.method || 'POST', body: formProps, headers: {'Content-Type': 'application/x-www-form-urlencoded'} });
               let text = await res.text();
               sendToFlutter(reqId, 'نموذج (FORM)', form.method.toUpperCase(), form.action || window.location.href, formProps, text.substring(0,3000));
               document.open(); document.write(text); document.close();
            } catch(err) {
               sendToFlutter(reqId, 'نموذج (FORM)', form.method, form.action, formProps, 'خطأ: ' + err.toString());
               form.submit(); 
            }
          }
        }, true);

        const origFetch = window.fetch;
        window.fetch = async function(...args) {
          let url = typeof args[0] === 'string' ? args[0] : (args[0] && args[0].url ? args[0].url : 'Unknown');
          let method = (args[1] && args[1].method) ? args[1].method : 'GET';
          let body = (args[1] && args[1].body) ? args[1].body : '';
          let reqId = 'fetch_' + Date.now() + Math.random();
          sendToFlutter(reqId, 'خلفية (FETCH)', method, url, typeof body === 'string' ? body : 'بيانات مشفرة', '⏳ قيد الانتظار...');
          try {
            let res = await origFetch.apply(this, args);
            let clone = res.clone();
            clone.text().then(text => { sendToFlutter(reqId, 'خلفية (FETCH)', method, url, typeof body === 'string' ? body : 'بيانات مشفرة', text.substring(0,3000)); }).catch(e => { sendToFlutter(reqId, 'خلفية (FETCH)', method, url, 'ملف ثنائي', 'لا يمكن قراءة الرد'); });
            return res;
          } catch(err) { throw err; }
        };

        const origOpen = XMLHttpRequest.prototype.open;
        const origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url) {
          this._exMethod = method; this._exUrl = url; this._exId = 'xhr_' + Date.now() + Math.random();
          origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function(body) {
          sendToFlutter(this._exId, 'نبض (XHR)', this._exMethod, this._exUrl, typeof body === 'string' ? body : '', '⏳ بانتظار الرد...');
          this.addEventListener('load', function() { sendToFlutter(this._exId, 'نبض (XHR)', this._exMethod, this._exUrl, typeof body === 'string' ? body : '', this.responseText ? this.responseText.substring(0,3000) : ''); });
          origSend.apply(this, arguments);
        };
      }
    ''');
  }

  void _applyAllTools() {
    _injectCoreRadar();
    if (_optMediaBlocker) _controller.runJavaScript("var s=document.createElement('style');s.innerHTML='img,video,iframe,canvas{display:none !important;} *{background-image:none !important;}';document.head.appendChild(s);");
    if (_optConsoleHijack) _controller.runJavaScript("if(!window.__exhxXConsole) { window.__exhxXConsole = true; const origLog = console.log; console.log = function() { ExhxxLog.postMessage('[سجل الموقع] ' + Array.from(arguments).join(' ')); origLog.apply(console, arguments); }; }");
    if (_optUnlockRightClick) _controller.runJavaScript("document.addEventListener('contextmenu', e => e.stopPropagation(), true); document.addEventListener('selectstart', e => e.stopPropagation(), true); var s=document.createElement('style');s.innerHTML='*{user-select: auto !important; -webkit-user-select: auto !important;}';document.head.appendChild(s);");
    if (_optAntiDebug) _controller.runJavaScript("console.warn=function(){}; console.error=function(){};");
    if (_optAutoScroll) _controller.runJavaScript("if(!window.vtSc) window.vtSc = setInterval(()=>window.scrollBy({top:500, behavior:'smooth'}), 800);"); else _controller.runJavaScript("if(window.vtSc) clearInterval(window.vtSc); window.vtSc=null;");
    if (_optShadowClicker) _controller.runJavaScript("if(!window.vtClk) window.vtClk = setInterval(()=>{ function traverse(n) { let res=[]; if(!n) return res; if(n.nodeType===1) res.push(n); if(n.shadowRoot) res.push(...traverse(n.shadowRoot)); let c = n.shadowRoot ? n.shadowRoot.childNodes : n.childNodes; if(c) for(let i=0; i<c.length; i++) res.push(...traverse(c[i])); return res; } let all = traverse(document.documentElement); let btns = all.filter(x => (x.tagName==='VT-UI-BUTTON'||x.tagName==='BUTTON') && (x.textContent||'').trim()==='...'); if(btns.length>0) { btns[0].scrollIntoView({block:'center'}); setTimeout(()=>btns[0].click(), 200); } }, 1500);"); else _controller.runJavaScript("if(window.vtClk) clearInterval(window.vtClk); window.vtClk=null;");
  }

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
  // مدفع الهجمات الآلي وتوليد السكربتات (المعرب بالكامل)
  // ==========================================
  void _openEnterpriseRepeater(NetworkLog log) {
    TextEditingController urlCtrl = TextEditingController(text: log.url);
    TextEditingController payloadCtrl = TextEditingController(text: log.payload);
    TextEditingController customHeadersCtrl = TextEditingController(text: "Content-Type: application/x-www-form-urlencoded\nX-Forwarded-For: 192.168.1.1");
    TextEditingController repeatCountCtrl = TextEditingController(text: "1");
    TextEditingController delayCtrl = TextEditingController(text: "500");

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF070913),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("مدفع الهجمات السيبراني 🚀", style: TextStyle(fontSize: 20, color: Color(0xFF00F0FF), fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(controller: urlCtrl, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(labelText: "رابط الهدف (Target URL)", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: payloadCtrl, maxLines: 3, style: const TextStyle(fontSize: 11, color: Colors.orangeAccent), decoration: const InputDecoration(labelText: "البيانات الخام (Raw Payload)", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: customHeadersCtrl, maxLines: 2, style: const TextStyle(fontSize: 11, color: Colors.greenAccent), decoration: const InputDecoration(labelText: "تزييف الهيدرات (Custom Headers)", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: repeatCountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "عدد التكرار", border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: delayCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "تأخير (ملي ثانية)", border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF111625), side: const BorderSide(color: Color(0xFF00F0FF))),
                    icon: const Icon(Icons.save, color: Color(0xFF00F0FF)), label: const Text("حفظ في الخزانة 🗄️", style: TextStyle(color: Color(0xFF00F0FF))),
                    onPressed: () {
                      setState(() { _savedPayloads.add(NetworkLog(DateTime.now().toString(), log.type, log.method, urlCtrl.text, payloadCtrl.text, "", log.cookies)); });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم حفظ الطلب في الخزانة بنجاح!")));
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    icon: const Icon(Icons.code, color: Colors.black), label: const Text("توليد بايثون 🐍", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      String pyCode = '''import requests\nimport re\n\nprint("⏳ جاري تهيئة الهجوم...")\nsession = requests.Session()\nurl = "${urlCtrl.text}"\npayload = ${_formatPayloadForPython(payloadCtrl.text)}\nheaders = {'Content-Type': 'application/x-www-form-urlencoded','User-Agent': 'Mozilla/5.0'}\n\n# كاسر حماية التوكن الذكي\ntry:\n    res = session.get(url)\n    token = re.search(r'name="_csrf"\\\\s+value="([^"]+)"', res.text).group(1)\n    if '_csrf' in payload: payload['_csrf'] = token\nexcept: pass\n\nprint("🚀 جاري ضرب السيرفر...")\nresponse = session.request("${log.method}", url, headers=headers, data=payload)\nprint("✅ رد السيرفر:\\n", response.text[:2000])''';
                      Clipboard.setData(ClipboardData(text: pyCode)); Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🐍 تم نسخ السكربت! افتح Pydroid 3 والصقه.")));
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB026FF), foregroundColor: Colors.white),
                    icon: const Icon(Icons.local_fire_department), label: const Text("إطلاق الهجوم الآلي 🚀"),
                    onPressed: () async {
                      int count = int.tryParse(repeatCountCtrl.text) ?? 1;
                      int delay = int.tryParse(delayCtrl.text) ?? 500;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🚀 جاري قصف السيرفر بـ $count طلبات...")));
                      
                      String p = payloadCtrl.text.replaceAll("'", "\\'");
                      for(int i=0; i<count; i++) {
                        String code = "fetch('${urlCtrl.text}', {method: '${log.method}', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: '$p'}).then(r=>r.text()).then(t=>ExhxxLog.postMessage(JSON.stringify({type: 'هجوم آلي (FUZZER)', method: '${log.method}', url: '${urlCtrl.text}', payload: '$p', response: t.substring(0,500)})));";
                        _controller.runJavaScript(code);
                        if(i < count - 1) await Future.delayed(Duration(milliseconds: delay));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      )
    );
  }

  // ==========================================
  // أدوات السحب المعمقة (Extraction Tools)
  // ==========================================
  void _extractAllLinks() async {
    final res = await _controller.runJavaScriptReturningResult("Array.from(document.querySelectorAll('a')).map(a => a.href).filter(h => h).join('\\n');");
    setState(() { _sysLogs.insert(0, "[روابط الموقع] \n" + res.toString().replaceAll('"', '')); });
    _currentIndex = 4;
  }
  void _extractAllImages() async {
    final res = await _controller.runJavaScriptReturningResult("Array.from(document.querySelectorAll('img')).map(i => i.src).filter(s => s).join('\\n');");
    setState(() { _sysLogs.insert(0, "[صور الموقع] \n" + res.toString().replaceAll('"', '')); });
    _currentIndex = 4;
  }

  // ==========================================
  // واجهات الإمبراطور (UI Tabs)
  // ==========================================
  Widget _buildBrowserTab() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF111625), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(child: TextField(
                controller: _urlController, style: const TextStyle(fontSize: 14, color: Colors.white),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15), filled: true, fillColor: const Color(0xFF070913),
                  hintText: "أدخل رابط الهدف...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onSubmitted: (val) { if(!val.startsWith("http")) val = "https://" + val; _controller.loadRequest(Uri.parse(val)); },
              )),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFFB026FF)]), borderRadius: BorderRadius.circular(12)),
                child: IconButton(icon: const Icon(Icons.rocket_launch, color: Colors.white), onPressed: () {
                  String val = _urlController.text; if(!val.startsWith("http")) val = "https://" + val; _controller.loadRequest(Uri.parse(val));
                }),
              ),
            ],
          ),
        ),
        Expanded(child: WebViewWidget(controller: _controller)),
      ],
    );
  }

  Widget _buildToolsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("أنظمة التجسس والاعتراض 📡", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00F0FF), letterSpacing: 1)),
        const SizedBox(height: 10),
        Card(color: const Color(0xFF111625), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Column(children: [
          SwitchListTile(activeColor: const Color(0xFF00F0FF), title: const Text("الرادار السيبراني الشامل"), subtitle: const Text("يعترض كل شيء بذكاء"), value: _optOmniSniffer, onChanged: (v){ setState(() { _optOmniSniffer=v; _injectCoreRadar(); });}),
          SwitchListTile(activeColor: const Color(0xFF00F0FF), title: const Text("مختطف الكونسول السري"), value: _optConsoleHijack, onChanged: (v){ setState(() { _optConsoleHijack=v; _applyAllTools(); });}),
          SwitchListTile(activeColor: const Color(0xFF00F0FF), title: const Text("فك حظر النسخ والتحديد"), value: _optUnlockRightClick, onChanged: (v){ setState(() { _optUnlockRightClick=v; _applyAllTools(); });}),
        ])),
        const SizedBox(height: 20),
        const Text("أنظمة الأتمتة والروبوت 🤖", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB026FF), letterSpacing: 1)),
        const SizedBox(height: 10),
        Card(color: const Color(0xFF111625), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Column(children: [
          SwitchListTile(activeColor: const Color(0xFFB026FF), title: const Text("حاجب الوسائط التيربو"), value: _optMediaBlocker, onChanged: (v){ setState(() { _optMediaBlocker=v; _applyAllTools(); });}),
          SwitchListTile(activeColor: const Color(0xFFB026FF), title: const Text("التمرير اللانهائي الذكي"), value: _optAutoScroll, onChanged: (v){ setState(() { _optAutoScroll=v; _applyAllTools(); });}),
          SwitchListTile(activeColor: const Color(0xFFB026FF), title: const Text("نقار أزرار الظل السحري"), value: _optShadowClicker, onChanged: (v){ setState(() { _optShadowClicker=v; _applyAllTools(); });}),
          SwitchListTile(activeColor: const Color(0xFFB026FF), title: const Text("قاتل الحمايات والتتبع"), value: _optAntiDebug, onChanged: (v){ setState(() { _optAntiDebug=v; _applyAllTools(); });}),
          SwitchListTile(activeColor: const Color(0xFFB026FF), title: const Text("تزييف بصمة الجهاز (كمبيوتر)"), value: _optSpoofer, onChanged: (v){ setState(() { _optSpoofer=v; _controller.setUserAgent(_optSpoofer ? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" : ""); _controller.reload(); });}),
        ])),
        const SizedBox(height: 20),
        const Text("عمليات السحب النووية ⚡", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orangeAccent, letterSpacing: 1)),
        const SizedBox(height: 10),
        Card(color: const Color(0xFF111625), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Column(children: [
          ListTile(leading: const Icon(Icons.link, color: Colors.blueAccent), title: const Text("سحب جميع الروابط بالموقع"), onTap: _extractAllLinks),
          ListTile(leading: const Icon(Icons.image, color: Colors.pinkAccent), title: const Text("سحب جميع صور الموقع"), onTap: _extractAllImages),
          ListTile(leading: const Icon(Icons.cookie, color: Colors.orange), title: const Text("حفظ جلسة الكوكيز في الخزانة"), onTap: () async {
            final res = await _controller.runJavaScriptReturningResult("document.cookie;");
            setState(() { _savedSessions["حساب_${DateTime.now().minute}:${DateTime.now().second}"] = res.toString().replaceAll('"', ''); });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم حفظ الجلسة بنجاح!")));
          }),
          ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text("تدمير التخزين وتصفير الموقع"), onTap: () async {
            await _controller.clearCache(); await _controller.clearLocalStorage(); _controller.reload();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("☢️ تم مسح بيانات الموقع!")));
          }),
        ])),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildNetworkTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), color: const Color(0xFF0B0F1C),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("رادار الشبكات 📡", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF00F0FF))),
              IconButton(icon: const Icon(Icons.delete_sweep, color: Color(0xFFB026FF)), onPressed: () => setState((){ _netLogs.clear(); })),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _netLogs.length,
            itemBuilder: (ctx, i) {
              var log = _netLogs[i];
              Color typeColor = log.type.contains('FORM') ? const Color(0xFFB026FF) : (log.type.contains('FUZZER') ? Colors.orangeAccent : const Color(0xFF00F0FF));
              return Card(
                color: const Color(0xFF111625), margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.white10)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text("[${log.method}] ${log.url}", style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text("النوع: ${log.type}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12), width: double.infinity, color: const Color(0xFF070913),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("البيانات المرسلة (RAW PAYLOAD):", style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            SelectableText(_formatPayloadForPython(log.payload), style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
                            const SizedBox(height: 10),
                            const Text("رد السيرفر (RESPONSE):", style: TextStyle(color: Color(0xFFB026FF), fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            SelectableText(log.response, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 15),
                            Center(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F0FF), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                icon: const Icon(Icons.flash_on), label: const Text("تعديل وإطلاق هجوم 🚀", style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () => _openEnterpriseRepeater(log),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildVaultTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF00F0FF), labelColor: Color(0xFF00F0FF), unselectedLabelColor: Colors.white54,
            tabs: [Tab(text: "بنك الثغرات 📚"), Tab(text: "خزانة الحسابات 🗄️")],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView.builder(
                  itemCount: _savedPayloads.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: const Icon(Icons.api, color: Color(0xFF00F0FF)),
                    title: Text(_savedPayloads[i].url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    subtitle: const Text("طلب محفوظ"),
                    trailing: IconButton(icon: const Icon(Icons.play_arrow, color: Colors.greenAccent), onPressed: () => _openEnterpriseRepeater(_savedPayloads[i])),
                  ),
                ),
                ListView.builder(
                  itemCount: _savedSessions.length,
                  itemBuilder: (ctx, i) {
                    String key = _savedSessions.keys.elementAt(i);
                    return ListTile(
                      leading: const Icon(Icons.security, color: Colors.orangeAccent),
                      title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("جلسة كوكيز جاهزة"),
                      trailing: IconButton(icon: const Icon(Icons.restore), onPressed: () {
                        _controller.runJavaScript("document.cookie = '${_savedSessions[key]}';");
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ تم استرجاع $key بنجاح!")));
                        _controller.reload();
                      }),
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSysLogsTab() {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(16), color: const Color(0xFF0B0F1C), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("السجلات والكونسول 💻", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54, fontSize: 16)), IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => setState((){ _sysLogs.clear(); }))])),
        Expanded(child: ListView.builder(itemCount: _sysLogs.length, itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.all(8), child: SelectableText("> ${_sysLogs[i]}", style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11)))))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: [_buildBrowserTab(), _buildToolsTab(), _buildNetworkTab(), _buildVaultTab(), _buildSysLogsTab()])),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF00F0FF), unselectedItemColor: Colors.white30, backgroundColor: const Color(0xFF0B0F1C),
        type: BottomNavigationBarType.fixed, showUnselectedLabels: true, selectedFontSize: 11, unselectedFontSize: 10,
        onTap: (idx) => setState(() { _currentIndex = idx; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.language), label: "متصفح"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "ترسانة"),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: "رادار"),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: "خزانة"),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: "سجلات"),
        ],
      ),
    );
  }
}
