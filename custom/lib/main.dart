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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _platform = MethodChannel('overlay_channel');
  bool _overlayActive = false;
  bool _hasPermission = false;
  int _selected = 0;
  Color _color = Colors.red;
  double _size = 60;
  double _fov = 90;
  double _opacity = 1.0;

  final List<Map<String, dynamic>> _crosshairs = [
    {'name': 'قناصة', 'type': 'sniper'},
    {'name': 'دائري', 'type': 'circle'},
    {'name': 'نقطة', 'type': 'dot'},
    {'name': 'COD', 'type': 'cod'},
  ];

  final List<Color> _colors = [
    Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.white, Colors.orange, Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final granted = await _platform.invokeMethod('checkPermission');
      setState(() => _hasPermission = granted ?? false);
    } catch (_) {}
  }

  Future<void> _requestPermission() async {
    try {
      await _platform.invokeMethod('requestOverlayPermission');
    } catch (e) {
      _showError('خطأ بالاتصال بالنظام: $e\nتأكد من بناء التطبيق مجدداً.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent));
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
      _showError('لم يتم العثور على كود الـ Native! تأكد من رفع الكود للمصنع بشكل صحيح. ($e)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('🎯 EXHXX Aim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_hasPermission)
              GestureDetector(
                onTap: _requestPermission,
                child: Container(
                  padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(8)),
                  child: const Text('اضغط هنا لمنح صلاحية الظهور فوق التطبيقات', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ),
            
            Container(
              height: 200, width: double.infinity, color: const Color(0xFF1C2526),
              child: Transform.scale(
                scale: _fov / 90.0,
                child: Center(
                  child: Opacity(
                    opacity: _opacity,
                    child: CustomPaint(size: Size(_size * 2.5, _size * 2.5), painter: CrosshairPainter(type: _crosshairs[_selected]['type'], color: _color, size: _size)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Wrap(
              spacing: 8, children: List.generate(_crosshairs.length, (i) => ChoiceChip(
                label: Text(_crosshairs[i]['name']), selected: _selected == i,
                onSelected: (v) => setState(() => _selected = i),
                selectedColor: _color, labelStyle: TextStyle(color: _selected == i ? Colors.black : Colors.white),
              )),
            ),
            const SizedBox(height: 20),
            
            Wrap(
              spacing: 12, children: _colors.map((c) => GestureDetector(
                onTap: () => setState(() => _color = c),
                child: CircleAvatar(backgroundColor: c, radius: 18, child: _color == c ? const Icon(Icons.check, color: Colors.black) : null),
              )).toList(),
            ),
            const SizedBox(height: 20),
            
            Slider(value: _size, min: 20, max: 120, onChanged: (v) => setState(() => _size = v)),
            const Text('حجم القناصة', style: TextStyle(color: Colors.white70)),
            
            Slider(value: _fov, min: 60, max: 120, onChanged: (v) => setState(() => _fov = v)),
            const Text('منظور الـ FOV', style: TextStyle(color: Colors.white70)),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: !_hasPermission ? Colors.orange : _overlayActive ? Colors.red : Colors.green),
                onPressed: _toggleOverlay,
                child: Text(!_hasPermission ? 'امنح الصلاحية أولاً' : _overlayActive ? 'إيقاف القنص' : 'تفعيل القنص', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CrosshairPainter extends CustomPainter {
  final String type; final Color color; final double size;
  CrosshairPainter({required this.type, required this.color, required this.size});

  @override
  void paint(Canvas canvas, Size cs) {
    final p = Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..isAntiAlias = true;
    final f = Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true;
    final c = Offset(cs.width/2, cs.height/2); final s = size * 0.5;
    
    switch (type) {
      case 'sniper':
        canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx-s*0.2,c.dy),p); canvas.drawLine(Offset(c.dx+s*0.2,c.dy),Offset(c.dx+s,c.dy),p);
        canvas.drawLine(Offset(c.dx,c.dy-s),Offset(c.dx,c.dy-s*0.2),p); canvas.drawLine(Offset(c.dx,c.dy+s*0.2),Offset(c.dx,c.dy+s),p);
        canvas.drawCircle(c,s*0.8,p); canvas.drawCircle(c,3,f); break;
      case 'circle': canvas.drawCircle(c,s*0.8,p); canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx+s,c.dy),p); canvas.drawLine(Offset(c.dx,c.dy-s),Offset(c.dx,c.dy+s),p); canvas.drawCircle(c,3,f); break;
      case 'dot': canvas.drawCircle(c,4,f); canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx-s*0.25,c.dy),p); canvas.drawLine(Offset(c.dx+s*0.25,c.dy),Offset(c.dx+s,c.dy),p); canvas.drawLine(Offset(c.dx,c.dy-s),Offset(c.dx,c.dy-s*0.25),p); canvas.drawLine(Offset(c.dx,c.dy+s*0.25),Offset(c.dx,c.dy+s),p); break;
      case 'cod': p.strokeWidth=4; canvas.drawLine(Offset(c.dx-s,c.dy),Offset(c.dx-s*0.18,c.dy),p); canvas.drawLine(Offset(c.dx+s*0.18,c.dy),Offset(c.dx+s,c.dy),p); canvas.drawLine(Offset(c.dx,c.dy-s*0.7),Offset(c.dx,c.dy-s*0.18),p); canvas.drawLine(Offset(c.dx,c.dy+s*0.18),Offset(c.dx,c.dy+s*0.7),p); canvas.drawCircle(c,3,f); break;
    }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}
