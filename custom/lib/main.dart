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
      title: 'EXHXX Target Lock',
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
  
  // حالات الروبوت: 0 = متوقف، 1 = ينتظر لمستك للزر، 2 = كاعد يضغط تلقائياً
  int _botState = 0; 
  
  final String targetUrl = 'https://www.virustotal.com/gui/domain/tiktokcdn.com/relations';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'ExhxxChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'TARGET_LOCKED') {
            setState(() { _botState = 2; });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🎯 تم قفل الهدف بالملم! الروبوت بدأ بالضغط...'), backgroundColor: Colors.orange),
            );
          } else if (message.message == 'STOP_BOT') {
            setState(() { _botState = 0; });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🛑 الزر اختفى! (انتهت القائمة بالكامل).'), backgroundColor: Colors.teal, duration: Duration(seconds: 4)),
            );
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

  // دالة تفعيل الاستماع للمسة المستخدم (أخذ المقاس بالملم)
  Future<void> _startTargeting() async {
    setState(() { _botState = 1; }); // حالة انتظار اللمسة
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('👆 اضغط بيدك على زر (...) اللي تريده الآن!'),
        backgroundColor: Colors.blueAccent,
        duration: Duration(seconds: 5),
      ),
    );

    // كود جافاسكربت يسجل لمستك ويقفل على الزر اللي اختاريته
    final String jsLockOn = '''
      if (window.vtClicker) clearInterval(window.vtClicker);
      
      // دالة صيد اللمسة
      const touchInterceptor = function(e) {
          // منع النقرة من تفعيل شيء آخر في الموقع مؤقتاً
          e.preventDefault();
          e.stopPropagation();
          
          // الخدعة السحرية: composedPath تخترق كل طبقات الظل وتجيب العنصر اللي انلمس بالملم!
          let path = e.composedPath();
          let targetBtn = null;
          
          // البحث في مسار اللمسة عن زر
          for(let i=0; i<path.length; i++) {
              if (path[i].tagName === 'VT-UI-BUTTON' || path[i].tagName === 'BUTTON' || (path[i].textContent && path[i].textContent.trim() === '...')) {
                  targetBtn = path[i];
                  break;
              }
          }
          if (!targetBtn) targetBtn = path[0]; // إذا ما لقى زر رسمي، يقفل على النص الملموس
          
          window.vtLockedTarget = targetBtn; // تم قفل الهدف!
          
          // إزالة الاستماع للمسات حتى ترجع الصفحة طبيعية
          document.removeEventListener('click', touchInterceptor, true);
          
          // إخبار التطبيق أنه تم القفل
          if (window.ExhxxChannel) window.ExhxxChannel.postMessage('TARGET_LOCKED');
          
          // بدء الروبوت بالضغط على هذا العنصر المختار حصراً
          let failCount = 0;
          window.vtClicker = setInterval(function() {
              if (window.vtLockedTarget) {
                  // التحقق هل الزر لا يزال موجود بالصفحة (ما انمسح لأن القائمة خلصت)
                  let isStillInDOM = window.vtLockedTarget.getRootNode() !== window.vtLockedTarget;
                  
                  if (isStillInDOM) {
                      // النزول لمستوى الزر والضغط عليه
                      window.vtLockedTarget.scrollIntoView({behavior: 'smooth', block: 'center'});
                      setTimeout(() => {
                          try { window.vtLockedTarget.click(); } catch(err){}
                      }, 200);
                      failCount = 0;
                  } else {
                      // الزر انمسح من الموقع (يعني القائمة خلصت)
                      failCount++;
                      if (failCount > 3) {
                          clearInterval(window.vtClicker);
                          if (window.ExhxxChannel) window.ExhxxChannel.postMessage('STOP_BOT');
                      }
                  }
              }
          }, 1500); // يضغط كل ثانية ونص
      };
      
      // تفعيل اعتراض أول لمسة قادمة لك
      document.addEventListener('click', touchInterceptor, true);
    ''';

    await _controller.runJavaScript(jsLockOn);
  }

  Future<void> _stopAutoClicker() async {
    setState(() { _botState = 0; });
    await _controller.runJavaScript('''
      if (window.vtClicker) clearInterval(window.vtClicker);
      // مسح مستمع اللمسات إذا المستخدم بطل
      document.removeEventListener('click', window.touchInterceptor, true);
    ''');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🛑 تم إيقاف الروبوت يدوياً!'), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXHXX LOCK-ON 🎯', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_botState != 0) _stopAutoClicker();
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
        onPressed: _botState == 0 ? _startTargeting : _stopAutoClicker,
        backgroundColor: _botState == 0 ? Colors.tealAccent : (_botState == 1 ? Colors.blueAccent : Colors.redAccent),
        foregroundColor: Colors.black,
        icon: Icon(_botState == 0 ? Icons.ads_click : (_botState == 1 ? Icons.touch_app : Icons.stop)),
        label: Text(
          _botState == 0 ? 'تحديد الهدف يدوياً 🎯' : (_botState == 1 ? '👆 المس الزر الآن!' : 'الروبوت يعمل.. إيقاف 🛑'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
