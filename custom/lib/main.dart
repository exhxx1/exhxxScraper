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
          onPageFinished: (String url) {
            setState(() { _isLoading = false; });
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  // دالة تشغيل الروبوت الهجومي
  Future<void> _startAutoLoad() async {
    setState(() { _isAutoLoading = true; });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🤖 الروبوت الهجومي اشتغل! راح ينزل ويضغط بقوة...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );

    // سكريبت الروبوت الجديد: مسح شامل وتمرير تلقائي
    final String jsAggressiveClicker = '''
      if (window.vtClicker) clearInterval(window.vtClicker);
      window.vtClicker = setInterval(function() {
        // 1. تمرير الشاشة للأسفل لتحفيز الموقع
        window.scrollBy(0, 1500);
        
        // 2. خوارزمية المسح العميق
        let clicked = false;
        function traverse(node) {
            if (clicked || !node) return;
            
            // اصطياد أي زر يحتوي على النقاط
            if (node.nodeType === 1 && (node.tagName === 'VT-UI-BUTTON' || node.tagName === 'BUTTON')) {
                if (node.textContent && node.textContent.includes('...')) {
                    node.click();
                    clicked = true;
                    return;
                }
            }
            
            // اختراق الظل (Shadow DOM)
            if (node.shadowRoot) traverse(node.shadowRoot);
            
            // البحث في الأبناء
            if (node.childNodes) {
                node.childNodes.forEach(child => {
                    if (child.nodeType === 1) traverse(child);
                });
            }
        }
        traverse(document.body);
      }, 1000); // ينفذ الهجوم كل ثانية
    ''';

    await _controller.runJavaScript(jsAggressiveClicker);
  }

  // دالة إيقاف الروبوت
  Future<void> _stopAutoLoad() async {
    setState(() { _isAutoLoading = false; });
    await _controller.runJavaScript('if (window.vtClicker) clearInterval(window.vtClicker);');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🛑 تم إيقاف الروبوت! تكدر تنسخ هسه براحتك.'), backgroundColor: Colors.teal),
    );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAutoLoading ? _stopAutoLoad : _startAutoLoad,
        backgroundColor: _isAutoLoading ? Colors.redAccent : Colors.orangeAccent,
        foregroundColor: Colors.black,
        icon: Icon(_isAutoLoading ? Icons.stop : Icons.smart_toy),
        label: Text(
          _isAutoLoading ? 'إيقاف الروبوت 🛑' : 'تشغيل روبوت التحميل 🤖',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
