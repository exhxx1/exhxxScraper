import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

void main() => runApp(const ExhxxGameMapApp());

class ExhxxGameMapApp extends StatelessWidget {
  const ExhxxGameMapApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EXHXX Cyber-Map',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030A05),
        textTheme: const TextTheme(bodyMedium: TextStyle(fontFamily: 'monospace')),
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
  String _currentLat = "36.20630"; // إحداثيات أربيل الافتراضية
  String _currentLng = "44.00890";
  bool _isRadarMode = false;

  final String _mapHtml = '''
  <!DOCTYPE html>
  <html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <style>
      body { margin:0; padding:0; background: #030A05; overflow: hidden; }
      
      /* الفلتر السحري: وضع الخريطة الداكنة السيبرانية */
      #map { 
         width: 100vw; height: 100vh; 
         transition: all 0.5s ease;
      }
      
      /* وضع الرادار العسكري (رؤية ليلية) */
      .radar-mode {
         filter: sepia(1) hue-rotate(90deg) saturate(3) brightness(0.8) contrast(1.2) !important;
      }
      
      .leaflet-control-container { display: none; } /* إخفاء أزرار الخريطة العادية لتبدو كلعبة */
    </style>
  </head>
  <body>
    <div id="map"></div>
    <script>
      var map = L.map('map', {zoomControl: false, attributionControl: false}).setView([36.2063, 44.0089], 15);
      
      // الطبقة الداكنة الأساسية (ستايل سيبراني/GTA)
      var darkLayer = L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { maxZoom: 19 });
      
      // طبقة القمر الصناعي (حقيقية 100%)
      var satLayer = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', { maxZoom: 19 });
      
      darkLayer.addTo(map);

      map.on('move', function() {
         var center = map.getCenter();
         if(window.ExhxxMap) {
           ExhxxMap.postMessage(JSON.stringify({lat: center.lat, lng: center.lng}));
         }
      });

      // دالة لتغيير مظهر اللعبة من الفلاتر
      window.toggleGameMode = function(isRadar) {
         if(isRadar) {
           map.removeLayer(darkLayer);
           satLayer.addTo(map);
           document.getElementById('map').classList.add('radar-mode');
         } else {
           map.removeLayer(satLayer);
           darkLayer.addTo(map);
           document.getElementById('map').classList.remove('radar-mode');
         }
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

  void _toggleMapStyle() {
    setState(() => _isRadarMode = !_isRadarMode);
    _controller.runJavaScript("window.toggleGameMode($_isRadarMode);");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. الخريطة الحقيقية بالخلفية
          WebViewWidget(controller: _controller),

          // 2. شبكة التصويب (Crosshair) في المنتصف
          const Center(
            child: Icon(Icons.add, color: Color(0xFF00FF41), size: 40),
          ),

          // 3. واجهة الألعاب (HUD - Heads Up Display)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // الشريط العلوي (معلومات اللاعب والطاقة)
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // قسم الطاقة (Health & Armor)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("PLAYER: EXHXX", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 5),
                          Container(
                            width: 120, height: 10,
                            decoration: BoxDecoration(border: Border.all(color: Colors.white24), color: Colors.black54),
                            child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.8, child: Container(color: const Color(0xFF00FF41))),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 120, height: 10,
                            decoration: BoxDecoration(border: Border.all(color: Colors.white24), color: Colors.black54),
                            child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.5, child: Container(color: Colors.blueAccent)),
                          ),
                        ],
                      ),
                      
                      // قسم المهمة والموقع
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black87, border: Border.all(color: const Color(0xFF00FF41))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text("ZONE: ERBIL SECTOR", style: TextStyle(color: Color(0xFF00FF41), fontSize: 12, fontWeight: FontWeight.bold)),
                            Text("MISSION: ACTIVE", style: TextStyle(color: Colors.amber, fontSize: 10)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // الشريط السفلي (الإحداثيات الحية والأسلحة)
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // زر تبديل وضع اللعبة (رادار / خريطة داكنة)
                      InkWell(
                        onTap: _toggleMapStyle,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black87, border: Border.all(color: _isRadarMode ? Colors.amber : const Color(0xFF00FF41))),
                          child: Icon(_isRadarMode ? Icons.satellite_alt : Icons.map, color: _isRadarMode ? Colors.amber : const Color(0xFF00FF41), size: 28),
                        ),
                      ),

                      // الإحداثيات الحية (Live Coordinates)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black87.withOpacity(0.7), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.white24)),
                        child: Row(
                          children: [
                            const Icon(Icons.gps_fixed, color: Color(0xFF00FF41), size: 16),
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
