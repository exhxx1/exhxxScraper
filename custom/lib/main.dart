import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() => runApp(const CrosshairApp());

class CrosshairApp extends StatelessWidget {
  const CrosshairApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _platform = MethodChannel('overlay_channel');
  bool _overlayActive = false;
  int _selectedCrosshair = 0;
  Color _color = Colors.red;
  double _size = 60;
  double _fov = 90;

  final List<Map<String, dynamic>> _crosshairs = [
    {'name': 'قناصة كلاسيك', 'type': 'sniper'},
    {'name': 'دائري', 'type': 'circle'},
    {'name': 'ملكي', 'type': 'royal'},
    {'name': 'مزدوج', 'type': 'double'},
    {'name': 'شبكة', 'type': 'grid'},
    {'name': 'نقطة', 'type': 'dot'},
    {'name': 'COD موبايل', 'type': 'cod'},
    {'name': 'الماسة', 'type': 'diamond'},
  ];

  final List<Color> _colors = [
    Colors.red, Colors.green, Colors.blue,
    Colors.yellow, Colors.white, Colors.orange,
    Colors.purple, Colors.cyan,
  ];

  Future<void> _requestOverlayPermission() async {
    try {
      await _platform.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  Future<void> _toggleOverlay() async {
    try {
      if (_overlayActive) {
        await _platform.invokeMethod('stopOverlay');
      } else {
        await _platform.invokeMethod('startOverlay', {
          'type': _crosshairs[_selectedCrosshair]['type'],
          'color': _color.value,
          'size': _size,
          'fov': _fov,
        });
      }
      setState(() => _overlayActive = !_overlayActive);
    } catch (_) {
      await _requestOverlayPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('🎯 Crosshair + FOV', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // معاينة الـ Crosshair
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1C2526),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomPaint(
                  size: Size(_size * 2, _size * 2),
                  painter: CrosshairPainter(
                    type: _crosshairs[_selectedCrosshair]['type'],
                    color: _color,
                    size: _size,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // اختيار الشكل
            const Text('شكل الـ Crosshair:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: List.generate(_crosshairs.length, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedCrosshair = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedCrosshair == i ? _color : const Color(0xFF1C2526),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _color.withOpacity(0.5)),
                    ),
                    child: Text(
                      _crosshairs[i]['name'],
                      style: TextStyle(
                        color: _selectedCrosshair == i ? Colors.black : Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // اختيار اللون
            const Text('اللون:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _colors.map((c) => GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 35, height: 35,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: _color == c ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // حجم الـ Crosshair
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الحجم:', style: TextStyle(color: Colors.white70)),
                Text('${_size.toInt()}', style: TextStyle(color: _color)),
              ],
            ),
            Slider(
              value: _size, min: 20, max: 120,
              activeColor: _color,
              onChanged: (v) => setState(() => _size = v),
            ),

            // منظور الآيباد FOV
            const Divider(color: Colors.white24),
            Row(
              children: [
                const Text('📱 منظور الآيباد (FOV): ', style: TextStyle(color: Colors.white70)),
                Text('${_fov.toInt()}°', style: TextStyle(color: _color, fontWeight: FontWeight.bold)),
              ],
            ),
            const Text('كلما زاد الرقم، شفت أكثر من الشاشة',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            Slider(
              value: _fov, min: 60, max: 120,
              activeColor: Colors.orange,
              onChanged: (v) => setState(() => _fov = v),
            ),

            const SizedBox(height: 16),

            // زر التفعيل
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _overlayActive ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                icon: Icon(_overlayActive ? Icons.stop : Icons.play_arrow, color: Colors.white),
                label: Text(
                  _overlayActive ? 'إيقاف الـ Overlay' : 'تفعيل فوق الشاشة',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _toggleOverlay,
              ),
            ),

            const SizedBox(height: 12),
            const Text(
              '⚠️ عند أول تشغيل راح يطلب منك صلاحية "العرض فوق التطبيقات" - اقبلها',
              style: TextStyle(color: Colors.orange, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CrosshairPainter extends CustomPainter {
  final String type;
  final Color color;
  final double size;
  CrosshairPainter({required this.type, required this.color, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final c = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final s = size * 0.5;

    switch (type) {
      case 'sniper':
        final g = s * 0.2;
        canvas.drawLine(Offset(c.dx - s, c.dy), Offset(c.dx - g, c.dy), paint);
        canvas.drawLine(Offset(c.dx + g, c.dy), Offset(c.dx + s, c.dy), paint);
        canvas.drawLine(Offset(c.dx, c.dy - s), Offset(c.dx, c.dy - g), paint);
        canvas.drawLine(Offset(c.dx, c.dy + g), Offset(c.dx, c.dy + s), paint);
        canvas.drawCircle(c, s * 0.8, paint);
        canvas.drawCircle(c, 2, fill);
        break;
      case 'circle':
        canvas.drawCircle(c, s * 0.8, paint);
        canvas.drawLine(Offset(c.dx - s, c.dy), Offset(c.dx + s, c.dy), paint);
        canvas.drawLine(Offset(c.dx, c.dy - s), Offset(c.dx, c.dy + s), paint);
        canvas.drawCircle(c, 3, fill);
        break;
      case 'royal':
        canvas.drawLine(Offset(c.dx - s, c.dy), Offset(c.dx + s, c.dy), paint);
        canvas.drawLine(Offset(c.dx, c.dy - s), Offset(c.dx, c.dy + s), paint);
        canvas.drawCircle(Offset(c.dx - s, c.dy), 4, fill);
        canvas.drawCircle(Offset(c.dx + s, c.dy), 4, fill);
        canvas.drawCircle(Offset(c.dx, c.dy - s), 4, fill);
        canvas.drawCircle(Offset(c.dx, c.dy + s), 4, fill);
        canvas.drawCircle(c, 3, fill);
        break;
      case 'double':
        canvas.drawCircle(c, s * 0.9, paint);
        canvas.drawCircle(c, s * 0.4, paint);
        final g2 = s * 0.15;
        canvas.drawLine(Offset(c.dx - s, c.dy), Offset(c.dx - g2, c.dy), paint);
        canvas.drawLine(Offset(c.dx + g2, c.dy), Offset(c.dx + s, c.dy), paint);
        canvas.drawLine(Offset(c.dx, c.dy - s), Offset(c.dx, c.dy - g2), paint);
        canvas.drawLine(Offset(c.dx, c.dy + g2), Offset(c.dx, c.dy + s), paint);
        break;
      case 'grid':
        for (int i = -2; i <= 2; i++) {
          paint.strokeWidth = i == 0 ? 2.5 : 1;
          canvas.drawLine(Offset(c.dx + i * s * 0.35, c.dy - s), Offset(c.dx + i * s * 0.35, c.dy + s), paint);
          canvas.drawLine(Offset(c.dx - s, c.dy + i * s * 0.35), Offset(c.dx + s, c.dy + i * s * 0.35), paint);
        }
        break;
      case 'dot':
        canvas.drawCircle(c, 4, fill);
        paint.strokeWidth = 1.5;
        final g3 = s * 0.25;
        canvas.drawLine(Offset(c.dx - s, c.dy), Offset(c.dx - g3, c.dy), paint);
        canvas.drawLine(Offset(c.dx + g3, c.dy), Offset(c.dx + s, c.dy), paint);
        canvas.drawLine(Offset(c.dx, c.dy - s), Offset(c.dx, c.dy - g3), paint);
        canvas.drawLine(Offset(c.dx, c.dy + g3), Offset(c.dx, c.dy + s), paint);
        break;
      case 'cod':
        paint.strokeWidth = 3;
        final g4 = s * 0.18;
        canvas.drawLine(Offset(c.dx - s, c.dy), Offset(c.dx - g4, c.dy), paint);
        canvas.drawLine(Offset(c.dx + g4, c.dy), Offset(c.dx + s, c.dy), paint);
        canvas.drawLine(Offset(c.dx, c.dy - s * 0.7), Offset(c.dx, c.dy - g4), paint);
        canvas.drawLine(Offset(c.dx, c.dy + g4), Offset(c.dx, c.dy + s * 0.7), paint);
        canvas.drawCircle(c, 2.5, fill);
        break;
      case 'diamond':
        final path = Path();
        path.moveTo(c.dx, c.dy - s);
        path.lineTo(c.dx + s * 0.6, c.dy);
        path.lineTo(c.dx, c.dy + s);
        path.lineTo(c.dx - s * 0.6, c.dy);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawCircle(c, 3, fill);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
