import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

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
  final TextEditingController _targetController = TextEditingController();
  bool _isHostMode = true; // true = Hosts/SNI, false = IPs
  
  // === الكونسول الحي ===
  List<String> consoleLogs = [];
  final ScrollController _scrollController = ScrollController();

  void logToConsole(String msg) {
    setState(() {
      consoleLogs.add("[${DateTime.now().toString().substring(11, 19)}] $msg");
      if (consoleLogs.length > 300) consoleLogs.removeAt(0);
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // === محرك الفحص الحقيقي (Real Socket Connection) ===
  Future<void> startScan() async {
    List<String> rawTargets = _targetController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (rawTargets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ الحقل فارغ! ضع لستة هوستات أو آيبيهات أولاً.", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() {
      isScanning = true;
      totalScanned = 0; aliveIps = 0; deadIps = 0;
      consoleLogs.clear();
    });

    logToConsole("⚡ بدء تشغيل محرك EXHXX Reaper الحقيقي...");
    logToConsole("🎯 الأهداف المستلمة: ${rawTargets.length}");
    logToConsole("⚙️ نوع الفحص: ${_isHostMode ? 'Hosts / SNI' : 'IPs'}");

    int concurrency = _threads.toInt();
    int currentIndex = 0;

    // عامل الفحص (Worker)
    Future<void> worker() async {
      while (isScanning && currentIndex < rawTargets.length) {
        int myIndex;
        // قفل بسيط لضمان عدم تكرار الفحص لنفس الهدف
        myIndex = currentIndex++;
        if (myIndex >= rawTargets.length) break;

        String target = rawTargets[myIndex];
        await _checkTarget(target);
      }
    }

    List<Future> workers = [];
    for (int i = 0; i < concurrency; i++) {
      workers.add(worker());
    }

    await Future.wait(workers);

    if (mounted) {
      setState(() => isScanning = false);
      logToConsole("🏁 انتهى الفحص بالكامل!");
    }
  }

  Future<void> _checkTarget(String target) async {
    if (!isScanning) return;
    
    List<String> portsStr = _portController.text.split(',');
    bool foundAlive = false;

    for (String pStr in portsStr) {
      if (!isScanning) break;
      int port = int.tryParse(pStr.trim()) ?? 80;
      
      try {
        // اتصال حقيقي بالهدف (TCP Socket)
        final socket = await Socket.connect(target, port, timeout: Duration(milliseconds: (_timeout * 1000).toInt()));
        socket.destroy(); // نغلق الاتصال فور نجاحه لتوفير الموارد
        foundAlive = true;
        
        if (!mounted) return;
        setState(() {
          aliveIps++;
          logToConsole("✅ LIVE -> $target:$port | TCP OK");
        });
        break; // إذا اشتغل بورت واحد نعبر للهدف اللي بعده
      } catch (e) {
        // فشل الاتصال بهذا البورت
      }
    }

    if (!foundAlive && mounted) {
      setState(() {
        deadIps++;
      });
    }
    
    if (mounted) setState(() => totalScanned++);
  }

  void stopScan() {
    setState(() => isScanning = false);
    logToConsole("🛑 تم إيقاف الفحص يدوياً.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1221),
        title: const Text('💀 EXHXX CloudReaper Pro', style: TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
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
            const SizedBox(height: 15),

            // === الجزء العلوي القابل للتمرير (الإعدادات والأهداف) ===
            Expanded(
              flex: 3,
              child: ListView(
                children: [
                  // --- مربع إدخال الأهداف (الجديد) ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1221),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("🎯 قائمة الأهداف (Targets)", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                            ToggleButtons(
                              isSelected: [_isHostMode, !_isHostMode],
                              onPressed: isScanning ? null : (index) => setState(() => _isHostMode = index == 0),
                              color: Colors.white54,
                              selectedColor: Colors.black,
                              fillColor: const Color(0xFF00FF41),
                              borderRadius: BorderRadius.circular(5),
                              constraints: const BoxConstraints(minHeight: 25, minWidth: 60),
                              children: const [Text("الهوستات", style: TextStyle(fontSize: 12)), Text("الآيبيهات", style: TextStyle(fontSize: 12))],
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _targetController,
                          enabled: !isScanning,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: "الصق لستة الهوستات (SNI) أو الآيبيهات هنا...\nمثال:\nwww.example.com\n104.16.0.1",
                            hintStyle: TextStyle(color: Colors.white24),
                            filled: true, fillColor: Colors.black26,
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- إعدادات المحرك ---
                  Container(
                    padding: const EdgeInsets.all(12),
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

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("مهلة الاتصال (Timeout):"),
                            Text("${_timeout.toStringAsFixed(1)}s", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _timeout, min: 0.5, max: 10.0, divisions: 19,
                          activeColor: Colors.orange,
                          onChanged: isScanning ? null : (v) => setState(() => _timeout = v),
                        ),

                        TextField(
                          controller: _portController,
                          enabled: !isScanning,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'البورتات (مثال: 80, 443, 8080)',
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))),
                            filled: true, fillColor: Colors.black26,
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // === الكونسول الحي (Live Console) ===
            Expanded(
              flex: 2,
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
                    if (log.contains("⚡") || log.contains("🎯") || log.contains("⚙️")) textColor = Colors.amber;

                    return Text(log, style: TextStyle(color: textColor, fontSize: 12));
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            // === زر التشغيل ===
            SizedBox(
              width: double.infinity,
              height: 50,
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1221),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
