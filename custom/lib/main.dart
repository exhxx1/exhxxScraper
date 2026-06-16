import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const ExhxxScraperApp());
}

class ExhxxScraperApp extends StatelessWidget {
  const ExhxxScraperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EXHXX Lab',
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
  String _activeBotName = "";
  final String targetUrl = 'https://www.virustotal.com/gui/domain/tiktokcdn.com/relations';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() { _isLoading = false; });
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  // دالة إطلاق الروبوت بناءً على الرقم المختار من 1 إلى 6
  Future<void> _fireBot(int strategy, String botName) async {
    setState(() { _activeBotName = botName; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🚀 تم تشغيل: \$botName'), backgroundColor: Colors.orange, duration: const Duration(seconds: 2)),
    );

    // سكريبت الجافاسكربت الشامل الذي يحتوي على 6 خطط هجومية
    final String jsArsenal = '''
      if (window.vtClicker) clearInterval(window.vtClicker);
      
      window.vtClicker = setInterval(function() {
        let strategy = $strategy;
        
        // مسح الظل الشامل
        function getAllElements(root) {
            let all = [];
            function traverse(node) {
                if (!node || node.nodeType !== 1) return;
                all.push(node);
                if (node.shadowRoot) traverse(node.shadowRoot);
                let children = node.shadowRoot ? node.shadowRoot.childNodes : node.childNodes;
                if (children) { for (let i = 0; i < children.length; i++) traverse(children[i]); }
            }
            traverse(root);
            return all;
        }

        let elements = getAllElements(document.documentElement);
        let clicked = false;

        // ---------------------------------------------------------
        // الخطة 1: القناص المباشر (يضغط على أول زر ... يلقاه بالشاشة)
        // ---------------------------------------------------------
        if (strategy === 1) {
            window.scrollBy({ top: 300, behavior: 'smooth' });
            let btn = elements.find(n => (n.tagName === 'VT-UI-BUTTON' || n.tagName === 'BUTTON') && (n.textContent || "").trim() === '...');
            if (btn) { btn.scrollIntoView({block: 'center'}); setTimeout(()=>btn.click(), 200); clicked = true; }
        }

        // ---------------------------------------------------------
        // الخطة 2: قناص الحاوية (يبحث عن قسم Subdomains ويقفل عليه)
        // ---------------------------------------------------------
        else if (strategy === 2) {
            window.scrollBy({ top: 300, behavior: 'smooth' });
            let subdomainsContainer = elements.find(n => n.textContent && n.textContent.includes('Subdomains') && n.tagName.includes('VT-UI'));
            if (subdomainsContainer) {
                let btns = getAllElements(subdomainsContainer).filter(n => (n.tagName === 'VT-UI-BUTTON' || n.tagName === 'BUTTON') && (n.textContent || "").trim() === '...');
                if (btns.length > 0) { btns[0].scrollIntoView({block: 'center'}); setTimeout(()=>btns[0].click(), 200); clicked = true; }
            }
        }

        // ---------------------------------------------------------
        // الخطة 3: محاكي الماوس الحقيقي (Event Dispatcher)
        // ---------------------------------------------------------
        else if (strategy === 3) {
            window.scrollBy({ top: 300, behavior: 'smooth' });
            let btn = elements.find(n => (n.tagName === 'VT-UI-BUTTON' || n.tagName === 'BUTTON') && (n.textContent || "").trim() === '...');
            if (btn) {
                btn.scrollIntoView({block: 'center'});
                setTimeout(() => {
                    btn.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, composed: true }));
                }, 200);
                clicked = true;
            }
        }

        // ---------------------------------------------------------
        // الخطة 4: باحث الأكواد المخفية (Aria-Label)
        // ---------------------------------------------------------
        else if (strategy === 4) {
            window.scrollBy({ top: 300, behavior: 'smooth' });
            let btn = elements.find(n => {
               let aria = (n.getAttribute('aria-label') || "").toLowerCase();
               let title = (n.getAttribute('title') || "").toLowerCase();
               return aria.includes('load') || title.includes('more');
            });
            if (btn) { btn.scrollIntoView({block: 'center'}); setTimeout(()=>btn.click(), 200); clicked = true; }
        }

        // ---------------------------------------------------------
        // الخطة 5: المجنزرة (يضغط على كل أزرار ... في كل الأقسام معاً!)
        // ---------------------------------------------------------
        else if (strategy === 5) {
            window.scrollBy({ top: 500, behavior: 'smooth' });
            let btns = elements.filter(n => (n.tagName === 'VT-UI-BUTTON' || n.tagName === 'BUTTON') && (n.textContent || "").trim() === '...');
            btns.forEach(b => b.click()); // يضغطها كلها بدون تفكير
            if(btns.length > 0) clicked = true;
        }

        // ---------------------------------------------------------
        // الخطة 6: القناص الجغرافي (يبحث بجوار كلمة Subdomains مباشرة)
        // ---------------------------------------------------------
        else if (strategy === 6) {
            let walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null, false);
            let node;
            while (node = walker.nextNode()) {
                if (node.nodeValue.includes('Subdomains')) {
                    let parent = node.parentElement;
                    for(let i=0; i<5; i++) { if(parent) parent = parent.parentElement; } // اصعد 5 درجات
                    if (parent) {
                        let btn = getAllElements(parent).find(n => n.textContent && n.textContent.trim() === '...');
                        if (btn) { btn.scrollIntoView({block: 'center'}); setTimeout(()=>btn.click(), 200); clicked = true; break; }
                    }
                }
            }
        }

      }, 1500); 
    ''';

    await _controller.runJavaScript(jsArsenal);
  }

  Future<void> _stopAllBots() async {
    setState(() { _activeBotName = ""; });
    await _controller.runJavaScript('if (window.vtClicker) clearInterval(window.vtClicker);');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🛑 تم إيقاف جميع الروبوتات.'), backgroundColor: Colors.red),
    );
  }

  // واجهة اختيار الروبوتات (المختبر)
  void _openLabMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧪 مختبر الروبوتات (اختر خطة وجرب)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10, runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _botButton(1, '1. المباشر (أول زر)', Colors.blue),
                  _botButton(2, '2. قناص الحاوية (مخصص)', Colors.green),
                  _botButton(3, '3. محاكي الماوس', Colors.purple),
                  _botButton(4, '4. باحث الأكواد', Colors.teal),
                  _botButton(5, '5. المجنزرة (يضغط الكل)', Colors.orange),
                  _botButton(6, '6. القناص الجغرافي', Colors.brown),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                onPressed: () { Navigator.pop(context); _stopAllBots(); },
                icon: const Icon(Icons.stop), label: const Text('إيقاف الروبوت الحالي 🛑', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _botButton(int id, String title, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      onPressed: () {
        Navigator.pop(context);
        _fireBot(id, title);
      },
      child: Text(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_activeBotName.isEmpty ? 'EXHXX LAB 🧪' : 'شغال: $_activeBotName 🤖', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { _stopAllBots(); setState(() { _isLoading = true; }); _controller.reload(); },
          )
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openLabMenu,
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.science),
        label: const Text('فتح المختبر 🧪', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
