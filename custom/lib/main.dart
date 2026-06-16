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

  // دالة تشغيل الروبوت الآلي
  Future<void> _startAutoLoad() async {
    setState(() { _isAutoLoading = true; });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🤖 تم تفعيل الروبوت! راح ينزل ويضغط ( ... ) تلقائياً...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );

    // سكريبت الروبوت: يبحث بالظل (Shadow DOM) ويضغط الزر كل ثانية ونص
    final String jsAutoClicker = '''
      if (window.vtClicker) clearInterval(window.vtClicker);
      window.vtClicker = setInterval(function() {
        let clicked = false;
        function walk(node) {
          if (clicked || !node || node.nodeType !== 1) return;
          
          // البحث عن أزرار الموقع الرسمية
          if (node.tagName === 'VT-UI-BUTTON' || node.tagName === 'BUTTON') {
              let text = node.textContent.trim();
              if (text === '...' || text.toLowerCase().includes('load more')) {
                  node.click();
                  clicked = true;
                  // التمرير التلقائي للأسفل لمتابعة التحميل
                  node.scrollIntoView({behavior: "smooth", block: "center"});
                  return;
              }
          }
          
          // الدخول للطبقات المخفية
          if (node.shadowRoot) walk(node.shadowRoot);
          for (let i = 0; i < node.children.length; i++) {
              walk(node.children[i]);
          }
        }
        walk(document.documentElement);
      }, 1500); // 1500 مللي ثانية (ثانية ونصف) بين كل ضغطة
    ''';

    await _controller.runJavaScript(jsAutoClicker);
  }

  // دالة إيقاف الروبوت
  Future<void> _stopAutoLoad() async {
    setState(() { _isAutoLoading = false; });
    await _controller.runJavaScript('if (window.vtClicker) clearInterval(window.vtClicker);');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🛑 تم إيقاف الروبوت! تكدر تنسخ هسه.'), backgroundColor: Colors.red),
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
