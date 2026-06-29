import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const CloudReaperApp());
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

  // === الإعدادات ===
  double _threads = 50;
  double _timeout = 2.0;
  final TextEditingController _portController = TextEditingController(text: "80, 443");
  
  // === الكونسول الحي ===
  List<String> consoleLogs = [];
  final ScrollController _scrollController = ScrollController();

  // === دالة طباعة الكونسول ===
  void logToConsole(String msg) {
    setState(() {
      consoleLogs.add("[${DateTime.now().toString().substring(11, 19)}] $msg");
      if (consoleLogs.length > 200) consoleLogs.removeAt(0); // منع امتلاء الرام
    });
    // النزول التلقائي لأسفل الكونسول
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // === محاكي توليد الآيبيهات (للتجربة السريعة) ===
  String getRandomCloudflareIp() {
    final ranges = ["104.16", "104.17", "104.18", "104.19", "172.64", "172.65"];
    final r = Random();
    return "${ranges[r.nextInt(ranges.length)]}.${r.nextInt(255)}.${r.nextInt(255)}";
  }

  // === محرك الفحص الأساسي ===
  Future<void> startScan() async {
    setState(() {
      isScanning = true;
      totalScanned = 0; aliveIps = 0; deadIps = 0;
      consoleLogs.clear();
    });
    logToConsole("⚡ بدء تشغيل محرك EXHXX Reaper...");
    logToConsole("🎯 البورتات المستهدفة: ${_portController.text}");
    logToConsole("🚀 عدد العمال (Threads): ${_threads.toInt()}");

    // محاكاة عمل الـ Threads للاتصال السريع
    while (isScanning) {
      List<Future> tasks = [];
      for (int i = 0; i < _threads.toInt(); i++) {
        if (!isScanning) break;
        tasks.add(_checkIp(getRandomCloudflareIp()));
      }
      await Future.wait(tasks);
      await Future.delayed(const Duration(milliseconds: 100)); // استراحة خفيفة للمعالج
    }
  }

  void stopScan() {
    setState(() {
      isScanning = false;
    });
    logToConsole("🛑 تم إيقاف الفحص يدوياً.");
  }

  Future<void> _checkIp(String ip) async {
    if (!isScanning) return;
    
    // محاكاة الفحص (هنا نضع Socket.connect الحقيقي لاحقاً)
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));
    
    bool isAlive = Random().nextInt(100) > 85; // نسبة نجاح وهمية 15% للتجربة
    
    if (!mounted) return;
    setState(() {
      totalScanned++;
      if (isAlive) {
        aliveIps++;
        logToConsole("✅ LIVE -> $ip | HTTP 200 | CF-RAY");
      } else {
        deadIps++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1221),
        title: const Text('💀 EXHXX CloudReaper Pro', style: TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.data_object, color: Colors.amber), onPressed: () {})
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // === بطاقات الإحصائيات ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("مفحوص", totalScanned.toString(), Colors.blueAccent),
                _buildStatCard("شغال ✅", aliveIps.toString(), const Color(0xFF00FF41)),
                _buildStatCard("ميت ❌", deadIps.toString(), Colors.redAccent),
              ],
            ),
            const SizedBox(height: 20),

            // === لوحة التحكم والإعدادات ===
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1221),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("⚙️ إعدادات المحرك (Engine Controls)", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white12),
                  
                  // Threads Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("عمليات متزامنة (Threads):"),
                      Text("${_threads.toInt()}", style: const TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _threads, min: 10, max: 200, divisions: 19,
                    activeColor: const Color(0xFF00FF41),
                    onChanged: isScanning ? null : (v) => setState(() => _threads = v),
                  ),

                  // Timeout Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("مهلة الاتصال (Timeout):"),
                      Text("${_timeout.toStringAsFixed(1)}s", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _timeout, min: 0.5, max: 5.0, divisions: 9,
                    activeColor: Colors.orange,
                    onChanged: isScanning ? null : (v) => setState(() => _timeout = v),
                  ),

                  // Ports Input
                  TextField(
                    controller: _portController,
                    enabled: !isScanning,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'البورتات (مثال: 80, 443, 8080)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))),
                      filled: true, fillColor: Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // === الكونسول الحي (Live Console) ===
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.5)),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: consoleLogs.length,
                  itemBuilder: (context, index) {
                    String log = consoleLogs[index];
                    Color textColor = Colors.white70;
                    if (log.contains("✅")) textColor = const Color(0xFF00FF41);
                    if (log.contains("🛑")) textColor = Colors.redAccent;
                    if (log.contains("⚡")) textColor = Colors.amber;

                    return Text(log, style: TextStyle(color: textColor, fontSize: 12));
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),

            // === أزرار التشغيل ===
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScanning ? Colors.redAccent : const Color(0xFF00FF41),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(isScanning ? Icons.stop_circle : Icons.rocket_launch, color: Colors.black),
                label: Text(
                  isScanning ? "إيقاف الهجوم (STOP)" : "بدء الصيد (START Hacking)",
                  style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1221),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
