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

  Future<void> _extractAndCopyDomains() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري سحب الدومينات، لحظة يا بطل... ⏳')),
    );

    try {
      final Object result = await _controller.runJavaScriptReturningResult("document.body.innerText;");
      String pageText = result.toString();

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
            const SnackBar(content: Text('لم يتم العثور على دومينات. انزل لأسفل الصفحة لتتحمل.')),
          );
        }
        return;
      }

      String finalText = uniqueDomains.join('\n');
      await Clipboard.setData(ClipboardData(text: finalText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم سحب ونسخ ${uniqueDomains.length} دومين بنجاح! 🚀'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _extractAndCopyDomains,
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.content_copy),
        label: const Text('سحب الدومينات 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
