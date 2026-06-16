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
      title: 'EXHXX Ultimate Commander',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A1A)),
        colorScheme: ColorScheme.dark(primary: Colors.tealAccent, secondary: Colors.orangeAccent),
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
  
  List<String> _logs = [];

  // ==========================================
  // حالات الأدوات (Tool States)
  // ==========================================
  bool _optSniffer = false;
  bool _optMediaBlocker = false;
  bool _optAutoScroll = false;
  bool _optAutoClicker = false;
  bool _optDarkMode = false;
  bool _optSpoofer = false;
  bool _optAntiDebug = false;

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
  // محرك حقن الأدوات (Tool Injection Engine)
  // ==========================================
  void _applyEnabledTools() {
    if (_optSniffer) {
      _controller.runJavaScript('''
        if(!window.exhxxSniff){
          window.exhxxSniff = true;
          const origFetch = window.fetch;
          window.fetch = async function() {
            ExhxxLog.postMessage('🕵️ FETCH: ' + arguments[0]);
            return origFetch.apply(this, arguments);
          };
          const origXhr = XMLHttpRequest.prototype.open;
          XMLHttpRequest.prototype.open = function() {
            ExhxxLog.postMessage('🕵️ XHR: ' + arguments[1]);
            origXhr.apply(this, arguments);
          };
        }
      ''');
    }

    if (_optMediaBlocker) {
      _controller.runJavaScript("var s=document.createElement('style');s.innerHTML='img,video,iframe,canvas{display:none !important;} *{background-image:none !important;}';document.head.appendChild(s);");
    }

    if (_optAutoScroll) {
      _controller.runJavaScript("if(!window.vtScroller) window.vtScroller = setInterval(()=>window.scrollBy({top:400, behavior:'smooth'}), 1000);");
    } else {
      _controller.runJavaScript("if(window.vtScroller) clearInterval(window.vtScroller); window.vtScroller=null;");
    }

    if (_optDarkMode) {
      _controller.runJavaScript("document.documentElement.style.filter = 'invert(1) hue-rotate(180deg)'; document.body.style.backgroundColor = '#FFF';");
    } else {
      _controller.runJavaScript("document.documentElement.style.filter = '';");
    }

    if (_optAntiDebug) {
      _controller.runJavaScript("console.log=function(){}; console.warn=function(){}; console.error=function(){}; setInterval(()=>{Function.prototype.constructor=function(){};}, 100);");
    }

    if (_optAutoClicker) {
      _controller.runJavaScript('''
        if(!window.vtClicker) window.vtClicker = setInterval(()=>{
          function traverse(n) {
            let res=[];
            if(!n) return res;
            if(n.nodeType===1) res.push(n);
            if(n.shadowRoot) res.push(...traverse(n.shadowRoot));
            let c = n.shadowRoot ? n.shadowRoot.childNodes : n.childNodes;
            for(let i=0; i<c.length; i++) res.push(...traverse(c[i]));
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

  void _harvestCookies() async {
    final result = await _controller.runJavaScriptReturningResult("document.cookie;");
    setState(() { _logs.add("🍪 COOKIES: \${result.toString()}"); });
    _currentIndex = 2; // Jump to logs
  }

  void _nukeStorage() async {
    await _controller.clearCache();
    await _controller.clearLocalStorage();
    setState(() { _logs.add("☢️ تم مسح الكاش وبيانات التخزين بنجاح!"); });
    _controller.reload();
  }

  void _injectCustomJs() {
    TextEditingController jsCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("حقن كود JavaScript"),
      content: TextField(controller: jsCtrl, maxLines: 5, decoration: const InputDecoration(hintText: "alert('EXHXX!');")),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("إلغاء")),
        ElevatedButton(onPressed: (){
          _controller.runJavaScript(jsCtrl.text);
          Navigator.pop(ctx);
        }, child: const Text("حقن 💉"))
      ],
    ));
  }

  // ==========================================
  // تصميم الواجهات (UI Views)
  // ==========================================
  Widget _buildBrowserTab() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF1A1A1A), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(child: TextField(
                controller: _urlController, style: const TextStyle(fontSize: 14),
                // تم إصلاح OutlineBorder إلى OutlineInputBorder
                decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 15), hintText: "Enter URL...", filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
                onSubmitted: (val) => _controller.loadRequest(Uri.parse(val)),
              )),
              IconButton(icon: const Icon(Icons.send, color: Colors.tealAccent), onPressed: () => _controller.loadRequest(Uri.parse(_urlController.text))),
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
        const Text("أدوات الأتمتة المتقدمة 🎛️", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
        const Divider(),
        SwitchListTile(title: const Text("🕵️ صائد الروابط (Network Sniffer)"), subtitle: const Text("يسجل روابط API بصفحة السجلات"), value: _optSniffer, onChanged: (v){ setState(() { _optSniffer=v; _applyEnabledTools(); });}),
        SwitchListTile(title: const Text("🚀 مانع الميديا (Turbo Blocker)"), subtitle: const Text("يخفي الصور والفيديوهات لتسريع التحميل"), value: _optMediaBlocker, onChanged: (v){ setState(() { _optMediaBlocker=v; _applyEnabledTools(); });}),
        SwitchListTile(title: const Text("📜 التمرير التلقائي (Auto Scroll)"), subtitle: const Text("ينزل الشاشة تلقائياً باستمرار"), value: _optAutoScroll, onChanged: (v){ setState(() { _optAutoScroll=v; _applyEnabledTools(); });}),
        SwitchListTile(title: const Text("🤖 النقار الجذري (Shadow Auto-Clicker)"), subtitle: const Text("يخترق الظل ويضغط أزرار (...)"), value: _optAutoClicker, onChanged: (v){ setState(() { _optAutoClicker=v; _applyEnabledTools(); });}),
        SwitchListTile(title: const Text("🕶️ فارض الوضع الليلي (Dark Mode)"), subtitle: const Text("يقلب ألوان المواقع المزعجة"), value: _optDarkMode, onChanged: (v){ setState(() { _optDarkMode=v; _applyEnabledTools(); });}),
        SwitchListTile(title: const Text("🛡️ مانع التتبع (Anti-Debug Bypass)"), subtitle: const Text("يمنع المواقع من مراقبة السكربتات"), value: _optAntiDebug, onChanged: (v){ setState(() { _optAntiDebug=v; _applyEnabledTools(); });}),
        SwitchListTile(title: const Text("💻 مزيف الجهاز (Desktop Spoofer)"), subtitle: const Text("يعرض الموقع ككمبيوتر ويندوز"), value: _optSpoofer, onChanged: (v){ 
          setState(() { _optSpoofer=v; });
          _controller.setUserAgent(_optSpoofer ? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" : "");
          _controller.reload();
        }),
        const SizedBox(height: 15),
        const Text("أدوات التدخل السريع ⚡", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
        const Divider(),
        ListTile(leading: const Icon(Icons.cookie, color: Colors.brown), title: const Text("سحب الكوكيز (Harvest Cookies)"), onTap: _harvestCookies),
        ListTile(leading: const Icon(Icons.code, color: Colors.blue), title: const Text("حقن كود مخصص (Inject JS)"), onTap: _injectCustomJs),
        ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text("المسح النووي (Nuke Storage)"), onTap: _nukeStorage),
      ],
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8), color: const Color(0xFF111111),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black), icon: const Icon(Icons.copy), label: const Text("نسخ الكل"), onPressed: (){
                Clipboard.setData(ClipboardData(text: _logs.join('\n')));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم نسخ السجلات!")));
              }),
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), icon: const Icon(Icons.clear), label: const Text("تنظيف"), onPressed: (){
                setState((){ _logs.clear(); });
              }),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SelectableText(_logs[i], style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12)),
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
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [_buildBrowserTab(), _buildToolsTab(), _buildLogsTab()],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1A1A1A),
        onTap: (idx) => setState(() { _currentIndex = idx; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.language), label: "Browser"),
          BottomNavigationBarItem(icon: Icon(Icons.construction), label: "Tools"),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: "Logs"),
        ],
      ),
    );
  }
}
