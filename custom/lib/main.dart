import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';

void main() => runApp(const ExhxxMatrixApp());

class ExhxxMatrixApp extends StatelessWidget {
  const ExhxxMatrixApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EXHXX The Matrix',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030A05), // Deep Matrix Green/Black
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF06140A), elevation: 0),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF00FF41), secondary: Color(0xFF008F11)),
        cardColor: const Color(0xFF0B1F10),
        dividerColor: const Color(0xFF00FF41).withOpacity(0.2),
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 12, fontFamily: 'monospace')),
      ),
      home: const MainScreen(),
    );
  }
}

class UnifiedLog {
  final String id, category, method, urlOrTitle, payload, response;
  final DateTime timestamp;
  UnifiedLog({required this.id, required this.category, required this.method, required this.urlOrTitle, required this.payload, required this.response, required this.timestamp});
}

class ToolItem {
  final String category, title, description, script;
  final IconData icon;
  final Color color;
  ToolItem({required this.category, required this.title, required this.description, required this.script, required this.icon, required this.color});
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
  final TextEditingController _searchController = TextEditingController();
  
  final List<UnifiedLog> _unifiedLogs = [];
  final List<UnifiedLog> _vaultPayloads = [];
  final Map<String, String> _vaultSessions = {};

  String _activeFilter = 'الكل'; 
  bool _optOmniSniffer = true;
  String _searchQuery = "";

  late List<ToolItem> _allTools;

