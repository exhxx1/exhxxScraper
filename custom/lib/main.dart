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
  String _activeMode = "dark";
  
  // حالات الأنظمة الحية
  bool _trafficEnabled = false;
  bool _flightsEnabled = false;
  bool _camsEnabled = false;

  final String _mapHtml = '''
  <!DOCTYPE html>
  <html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.css" />
    <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.js"></script>
    <style>
      html, body { width: 100%; height: 100%; margin: 0; padding: 0; background: #030A05; overflow: hidden; }
      #map { width: 100%; height: 100%; transition: filter 0.8s ease; }
      .radar-mode { filter: sepia(1) hue-rotate(90deg) saturate(3) brightness(0.8) contrast(1.2) !important; }
      .neon-mode { filter: invert(1) hue-rotate(180deg) saturate(2.5) brightness(0.9) !important; }
      .leaflet-control-container { display: none; } 
      
      /* تصميم أيقونات الطائرات والكاميرات */
      .plane-icon { font-size: 20px; color: #00FF41; filter: drop-shadow(0 0 5px #00FF41); }
      .cam-icon { font-size: 20px; color: #FF0055; filter: drop-shadow(0 0 5px #FF0055); animation: blink 2s infinite; }
      @keyframes blink { 0% {opacity: 1;} 50% {opacity: 0.4;} 100% {opacity: 1;} }
    </style>
  </head>
  <body>
    <div id="map"></div>
    <script>
      var map = L.map('map', {zoomControl: false, attributionControl: false}).setView([36.2063, 44.0089], 14);
      
      var layers = {
        'dark': L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { maxZoom: 19 }),
        'satellite': L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', { maxZoom: 19 }),
        'hybrid': L.tileLayer('https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}', { maxZoom: 20 }),
        'street': L.tileLayer('https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', { maxZoom: 20 }),
        'terrain': L.tileLayer('https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}', { maxZoom: 20 }),
        'light': L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', { maxZoom: 19 }),
        'traffic': L.tileLayer('https://mt1.google.com/vt/lyrs=m@221097413,traffic&x={x}&y={y}&z={z}', { maxZoom: 20 }) // رادار المرور
      };

      var currentLayer = layers['dark'];
      currentLayer.addTo(map);

      // --- الأنظمة الحية (Live Systems) ---
      
      // 1. نظام الطائرات (Flight Tracker)
      var flightLayer = L.layerGroup();
      var planes = [];
      function spawnPlanes() {
         let center = map.getCenter();
         for(let i=0; i<5; i++) {
            let lat = center.lat + (Math.random() - 0.5) * 0.05;
            let lng = center.lng + (Math.random() - 0.5) * 0.05;
            let icon = L.divIcon({className: 'plane-icon', html: '✈️', iconSize: [20,20]});
            let marker = L.marker([lat, lng], {icon: icon}).bindPopup("FLIGHT EXH-" + Math.floor(Math.random()*9999));
            planes.push({marker: marker, lat: lat, lng: lng, dLat: (Math.random()-0.5)*0.0002, dLng: (Math.random()-0.5)*0.0002});
            flightLayer.addLayer(marker);
         }
      }
      setInterval(() => {
         planes.forEach(p => {
            p.lat += p.dLat; p.lng += p.dLng;
            p.marker.setLatLng([p.lat, p.lng]);
         });
      }, 1000);

      // 2. نظام الكاميرات (Webcams)
      var camLayer = L.layerGroup();
      function spawnCams() {
         camLayer.clearLayers();
         let center = map.getCenter();
         for(let i=0; i<4; i++) {
            let lat = center.lat + (Math.random() - 0.5) * 0.02;
            let lng = center.lng + (Math.random() - 0.5) * 0.02;
            let icon = L.divIcon({className: 'cam-icon', html: '📷', iconSize: [20,20]});
            L.marker([lat, lng], {icon: icon}).bindPopup("LIVE SECURE CAM #" + i).addTo(camLayer);
         }
      }

      // دوال تحكم ފلاتر وأنظمة البث الحي
      window.changeStyle = function(mode) {
         map.removeLayer(currentLayer);
         let mapEl = document.getElementById('map');
         mapEl.className = ''; 

         if(mode === 'radar') { currentLayer = layers['satellite']; mapEl.classList.add('radar-mode'); }
         else if (mode === 'neon') { currentLayer = layers['light']; mapEl.classList.add('neon-mode'); }
         else { currentLayer = layers[mode]; }
         currentLayer.addTo(map);
      };

      window.toggleSystem = function(sys, state) {
         if(sys === 'traffic') { changeStyle(state ? 'traffic' : 'dark'); }
         if(sys === 'flights') { if(state){ spawnPlanes(); map.addLayer(flightLayer); } else { map.removeLayer(flightLayer); planes=[]; flightLayer.clearLayers(); } }
         if(sys === 'cams') { if(state){ spawnCams(); map.addLayer(camLayer); } else { map.removeLayer(camLayer); } }
         if(sys === 'gps') { map.locate({setView: true, maxZoom: 16}); }
      };

      map.on('move', function() {
         var center = map.getCenter();
         if(window.ExhxxMap) ExhxxMap.postMessage(JSON.stringify({lat: center.lat, lng: center.lng}));
      });
      map.on('locationfound', function(e) {
         L.circleMarker(e.latlng, {color: '#00FF41', radius: 8}).addTo(map);
      });
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
    Navigator.pop(context); 
  }

  void _toggleLiveSystem(String sys, bool state) {
    _controller.runJavaScript("window.toggleSystem('$sys', $state);");
  }

  void _openLayersMenu() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: const Color(0xFF030A05).withOpacity(0.95), border: const Border(top: BorderSide(color: Color(0xFF00FF41), width: 2)), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
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

  void _openLiveSystemsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            decoration: BoxDecoration(color: const Color(0xFF030A05).withOpacity(0.95), border: const Border(top: BorderSide(color: Colors.amber, width: 2)), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("أنظمة البث الحي والتعقب 🔴", style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                SwitchListTile(
                  activeColor: Colors.amber, title: const Text("رادار الازدحامات (Live Traffic)", style: TextStyle(color: Colors.white)), subtitle: const Text("حالة المرور في الشوارع", style: TextStyle(color: Colors.white54, fontSize: 10)),
                  value: _trafficEnabled, onChanged: (v) { setModalState(() => _trafficEnabled = v); setState(() => _trafficEnabled = v); _toggleLiveSystem('traffic', v); }
                ),
                SwitchListTile(
                  activeColor: const Color(0xFF00FF41), title: const Text("تتبع الطيران (Live Flights)", style: TextStyle(color: Colors.white)), subtitle: const Text("رصد الطائرات في مجالك الجوي", style: TextStyle(color: Colors.white54, fontSize: 10)),
                  value: _flightsEnabled, onChanged: (v) { setModalState(() => _flightsEnabled = v); setState(() => _flightsEnabled = v); _toggleLiveSystem('flights', v); }
                ),
                SwitchListTile(
                  activeColor: Colors.pinkAccent, title: const Text("كاميرات المراقبة (Webcams)", style: TextStyle(color: Colors.white)), subtitle: const Text("نقاط وصول الكاميرات الحية", style: TextStyle(color: Colors.white54, fontSize: 10)),
                  value: _camsEnabled, onChanged: (v) { setModalState(() => _camsEnabled = v); setState(() => _camsEnabled = v); _toggleLiveSystem('cams', v); }
                ),
                ListTile(
                  leading: const Icon(Icons.my_location, color: Colors.blueAccent), title: const Text("تعقب موقعي (Live GPS)", style: TextStyle(color: Colors.white)), subtitle: const Text("تحديد موقعك عبر الأقمار الصناعية", style: TextStyle(color: Colors.white54, fontSize: 10)),
                  onTap: () { _toggleLiveSystem('gps', true); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🛰️ جاري تحديد موقعك عبر الأقمار..."))); }
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildModeBtn(String title, String mode, IconData icon, Color color) {
    bool isActive = _activeMode == mode;
    return InkWell(
      onTap: () => _setMapMode(mode),
      child: Container(
        width: 110, padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: isActive ? color.withOpacity(0.2) : Colors.black54, border: Border.all(color: isActive ? color : Colors.white12), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: TextStyle(color: isActive ? color : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          const Center(child: Icon(Icons.add, color: Color(0xFF00FF41), size: 40)),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // أزرار التحكم السفلية
                      Row(
                        children: [
                          InkWell(
                            onTap: _openLayersMenu,
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black87, border: Border.all(color: const Color(0xFF00FF41), width: 2)), child: const Icon(Icons.layers, color: Color(0xFF00FF41), size: 28)),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: _openLiveSystemsMenu,
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black87, border: Border.all(color: Colors.amber, width: 2)), child: const Icon(Icons.sensors, color: Colors.amber, size: 28)),
                          ),
                        ],
                      ),
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
