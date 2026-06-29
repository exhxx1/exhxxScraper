import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';

void main() {
  // تجاوز أخطاء شهادات الـ SSL عالمياً لتسهيل فحص الهوستات
  HttpOverrides.global = MyHttpOverrides();
  runApp(const CloudReaperApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class CloudReaperApp extends StatelessWidget {
  const CloudReaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EXHXX CloudReaper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070B19),
        primaryColor: const Color(0xFF00FF41),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'monospace', color: Colors.white),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // === الإحصائيات ===
  int totalScanned = 0;
  int aliveIps = 0;
  int deadIps = 0;
  bool isScanning = false;
  List<String> workingTargetsList = []; 

  // === الإعدادات ===
  double _threads = 100;
  double _timeout = 2.0;
  double _autoStopLimit = 0;
  final TextEditingController _portController = TextEditingController(text: "80, 443");
  final TextEditingController _targetController = TextEditingController();
  bool _isHostMode = false;
  
  // === الكونسول الحي ===
  List<Map<String, dynamic>> consoleLogs = [];
  final ScrollController _scrollController = ScrollController();

  final List<String> cfRanges = ["104.16", "104.17", "104.18", "104.19", "104.20", "104.21", "172.64", "172.65", "172.66", "172.67", "103.21", "103.22", "141.101"];

  void logToConsole(String msg, {bool isSuccess = false, bool isSystem = false, int port = 80}) {
    setState(() {
      consoleLogs.add({
        "time": "[${DateTime.now().toString().substring(11, 19)}]",
        "msg": msg,
        "isSuccess": isSuccess,
        "isSystem": isSystem,
        "port": port
      });
      if (consoleLogs.length > 400) consoleLogs.removeAt(0);
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // --- ميزة التوليد بالعدد المخصص ---
  void showGenerateDialog() {
    TextEditingController countCtrl = TextEditingController(text: "100");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1221),
        title: const Text("⚙️ توليد آيبيهات عشوائية", style: TextStyle(color: Colors.amber)),
        content: TextField(
          controller: countCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "شگد تريد تولد؟ (مثال: 500)",
            labelStyle: TextStyle(color: Colors.grey),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              int count = int.tryParse(countCtrl.text) ?? 50;
              Navigator.pop(ctx);
              _generateIPs(count);
            },
            child: const Text("توليد الآن", style: TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _generateIPs(int count) {
    final r = Random();
    String generated = "";
    for (int i = 0; i < count; i++) {
      String base = cfRanges[r.nextInt(cfRanges.length)];
      generated += "$base.${r.nextInt(256)}.${r.nextInt(256)}\n";
    }
    setState(() {
      _targetController.text = _targetController.text + generated;
      _isHostMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ تم توليد $count آي بي عشوائي بنجاح!"), backgroundColor: Colors.green));
  }

  void removeDuplicates() {
    List<String> targets = _targetController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    int originalLength = targets.length;
    targets = targets.toSet().toList();
    _targetController.text = targets.join('\n') + (targets.isNotEmpty ? '\n' : '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🧹 تم تنظيف ${originalLength - targets.length} أهداف مكررة!"), backgroundColor: Colors.blueAccent));
  }

  void exportLiveTargets() {
    if (workingTargetsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ لا يوجد أهداف شغالة لتصديرها!"), backgroundColor: Colors.orange));
      return;
    }
    Clipboard.setData(ClipboardData(text: workingTargetsList.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("📥 تم نسخ ${workingTargetsList.length} آي بي/هوست شغال للحافظة!"), backgroundColor: Colors.green));
  }

  // === محرك الفحص الدقيق (HTTP Client) ===
  Future<void> startScan() async {
    List<String> rawTargets = _targetController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (rawTargets.isEmpty) return;

    setState(() {
      isScanning = true;
      totalScanned = 0; aliveIps = 0; deadIps = 0;
      workingTargetsList.clear();
      consoleLogs.clear();
    });

    logToConsole("⚡ بدء الصيد العميق (HTTP Engine)...", isSystem: true);
    int concurrency = _threads.toInt();
    int currentIndex = 0;

    Future<void> worker() async {
      while (isScanning && currentIndex < rawTargets.length) {
        if (_autoStopLimit > 0 && aliveIps >= _autoStopLimit) {
          isScanning = false;
          logToConsole("🛑 تم الوصول للحد الأقصى للصيد (${_autoStopLimit.toInt()})", isSystem: true);
          break;
        }
        
        int myIndex = currentIndex++;
        if (myIndex >= rawTargets.length) break;
        await _checkTargetHTTP(rawTargets[myIndex]);
      }
    }

    List<Future> workers = List.generate(concurrency, (_) => worker());
    await Future.wait(workers);

    if (mounted && isScanning) {
      setState(() => isScanning = false);
      logToConsole("🏁 انتهت لستة الأهداف بالكامل!", isSystem: true);
    }
  }

  Future<void> _checkTargetHTTP(String target) async {
    if (!isScanning) return;
    List<String> portsStr = _portController.text.split(',');
    bool foundAlive = false;

    for (String pStr in portsStr) {
      if (!isScanning) break;
      int port = int.tryParse(pStr.trim()) ?? 80;
      // البورتات الآمنة تستخدم HTTPS
      String scheme = (port == 443 || port == 8443 || port == 2053 || port == 2083 || port == 2087 || port == 2096) ? "https" : "http";
      
      HttpClient? client;
      try {
        client = HttpClient()
          ..connectionTimeout = Duration(milliseconds: (_timeout * 1000).toInt());

        final request = await client.getUrl(Uri.parse('$scheme://$target:$port/'));
        request.headers.set('User-Agent', 'Mozilla/5.0');
        request.headers.set('Connection', 'close');

        final response = await request.close();
        int statusCode = response.statusCode;

        // جلب هيدرات كلاودفلير للتأكيد
        String server = response.headers.value('Server') ?? '';
        String cfRay = response.headers.value('CF-RAY') ?? '';
        bool isCf = server.toLowerCase().contains('cloudflare') || cfRay.isNotEmpty;
        String cfMark = isCf ? " [CF]" : "";

        foundAlive = true;
        if (!mounted) return;
        HapticFeedback.lightImpact();
        
        setState(() {
          aliveIps++;
          workingTargetsList.add("$target:$port");
          logToConsole("✅ $target:$port | HTTP $statusCode$cfMark", isSuccess: true, port: port);
        });
        break; // إذا اشتغل بورت نتوقف وننتقل للهدف التالي
      } catch (e) {
        // ميت
      } finally {
        client?.close(force: true); // تنظيف الرام فوراً
      }
    }

    if (!foundAlive && mounted) setState(() => deadIps++);
    if (mounted) setState(() => totalScanned++);
  }

  void stopScan() {
    setState(() => isScanning = false);
    logToConsole("🛑 تم إيقاف الفحص يدوياً.", isSystem: true);
  }

  @override
  Widget build(BuildContext context) {
    double successRate = totalScanned == 0 ? 0 : (aliveIps / totalScanned) * 100;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1221),
        title: const Text('💀 EXHXX CloudReaper Pro', style: TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: Colors.amber, size: 20),
            tooltip: 'مسح الكونسول',
            onPressed: () => setState(() => consoleLogs.clear()),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("مفحوص", totalScanned.toString(), Colors.blueAccent),
                _buildStatCard("شغال ✅", aliveIps.toString(), const Color(0xFF00FF41)),
                _buildStatCard("النجاح %", "${successRate.toStringAsFixed(1)}%", Colors.amber),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              flex: 4,
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0B1221), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("🎯 قائمة الأهداف", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                            ToggleButtons(
                              isSelected: [_isHostMode, !_isHostMode],
                              onPressed: isScanning ? null : (i) => setState(() => _isHostMode = i == 0),
                              color: Colors.white54, selectedColor: Colors.black, fillColor: const Color(0xFF00FF41),
                              borderRadius: BorderRadius.circular(5), constraints: const BoxConstraints(minHeight: 25, minWidth: 60),
                              children: const [Text("الهوستات", style: TextStyle(fontSize: 12)), Text("الآيبيهات", style: TextStyle(fontSize: 12))],
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _targetController, enabled: !isScanning, maxLines: 4,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(filled: true, fillColor: Colors.black26, border: OutlineInputBorder(), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41)))),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _toolBtn(Icons.auto_awesome, "توليد CF", showGenerateDialog, Colors.blue), // زر التوليد الجديد
                              const SizedBox(width: 8),
                              _toolBtn(Icons.delete_sweep, "تنظيف المكرر", removeDuplicates, Colors.orange),
                              const SizedBox(width: 8),
                              _toolBtn(Icons.copy_all, "تصدير الشغال", exportLiveTargets, const Color(0xFF00FF41)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0B1221), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("⚙️ إعدادات المحرك", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        const Divider(color: Colors.white12),
                        _sliderRow("متزامنة (Threads):", _threads, 10, 300, const Color(0xFF00FF41), (v) => setState(() => _threads = v)),
                        _sliderRow("مهلة (Timeout):", _timeout, 0.5, 5.0, Colors.orange, (v) => setState(() => _timeout = v), isDbl: true),
                        _sliderRow("توقف تلقائي عند:", _autoStopLimit, 0, 100, Colors.redAccent, (v) => setState(() => _autoStopLimit = v), isStop: true),
                        
                        TextField(
                          controller: _portController, enabled: !isScanning, style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'البورتات (80, 443, 8080)', labelStyle: TextStyle(color: Colors.grey), filled: true, fillColor: Colors.black26, isDense: true, border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity, padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.5))),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: consoleLogs.length,
                  itemBuilder: (context, index) {
                    var log = consoleLogs[index];
                    Color txtColor = Colors.white70;
                    if (log['isSystem']) txtColor = Colors.amber;
                    else if (log['isSuccess']) {
                      txtColor = log['port'] == 443 ? const Color(0xFF00FFFF) : const Color(0xFF00FF41); 
                    }

                    return InkWell(
                      onTap: () {
                        if (log['isSuccess']) {
                          // تنظيف النسخ من الرموز 
                          String cleanIp = log['msg'].split('|')[0].replaceAll("✅ ", "").trim();
                          Clipboard.setData(ClipboardData(text: cleanIp));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("📋 تم نسخ: $cleanIp"), duration: const Duration(seconds: 1)));
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text("${log['time']} ${log['msg']}", style: TextStyle(color: txtColor, fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: isScanning ? Colors.redAccent : const Color(0xFF00FF41), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: Icon(isScanning ? Icons.stop_circle : Icons.rocket_launch, color: Colors.black),
                label: Text(isScanning ? "إيقاف الهجوم (STOP)" : "بدء الصيد (START Hacking)", style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: isScanning ? stopScan : startScan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF0B1221), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3)), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap, Color color) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.2), foregroundColor: color, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), side: BorderSide(color: color.withOpacity(0.5))),
      icon: Icon(icon, size: 16), label: Text(label, style: const TextStyle(fontSize: 12)), onPressed: isScanning ? null : onTap,
    );
  }

  Widget _sliderRow(String label, double val, double min, double max, Color color, Function(double) onChanged, {bool isDbl = false, bool isStop = false}) {
    String valStr = isStop && val == 0 ? "بدون توقف" : (isDbl ? "${val.toStringAsFixed(1)}s" : "${val.toInt()}");
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 13)), Text(valStr, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))]),
        Slider(value: val, min: min, max: max, activeColor: color, onChanged: isScanning ? null : onChanged),
      ],
    );
  }
}
