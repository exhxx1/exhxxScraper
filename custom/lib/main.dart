import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() => runApp(const ExhxxGlobalStandardApp());

class ExhxxGlobalStandardApp extends StatelessWidget {
  const ExhxxGlobalStandardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EXHXX Level MAX',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E17), 
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F1423), elevation: 0),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF00E5FF), secondary: Color(0xFF7C4DFF)),
        cardColor: const Color(0xFF141A29),
        dividerColor: Colors.white10,
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 12)),
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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://kd1s.com');
  
  final List<UnifiedLog> _unifiedLogs = [];
  final List<UnifiedLog> _vaultPayloads = [];
  final Map<String, String> _vaultSessions = {};

  String _activeFilter = 'الكل'; 
  bool _optOmniSniffer = true;
  String _userAgent = "default";

  @override
  void initState() {
    super.initState();
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

  void _injectCoreRadar() {
    if (!_optOmniSniffer) return;
    _controller.runJavaScript(r'''
      if(!window.__exhxxCoreHooked) {
        window.__exhxxCoreHooked = true;
        
        function sendLog(id, category, method, url, payload, response) {
          if(url && (url.includes('google-analytics') || url.includes('g/collect'))) return; 
          let fullUrl = url; if(url && url.startsWith('/')) fullUrl = window.location.origin + url;
          try { ExhxxLog.postMessage(JSON.stringify({id: id, category: category, method: method, url: fullUrl, payload: payload ? String(payload) : '', response: response ? String(response) : ''})); } catch(e){}
        }

        const origLog = console.log; const origWarn = console.warn; const origErr = console.error;
        console.log = function(...args) { sendLog('log_'+Date.now(), 'CONSOLE', 'INFO', 'Console Log', args.join(' '), ''); origLog.apply(console, args); };
        console.warn = function(...args) { sendLog('warn_'+Date.now(), 'CONSOLE', 'WARN', 'Console Warning', args.join(' '), ''); origWarn.apply(console, args); };
        console.error = function(...args) { sendLog('err_'+Date.now(), 'CONSOLE', 'ERROR', 'Console Error', args.join(' '), ''); origErr.apply(console, args); };

        document.addEventListener('submit', async function(e) {
          if(e.target && e.target.tagName === 'FORM') {
            e.preventDefault(); 
            let form = e.target;
            let formProps = new URLSearchParams(new FormData(form)).toString(); 
            let reqId = 'form_' + Date.now();
            sendLog(reqId, 'FORM', form.method.toUpperCase() || 'POST', form.action || window.location.href, formProps, '⏳ جاري المعالجة...');
            try {
               let res = await fetch(form.action || window.location.href, { method: form.method || 'POST', body: formProps, headers: {'Content-Type': 'application/x-www-form-urlencoded'} });
               let text = await res.text();
               sendLog(reqId, 'FORM', form.method.toUpperCase(), form.action || window.location.href, formProps, text.substring(0,3000));
               document.open(); document.write(text); document.close();
            } catch(err) { sendLog(reqId, 'FORM', form.method, form.action, formProps, 'خطأ: ' + err.toString()); form.submit(); }
          }
        }, true);

        const origFetch = window.fetch;
        window.fetch = async function(...args) {
          let url = typeof args[0] === 'string' ? args[0] : (args[0] && args[0].url ? args[0].url : 'Unknown');
          let method = (args[1] && args[1].method) ? args[1].method : 'GET';
          let body = (args[1] && args[1].body) ? args[1].body : '';
          let reqId = 'fetch_' + Date.now() + Math.random();
          sendLog(reqId, 'FETCH', method, url, typeof body === 'string' ? body : 'Binary Data', '⏳ بانتظار الرد...');
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
          sendLog(this._exId, 'XHR', this._exMethod, this._exUrl, typeof body === 'string' ? body : '', '⏳ قيد التنفيذ...');
          this.addEventListener('load', function() { sendLog(this._exId, 'XHR', this._exMethod, this._exUrl, typeof body === 'string' ? body : '', this.responseText ? this.responseText.substring(0,3000) : ''); });
          origSend.apply(this, arguments);
        };
      }
    ''');
  }

  void _runTool(String name, String script, {bool notify = true}) async {
    final res = await _controller.runJavaScriptReturningResult(script);
    String resultStr = res.toString().replaceAll('"', '').trim();
    if (resultStr.isEmpty || resultStr == 'null') resultStr = "تم التنفيذ أو لم يتم العثور على بيانات.";
    
    setState(() {
      _unifiedLogs.insert(0, UnifiedLog(
        id: 'tool_${DateTime.now().millisecondsSinceEpoch}', category: 'SYSTEM', method: 'TOOL', 
        urlOrTitle: 'أداة: $name', payload: 'تم استدعاء السكربت بنجاح', response: resultStr, timestamp: DateTime.now()
      ));
    });
    
    if(notify) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ اكتملت: $name", style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF00E5FF)));
    setState(() { _activeFilter = 'سحب وأدوات'; _currentIndex = 1; }); // الانتقال للرادار لرؤية النتيجة
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
  // واجهة مركز الاستخبارات (Intelligence Hub)
  // ==========================================
  Widget _buildIntelligenceHub() {
    List<UnifiedLog> filteredLogs = _unifiedLogs.where((log) {
      if (_activeFilter == 'الكل') return true;
      if (_activeFilter == 'طلبات (Network)' && ['FORM', 'FETCH', 'XHR'].contains(log.category)) return true;
      if (_activeFilter == 'الكونسول (Console)' && log.category == 'CONSOLE') return true;
      if (_activeFilter == 'سحب وأدوات' && log.category == 'SYSTEM') return true;
      return false;
    }).toList();

    return Column(
      children: [
        Container(
          color: const Color(0xFF0F1423), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['الكل', 'طلبات (Network)', 'الكونسول (Console)', 'سحب وأدوات'].map((filter) {
                bool isActive = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter, style: TextStyle(color: isActive ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
                    selected: isActive,
                    selectedColor: const Color(0xFF00E5FF), backgroundColor: const Color(0xFF141A29),
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
              Color catColor = log.category == 'FORM' ? const Color(0xFF7C4DFF) : (log.category == 'CONSOLE' ? Colors.orange : (log.category == 'SYSTEM' ? Colors.greenAccent : const Color(0xFF00E5FF)));
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), color: const Color(0xFF141A29),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.white10)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: catColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text(log.category, style: TextStyle(color: catColor, fontSize: 9, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(log.method.isNotEmpty ? "[${log.method}] ${log.urlOrTitle}" : log.urlOrTitle, style: const TextStyle(fontSize: 11, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12), color: const Color(0xFF0A0E17), width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if(log.payload.isNotEmpty) ...[
                              const Text("البيانات (PAYLOAD):", style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              SelectableText(['FORM','FETCH','XHR'].contains(log.category) ? _formatPayload(log.payload) : log.payload, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                              const SizedBox(height: 8),
                            ],
                            if(log.response.isNotEmpty) ...[
                              const Text("النتيجة/الرد (RESPONSE):", style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 10, fontWeight: FontWeight.bold)),
                              SelectableText(log.response, style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
                            ],
                            if(['FORM','FETCH','XHR'].contains(log.category)) ...[
                              const SizedBox(height: 15),
                              Center(child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black, minimumSize: const Size(200, 40)),
                                icon: const Icon(Icons.build, size: 16), label: const Text("توليد سكربت بايثون / هجوم 🚀", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
  // ترسانة الإمبراطور (الـ 25 أداة المطورة MAX)
  // ==========================================
  Widget _buildToolsArsenal() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildCategoryHeader("🛠️ استخراج وسحب البيانات (Data Extraction)"),
        _buildToolGrid([
          _ToolItem("سحب توكنات JWT", Icons.key, Colors.amber, () => _runTool("سحب JWT", "Array.from(document.body.innerText.matchAll(/ey[A-Za-z0-9-_=]+\\.[A-Za-z0-9-_=]+\\.?[A-Za-z0-9-_.+/=]*/g)).join('\\n');")),
          _ToolItem("سحب الإيميلات", Icons.email, Colors.blueAccent, () => _runTool("سحب الإيميلات", "Array.from(document.body.innerText.matchAll(/([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\\.[a-zA-Z0-9_-]+)/gi)).join('\\n');")),
          _ToolItem("سحب الأرقام", Icons.phone, Colors.greenAccent, () => _runTool("سحب الأرقام", "Array.from(document.body.innerText.matchAll(/(?:\\+?\\d{1,3}[- ]?)?\\(?\\d{3}\\)?[- ]?\\d{3}[- ]?\\d{4}/g)).join('\\n');")),
          _ToolItem("سحب CSRF المخفي", Icons.visibility_off, Colors.redAccent, () => _runTool("الحقول المخفية", "Array.from(document.querySelectorAll('input[type=\"hidden\"]')).map(i => i.name + ' = ' + i.value).join('\\n');")),
          _ToolItem("سحب الروابط", Icons.link, Colors.cyan, () => _runTool("سحب الروابط", "Array.from(document.querySelectorAll('a')).map(a => a.href).join('\\n');")),
          _ToolItem("سحب الصور", Icons.image, Colors.pinkAccent, () => _runTool("سحب الصور", "Array.from(document.querySelectorAll('img')).map(i => i.src).join('\\n');")),
          _ToolItem("سحب ملفات JS", Icons.javascript, Colors.yellow, () => _runTool("ملفات JS", "Array.from(document.scripts).map(s=>s.src).filter(Boolean).join('\\n');")),
          _ToolItem("سحب بيانات JSON", Icons.data_object, Colors.lightBlue, () => _runTool("بيانات JSON", "Array.from(document.scripts).filter(s=>s.type.includes('json')).map(s=>s.innerText).join('\\n\\n');")),
          _ToolItem("سحب الكوكيز", Icons.cookie, Colors.orange, () => _runTool("الكوكيز", "document.cookie;")),
        ]),

        _buildCategoryHeader("🪄 التلاعب بالواجهة وتخطي الحمايات (DOM & Bypass)"),
        _buildToolGrid([
          _ToolItem("وضع التعديل الحر", Icons.edit, Colors.teal, () => _runTool("التعديل الحر", "document.designMode = document.designMode === 'on' ? 'off' : 'on'; 'وضع التعديل: ' + document.designMode;")),
          _ToolItem("كشف الباسوردات", Icons.password, Colors.red, () => _runTool("كشف المرور", "document.querySelectorAll('input[type=\"password\"]').forEach(i=>i.type='text'); 'تم إظهار الكلمات المخفية';")),
          _ToolItem("إظهار المخفي", Icons.visibility, Colors.green, () => _runTool("إظهار المخفي", "document.querySelectorAll('*').forEach(e=>{if(getComputedStyle(e).display==='none')e.style.display='block';}); 'تم إظهار كل شيء';")),
          _ToolItem("إبادة النوافذ", Icons.block, Colors.deepOrange, () => _runTool("إبادة النوافذ", "document.querySelectorAll('*').forEach(e=>{let z=getComputedStyle(e).zIndex;if(z!=='auto'&&parseInt(z)>1000)e.remove();}); 'تم مسح النوافذ المنبثقة';")),
          _ToolItem("رسم حدود العناصر", Icons.border_outer, Colors.cyan, () => _runTool("حدود العناصر", "var s=document.createElement('style');s.innerHTML='*{outline:1px solid red!important}';document.head.appendChild(s); 'تم رسم الحدود لكشف الـ Divs';")),
          _ToolItem("تدمير CSS", Icons.flash_off, Colors.yellowAccent, () => _runTool("تدمير التصميم", "document.querySelectorAll('style,link[rel=\"stylesheet\"]').forEach(e=>e.remove()); 'تم تدمير التصميم للتسريع';")),
          _ToolItem("إيقاف المؤقتات", Icons.timer_off, Colors.pink, () => _runTool("إيقاف المؤقتات", "for(let i=0;i<10000;i++){clearTimeout(i);clearInterval(i);} 'تم إيقاف مؤقتات الانتظار';")),
          _ToolItem("تسريع الفيديو x16", Icons.speed, Colors.lightGreen, () => _runTool("تسريع الفيديو", "document.querySelectorAll('video').forEach(v=>v.playbackRate=16); 'تم تسريع الفيديوهات';")),
          _ToolItem("فك حظر النسخ", Icons.lock_open, Colors.lightGreenAccent, () => _runTool("فك الحظر", "document.oncontextmenu=null; document.onselectstart=null; document.oncopy=null; 'تم فك حظر النسخ واللصق';")),
        ]),

        _buildCategoryHeader("🤖 الأتمتة السريعة (Automation)"),
        _buildToolGrid([
          _ToolItem("تعبئة بيانات وهمية", Icons.auto_fix_high, Colors.indigoAccent, () => _runTool("تعبئة وهمية", "document.querySelectorAll('input').forEach(i=>{if(i.type==='email')i.value='test@hack.com';else if(i.type==='password')i.value='ExHxx@123';else if(i.type==='text')i.value='Hacker_1337';}); 'تم تعبئة الحقول باحترافية';")),
          _ToolItem("نقار أزرار الإرسال", Icons.ads_click, Colors.lime, () => _runTool("نقار الإرسال", "document.querySelectorAll('button[type=\"submit\"], input[type=\"submit\"]').forEach(b=>b.click()); 'تم ضغط جميع أزرار الإرسال';")),
          _ToolItem("التمرير اللانهائي", Icons.swipe_down, Colors.purpleAccent, () => _runTool("التمرير المستمر", "window.scrInt = setInterval(()=>window.scrollBy(0, 500), 1000); 'تم تفعيل التمرير التلقائي';")),
          _ToolItem("إيقاف التمرير", Icons.stop_circle, Colors.redAccent, () => _runTool("إيقاف التمرير", "clearInterval(window.scrInt); 'تم الإيقاف';")),
          _ToolItem("نقر أزرار الظل", Icons.touch_app, Colors.orangeAccent, () => _runTool("نقار الظل", "setInterval(()=>{let b=Array.from(document.querySelectorAll('*')).find(x=>x.shadowRoot); if(b) {let btn=b.shadowRoot.querySelector('button'); if(btn) btn.click();}}, 1000); 'تم تفعيل نقار جذور الظل';")),
          _ToolItem("حجب الوسائط", Icons.image_not_supported, Colors.grey, () => _runTool("حجب الصور", "var s=document.createElement('style');s.innerHTML='img,video,iframe{display:none!important}';document.head.appendChild(s); 'تم حجب الميديا لتسريع التحميل';")),
        ]),

        _buildCategoryHeader("💉 أنظمة الحقن والتطوير (Injection & Dev)"),
        _buildToolGrid([
          _ToolItem("حقن vConsole", Icons.developer_mode, Colors.green, () => _runTool("حقن vConsole", "var s=document.createElement('script');s.src='https://unpkg.com/vconsole/dist/vconsole.min.js';s.onload=()=>new window.VConsole();document.head.appendChild(s); 'تم حقن وحدة تحكم المطورين على الشاشة';")),
          _ToolItem("حقن مكتبة jQuery", Icons.javascript, Colors.blue, () => _runTool("حقن jQuery", "var s=document.createElement('script');s.src='https://code.jquery.com/jquery-3.6.0.min.js';document.head.appendChild(s); 'تم الحقن';")),
          _ToolItem("مانع أدوات التتبع", Icons.shield, Colors.redAccent, () => _runTool("حظر التتبع", "window.ga=function(){}; window.dataLayer=[]; 'تم إيقاف تحليلات جوجل وتتبع الموقع';")),
          _ToolItem("تجميد الصفحة", Icons.ac_unit, Colors.lightBlueAccent, () => _runTool("تجميد العمليات", "setTimeout(()=>{debugger;}, 3000); 'سيتم تجميد الصفحة بعد 3 ثوانٍ (افتح الكونسول)';")),
          _ToolItem("تزييف بصمة Win", Icons.desktop_mac, Colors.white, () { setState((){ _userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"; }); _controller.setUserAgent(_userAgent); _controller.reload(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تغيير البصمة إلى ويندوز")));}),
          _ToolItem("تزييف بصمة iOS", Icons.phone_iphone, Colors.grey, () { setState((){ _userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)"; }); _controller.setUserAgent(_userAgent); _controller.reload(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تغيير البصمة إلى ايفون")));}),
          _ToolItem("تصفير الموقع (Nuke)", Icons.delete_forever, Colors.red, () async { await _controller.clearCache(); await _controller.clearLocalStorage(); _controller.reload(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تصفير الموقع والكاش!")));}),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(padding: const EdgeInsets.only(top: 15, bottom: 10), child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)));
  }

  Widget _buildToolGrid(List<_ToolItem> tools) {
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.9),
      itemCount: tools.length,
      itemBuilder: (ctx, i) => InkWell(
        onTap: tools[i].onTap,
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF141A29), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tools[i].icon, color: tools[i].color, size: 26),
              const SizedBox(height: 8),
              Text(tools[i].title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // مدفع الهجمات وتوليد البايثون
  // ==========================================
  void _openRepeater(UnifiedLog log) async {
    String cookies = (await _controller.runJavaScriptReturningResult("document.cookie;")).toString().replaceAll('"', '');
    TextEditingController urlCtrl = TextEditingController(text: log.urlOrTitle);
    TextEditingController payloadCtrl = TextEditingController(text: log.payload);

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF0A0E17),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("منصة الهجوم وتوليد السكربتات 🚀", style: TextStyle(fontSize: 16, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: urlCtrl, style: const TextStyle(fontSize: 11), decoration: const InputDecoration(labelText: "الرابط (Target URL)", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: payloadCtrl, maxLines: 3, style: const TextStyle(fontSize: 11, color: Colors.orangeAccent), decoration: const InputDecoration(labelText: "البيانات (Payload)", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF141A29), side: const BorderSide(color: Color(0xFF00E5FF))),
                  icon: const Icon(Icons.save, color: Color(0xFF00E5FF), size: 16), label: const Text("حفظ للخزانة", style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10)),
                  onPressed: () { setState(() { _vaultPayloads.add(log); }); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم الحفظ في بنك الثغرات"))); },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  icon: const Icon(Icons.code, color: Colors.black, size: 16), label: const Text("توليد Python 🐍", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                  onPressed: () {
                    String pyCode = '''import requests\nimport re\n\nurl = "${urlCtrl.text}"\npayload = ${_formatPayload(payloadCtrl.text)}\nheaders = {\n  'Content-Type': 'application/x-www-form-urlencoded',\n  'User-Agent': 'Mozilla/5.0',\n  'Cookie': '$cookies'\n}\n\nsession = requests.Session()\nres = session.get(url)\nmatch = re.search(r'name="_csrf"\\\\s+value="([^"]+)"', res.text)\nif match and '_csrf' in payload: payload['_csrf'] = match.group(1)\n\nprint("🚀 Sending Attack...")\nresponse = session.post(url, headers=headers, data=payload)\nprint(response.text[:1500])''';
                    Clipboard.setData(ClipboardData(text: pyCode)); Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🐍 تم نسخ سكربت بايثون الذكي!")));
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF), foregroundColor: Colors.white),
                  icon: const Icon(Icons.flash_on, size: 16), label: const Text("إطلاق الهجوم", style: TextStyle(fontSize: 10)),
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
  // واجهة المتصفح (Browser)
  // ==========================================
  Widget _buildBrowserTab() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF0F1423), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white54), onPressed: () => _controller.goBack()),
              Expanded(child: TextField(
                controller: _urlController, style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15), filled: true, fillColor: const Color(0xFF0A0E17),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock, size: 14, color: Colors.greenAccent),
                ),
                onSubmitted: (val) { if(!val.startsWith("http")) val = "https://" + val; _controller.loadRequest(Uri.parse(val)); },
              )),
              IconButton(icon: const Icon(Icons.refresh, size: 20, color: Colors.white54), onPressed: () => _controller.reload()),
            ],
          ),
        ),
        Expanded(child: WebViewWidget(controller: _controller)),
      ],
    );
  }

  // ==========================================
  // الخزانة (Vault)
  // ==========================================
  Widget _buildVaultTab() {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.all(15), child: Text("خزانة الحسابات والأرشيف 🗄️", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)))),
        Expanded(
          child: ListView.builder(
            itemCount: _vaultPayloads.length,
            itemBuilder: (ctx, i) => Card(
              color: const Color(0xFF141A29), margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.api, color: Color(0xFF7C4DFF)),
                title: Text(_vaultPayloads[i].urlOrTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                subtitle: const Text("طلب محفوظ ببنك الثغرات", style: TextStyle(fontSize: 9, color: Colors.white54)),
                trailing: IconButton(icon: const Icon(Icons.play_arrow, color: Color(0xFF00E5FF)), onPressed: () => _openRepeater(_vaultPayloads[i])),
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: [_buildBrowserTab(), _buildIntelligenceHub(), _buildToolsArsenal(), _buildVaultTab()])),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF00E5FF), unselectedItemColor: Colors.white30, backgroundColor: const Color(0xFF0F1423),
        type: BottomNavigationBarType.fixed, showUnselectedLabels: true, selectedFontSize: 10, unselectedFontSize: 9,
        onTap: (idx) => setState(() { _currentIndex = idx; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.language), label: "المتصفح"),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: "الرادار"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "الترسانة MAX"),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: "الخزانة"),
        ],
      ),
    );
  }
}

class _ToolItem {
  final String title; final IconData icon; final Color color; final VoidCallback onTap;
  _ToolItem(this.title, this.icon, this.color, this.onTap);
}
