import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _hasPermission = false;
  int _selected = 0;
  Color _color = Colors.red;
  double _size = 60;
  double _fov = 90;
  double _opacity = 1.0;

  final List<Map<String, dynamic>> _crosshairs = [
    {'name': 'قناصة كلاسيك', 'type': 'sniper'},
    {'name': 'دائري', 'type': 'circle'},
    {'name': 'ملكي', 'type': 'royal'},
    {'name': 'مزدوج', 'type': 'double'},
    {'name': 'شبكة', 'type': 'grid'},
    {'name': 'نقطة', 'type': 'dot'},
    {'name': 'COD موبايل', 'type': 'cod'},
    {'name': 'الماسة', 'type': 'diamond'},
    {'name': 'تكتيكال', 'type': 'tactical'},
    {'name': 'نجمة', 'type': 'star'},
    {'name': 'سهم', 'type': 'arrow'},
  ];

  final List<Color> _colors = [
    Colors.red, Colors.green, Colors.blue, Colors.yellow,
    Colors.white, Colors.orange, Colors.purple, Colors.cyan,
    Colors.pink, Colors.lime, Colors.amber, Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final granted = await _platform.invokeMethod('checkPermission');
      setState(() => _hasPermission = granted ?? false);
    } catch (_) {}
  }

  Future<void> _requestPermission() async {
    await _platform.invokeMethod('requestOverlayPermission');
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermission();
  }

  Future<void> _toggleOverlay() async {
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }
    try {
      if (_overlayActive) {
        await _platform.invokeMethod('stopOverlay');
      } else {
        await _platform.invokeMethod('startOverlay', {
          'type': _crosshairs[_selected]['type'],
          'color': _color.value,
          'size': _size,
          'fov': _fov,
          'opacity': _opacity,
        });
      }
      setState(() => _overlayActive = !_overlayActive);
    } catch (e) {
      await _requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final fovScale = _fov / 90.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('🎯 Crosshair Pro',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_hasPermission ? Icons.check_circle : Icons.warning,
                color: _hasPermission ? Colors.green : Colors.orange),
            onPressed: _requestPermission,
            tooltip: _hasPermission ? 'صلاحية ممنوحة' : 'اضغط لمنح الصلاحية',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // تحذير الصلاحية
            if (!_hasPermission)
              GestureDetector(
                onTap: _requestPermission,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'اضغط هنا لمنح صلاحية الظهور فوق التطبيقات',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      )),
                    ],
                  ),
                ),
              ),

            // معاينة مع FOV
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 220,
                width: double.infinity,
                color: const Color(0xFF1C2526),
                child: Transform.scale(
                  scale: fovScale,
                  child: Center(
                    child: Opacity(
                      opacity: _opacity,
                      child: CustomPaint(
                        size: Size(_size * 2.5, _size * 2.5),
                        painter: CrosshairPainter(
                          type: _crosshairs[_selected]['type'],
                          color: _color,
                          size: _size,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text('FOV: ${_fov.toInt()}° | معاينة حقيقية',
                style: const TextStyle(color: Colors.white38, fontSize: 11))),
            const SizedBox(height: 16),

            // اختيار الشكل
            const Text('🔫 شكل الـ Crosshair',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: List.generate(_crosshairs.length, (i) => GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selected == i ? _color : const Color(0xFF1C2526),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _color.withOpacity(0.5)),
                  ),
                  child: Text(_crosshairs[i]['name'],
                    style: TextStyle(
                      color: _selected == i ? Colors.black : Colors.white,
                      fontSize: 12, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 16),

            // الألوان
            const Text('🎨 اللون',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _colors.map((c) => GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: _color == c ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: _color == c
                        ? [BoxShadow(color: c.withOpacity(0.7), blurRadius: 10)] : null,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // الحجم
            _sliderRow('📏 الحجم', _size, 20, 120, _color,
                (v) => setState(() => _size = v)),

            // الشفافية
            _sliderRow('💧 الشفافية', _opacity, 0.1, 1.0, Colors.blue,
                (v) => setState(() => _opacity = v)),

            // FOV
            const Divider(color: Colors.white12, height: 24),
            Row(children: [
              const Text('📱 منظور الآيباد (FOV): ',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text('${_fov.toInt()}°',
                  style: const TextStyle(color: Colors.orange,
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const Text('60° = عادي | 90° = واسع | 120° = آيباد كامل',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            Slider(value: _fov, min: 60, max: 120, divisions: 60,
                activeColor: Colors.orange,
                onChanged: (v) => setState(() => _fov = v)),

            const SizedBox(height: 16),

            // زر التفعيل
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_hasPermission
                      ? Colors.orange
                      : _overlayActive ? Colors.red : Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  !_hasPermission ? Icons.lock_open
                      : _overlayActive ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                ),
                label: Text(
                  !_hasPermission ? '🔓 امنح الصلاحية أولاً'
                      : _overlayActive ? '⏹ إيقاف الـ Overlay'
                      : '▶ تفعيل فوق الشاشة',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _toggleOverlay,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow(String label, double val, double min, double max,
      Color color, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(val.toStringAsFixed(1),
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ]),
        Slider(value: val, min: min, max: max, activeColor: color,
            onChanged: onChanged as void Function(double)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class CrosshairPainter extends CustomPainter {
  final String type;
  final Color color;
  final double size;
  CrosshairPainter({required this.type, required this.color, required this.size});

  @override
  void paint(Canvas canvas, Size cs) {
    final p = Paint()..color = color..strokeWidth = 2.5
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..isAntiAlias = true;
    final f = Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true;
    final c = Offset(cs.width/2, cs.height/2);
    final s = size * 0.5;

    switch (type) {
      case 'sniper':
        final g = s*0.2;
        canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx-g,c.dy),p);
        canvas.drawLine(Offset(c.dx+g,c.dy),Offset(c.dx+s,c.dy),p);
        canvas.drawLine(Offset(c.dx,c.dy-s),Offset(c.dx,c.dy-g),p);
        canvas.drawLine(Offset(c.dx,c.dy+g),Offset(c.dx,c.dy+s),p);
        canvas.drawCircle(c,s*0.8,p); canvas.drawCircle(c,2,f);
        break;
      case 'circle':
        canvas.drawCircle(c,s*0.8,p);
        canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx+s,c.dy),p);
        canvas.drawLine(Offset(c.dx,c.dy-s),Offset(c.dx,c.dy+s),p);
        canvas.drawCircle(c,3,f); break;
      case 'royal':
        canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx+s,c.dy),p);
        canvas.drawLine(Offset(c.dx,c.dy-s),Offset(c.dx,c.dy+s),p);
        for(var pt in [Offset(c.dx-s,c.dy),Offset(c.dx+s,c.dy),
          Offset(c.dx,c.dy-s),Offset(c.dx,c.dy+s)])
          canvas.drawCircle(pt,4,f);
        canvas.drawCircle(c,3,f); break;
      case 'double':
        canvas.drawCircle(c,s*0.9,p); canvas.drawCircle(c,s*0.4,p);
        final g2=s*0.15;
        canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx-g2,c.dy),p);
        canvas.drawLine(Offset(c.dx+g2,c.dy),Offset(c.dx+s,c.dy),p);
        canvas.drawLine(Offset(c.dx,c.dy-s),Offset(c.dx,c.dy-g2),p);
        canvas.drawLine(Offset(c.dx,c.dy+g2),Offset(c.dx,c.dy+s),p); break;
      case 'grid':
        for(int i=-2;i<=2;i++){
          p.strokeWidth=i==0?2.5:1;
          canvas.drawLine(Offset(c.dx+i*s*0.35,c.dy-s),Offset(c.dx+i*s*0.35,c.dy+s),p);
          canvas.drawLine(Offset(c.dx-s,c.dy+i*s*0.35),Offset(c.dx+s,c.dy+i*s*0.35),p);
        } break;
      case 'dot':
        canvas.drawCircle(c,4,f); p.strokeWidth=1.5;
        final g3=s*0.25;
        canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx-g3,c.dy),p);
        canvas.drawLine(Offset(c.dx+g3,c.dy),Offset(c.dx+s,c.dy),p);
        canvas.drawLine(Offset(c.dx,c.dy-s),Offset(c.dx,c.dy-g3),p);
        canvas.drawLine(Offset(c.dx,c.dy+g3),Offset(c.dx,c.dy+s),p); break;
      case 'cod':
        p.strokeWidth=3; final g4=s*0.18;
        canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx-g4,c.dy),p);
        canvas.drawLine(Offset(c.dx+g4,c.dy),Offset(c.dx+s,c.dy),p);
        canvas.drawLine(Offset(c.dx,c.dy-s*0.7),Offset(c.dx,c.dy-g4),p);
        canvas.drawLine(Offset(c.dx,c.dy+g4),Offset(c.dx,c.dy+s*0.7),p);
        canvas.drawCircle(c,2.5,f); break;
      case 'diamond':
        final path=Path()..moveTo(c.dx,c.dy-s)..lineTo(c.dx+s*0.6,c.dy)
          ..lineTo(c.dx,c.dy+s)..lineTo(c.dx-s*0.6,c.dy)..close();
        canvas.drawPath(path,p); canvas.drawCircle(c,3,f); break;
      case 'tactical':
        final g5=s*0.3;
        canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx-g5,c.dy),p);
        canvas.drawLine(Offset(c.dx+g5,c.dy),Offset(c.dx+s,c.dy),p);
        canvas.drawLine(Offset(c.dx,c.dy-s),Offset(c.dx,c.dy-g5),p);
        canvas.drawLine(Offset(c.dx-s*0.4,c.dy+g5),Offset(c.dx,c.dy+s),p);
        canvas.drawLine(Offset(c.dx+s*0.4,c.dy+g5),Offset(c.dx,c.dy+s),p);
        canvas.drawCircle(c,3,f); break;
      case 'star':
        for(int i=0;i<4;i++){
          final angle=i*3.14159/4;
          canvas.drawLine(c,Offset(c.dx+s*0.9*(i%2==0?1:-1)*0,c.dy),p);
        }
        for(int i=0;i<8;i++){
          final angle=i*3.14159/4;
          canvas.drawLine(c,
            Offset(c.dx+s*0.9*dart_math_cos(angle),c.dy+s*0.9*dart_math_sin(angle)),p);
        }
        canvas.drawCircle(c,3,f); break;
      case 'arrow':
        canvas.drawLine(Offset(c.dx,c.dy-s),Offset(c.dx,c.dy+s*0.3),p);
        canvas.drawLine(Offset(c.dx-s*0.4,c.dy-s*0.4),Offset(c.dx,c.dy-s),p);
        canvas.drawLine(Offset(c.dx+s*0.4,c.dy-s*0.4),Offset(c.dx,c.dy-s),p);
        canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx+s,c.dy),p);
        canvas.drawCircle(c,3,f); break;
      default:
        canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx+s,c.dy),p);
        canvas.drawLine(Offset(c.dx,c.dy-s),Offset(c.dx,c.dy+s),p);
        canvas.drawCircle(c,4,f);
    }
  }

  double dart_math_cos(double a) {
    return [1.0,0.707,0.0,-0.707,-1.0,-0.707,0.0,0.707][((a/(3.14159/4)).round()%8+8)%8];
  }
  double dart_math_sin(double a) {
    return [0.0,0.707,1.0,0.707,0.0,-0.707,-1.0,-0.707][((a/(3.14159/4)).round()%8+8)%8];
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}