  @override
  void initState() {
    super.initState();
    _initTools();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('ExhxxLog', onMessageReceived: (msg) {
        try {
          var data = jsonDecode(msg.message);
          setState(() {
            int existingIdx = _unifiedLogs.indexWhere((element) => element.id == data['id']);
            if (existingIdx != -1) {
              _unifiedLogs[existingIdx] = UnifiedLog(
                id: data['id'], category: data['category'] ?? 'NETWORK', method: data['method'] ?? '', 
                urlOrTitle: data['url'] ?? '', payload: data['payload'] ?? _unifiedLogs[existingIdx].payload, 
                response: data['response'] ?? '', timestamp: _unifiedLogs[existingIdx].timestamp
              );
            } else {
              _unifiedLogs.insert(0, UnifiedLog(
                id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                category: data['category'] ?? 'SYSTEM', method: data['method'] ?? '',
                urlOrTitle: data['url'] ?? data['title'] ?? 'Log', payload: data['payload'] ?? '',
                response: data['response'] ?? '', timestamp: DateTime.now()
              ));
            }
          });
        } catch(e) {}
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) { _injectCoreRadar(); },
      ))
      ..loadRequest(Uri.parse(_urlController.text));
  }

  // ==========================================
  // قاعدة بيانات الأدوات (Matrix Database)
  // ==========================================
  void _initTools() {
    _allTools = [
      // 1. الشبكات العميقة
      ToolItem(category: "الشبكات", title: "كشف مسارات API", description: "يستخرج روابط الـ API المخفية", icon: Icons.api, color: Colors.cyan, script: "Array.from(document.body.innerText.matchAll(/\\/api\\/v[1-9]\\/[a-zA-Z0-9_\\-\\/]+/g)).join('\\n');"),
      ToolItem(category: "الشبكات", title: "اعتراض GraphQL", description: "يجهز الكونسول لصيد GraphQL", icon: Icons.graphic_eq, color: Colors.purpleAccent, script: "console.log('جاهز لاصطياد GraphQL');"),
      
      // 2. التلاعب البصري (DOM)
      ToolItem(category: "تلاعب الواجهة", title: "القاتل بالنقرة (Click-to-Delete)", description: "انقر على أي عنصر لحذفه فوراً", icon: Icons.dangerous, color: Colors.redAccent, script: "window.__c2d = (e) => { e.preventDefault(); e.stopPropagation(); e.target.remove(); document.removeEventListener('click', window.__c2d, true); }; document.addEventListener('click', window.__c2d, true); 'تم التفعيل: المس أي شيء لحذفه!';"),
      ToolItem(category: "تلاعب الواجهة", title: "التعديل الحر (Design Mode)", description: "تعديل نصوص الموقع كملف وورد", icon: Icons.edit, color: Colors.greenAccent, script: "document.designMode = document.designMode === 'on' ? 'off' : 'on'; 'وضع التعديل: ' + document.designMode;"),
      ToolItem(category: "تلاعب الواجهة", title: "إظهار الأزرار المخفية", description: "يفضح عناصر المطورين المخفية", icon: Icons.visibility, color: Colors.amber, script: "document.querySelectorAll('*').forEach(e=>{if(getComputedStyle(e).display==='none'||getComputedStyle(e).opacity==='0')e.style.display='block';e.style.opacity='1';}); 'تم إظهار كل شيء';"),
      ToolItem(category: "تلاعب الواجهة", title: "كشف الباسوردات", description: "يحول النجوم لنص مقروء", icon: Icons.password, color: Colors.pink, script: "document.querySelectorAll('input[type=\"password\"]').forEach(i=>i.type='text'); 'تم فضح الباسوردات';"),

      // 3. الحصادة (Extraction)
      ToolItem(category: "الحصادة", title: "سحب الجداول لـ CSV", description: "يحول جداول الموقع إلى إكسل", icon: Icons.table_view, color: Colors.blueAccent, script: "let csv=[]; document.querySelectorAll('table tr').forEach(row=>{let cols=row.querySelectorAll('td,th'); let rowData=[]; cols.forEach(c=>rowData.push(c.innerText.trim())); csv.push(rowData.join(','));}); csv.join('\\n');"),
      ToolItem(category: "الحصادة", title: "سحب توكنات JWT", description: "يستخرج رموز الأمان", icon: Icons.key, color: Colors.orange, script: "Array.from(document.body.innerText.matchAll(/ey[A-Za-z0-9-_=]+\\.[A-Za-z0-9-_=]+\\.?[A-Za-z0-9-_.+/=]*/g)).join('\\n');"),
      ToolItem(category: "الحصادة", title: "سحب الإيميلات", description: "استخراج الإيميلات بالـ Regex", icon: Icons.email, color: Colors.blue, script: "Array.from(document.body.innerText.matchAll(/([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\\.[a-zA-Z0-9_-]+)/gi)).map(m=>m[0]).join('\\n');"),
      ToolItem(category: "الحصادة", title: "سحب حقول CSRF", description: "يفضح توكنات الحماية", icon: Icons.security, color: Colors.teal, script: "Array.from(document.querySelectorAll('input[type=\"hidden\"]')).map(i => i.name + ' = ' + i.value).join('\\n');"),
      ToolItem(category: "الحصادة", title: "سحب روابط الصور", description: "يستخرج الـ SRC للصور", icon: Icons.image, color: Colors.indigo, script: "Array.from(document.querySelectorAll('img')).map(i => i.src).join('\\n');"),
      
      // 4. التخفي (Stealth)
      ToolItem(category: "التخفي", title: "تزييف الـ Canvas", description: "يمنع تتبع كرت الشاشة", icon: Icons.brush, color: Colors.lightGreen, script: "const og=HTMLCanvasElement.prototype.getContext;HTMLCanvasElement.prototype.getContext=function(t,a){const c=og.call(this,t,a);if(t==='2d'){const ogF=c.fillText;c.fillText=function(...args){return ogF.apply(this,args)};}return c;}; 'تم تزييف الكانفاس';"),
      ToolItem(category: "التخفي", title: "تزييف المعالج (Concurrency)", description: "يخفي عدد أنوية جهازك", icon: Icons.memory, color: Colors.deepOrange, script: "Object.defineProperty(navigator, 'hardwareConcurrency', {get: () => 8}); 'تم تغيير عدد الأنوية إلى 8';"),
      ToolItem(category: "التخفي", title: "قتل حمايات المتصفح (Webdriver)", description: "يدمر كشف البوتات", icon: Icons.shield, color: Colors.red, script: "Object.defineProperty(navigator, 'webdriver', {get: () => false}); 'تم مسح أثر البوتات';"),

      // 5. الأتمتة (Automation)
      ToolItem(category: "الأتمتة", title: "تعبئة نماذج وهمية شاملة", description: "يملأ الحقول ببيانات هاكر", icon: Icons.auto_fix_high, color: Colors.cyanAccent, script: "document.querySelectorAll('input').forEach(i=>{if(i.type==='email')i.value='admin@matrix.com';else if(i.type==='password')i.value='Neo_1337';else if(i.type==='text'||i.type==='search')i.value='Inject_Test';}); 'تم تعبئة النماذج';"),
      ToolItem(category: "الأتمتة", title: "نقار الظل الشامل", description: "يخترق ShadowDOM ويضغط", icon: Icons.ads_click, color: Colors.lime, script: "setInterval(()=>{let b=Array.from(document.querySelectorAll('*')).find(x=>x.shadowRoot); if(b) {let btn=b.shadowRoot.querySelector('button'); if(btn) btn.click();}}, 1000); 'مفعل';"),
      ToolItem(category: "الأتمتة", title: "إيقاف كل المؤقتات (Timers)", description: "يصفر عدادات الانتظار", icon: Icons.timer_off, color: Colors.pinkAccent, script: "let id=window.setTimeout(function(){},0); while(id--) {window.clearTimeout(id); window.clearInterval(id);} 'تم تصفير المؤقتات';"),
      ToolItem(category: "الأتمتة", title: "تصفير شامل (Nuke)", description: "يمسح الكاش والبيانات", icon: Icons.delete_forever, color: Colors.redAccent, script: "localStorage.clear(); sessionStorage.clear(); 'تم التصفير';"),
    ];
  }

  // ==========================================
  // النواة: صائد الماتريكس (WebSockets + XHR + Fetch + Forms)
  // ==========================================
  void _injectCoreRadar() {
    if (!_optOmniSniffer) return;
    _controller.runJavaScript(r'''
      if(!window.__exhxxMatrixHook) {
        window.__exhxxMatrixHook = true;
        
        function sendLog(id, category, method, url, payload, response) {
          if(url && (url.includes('google-analytics') || url.includes('g/collect'))) return; 
          let fullUrl = url; if(url && url.startsWith('/')) fullUrl = window.location.origin + url;
          try { ExhxxLog.postMessage(JSON.stringify({id: id, category: category, method: method, url: fullUrl, payload: payload ? String(payload) : '', response: response ? String(response) : ''})); } catch(e){}
        }

        // 1. اختطاف الـ WebSockets (جديد)
        const OrigWS = window.WebSocket;
        window.WebSocket = function(url, protocols) {
          let wsId = 'ws_' + Date.now();
          sendLog(wsId, 'WEBSOCKET', 'CONNECT', url, '', 'تم فتح قناة اتصال حية');
          const ws = new OrigWS(url, protocols);
          ws.addEventListener('message', function(e) { sendLog('ws_msg_'+Date.now(), 'WEBSOCKET', 'RECEIVE', url, '', e.data ? String(e.data).substring(0,1000) : ''); });
          const origSend = ws.send;
          ws.send = function(data) { sendLog('ws_snd_'+Date.now(), 'WEBSOCKET', 'SEND', url, typeof data === 'string' ? data : 'Binary Payload', ''); origSend.apply(this, arguments); };
          return ws;
        };

        // 2. اختطاف النماذج (Forms)
        document.addEventListener('submit', async function(e) {
          if(e.target && e.target.tagName === 'FORM') {
            e.preventDefault(); 
            let form = e.target;
            let formProps = new URLSearchParams(new FormData(form)).toString(); 
            let reqId = 'form_' + Date.now();
            sendLog(reqId, 'FORM', form.method.toUpperCase() || 'POST', form.action || window.location.href, formProps, '⏳ بانتظار السيرفر...');
            try {
               let res = await fetch(form.action || window.location.href, { method: form.method || 'POST', body: formProps, headers: {'Content-Type': 'application/x-www-form-urlencoded'} });
               let text = await res.text();
               sendLog(reqId, 'FORM', form.method.toUpperCase(), form.action || window.location.href, formProps, text.substring(0,3000));
               document.open(); document.write(text); document.close();
            } catch(err) { sendLog(reqId, 'FORM', form.method, form.action, formProps, 'خطأ: ' + err.toString()); form.submit(); }
          }
        }, true);

        // 3. اختطاف Fetch & XHR
        const origFetch = window.fetch;
        window.fetch = async function(...args) {
          let url = typeof args[0] === 'string' ? args[0] : (args[0] && args[0].url ? args[0].url : 'Unknown');
          let method = (args[1] && args[1].method) ? args[1].method : 'GET';
          let body = (args[1] && args[1].body) ? args[1].body : '';
          let reqId = 'fetch_' + Date.now() + Math.random();
          sendLog(reqId, 'FETCH', method, url, typeof body === 'string' ? body : 'Binary Data', '⏳ ...');
          try {
            let res = await origFetch.apply(this, args);
            let clone = res.clone();
            clone.text().then(text => sendLog(reqId, 'FETCH', method, url, typeof body === 'string' ? body : 'Binary Data', text.substring(0,3000))).catch(e => sendLog(reqId, 'FETCH', method, url, 'Binary', 'Unreadable'));
            return res;
          } catch(err) { throw err; }
        };

        const origOpen = XMLHttpRequest.prototype.open; const origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url) { this._exMethod = method; this._exUrl = url; this._exId = 'xhr_' + Date.now() + Math.random(); origOpen.apply(this, arguments); };
        XMLHttpRequest.prototype.send = function(body) {
          sendLog(this._exId, 'XHR', this._exMethod, this._exUrl, typeof body === 'string' ? body : '', '⏳ ...');
          this.addEventListener('load', function() { sendLog(this._exId, 'XHR', this._exMethod, this._exUrl, typeof body === 'string' ? body : '', this.responseText ? this.responseText.substring(0,3000) : ''); });
          origSend.apply(this, arguments);
        };
      }
    ''');
  }

  void _runTool(String name, String script, {bool notify = true}) async {
    final res = await _controller.runJavaScriptReturningResult(script);
    String resultStr = res.toString().replaceAll('"', '').trim();
    if (resultStr.isEmpty || resultStr == 'null') resultStr = "تم التنفيذ بصمت.";
    
    setState(() {
      _unifiedLogs.insert(0, UnifiedLog(id: 'tool_${DateTime.now().millisecondsSinceEpoch}', category: 'SYSTEM', method: 'TOOL', urlOrTitle: 'أداة: $name', payload: 'تم الاستدعاء', response: resultStr, timestamp: DateTime.now()));
    });
    
    if(notify) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ نُفذت: $name", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF00FF41)));
    setState(() { _activeFilter = 'سحب وأدوات'; _currentIndex = 1; }); 
  }

  String _formatPayload(String raw) {
    if (!raw.contains('=') || !raw.contains('&')) return raw;
    String dict = "{\n";
    for (var part in raw.split('&')) {
      var kv = part.split('=');
      if (kv.length >= 2) dict += '    "${Uri.decodeComponent(kv[0])}": "${Uri.decodeComponent(kv.sublist(1).join('='))}",\n';
    }
    return dict + "}";
  }

  // ==========================================
  // مدفع الهجمات (Repeater) + Python + Node.js
  // ==========================================
  void _openRepeater(UnifiedLog log) async {
    String cookies = (await _controller.runJavaScriptReturningResult("document.cookie;")).toString().replaceAll('"', '');
    TextEditingController urlCtrl = TextEditingController(text: log.urlOrTitle);
    TextEditingController payloadCtrl = TextEditingController(text: log.payload);

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF030A05),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("المصنع السيبراني (Bot Factory) 🤖", style: TextStyle(fontSize: 16, color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: urlCtrl, style: const TextStyle(fontSize: 11, color: Colors.white), decoration: const InputDecoration(labelText: "الرابط", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: payloadCtrl, maxLines: 3, style: const TextStyle(fontSize: 11, color: Color(0xFF00FF41)), decoration: const InputDecoration(labelText: "البيانات (Payload)", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06140A), side: const BorderSide(color: Color(0xFF00FF41))),
                  icon: const Icon(Icons.save, color: Color(0xFF00FF41), size: 16), label: const Text("حفظ", style: TextStyle(color: Color(0xFF00FF41), fontSize: 10)),
                  onPressed: () { setState(() { _vaultPayloads.add(log); }); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ حفظ في المصفوفة"))); },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  icon: const Icon(Icons.code, color: Colors.black, size: 16), label: const Text("Python 🐍", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                  onPressed: () {
                    String pyCode = '''import requests\nimport re\n\nurl = "${urlCtrl.text}"\npayload = ${_formatPayload(payloadCtrl.text)}\nheaders = {\n  'Content-Type': 'application/x-www-form-urlencoded',\n  'User-Agent': 'Mozilla/5.0',\n  'Cookie': '$cookies'\n}\n\nsession = requests.Session()\nres = session.get(url)\nmatch = re.search(r'name="_csrf"\\\\s+value="([^"]+)"', res.text)\nif match and '_csrf' in payload: payload['_csrf'] = match.group(1)\n\nprint("🚀 Sending Attack...")\nresponse = session.post(url, headers=headers, data=payload)\nprint(response.text[:1500])''';
                    Clipboard.setData(ClipboardData(text: pyCode)); Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🐍 نُسخ كود بايثون الذكي!")));
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008F11)),
                  icon: const Icon(Icons.javascript, color: Colors.black, size: 16), label: const Text("Node.js", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                  onPressed: () {
                    String jsCode = '''const axios = require('axios');\nconst data = new URLSearchParams(${_formatPayload(payloadCtrl.text)}).toString();\naxios.post('${urlCtrl.text}', data, {\n  headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Cookie': '$cookies' }\n}).then(res => console.log(res.data)).catch(err => console.log(err.message));''';
                    Clipboard.setData(ClipboardData(text: jsCode)); Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🟢 نُسخ كود Node.js Axios!")));
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF41), foregroundColor: Colors.black),
                  icon: const Icon(Icons.flash_on, size: 16), label: const Text("إطلاق الهجوم 🚀", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    String p = payloadCtrl.text.replaceAll("'", "\\'");
                    _controller.runJavaScript("fetch('${urlCtrl.text}', {method: '${log.method}', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: '$p'}).then(r=>r.text()).then(t=>ExhxxLog.postMessage(JSON.stringify({id:'atk_${DateTime.now().millisecondsSinceEpoch}', category: 'SYSTEM', method: 'ATTACK', url: '${urlCtrl.text}', payload: '$p', response: t.substring(0,1000)})));");
                    Navigator.pop(ctx);
                    setState(() { _activeFilter = 'سحب وأدوات'; _currentIndex = 1; });
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
  // واجهة مركز الاستخبارات
  // ==========================================
  Widget _buildIntelligenceHub() {
    List<UnifiedLog> filteredLogs = _unifiedLogs.where((log) {
      if (_activeFilter == 'الكل') return true;
      if (_activeFilter == 'طلبات (Network)' && ['FORM', 'FETCH', 'XHR', 'WEBSOCKET'].contains(log.category)) return true;
      if (_activeFilter == 'سحب وأدوات' && log.category == 'SYSTEM') return true;
      return false;
    }).toList();

    return Column(
      children: [
        Container(
          color: const Color(0xFF06140A), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['الكل', 'طلبات (Network)', 'سحب وأدوات'].map((filter) {
                bool isActive = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter, style: TextStyle(color: isActive ? Colors.black : const Color(0xFF00FF41), fontWeight: FontWeight.bold, fontSize: 11)),
                    selected: isActive,
                    selectedColor: const Color(0xFF00FF41), backgroundColor: const Color(0xFF030A05),
                    onSelected: (val) => setState(() => _activeFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredLogs.length,
            itemBuilder: (ctx, i) {
              var log = filteredLogs[i];
              Color catColor = log.category == 'WEBSOCKET' ? Colors.yellow : (log.category == 'FORM' ? const Color(0xFF008F11) : const Color(0xFF00FF41));
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), color: const Color(0xFF0B1F10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.3))),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: catColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2)), child: Text(log.category, style: TextStyle(color: catColor, fontSize: 9, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(log.method.isNotEmpty ? "[${log.method}] ${log.urlOrTitle}" : log.urlOrTitle, style: const TextStyle(fontSize: 11, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12), color: const Color(0xFF030A05), width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if(log.payload.isNotEmpty) ...[
                              const Text("البيانات (PAYLOAD):", style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              SelectableText(['FORM','FETCH','XHR'].contains(log.category) ? _formatPayload(log.payload) : log.payload, style: const TextStyle(color: Color(0xFF00FF41), fontSize: 11, fontFamily: 'monospace')),
                              const SizedBox(height: 8),
                            ],
                            if(log.response.isNotEmpty) ...[
                              const Text("الرد (RESPONSE):", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                              SelectableText(log.response, style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
                            ],
                            if(['FORM','FETCH','XHR'].contains(log.category)) ...[
                              const SizedBox(height: 15),
                              Center(child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF41), foregroundColor: Colors.black, minimumSize: const Size(200, 36)),
                                icon: const Icon(Icons.precision_manufacturing, size: 16), label: const Text("المصنع وتوليد السكربتات 🤖", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                onPressed: () => _openRepeater(log),
                              ))
                            ]
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

  // ==========================================
  // الترسانة الذكية (Searchable Arsenal)
  // ==========================================
  Widget _buildToolsArsenal() {
    List<ToolItem> displayedTools = _allTools.where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()) || t.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    // Group tools by category
    Map<String, List<ToolItem>> categorized = {};
    for (var t in displayedTools) {
      if (!categorized.containsKey(t.category)) categorized[t.category] = [];
      categorized[t.category]!.add(t);
    }

    return Column(
      children: [
        Container(
          color: const Color(0xFF06140A), padding: const EdgeInsets.all(10),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Color(0xFF00FF41), fontSize: 13),
            decoration: InputDecoration(
              hintText: "ابحث عن أداة (مثال: سحب، تزييف، حذف)...",
              hintStyle: TextStyle(color: const Color(0xFF00FF41).withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF00FF41)),
              filled: true, fillColor: const Color(0xFF030A05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00FF41))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00FF41), width: 2)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: categorized.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 10, bottom: 8), child: Text(">> ${entry.key}", style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold))),
                  GridView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
                    itemCount: entry.value.length,
                    itemBuilder: (ctx, i) => InkWell(
                      onTap: () => _runTool(entry.value[i].title, entry.value[i].script),
                      child: Container(
                        decoration: BoxDecoration(color: const Color(0xFF0B1F10), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3))),
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(entry.value[i].icon, color: entry.value[i].color, size: 28),
                            const SizedBox(height: 8),
                            Text(entry.value[i].title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBrowserTab() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF06140A), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF00FF41)), onPressed: () => _controller.goBack()),
              Expanded(child: TextField(
                controller: _urlController, style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15), filled: true, fillColor: const Color(0xFF030A05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock, size: 14, color: Color(0xFF00FF41)),
                ),
                onSubmitted: (val) { if(!val.startsWith("http")) val = "https://" + val; _controller.loadRequest(Uri.parse(val)); },
              )),
              IconButton(icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF00FF41)), onPressed: () => _controller.reload()),
            ],
          ),
        ),
        Expanded(child: WebViewWidget(controller: _controller)),
      ],
    );
  }

  Widget _buildVaultTab() {
    return ListView.builder(
      itemCount: _vaultPayloads.length,
      itemBuilder: (ctx, i) => Card(
        color: const Color(0xFF0B1F10), margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: const Icon(Icons.api, color: Color(0xFF00FF41)),
          title: Text(_vaultPayloads[i].urlOrTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
          subtitle: const Text("محفوظة بالماتريكس", style: TextStyle(fontSize: 9, color: Colors.white54)),
          trailing: IconButton(icon: const Icon(Icons.play_arrow, color: Color(0xFF00FF41)), onPressed: () => _openRepeater(_vaultPayloads[i])),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: [_buildBrowserTab(), _buildIntelligenceHub(), _buildToolsArsenal(), _buildVaultTab()])),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black, unselectedItemColor: const Color(0xFF00FF41), 
        backgroundColor: const Color(0xFF00FF41),
        type: BottomNavigationBarType.fixed, showUnselectedLabels: true, selectedFontSize: 11, unselectedFontSize: 10,
        onTap: (idx) => setState(() { _currentIndex = idx; }),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.language, color: _currentIndex == 0 ? Colors.black : const Color(0xFF00FF41)), label: "المتصفح"),
          BottomNavigationBarItem(icon: Icon(Icons.radar, color: _currentIndex == 1 ? Colors.black : const Color(0xFF00FF41)), label: "الماتريكس"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view, color: _currentIndex == 2 ? Colors.black : const Color(0xFF00FF41)), label: "الترسانة"),
          BottomNavigationBarItem(icon: Icon(Icons.shield, color: _currentIndex == 3 ? Colors.black : const Color(0xFF00FF41)), label: "الخزانة"),
        ],
      ),
    );
  }
}
