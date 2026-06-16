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
      title: 'EXHXX Auto Clicker',
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
  bool _isAutoClicking = false;
  final String targetUrl = 'https://www.virustotal.com/gui/domain/tiktokcdn.com/relations';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 1. إنشاء جسر التواصل بين JS و Flutter
      ..addJavaScriptChannel(
        'ExhxxChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'STOP_BOT') {
            _stopAutoClickerFromJS();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() { _isLoading = false; });
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  // دالة تُستدعى تلقائياً عندما يرسل الجافاسكربت إشارة انتهاء
  void _stopAutoClickerFromJS() {
    if (!mounted) return;
    setState(() { _isAutoClicking = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛑 انتهت القائمة بالكامل! النقار طفى نفسه تلقائياً.'), 
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _startAutoClicker() async {
    setState(() { _isAutoClicking = true; });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🤖 تم تشغيل النقار! راح ينزل ويضغط، ومن يخلص يطفي الزر من كيفه.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );

    final String jsUltimateClicker = '''
      if (window.vtClicker) clearInterval(window.vtClicker);
      
      let failCount = 0; 
      const MAX_FAILS = 8; 

      window.vtClicker = setInterval(function() {
        window.scrollBy({ top: 400, left: 0, behavior: 'smooth' });
        
        // 2. إصلاح مسح الـ Shadow DOM بشكل هندسي دقيق
        function getAllElements(root) {
            let all = [];
            function traverse(node) {
                if (!node) return;
                if (node.nodeType === 1) all.push(node); // Elements only
                
                // الغوص في الظل
                if (node.shadowRoot) traverse(node.shadowRoot);
                
                // الغوص في الأبناء بشكل صحيح (يدعم الـ ShadowRoot والـ Element العادي)
                let childrenNodes = node.shadowRoot ? node.shadowRoot.childNodes : node.childNodes;
                if (childrenNodes) {
                    for (let i = 0; i < childrenNodes.length; i++) {
                        traverse(childrenNodes[i]);
                    }
                }
            }
            traverse(root);
            return all;
        }

        let elements = getAllElements(document.documentElement);
        
        let targetBtn = elements.find(n => {
            if (n.tagName === 'VT-UI-BUTTON' || n.tagName === 'BUTTON') {
                let text = (n.textContent || "").trim();
                let aria = (n.getAttribute('aria-label') || "").toLowerCase();
                let title = (n.getAttribute('title') || "").toLowerCase();
                return text === '...' || aria.includes('load more') || title.includes('load more');
            }
            return false;
        });

        if (targetBtn) {
            // 3. التوجيه للزر (ScrollIntoView) قبل الضغط لتجنب أخطاء العرض
            targetBtn.scrollIntoView({ behavior: 'smooth', block: 'center' });
            
            // تأخير بسيط جداً لضمان وصول التمرير قبل الضغط
            setTimeout(() => {
                targetBtn.click();
            }, 300);
            
            failCount = 0; 
        } else {
            failCount++; 
            if (failCount >= MAX_FAILS) {
                clearInterval(window.vtClicker);
                // 4. إرسال إشارة عبر الجسر إلى تطبيق Flutter لإيقاف الزر
                if (window.ExhxxChannel) {
                    window.ExhxxChannel.postMessage('STOP_BOT');
                }
            }
        }

      }, 1500); 
    ''';

    await _controller.runJavaScript(jsUltimateClicker);
  }

  Future<void> _stopAutoClicker() async {
    setState(() { _isAutoClicking = false; });
    await _controller.runJavaScript('if (window.vtClicker) clearInterval(window.vtClicker);');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🛑 تم إيقاف النقار يدوياً!'), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXHXX ULTIMATE CLICKER 🤖', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_isAutoClicking) _stopAutoClicker();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAutoClicking ? _stopAutoClicker : _startAutoClicker,
        backgroundColor: _isAutoClicking ? Colors.redAccent : Colors.orangeAccent,
        foregroundColor: Colors.black,
        icon: Icon(_isAutoClicking ? Icons.stop : Icons.smart_toy),
        label: Text(
          _isAutoClicking ? 'النقار يعمل.. إيقاف 🛑' : 'تشغيل النقار النهائي 🤖',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
