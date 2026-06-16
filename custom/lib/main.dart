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
        scaffoldBackgroundColor: const Color(0xFF070707),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF111111)),
        colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent, secondary: Colors.amberAccent),
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
  final TextEditingController _urlController = TextEditingController(text: 'https://kd1s.com');
  
  final List<String> _logs = [];

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
        setState(() { _logs.add(msg.message); });
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          _injectOmniRadar(); 
        },
        onPageFinished: (url) {
          _applyEnabledTools();
        },
      ))
      ..loadRequest(Uri.parse(_urlController.text));
  }

  // ==========================================
  // محرك الرادار الشامل مع مفكك الشفرات (Auto-Decoder)
  // ==========================================
  void _injectOmniRadar() {
    if (!_optOmniSniffer) return;
    
    _controller.runJavaScript('''
      if(!window.__exhxxOmniHooked){
        window.__exhxxOmniHooked = true;

        // دالة تفكيك الشفرات (URL Decode & JSON Parse) لتجميل العرض
        function decodeAndFormat(data) {
           if(!data) return '';
           if(typeof data !== 'string') return 'Binary/Object';
           
           // محاولة فك ترميز الـ URL (تحويل %5B إلى [ وما إلى ذلك)
           let decoded = data;
           try { decoded = decodeURIComponent(data.replace(/\\+/g, ' ')); } catch(e) {}
           
           // محاولة تحويل البيانات إلى شكل JSON مرتب إذا كانت من نوع Form
           if(decoded.includes('=')) {
              let obj = {};
              decoded.split('&').forEach(pair => {
                 let parts = pair.split('=');
                 if(parts.length === 2) obj[parts[0]] = parts[1];
              });
              return JSON.stringify(obj, null, 2);
           }
           
           try {
              return JSON.stringify(JSON.parse(decoded), null, 2);
           } catch(e) {
              return decoded.substring(0, 500); 
           }
        }

        function logTraffic(type, method, url, data) {
           // تجاهل روابط جوجل أنالتكس لأنها مزعجة وتملأ الشاشة
           if(url.includes('google-analytics.com') || url.includes('google.com/g/collect')) return;

           let prettyData = decodeAndFormat(data);
           let payload = data ? "\\n[PAYLOAD]:\\n" + prettyData : "";
           ExhxxLog.postMessage('[' + type + '] [' + method + '] ' + url + payload);
        }

        // 1. اعتراض Fetch API
        const origFetch = window.fetch;
        window.fetch = async function(...args) {
          let url = typeof args[0] === 'string' ? args[0] : (args[0] && args[0].url ? args[0].url : 'Unknown URL');
          let method = (args[1] && args[1].method) ? args[1].method : 'GET';
          let body = (args[1] && args[1].body) ? args[1].body : '';
          logTraffic('FETCH', method, url, body);
          return origFetch.apply(this, args);
        };

        // 2. اعتراض XMLHttpRequest
        const origOpen = XMLHttpRequest.prototype.open;
        const origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url) {
          this._exhxxMethod = method;
          this._exhxxUrl = url;
          origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function(body) {
          logTraffic('XHR', this._exhxxMethod, this._exhxxUrl, body);
          origSend.apply(this, arguments);
        };

        // 3. اعتراض Forms (النماذج - مثل تسجيل الدخول والرشق)
        document.addEventListener('submit', function(e) {
          if(e.target && e.target.tagName === 'FORM') {
            let formData = new FormData(e.target);
            let obj = {};
            formData.forEach((value, key) => { obj[key] = value; });
            logTraffic('FORM', e.target.method.toUpperCase(), e.target.action || window.location.href, JSON.stringify(obj));
          }
        }, true);
      }
    ''');
  }

  void _applyEnabledTools() {
    _injectOmniRadar(); 

    if (_optMediaBlocker) {
      _controller.runJavaScript("var s=document.createElement('style');s.innerHTML='img,video,iframe,canvas{display:none !important;} *{background-image:none !important;}';document.head.appendChild(s);");
    }
    if (_optConsoleHijack) {
      _controller.runJavaScript('''
        if(!window.__exhxxConsoleHooked) {
          window.__exhxxConsoleHooked = true;
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
        document.addEventListener('contextmenu', event => event.stopPropagation(), true);
        document.addEventListener('selectstart', event => event.stopPropagation(), true);
        document.addEventListener('copy', event => event.stopPropagation(), true);
        var s=document.createElement('style');s.innerHTML='*{user-select: auto !important; -webkit-user-select: auto !important;}';document.head.appendChild(s);
      ''');
    }
    if (_optAntiDebug) {
      _controller.runJavaScript("console.warn=function(){}; console.error=function(){}; setInterval(()=>{Function.prototype.constructor=function(){};}, 100);");
    }
    if (_optAutoScroll) {
      _controller.runJavaScript("if(!window.vtScroller) window.vtScroller = setInterval(()=>window.scrollBy({top:500, behavior:'smooth'}), 800);");
    } else {
      _controller.runJavaScript("if(window.vtScroller) clearInterval(window.vtScroller); window.vtScroller=null;");
    }
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

  void _harvestCookies() async {
    final result = await _controller.runJavaScriptReturningResult("document.cookie;");
    setState(() { _logs.add("[DATA] 🍪 COOKIES: \n" + result.toString().replaceAll('"', '')); });
    _currentIndex = 2; 
  }

  void _extractAllLinks() async {
    final result = await _controller.runJavaScriptReturningResult("Array.from(document.querySelectorAll('a')).map(a => a.href).join('\\n');");
    setState(() { _logs.add("[DATA] 🔗 ALL LINKS: \n" + result.toString().replaceAll('"', '')); });
    _currentIndex = 2;
  }

  void _extractLiveDOM() async {
    final result = await _controller.runJavaScriptReturningResult("document.documentElement.outerHTML;");
    setState(() { _logs.add("[DATA] 📄 HTML SOURCE: \n" + result.toString().substring(0, 1000) + "... (تم سحب الكود)"); });
    _currentIndex = 2;
  }

  void _nukeStorage() async {
    await _controller.clearCache();
    await _controller.clearLocalStorage();
    setState(() { _logs.add("[SYSTEM] ☢️ تم تدمير الكاش والبيانات بالكامل!"); });
    _controller.reload();
  }

  void _injectCustomJs() {
    TextEditingController jsCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text("حقن كود JavaScript", style: TextStyle(color: Colors.cyanAccent)),
      content: TextField(controller: jsCtrl, maxLines: 6, style: const TextStyle(color: Colors.white, fontFamily: 'monospace'), decoration: const InputDecoration(hintText: "اكتب الكود هنا...", border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
        ElevatedButton(onPressed: (){
          _controller.runJavaScript(jsCtrl.text);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("💉 تم حقن الكود بنجاح!")));
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black), child: const Text("حقن وتنفيد"))
      ],
    ));
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
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15), hintText: "https://...", 
                  filled: true, fillColor: Colors.black, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)
                ),
                onSubmitted: (val) {
                  if(!val.startsWith("http")) val = "https://" + val;
                  _controller.loadRequest(Uri.parse(val));
                },
              )),
              IconButton(icon: const Icon(Icons.rocket_launch, color: Colors.cyanAccent), onPressed: () {
                String val = _urlController.text;
                if(!val.startsWith("http")) val = "https://" + val;
                _controller.loadRequest(Uri.parse(val));
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
        const Text("أنظمة الاستخبارات (Intelligence)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
        const Divider(color: Colors.white24),
        SwitchListTile(activeColor: Colors.cyanAccent, title: const Text("📡 الرادار الشامل (Omni-Sniffer)"), subtitle: const Text("يعترض الطلبات ويفك التشفير تلقائياً"), value: _optOmniSniffer, onChanged: (v){ setState(() { _optOmniSniffer=v; _injectOmniRadar(); });}),
        SwitchListTile(activeColor: Colors.cyanAccent, title: const Text("🎙️ مختطف الكونسول (Console Hijack)"), subtitle: const Text("يتجسس على أخطاء ورسائل الموقع السرية"), value: _optConsoleHijack, onChanged: (v){ setState(() { _optConsoleHijack=v; _applyEnabledTools(); });}),
        SwitchListTile(activeColor: Colors.cyanAccent, title: const Text("🔓 فك حظر النسخ (Unlock Copy)"), subtitle: const Text("يلغي حظر الكليك يمين والنسخ بالموقع"), value: _optUnlockRightClick, onChanged: (v){ setState(() { _optUnlockRightClick=v; _applyEnabledTools(); });}),
        
        const SizedBox(height: 20),
        const Text("أنظمة التحكم والأتمتة (Control & Automation)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
        const Divider(color: Colors.white24),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("🚀 تيربو بلوكر (Media Blocker)"), subtitle: const Text("إخفاء الميديا لزيادة سرعة الموقع 10x"), value: _optMediaBlocker, onChanged: (v){ setState(() { _optMediaBlocker=v; _applyEnabledTools(); });}),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("📜 التمرير السريع (Fast Scroll)"), subtitle: const Text("روبوت ينزل الشاشة بسرعة لتحفيز الـ Lazy Load"), value: _optAutoScroll, onChanged: (v){ setState(() { _optAutoScroll=v; _applyEnabledTools(); });}),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("🤖 النقار الجذري (Shadow Clicker)"), subtitle: const Text("اختراق الظل لضغط أزرار Load More"), value: _optShadowClicker, onChanged: (v){ setState(() { _optShadowClicker=v; _applyEnabledTools(); });}),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("💻 مزيف الجهاز (Desktop Spoofer)"), subtitle: const Text("تغيير البصمة لـ Windows PC"), value: _optSpoofer, onChanged: (v){ 
          setState(() { _optSpoofer=v; });
          _controller.setUserAgent(_optSpoofer ? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" : "");
          _controller.reload();
        }),
        SwitchListTile(activeColor: Colors.amberAccent, title: const Text("🛡️ قاتل الحمايات (Anti-Debug)"), subtitle: const Text("يمنع الموقع من اكتشاف أدواتك"), value: _optAntiDebug, onChanged: (v){ setState(() { _optAntiDebug=v; _applyEnabledTools(); });}),

        const SizedBox(height: 20),
        const Text("عمليات السحب النووية (Extraction)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
        const Divider(color: Colors.white24),
        ListTile(leading: const Icon(Icons.cookie, color: Colors.orange), title: const Text("سحب كل الكوكيز (Harvest Cookies)"), onTap: _harvestCookies),
        ListTile(leading: const Icon(Icons.link, color: Colors.lightBlue), title: const Text("استخراج كل الروابط (Extract All Links)"), onTap: _extractAllLinks),
        ListTile(leading: const Icon(Icons.html, color: Colors.green), title: const Text("سحب كود الـ HTML الحي (Live DOM)"), onTap: _extractLiveDOM),
        ListTile(leading: const Icon(Icons.code, color: Colors.purpleAccent), title: const Text("حقن سكربت JS مخصص (Inject Code)"), onTap: _injectCustomJs),
        ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text("المسح النووي وتصفير الهوية (Nuke Data)"), onTap: _nukeStorage),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), color: const Color(0xFF111111),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("OMNI TERMINAL", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.grey)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.copy, color: Colors.cyanAccent), onPressed: (){
                    Clipboard.setData(ClipboardData(text: _logs.join('\n\\n')));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم نسخ جميع البيانات للاستخدام!")));
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
                Color textColor = Colors.white;
                if (_logs[i].startsWith('[FETCH]')) textColor = Colors.greenAccent;
                else if (_logs[i].startsWith('[XHR]')) textColor = Colors.cyanAccent;
                else if (_logs[i].startsWith('[FORM]')) textColor = Colors.pinkAccent;
                else if (_logs[i].startsWith('[DATA]')) textColor = Colors.amberAccent;
                else if (_logs[i].startsWith('[CONSOLE]')) textColor = Colors.yellowAccent;
                else if (_logs[i].startsWith('[SYSTEM]')) textColor = Colors.redAccent;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: SelectableText("> ${_logs[i]}", style: TextStyle(color: textColor, fontFamily: 'monospace', fontSize: 13)),
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
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.grey[700],
        backgroundColor: const Color(0xFF111111),
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() { _currentIndex = idx; }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.public), label: "Browser"),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize), label: "Omni Tools"),
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: "Terminal"),
        ],
      ),
    );
  }
}
