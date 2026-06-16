import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ExhxxScraperApp());
}

class ExhxxScraperApp extends StatelessWidget {
  const ExhxxScraperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EXHXX Domain Scraper',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      ),
      home: const ScraperScreen(),
    );
  }
}

class ScraperScreen extends StatefulWidget {
  const ScraperScreen({super.key});

  @override
  State<ScraperScreen> createState() => _ScraperScreenState();
}

class _ScraperScreenState extends State<ScraperScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isAutoLoading = false;
  final String targetUrl = 'https://www.virustotal.com/gui/domain/tiktokcdn.com/relations';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            setState(() { _isLoading = false; });
            // تصفير الذاكرة السابقة عند تحديث الصفحة
            await _controller.runJavaScript('window.exhxxDomains = new Set();');
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  // دالة تشغيل الروبوت القناص والذاكرة الحية
  Future<void> _startAutoLoad() async {
    setState(() { _isAutoLoading = true; });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🤖 تم تفعيل القناص! كاعد يسحب الدومينات للذاكرة ويضغط...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );

    // الروبوت الجذري (جافاسكربت)
    final String jsSniperBot = '''
      if (!window.exhxxDomains) window.exhxxDomains = new Set();
      if (window.vtClicker) clearInterval(window.vtClicker);
      
      window.vtClicker = setInterval(function() {
        let allNodes = [];
        function traverse(node) {
            if (!node || node.nodeType !== 1) return;
            allNodes.push(node);
            if (node.shadowRoot) traverse(node.shadowRoot);
            let children = node.children || [];
            for (let i = 0; i < children.length; i++) traverse(children[i]);
        }
        traverse(document.documentElement);

        // 1. نظام الذاكرة الحية: سحب الدومينات الموجودة حالياً بالشاشة وحفظها
        function getShadowText(n) {
            let t = '';
            if (n.nodeType === 3) t += n.nodeValue + ' ';
            else if (n.nodeType === 1) {
                if (n.tagName === 'SCRIPT' || n.tagName === 'STYLE') return '';
                let childs = n.shadowRoot ? n.shadowRoot.childNodes : n.childNodes;
                for (let i = 0; i < childs.length; i++) t += getShadowText(childs[i]);
            }
            return t;
        }
        
        let currentText = getShadowText(document.body);
        let matches = currentText.match(/\\b(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}\\b/g);
        if (matches) {
            matches.forEach(m => {
                // فلترة استبعاد الكلمات الشائعة بالموقع
                if (!m.includes('virustotal') && !m.includes('gandi.net') && !m.includes('tiktokcdn.com')) {
                    window.exhxxDomains.add(m);
                }
            });
        }

        // 2. نظام القناص: البحث عن زر التحميل الخاص بـ Subdomains فقط
        let buttons = allNodes.filter(n => (n.tagName === 'VT-UI-BUTTON' || n.tagName === 'BUTTON') && n.textContent && n.textContent.includes('...'));
        
        for (let btn of buttons) {
            let current = btn;
            let isSubdomains = false;
            let isOtherSection = false;
            
            // الصعود 15 طبقة للبحث عن اسم القسم
            for (let i = 0; i < 15; i++) {
                if (!current) break;
                let text = current.textContent || "";
                
                if (text.includes('Subdomains')) isSubdomains = true;
                if (text.includes('Communicating Files') || text.includes('Resolutions') || text.includes('Historical Whois')) {
                    isOtherSection = true;
                }
                
                if (current.parentElement) {
                    current = current.parentElement;
                } else if (current.getRootNode() && current.getRootNode().host) {
                    current = current.getRootNode().host;
                } else {
                    break;
                }
            }
            
            // إذا الزر تابع للسب-دومين ومو تابع لغير قسم، اضغطه فوراً!
            if (isSubdomains && !isOtherSection) {
                btn.click();
                btn.scrollIntoView({behavior: "smooth", block: "center"});
                break; 
            }
        }
      }, 1000); // يفحص ويسحب كل ثانية
    ''';

    await _controller.runJavaScript(jsSniperBot);
  }

  Future<void> _stopAutoLoad() async {
    setState(() { _isAutoLoading = false; });
    await _controller.runJavaScript('if (window.vtClicker) clearInterval(window.vtClicker);');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🛑 تم إيقاف الروبوت! دوس زر السحب هسه.'), backgroundColor: Colors.teal),
    );
  }

  // دالة السحب من الذاكرة المخفية بدل الشاشة
  Future<void> _extractAndCopyDomains() async {
     try {
      // نطلب من المتصفح يعطينا كل الدومينات اللي انحفظت بمتغير window.exhxxDomains
      final Object result = await _controller.runJavaScriptReturningResult(
        "Array.from(window.exhxxDomains || []).join('\\n');"
      );
      
      String finalDomains = result.toString().replaceAll('"', '').trim();
      
      if (finalDomains.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الذاكرة فارغة! شغل الروبوت أولاً.'), backgroundColor: Colors.red));
        return;
      }

      await Clipboard.setData(ClipboardData(text: finalDomains));
      
      // حساب العدد من عدد الأسطر
      int count = finalDomains.split('\\n').length;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم سحب ($count) دومين بنجاح من الذاكرة الحية! 🔥'), backgroundColor: Colors.teal, duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXHXX SCRAPER 🤖', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_isAutoLoading) _stopAutoLoad();
              setState(() { _isLoading = true; });
              _controller.reload();
            },
          )
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: "btn_load",
              onPressed: _isAutoLoading ? _stopAutoLoad : _startAutoLoad,
              backgroundColor: _isAutoLoading ? Colors.redAccent : Colors.orangeAccent,
              foregroundColor: Colors.black,
              icon: Icon(_isAutoLoading ? Icons.stop : Icons.smart_toy),
              label: Text(_isAutoLoading ? 'إيقاف الروبوت 🛑' : 'تشغيل القناص 🎯', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            FloatingActionButton.extended(
              heroTag: "btn_scrape",
              onPressed: _extractAndCopyDomains,
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.content_copy),
              label: const Text('سحب من الذاكرة 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
