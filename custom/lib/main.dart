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
          onPageFinished: (String url) {
            setState(() { _isLoading = false; });
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  // دالة تشغيل الروبوت الشامل ذو الـ 3 استراتيجيات
  Future<void> _startAutoLoad() async {
    setState(() { _isAutoLoading = true; });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🤖 الروبوت الشامل اشتغل! راح يطبق 3 خطط للاختراق...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );

    final String jsMultiStrategyClicker = '''
      if (window.vtClicker) clearInterval(window.vtClicker);
      window.vtClicker = setInterval(function() {
        // 1. نزول الشاشة لتحفيز التحميل (Lazy Load)
        window.scrollBy(0, 800);
        
        // 2. سحب كل عناصر الصفحة شاملة الطبقات المخفية (Shadow DOM)
        function getAllElements(root) {
            let all = [];
            function traverse(node) {
                if (!node || node.nodeType !== 1) return;
                all.push(node);
                if (node.shadowRoot) traverse(node.shadowRoot);
                let children = node.children || [];
                for (let i = 0; i < children.length; i++) traverse(children[i]);
            }
            traverse(document.documentElement);
            return all;
        }
        
        let allNodes = getAllElements(document.documentElement);
        let possibleButtons = allNodes.filter(n => n.tagName === 'VT-UI-BUTTON' || n.tagName === 'BUTTON');
        
        let clicked = false;

        // الخطة الأولى: البحث بالنص المباشر واختيار (الأول فقط)
        let textBtns = possibleButtons.filter(b => b.textContent && (b.textContent.includes('...') || b.textContent.toLowerCase().includes('load')));
        if (textBtns.length > 0) {
            textBtns[0].click();
            clicked = true;
        }
        
        // الخطة الثانية: البحث بالـ ID أو Class (إذا كان الزر عبارة عن أيقونة بدون نص) واختيار (الأول فقط)
        if (!clicked) {
            let idBtns = possibleButtons.filter(b => (b.id && b.id.toLowerCase().includes('more')) || (b.className && typeof b.className === 'string' && b.className.toLowerCase().includes('load')));
            if (idBtns.length > 0) {
                idBtns[0].click();
                clicked = true;
            }
        }
        
        // الخطة الثالثة (زر الطوارئ): أي عنصر بالصفحة يحتوي على وظيفة (Load More)
        if (!clicked) {
            let emergencyBtns = allNodes.filter(n => n.getAttribute && (n.getAttribute('aria-label') === 'Load more' || n.getAttribute('title') === 'Load more'));
            if (emergencyBtns.length > 0) {
                emergencyBtns[0].click();
                clicked = true;
            }
        }

      }, 1500); // يفحص ويضغط كل ثانية ونص حتى ما يعلق المتصفح
    ''';

    await _controller.runJavaScript(jsMultiStrategyClicker);
  }

  Future<void> _stopAutoLoad() async {
    setState(() { _isAutoLoading = false; });
    await _controller.runJavaScript('if (window.vtClicker) clearInterval(window.vtClicker);');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🛑 تم إيقاف الروبوت! تكدر تنسخ هسه.'), backgroundColor: Colors.teal),
    );
  }

  // أبقيت زر سحب الدومينات في حال أردت استخدامه كخيار ثاني للنسخ
  Future<void> _extractAndCopyDomains() async {
     try {
      final String jsDeepExtractor = '''
        (function() {
          function getShadowText(node) {
            let text = '';
            if (node.nodeType === 3) text += node.nodeValue + ' ';
            else if (node.nodeType === 1) {
              if (node.tagName === 'SCRIPT' || node.tagName === 'STYLE') return '';
              let children = node.shadowRoot ? node.shadowRoot.childNodes : node.childNodes;
              for (let i = 0; i < children.length; i++) text += getShadowText(children[i]);
            }
            return text;
          }
          return getShadowText(document.body);
        })();
      ''';
      final Object result = await _controller.runJavaScriptReturningResult(jsDeepExtractor);
      RegExp domainRegex = RegExp(r'\b(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}\b');
      Iterable<RegExpMatch> matches = domainRegex.allMatches(result.toString());
      Set<String> uniqueDomains = {};
      for (var m in matches) {
        if (!m.group(0)!.contains('virustotal')) uniqueDomains.add(m.group(0)!);
      }
      if (uniqueDomains.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: uniqueDomains.join('\n')));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ تم سحب ${uniqueDomains.length} دومين!')));
      }
    } catch (e) {}
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
              label: Text(_isAutoLoading ? 'إيقاف الروبوت 🛑' : 'تشغيل روبوت التحميل 🤖', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            FloatingActionButton.extended(
              heroTag: "btn_scrape",
              onPressed: _extractAndCopyDomains,
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.content_copy),
              label: const Text('سحب 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
