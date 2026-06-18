import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() => runApp(const CrosshairApp());

class CrosshairApp extends StatelessWidget {
  const CrosshairApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CrosshairScreen(),
    );
  }
}

class CrosshairScreen extends StatefulWidget {
  const CrosshairScreen({super.key});
  @override
  State<CrosshairScreen> createState() => _CrosshairScreenState();
}

class _CrosshairScreenState extends State<CrosshairScreen> {
  int _selected = 0;
  Color _color = Colors.red;
  double _size = 60;

  final List<Map<String, dynamic>> _crosshairs = [
    {'name': '🎯 قناصة كلاسيك', 'type': 'sniper'},
    {'name': '⊕ دائري', 'type': 'circle'},
    {'name': '✛ ملكي', 'type': 'royal'},
    {'name': '◎ قناصة مزدوج', 'type': 'double'},
    {'name': '⊞ شبكة', 'type': 'grid'},
    {'name': '• نقطة دقيقة', 'type': 'dot'},
    {'name': '🔫 COD موبايل', 'type': 'cod'},
    {'name': '❖ الماسة', 'type': 'diamond'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('🎯 Crosshair Overlay', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // عرض الـ Crosshair
          Container(
            height: 250,
            color: const Color(0xFF0A0A0A),
            child: Center(
              child: CustomPaint(
                size: Size(_size * 2, _size * 2),
                painter: CrosshairPainter(
                  type: _crosshairs[_selected]['type'],
                  color: _color,
                  size: _size,
                ),
              ),
            ),
          ),

          // اختيار النوع
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(10),
              itemCount: _crosshairs.length,
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selected == i ? _color : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _color.withOpacity(0.5)),
                    ),
                    child: Text(
                      _crosshairs[i]['name'],
                      style: TextStyle(
                        color: _selected == i ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // اختيار اللون
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎨 اللون:', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Colors.red, Colors.green, Colors.blue,
                    Colors.yellow, Colors.white, Colors.orange,
                    Colors.purple, Colors.cyan,
                  ].map((c) => GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 35, height: 35,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _color == c
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('📏 الحجم:', style: TextStyle(color: Colors.white, fontSize: 14)),
                Slider(
                  value: _size,
                  min: 20, max: 120,
                  activeColor: _color,
                  onChanged: (v) => setState(() => _size = v),
                ),
              ],
            ),
          ),
        ],
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

    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final s = size * 0.5;

    switch (type) {
      case 'sniper':
        // قناصة كلاسيك مع gap بالمنتصف
        final gap = s * 0.2;
        canvas.drawLine(Offset(center.dx - s, center.dy), Offset(center.dx - gap, center.dy), paint);
        canvas.drawLine(Offset(center.dx + gap, center.dy), Offset(center.dx + s, center.dy), paint);
        canvas.drawLine(Offset(center.dx, center.dy - s), Offset(center.dx, center.dy - gap), paint);
        canvas.drawLine(Offset(center.dx, center.dy + gap), Offset(center.dx, center.dy + s), paint);
        canvas.drawCircle(center, s * 0.8, paint);
        canvas.drawCircle(center, 2, paintFill);
        break;

      case 'circle':
        canvas.drawCircle(center, s * 0.8, paint);
        canvas.drawLine(Offset(center.dx - s, center.dy), Offset(center.dx + s, center.dy), paint);
        canvas.drawLine(Offset(center.dx, center.dy - s), Offset(center.dx, center.dy + s), paint);
        canvas.drawCircle(center, 3, paintFill);
        break;

      case 'royal':
        // خطوط مع نقاط على الأطراف
        canvas.drawLine(Offset(center.dx - s, center.dy), Offset(center.dx + s, center.dy), paint);
        canvas.drawLine(Offset(center.dx, center.dy - s), Offset(center.dx, center.dy + s), paint);
        canvas.drawCircle(Offset(center.dx - s, center.dy), 4, paintFill);
        canvas.drawCircle(Offset(center.dx + s, center.dy), 4, paintFill);
        canvas.drawCircle(Offset(center.dx, center.dy - s), 4, paintFill);
        canvas.drawCircle(Offset(center.dx, center.dy + s), 4, paintFill);
        canvas.drawCircle(center, 3, paintFill);
        break;

      case 'double':
        canvas.drawCircle(center, s * 0.9, paint);
        canvas.drawCircle(center, s * 0.4, paint);
        final gap2 = s * 0.15;
        canvas.drawLine(Offset(center.dx - s, center.dy), Offset(center.dx - gap2, center.dy), paint);
        canvas.drawLine(Offset(center.dx + gap2, center.dy), Offset(center.dx + s, center.dy), paint);
        canvas.drawLine(Offset(center.dx, center.dy - s), Offset(center.dx, center.dy - gap2), paint);
        canvas.drawLine(Offset(center.dx, center.dy + gap2), Offset(center.dx, center.dy + s), paint);
        break;

      case 'grid':
        for (int i = -2; i <= 2; i++) {
          canvas.drawLine(
            Offset(center.dx + i * s * 0.35, center.dy - s),
            Offset(center.dx + i * s * 0.35, center.dy + s),
            paint..strokeWidth = i == 0 ? 2.5 : 1,
          );
          canvas.drawLine(
            Offset(center.dx - s, center.dy + i * s * 0.35),
            Offset(center.dx + s, center.dy + i * s * 0.35),
            paint..strokeWidth = i == 0 ? 2.5 : 1,
          );
        }
        break;

      case 'dot':
        canvas.drawCircle(center, 4, paintFill);
        paint.strokeWidth = 1.5;
        final gap3 = s * 0.25;
        canvas.drawLine(Offset(center.dx - s, center.dy), Offset(center.dx - gap3, center.dy), paint);
        canvas.drawLine(Offset(center.dx + gap3, center.dy), Offset(center.dx + s, center.dy), paint);
        canvas.drawLine(Offset(center.dx, center.dy - s), Offset(center.dx, center.dy - gap3), paint);
        canvas.drawLine(Offset(center.dx, center.dy + gap3), Offset(center.dx, center.dy + s), paint);
        break;

      case 'cod':
        // COD موبايل ستايل
        final gap4 = s * 0.18;
        paint.strokeWidth = 3;
        canvas.drawLine(Offset(center.dx - s, center.dy), Offset(center.dx - gap4, center.dy), paint);
        canvas.drawLine(Offset(center.dx + gap4, center.dy), Offset(center.dx + s, center.dy), paint);
        canvas.drawLine(Offset(center.dx, center.dy - s * 0.7), Offset(center.dx, center.dy - gap4), paint);
        canvas.drawLine(Offset(center.dx, center.dy + gap4), Offset(center.dx, center.dy + s * 0.7), paint);
        canvas.drawCircle(center, 2.5, paintFill);
        break;

      case 'diamond':
        final path = Path();
        path.moveTo(center.dx, center.dy - s);
        path.lineTo(center.dx + s * 0.6, center.dy);
        path.lineTo(center.dx, center.dy + s);
        path.lineTo(center.dx - s * 0.6, center.dy);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawCircle(center, 3, paintFill);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
