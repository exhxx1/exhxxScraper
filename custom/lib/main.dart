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

  // دالة تشغيل النقار الذكي والمحسّن
  Future<void> _startAutoClicker() async {
    setState(() { _isAutoClicking = true; });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🤖 تم تشغيل النقار الذكي! راح ينزل بهدوء ويوقف تلقائياً من يخلص.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );

    // كود جافاسكربت المحسن بناءً على التحليل المعماري
    final String jsSmartClicker = '''
      if (window.vtClicker) clearInterval(window.vtClicker);
      
      let failCount = 0; // عداد ذكي لاكتشاف نهاية القائمة
      const MAX_FAILS = 8; // إذا بحث 8 مرات متتالية وما لقى الزر، يطفي نفسه

      window.vtClicker = setInterval(function() {
        // 1. التمرير الهادئ (Smooth Scroll) بمقدار أقل لتجنب تجاوز الزر
        window.scrollBy({ top: 400, left: 0, behavior: 'smooth' });
        
        // 2. دالة المسح الشامل القوية لكل عناصر الصفحة (بما فيها الـ Shadow DOM)
        function getAllElements(root) {
            let all = [];
            function traverse(node) {
                if (!node || node.nodeType !== 1) return;
                all.push(node);
                if (node.shadowRoot) traverse(node.shadowRoot);
                let children = node.children || [];
                for (let i = 0; i < children.length; i++) traverse(children[i]);
            }
            traverse(root);
            return all;
        }

        let elements = getAllElements(document.documentElement);
        
        // البحث عن الزر ضمن جميع العناصر المستخرجة
        let targetBtn = elements.find(n => {
            if (n.tagName === 'VT-UI-BUTTON' || n.tagName === 'BUTTON') {
                let text = (n.textContent || "").trim();
                let aria = (n.getAttribute('aria-label') || "").toLowerCase();
                let title = (n.getAttribute('title') || "").toLowerCase();
                return text === '...' || aria.includes('load more') || title.includes('load more');
            }
            return false;
        });

        // 3. اتخاذ القرار (الضغط أو زيادة العداد)
        if (targetBtn) {
            targetBtn.click();
            failCount = 0; // تصفير العداد لأننا لقينا الزر
        } else {
            failCount++; // زيادة العداد
            if (failCount >= MAX_FAILS) {
                // إيقاف الروبوت تلقائياً لعدم وجود الزر لفترة طويلة
                clearInterval(window.vtClicker);
                console.log("EXHXX_BOT: Finished all clicks.");
            }
        }

      }, 1500); // الانتظار 1.5 ثانية يكفي لتحميل البيانات الجديدة بهدوء
    ''';

    await _controller.runJavaScript(jsSmartClicker);
  }

  Future<void> _stopAutoClicker() async {
    setState(() { _isAutoClicking = false; });
    await _controller.runJavaScript('if (window.vtClicker) clearInterval(window.vtClicker);');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🛑 تم إيقاف النقار!'), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXHXX SMART CLICKER 🤖', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          _isAutoClicking ? 'إيقاف النقار 🛑' : 'تشغيل النقار 🤖',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
