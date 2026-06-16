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
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() { _isLoading = false; });
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  // دالة تشغيل روبوت النقر (النقار)
  Future<void> _startAutoClicker() async {
    setState(() { _isAutoClicking = true; });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🤖 تم تشغيل النقار! راح ينزل ويضغط على (...) فقط.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );

    // كود جافاسكربت نقي: ينزل الشاشة، يبحث عن (...) في كل الطبقات المخفية، ويضغط!
    final String jsPureClicker = '''
      if (window.vtClicker) clearInterval(window.vtClicker);
      
      window.vtClicker = setInterval(function() {
        // 1. التمرير للأسفل ببطء لضمان ظهور الزر
        window.scrollBy(0, 800);
        
        let clicked = false;

        // 2. دالة اختراق الطبقات المخفية (Shadow DOM) والبحث عن الزر
        function findAndClick(node) {
            if (clicked || !node || node.nodeType !== 1) return;

            // فحص إذا كان العنصر هو زر
            if (node.tagName === 'VT-UI-BUTTON' || node.tagName === 'BUTTON') {
                let text = (node.textContent || "").trim();
                let aria = (node.getAttribute('aria-label') || "").toLowerCase();
                let title = (node.getAttribute('title') || "").toLowerCase();

                // إذا كان الزر يحتوي على نقاط أو اسمه تحميل المزيد
                if (text === '...' || aria.includes('load more') || title.includes('load more')) {
                    node.click();
                    clicked = true;
                    return;
                }
            }

            // الغوص في الطبقات المخفية (Shadow Root)
            if (node.shadowRoot) findAndClick(node.shadowRoot);

            // الغوص في العناصر العادية
            let children = node.children || [];
            for (let i = 0; i < children.length; i++) {
                findAndClick(children[i]);
            }
        }

        // بدء البحث من بداية الصفحة
        findAndClick(document.body);

      }, 1500); // يفحص ويضغط كل ثانية ونصف
    ''';

    await _controller.runJavaScript(jsPureClicker);
  }

  // دالة إيقاف الروبوت
  Future<void> _stopAutoClicker() async {
    setState(() { _isAutoClicking = false; });
    await _controller.runJavaScript('if (window.vtClicker) clearInterval(window.vtClicker);');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🛑 تم إيقاف النقار! تقدر تنسخ الدومينات براحتك هسه.'), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXHXX CLICKER 🤖', style: TextStyle(fontWeight: FontWeight.bold)),
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
      // زر عائم واحد كبير بنص الشاشة للتحكم بالروبوت
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAutoClicking ? _stopAutoClicker : _startAutoClicker,
        backgroundColor: _isAutoClicking ? Colors.redAccent : Colors.orangeAccent,
        foregroundColor: Colors.black,
        icon: Icon(_isAutoClicking ? Icons.stop : Icons.smart_toy),
        label: Text(
          _isAutoClicking ? 'إيقاف النقار 🛑' : 'تشغيل النقار 🤖',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
