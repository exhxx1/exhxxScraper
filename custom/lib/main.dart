import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

void main() => runApp(const Exhxx78App());

class Exhxx78App extends StatelessWidget {
  const Exhxx78App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'exhxx78',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030A05),
        textTheme: const TextTheme(bodyMedium: TextStyle(fontFamily: 'monospace')),
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent),
      ),
      home: const GameMapScreen(),
    );
  }
}

class GameMapScreen extends StatefulWidget {
  const GameMapScreen({super.key});
  @override
  State<GameMapScreen> createState() => _GameMapScreenState();
}

class _GameMapScreenState extends State<GameMapScreen> {
  late final WebViewController _controller;
  String _currentLat = "36.20630"; 
  String _currentLng = "44.00890";
  String _activeMode = "dark"; // الوضع الافتراضي

  final String _mapHtml = '''
  <!DOCTYPE html>
  <html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
      body { margin:0; padding:0; background: #030A05; overflow: hidden; }
      
      #map { 
         width: 100vw; height: 100vh; 
         transition: filter 0.8s ease;
      }
      
      /* الفلاتر السحرية للأوضاع المخصصة */
      .radar-mode { filter: sepia(1) hue-rotate(90deg) saturate(3) brightness(0.8) contrast(1.2) !important; }
      .neon-mode { filter: invert(1) hue-rotate(180deg) saturate(2.5) brightness(0.9) !important; }
      
      .leaflet-control-container { display: none; } 
    </style>
  </head>
  <body>
    <div id="map"></div>
    <script>
      var map = L.map('map', {zoomControl: false, attributionControl: false}).setView([36.2063, 44.0089], 15);
      
      // ترسانة المحركات والطبقات
      var layers = {
        'dark': L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { maxZoom: 19 }),
        'satellite': L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', { maxZoom: 19 }),
        'hybrid': L.tileLayer('https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}', { maxZoom: 20 }), // بيوت + أسماء الشوارع
        'street': L.tileLayer('https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', { maxZoom: 20 }), // شوارع جوجل
        'terrain': L.tileLayer('https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}', { maxZoom: 20 }), // تضاريس
        'light': L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', { maxZoom: 19 })
      };

      var currentLayer = layers['dark'];
      currentLayer.addTo(map);

      map.on('move', function() {
         var center = map.getCenter();
         if(window.ExhxxMap) {
           ExhxxMap.postMessage(JSON.stringify({lat: center.lat, lng: center.lng}));
         }
      });

      // دالة تغيير الأوضاع (Themes)
      window.changeStyle = function(mode) {
         map.removeLayer(currentLayer);
         let mapEl = document.getElementById('map');
         mapEl.className = ''; // تصفير الفلاتر

         if(mode === 'radar') {
            currentLayer = layers['satellite']; // الرادار يستخدم القمر الصناعي
            mapEl.classList.add('radar-mode');
         } else if (mode === 'neon') {
            currentLayer = layers['light']; // النيون يستخدم الخريطة الفاتحة ليعكسها
            mapEl.classList.add('neon-mode');
         } else {
            currentLayer = layers[mode];
         }
         
         currentLayer.addTo(map);
      };
    </script>
  </body>
  </html>
  ''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('ExhxxMap', onMessageReceived: (msg) {
        var data = jsonDecode(msg.message);
        setState(() {
          _currentLat = data['lat'].toStringAsFixed(5);
          _currentLng = data['lng'].toStringAsFixed(5);
        });
      })
      ..loadHtmlString(_mapHtml);
  }

  void _setMapMode(String mode) {
    setState(() => _activeMode = mode);
    _controller.runJavaScript("window.changeStyle('$mode');");
    Navigator.pop(context); // إغلاق القائمة بعد الاختيار
  }

  // قائمة الأوضاع الفخمة
  void _openLayersMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF030A05).withOpacity(0.95),
          border: const Border(top: BorderSide(color: Color(0xFF00FF41), width: 2)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("أنظمة الرؤية والخرائط 🛰️", style: TextStyle(color: Color(0xFF00FF41), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
              children: [
                _buildModeBtn("داكن سيبراني", "dark", Icons.dark_mode, Colors.grey),
                _buildModeBtn("بيوت حقيقية (هايبرد)", "hybrid", Icons.house, Colors.amber),
                _buildModeBtn("قمر صناعي نقي", "satellite", Icons.satellite_alt, Colors.blueAccent),
                _buildModeBtn("رادار ليلي عسكري", "radar", Icons.radar, Colors.greenAccent),
                _buildModeBtn("ماتريكس نيون", "neon", Icons.local_fire_department, Colors.pinkAccent),
                _buildModeBtn("خريطة شوارع", "street", Icons.add_road, Colors.white),
                _buildModeBtn("تضاريس وجبال", "terrain", Icons.terrain, Colors.brown),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBtn(String title, String mode, IconData icon, Color color) {
    bool isActive = _activeMode == mode;
    return InkWell(
      onTap: () => _setMapMode(mode),
      child: Container(
        width: 110, padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.black54,
          border: Border.all(color: isActive ? color : Colors.white12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: isActive ? color : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. محرك الخرائط
          WebViewWidget(controller: _controller),

          // 2. شبكة التصويب (Crosshair)
          const Center(child: Icon(Icons.add, color: Color(0xFF00FF41), size: 40)),

          // 3. واجهة التحكم (HUD)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // الشريط العلوي (معلومات اللاعب)
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("SYSTEM: exhxx78", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                          const SizedBox(height: 5),
                          Container(width: 140, height: 8, decoration: BoxDecoration(border: Border.all(color: Colors.white24), color: Colors.black54), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.9, child: Container(color: const Color(0xFF00FF41)))),
                          const SizedBox(height: 4),
                          Container(width: 140, height: 8, decoration: BoxDecoration(border: Border.all(color: Colors.white24), color: Colors.black54), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.6, child: Container(color: Colors.blueAccent))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black87, border: Border.all(color: const Color(0xFF00FF41))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text("STATUS: ONLINE", style: TextStyle(color: Color(0xFF00FF41), fontSize: 11, fontWeight: FontWeight.bold)),
                            Text("LINK: SECURE", style: TextStyle(color: Colors.amber, fontSize: 10)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // الشريط السفلي (قائمة الأوضاع والإحداثيات)
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // زر فتح قائمة الأوضاع (Layers)
                      InkWell(
                        onTap: _openLayersMenu,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black87, border: Border.all(color: const Color(0xFF00FF41), width: 2)),
                          child: const Icon(Icons.layers, color: Color(0xFF00FF41), size: 28),
                        ),
                      ),

                      // الإحداثيات الحية
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black87.withOpacity(0.8), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.white24)),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, color: Color(0xFF00FF41), size: 16),
                            const SizedBox(width: 8),
                            Text("LAT: $_currentLat\nLNG: $_currentLng", style: const TextStyle(color: Color(0xFF00FF41), fontSize: 12, height: 1.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
