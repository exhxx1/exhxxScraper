import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // روبوت الضغط التلقائي على زر ( ... )
  Future<void> _autoLoadMore() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري البحث عن زر التحميل والضغط عليه... 🤖')),
    );

    final String jsClicker = '''
      (function() {
        function clickLoadMore(node) {
          if (node.nodeType === 1) { // ELEMENT_NODE
            if (node.textContent.trim() === '...') {
              try { node.click(); return true; } catch(e){}
            }
            let children = node.shadowRoot ? node.shadowRoot.childNodes : node.childNodes;
            for (let i = 0; i < children.length; i++) {
              if (clickLoadMore(children[i])) return true;
            }
          }
          return false;
        }
        return clickLoadMore(document.body);
      })();
    ''';

    final Object result = await _controller.runJavaScriptReturningResult(jsClicker);
    
    if (result.toString() == 'true') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم ضغط زر (...) بنجاح! انتظر ثواني للتحميل ⏳'), backgroundColor: Colors.orange),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على زر (...). قد تكون وصلت للنهاية!'), backgroundColor: Colors.grey),
      );
    }
  }

  // الدالة السحرية المحدثة لاختراق حماية Shadow DOM وسحب الدومينات
  Future<void> _extractAndCopyDomains() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري اختراق الصفحة وسحب الدومينات... 🚀')),
    );

    try {
      final String jsDeepExtractor = '''
        (function() {
          function getShadowText(node) {
            let text = '';
            if (node.nodeType === 3) { // TEXT_NODE
              text += node.nodeValue + ' ';
            } else if (node.nodeType === 1) { // ELEMENT_NODE
              if (node.tagName === 'SCRIPT' || node.tagName === 'STYLE') return '';
              let children = node.shadowRoot ? node.shadowRoot.childNodes : node.childNodes;
              for (let i = 0; i < children.length; i++) {
                text += getShadowText(children[i]);
              }
            }
            return text;
          }
          return getShadowText(document.body);
        })();
      ''';

      final Object result = await _controller.runJavaScriptReturningResult(jsDeepExtractor);
      String pageText = result.toString();

      // فلترة النصوص بدقة
      RegExp domainRegex = RegExp(r'\b(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}\b');
      Iterable<RegExpMatch> matches = domainRegex.allMatches(pageText);

      Set<String> uniqueDomains = {};
      for (var match in matches) {
        String domain = match.group(0)!;
        if (!domain.contains('virustotal') && domain.contains('.')) {
          uniqueDomains.add(domain);
        }
      }

      if (uniqueDomains.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم العثور على دومينات، حاول تحديث الصفحة.'), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      String finalText = uniqueDomains.join('\n');
      await Clipboard.setData(ClipboardData(text: finalText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم سحب (${uniqueDomains.length}) دومين للحافظة! 🔥'),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXHXX SCRAPER 🕷️', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
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
            const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
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
              onPressed: _autoLoadMore,
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.downloading),
              label: const Text('تحميل المزيد 🔄', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            FloatingActionButton.extended(
              heroTag: "btn_scrape",
              onPressed: _extractAndCopyDomains,
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.content_copy),
              label: const Text('سحب الدومينات 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
