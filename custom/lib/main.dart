import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

void main() => runApp(const UltimateCommanderApp());

class UltimateCommanderApp extends StatelessWidget {
  const UltimateCommanderApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EXHXX Canary Commander',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF151515)),
        colorScheme: const ColorScheme.dark(primary: Colors.greenAccent, secondary: Colors.orangeAccent),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://www.virustotal.com/gui/domain/tiktokcdn.com/relations');
  
  final List<String> _logs = [];

  // ==========================================
  // حالات الأدوات (Tool States)
  // ==========================================
  bool _optCanarySniffer = false;
  bool _optMediaBlocker = false;
  bool _optAutoScroll = false;
  bool _optShadowClicker = false;
  bool _optConsoleHijack = false;
  bool _optSpoofer = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('ExhxxLog', onMessageReceived: (msg) {
        setState(() { _logs.add(msg.message); });
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          _applyEnabledTools();
        },
      ))
      ..loadRequest(Uri.parse(_urlController.text));
  }

  // ==========================================
  // محرك الحقن المتقدم (Advanced Injection Engine)
  // ==========================================
  void _applyEnabledTools() {
    // 1. نظام HttpCanary (Deep Fetch & XHR Interceptor)
    if (_optCanarySniffer) {
      _controller.runJavaScript('''
        if(!window.exhxxCanaryInstalled){
          window.exhxxCanaryInstalled = true;
          
          // اعتراض XHR
          const origOpen = XMLHttpRequest.prototype.open;
          const origSend = XMLHttpRequest.prototype.send;
          XMLHttpRequest.prototype.open = function(method, url) {
            this._exhxxMethod = method;
            this._exhxxUrl = url;
            origOpen.apply(this, arguments);
          };
          XMLHttpRequest.prototype.send = function(body) {
            ExhxxLog.postMessage('[XHR] [' + this._exhxxMethod + '] ' + this._exhxxUrl);
            origSend.apply(this, arguments);
          };

          // اعتراض Fetch
          const origFetch = window.fetch;
          window.fetch = async function() {
            let url = typeof arguments[0] === 'string' ? arguments[0] : (arguments[0] && arguments[0].url ? arguments[0].url : 'Unknown');
            let method = (arguments[1] && arguments[1].method) ? arguments[1].method : 'GET';
            ExhxxLog.postMessage('[FETCH] [' + method + '] ' + url);
            return origFetch.apply(this, arguments);
          };
        }
      ''');
    }

    // 2. مانع الميديا
    if (_optMediaBlocker) {
      _controller.runJavaScript("var s=document.createElement('style');s.innerHTML='img,video,iframe,canvas{display:none !important;} *{background-image:none !important;}';document.head.appendChild(s);");
    }

    // 3. مختطف الكونسول (يتجسس على المبرمجين)
    if (_optConsoleHijack) {
      _controller.runJavaScript('''
        if(!window.exhxxConsoleHijacked) {
          window.exhxxConsoleHijacked = true;
          const origLog = console.log;
          console.log = function() {
            ExhxxLog.postMessage('[CONSOLE] ' + Array.from(arguments).join(' '));
            origLog.apply(console, arguments);
          };
        }
      ''');
    }

    // 4. التمرير التلقائي
    if (_optAutoScroll) {
      _controller.runJavaScript("if(!window.vtScroller) window.vtScroller = setInterval(()=>window.scrollBy({top:400, behavior:'smooth'}), 1000);");
    } else {
      _controller.runJavaScript("if(window.vtScroller) clearInterval(window.vtScroller); window.vtScroller=null;");
    }

    // 5. النقار الجذري
    if (_optShadowClicker) {
      _controller.runJavaScript('''
        if(!window.vtClicker) window.vtClicker = setInterval(()=>{
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
      _controller.runJavaScript("if(window.vtClicker) clearInterval(window.vtClicker); window.vtClicker=null;");
    }
  }

  // ==========================================
  // أدوات الأكشن السريع (Quick Actions)
  // ==========================================
  void _harvestCookies() async {
    final result = await _controller.runJavaScriptReturningResult("document.cookie;");
    setState(() { _logs.add("[COOKIE] " + result.toString().replaceAll('"', '')); });
    _currentIndex = 2; 
  }

  void _extractLiveDOM() async {
    final result = await _controller.runJavaScriptReturningResult("document.documentElement.outerHTML;");
    setState(() { _logs.add("[DOM_SOURCE] " + result.toString().substring(0, 500) + "... (تم سحب الكود الحي!)"); });
    _currentIndex = 2;
  }

  void _nukeStorage() async {
    await _controller.clearCache();
    await _controller.clearLocalStorage();
    setState(() { _logs.add("[SYSTEM] ☢️ تم تدمير الكاش والبيانات! المتصفح الآن نظيف."); });
    _controller.reload();
  }

  // ==========================================
  // واجهات التطبيق (UI Tabs)
  // ==========================================
  Widget _buildBrowserTab() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF151515), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(child: TextField(
                controller: _urlController, style: const TextStyle(fontSize: 14, color: Colors.white),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15), hintText: "https://...", 
                  filled: true, fillColor: Colors.black, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)
                ),
                onSubmitted: (val) => _controller.loadRequest(Uri.parse(val)),
              )),
              IconButton(icon: const Icon(Icons.public, color: Colors.greenAccent), onPressed: () => _controller.loadRequest(Uri.parse(_urlController.text))),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.orangeAccent), onPressed: () => _controller.reload()),
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
        const Text("أنظمة التجسس والتحكم (Spy & Control) 🎛️", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
        const Divider(color: Colors.white24),
        SwitchListTile(activeColor: Colors.greenAccent, title: const Text("🕵️ نظام HttpCanary المصغر"), subtitle: const Text("اعتراض كل طلبات الـ API (XHR/Fetch)"), value: _optCanarySniffer, onChanged: (v){ setState(() { _optCanarySniffer=v; _applyEnabledTools(); });}),
        SwitchListTile(activeColor: Colors.greenAccent, title: const Text("🎙️ مختطف الكونسول (Console Hijack)"), subtitle: const Text("قراءة رسائل المبرمجين المخفية بالموقع"), value: _optConsoleHijack, onChanged: (v){ setState(() { _optConsoleHijack=v; _applyEnabledTools(); });}),
        SwitchListTile(activeColor: Colors.greenAccent, title: const Text("🚀 مانع الميديا (Turbo Blocker)"), subtitle: const Text("إيقاف الصور/الفيديو لتسريع التصفح"), value: _optMediaBlocker, onChanged: (v){ setState(() { _optMediaBlocker=v; _applyEnabledTools(); });}),
        SwitchListTile(activeColor: Colors.greenAccent, title: const Text("📜 التمرير التلقائي (Auto Scroll)"), subtitle: const Text("النزول لأسفل لتفعيل Lazy Load"), value: _optAutoScroll, onChanged: (v){ setState(() { _optAutoScroll=v; _applyEnabledTools(); });}),
        SwitchListTile(activeColor: Colors.greenAccent, title: const Text("🤖 النقار الجذري (Shadow Clicker)"), subtitle: const Text("الضغط التلقائي على أزرار Load More"), value: _optShadowClicker, onChanged: (v){ setState(() { _optShadowClicker=v; _applyEnabledTools(); });}),
        SwitchListTile(activeColor: Colors.greenAccent, title: const Text("💻 مزيف الهوية (Desktop Spoofer)"), subtitle: const Text("تغيير بصمة الجهاز (User-Agent)"), value: _optSpoofer, onChanged: (v){ 
          setState(() { _optSpoofer=v; });
          _controller.setUserAgent(_optSpoofer ? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" : "");
          _controller.reload();
        }),
        const SizedBox(height: 15),
        const Text("أدوات الاستخراج (Extraction Tools) ⚡", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
        const Divider(color: Colors.white24),
        ListTile(leading: const Icon(Icons.cookie, color: Colors.orangeAccent), title: const Text("سحب الكوكيز (Harvest Cookies)"), onTap: _harvestCookies),
        ListTile(leading: const Icon(Icons.html, color: Colors.blueAccent), title: const Text("سحب الكود الحي (Live DOM Source)"), onTap: _extractLiveDOM),
        ListTile(leading: const Icon(Icons.delete_forever, color: Colors.redAccent), title: const Text("المسح النووي (Nuke Storage)"), onTap: _nukeStorage),
      ],
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), color: const Color(0xFF151515),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TERMINAL LOGS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.grey)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.copy, color: Colors.greenAccent), onPressed: (){
                    Clipboard.setData(ClipboardData(text: _logs.join('\n')));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم نسخ السجلات!")));
                  }),
                  IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: (){
                    setState((){ _logs.clear(); });
                  }),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (ctx, i) {
                // تلوين السجلات حسب نوعها
                Color textColor = Colors.white;
                if (_logs[i].startsWith('[FETCH]')) textColor = Colors.greenAccent;
                else if (_logs[i].startsWith('[XHR]')) textColor = Colors.cyanAccent;
                else if (_logs[i].startsWith('[COOKIE]')) textColor = Colors.orangeAccent;
                else if (_logs[i].startsWith('[CONSOLE]')) textColor = Colors.yellowAccent;
                else if (_logs[i].startsWith('[SYSTEM]')) textColor = Colors.redAccent;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: SelectableText("> \n${_logs[i]}", style: TextStyle(color: textColor, fontFamily: 'monospace', fontSize: 11)),
                );
              },
            ),
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
          children: [_buildBrowserTab(), _buildToolsTab(), _buildLogsTab()],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: const Color(0xFF151515),
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() { _currentIndex = idx; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.public), label: "Browser"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "Canary Tools"),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: "Terminal"),
        ],
      ),
    );
  }
}
