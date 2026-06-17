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
      title: 'exhxx78 | كاشف الأبراج',
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
  String _activeMode = "hybrid"; 
  
  bool _realTowersEnabled = false;

  final String _telegramLink = "https://t.me/Exhxx_channel"; 

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
      .leaflet-control-container { display: none; } 
      
      .real-tower-icon { font-size: 26px; filter: drop-shadow(0 0 12px #00FF00); animation: pulseGreen 1.5s infinite; }
      @keyframes pulseGreen { 0% {transform: scale(1);} 50% {transform: scale(1.3);} 100% {transform: scale(1);} }
    </style>
  </head>
  <body>
    <div id="map"></div>
    <script>
      var map = L.map('map', {zoomControl: false, attributionControl: false}).setView([36.2063, 44.0089], 14);
      
      var layers = {
        'hybrid': L.tileLayer('https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}', { maxZoom: 20 }), 
        'satellite': L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', { maxZoom: 19 }),
        'dark': L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { maxZoom: 19 })
      };

      var currentLayer = layers['hybrid'];
      currentLayer.addTo(map);

      var realTowersLayer = L.layerGroup();
      
      window.fetchRealTowers = async function(state) {
         if(!state) {
            map.removeLayer(realTowersLayer);
            realTowersLayer.clearLayers();
            return;
         }
         map.addLayer(realTowersLayer);
         let center = map.getCenter();
         
         // استعلام ذكي (POST) يتخطى الحظر، بنطاق 3 كم لسرعة الاستجابة
         let query = '[out:json][timeout:15];(node["man_made"="mast"](around:3000,'+center.lat+','+center.lng+');node["telecom"="antenna"](around:3000,'+center.lat+','+center.lng+');node["tower:type"="communication"](around:3000,'+center.lat+','+center.lng+'););out;';
         
         if(window.ExhxxMap) window.ExhxxMap.postMessage(JSON.stringify({msg: "⏳ جاري اختراق السيرفرات لسحب مواقع الأبراج الحقيقية..."}));
         
         try {
             // استخدام طريقة POST لتخطي حظر الـ CORS والـ VPN
             let res = await fetch('https://overpass-api.de/api/interpreter', {
                 method: 'POST',
                 body: 'data=' + encodeURIComponent(query),
                 headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
             });
             
             if (!res.ok) throw new Error("Server Block");
             
             let data = await res.json();
             realTowersLayer.clearLayers();
             
             if(data.elements.length === 0) {
                if(window.ExhxxMap) window.ExhxxMap.postMessage(JSON.stringify({msg: "⚠️ لا توجد أبراج مسجلة في هذا النطاق"}));
             } else {
                data.elements.forEach(el => {
                   let icon = L.divIcon({className: 'real-tower-icon', html: '📡', iconSize: [26,26]});
                   let marker = L.marker([el.lat, el.lon], {icon: icon}).bindPopup("<b style='color:green;'>برج اتصالات حقيقي</b><br>ID: " + el.id);
                   realTowersLayer.addLayer(marker);
                });
                if(window.ExhxxMap) window.ExhxxMap.postMessage(JSON.stringify({msg: "✅ تم رصد " + data.elements.length + " أبراج بنجاح!"}));
             }
         } catch(e) {
             if(window.ExhxxMap) window.ExhxxMap.postMessage(JSON.stringify({msg: "❌ السيرفر مشغول أو يحظر الـ VPN، حاول مجدداً"}));
         }
      };

      window.changeStyle = function(mode) {
         map.removeLayer(currentLayer);
         document.getElementById('map').className = ''; 
         if(mode === 'radar') { currentLayer = layers['satellite']; document.getElementById('map').classList.add('radar-mode'); }
         else { currentLayer = layers[mode]; }
         currentLayer.addTo(map);
      };

      map.on('move', function() { var c = map.getCenter(); if(window.ExhxxMap) ExhxxMap.postMessage(JSON.stringify({lat: c.lat, lng: c.lng})); });
      map.on('locationfound', function(e) { 
         L.circleMarker(e.latlng, {color: '#00FF41', radius: 10, fillOpacity: 0.5}).addTo(map);
         map.setView(e.latlng, 15);
      });
      window.locateMe = function() { map.locate({setView: true, maxZoom: 16}); };
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
        if (data['msg'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg'], style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF030A05), duration: const Duration(seconds: 4)));
        } else {
          setState(() { _currentLat = data['lat'].toStringAsFixed(5); _currentLng = data['lng'].toStringAsFixed(5); });
        }
      })
      // إضافة baseUrl وهمي حتى يسمح نظام الأندرويد بالاتصال الخارجي بدون حظر CORS
      ..loadHtmlString(_mapHtml, baseUrl: "https://overpass-api.de"); 
  }

  void _openLayersMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: const Color(0xFF030A05).withOpacity(0.95), border: const Border(top: BorderSide(color: Color(0xFF00FF41), width: 2)), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("أنظمة الرؤية 🛰️", style: TextStyle(color: Color(0xFF00FF41), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModeBtn("بيوت حقيقية", "hybrid", Icons.house, Colors.amber),
                _buildModeBtn("قمر صناعي", "satellite", Icons.satellite_alt, Colors.blueAccent),
                _buildModeBtn("رادار ليلي", "radar", Icons.radar, Colors.greenAccent),
                _buildModeBtn("سيبراني", "dark", Icons.dark_mode, Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBtn(String title, String mode, IconData icon, Color color) {
    return InkWell(
      onTap: () { setState(() => _activeMode = mode); _controller.runJavaScript("window.changeStyle('$mode');"); Navigator.pop(context); },
      child: Container(width: 80, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _activeMode == mode ? color.withOpacity(0.2) : Colors.black54, border: Border.all(color: _activeMode == mode ? color : Colors.white12), borderRadius: BorderRadius.circular(10)), child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: TextStyle(color: _activeMode == mode ? color : Colors.white70, fontSize: 9, fontWeight: FontWeight.bold))])),
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
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black87.withOpacity(0.8), border: Border.all(color: const Color(0xFF00FF41)), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("👑 ملفات حيدر عادل", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 3),
                            Text("💻 المطور محمد عدنان", style: TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
                          icon: const Icon(Icons.telegram, size: 18), label: const Text("قناتنا", style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () { _controller.loadRequest(Uri.parse(_telegramLink)); },
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: _openLayersMenu,
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black87, border: Border.all(color: const Color(0xFF00FF41), width: 2)), child: const Icon(Icons.layers, color: Color(0xFF00FF41), size: 28)),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () {
                              setState(() => _realTowersEnabled = !_realTowersEnabled);
                              _controller.runJavaScript("window.fetchRealTowers($_realTowersEnabled);");
                            },
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black87, border: Border.all(color: _realTowersEnabled ? Colors.green : Colors.grey, width: 2)), child: Icon(Icons.cell_tower, color: _realTowersEnabled ? Colors.greenAccent : Colors.grey, size: 28)),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🛰️ جاري تحديد موقعك عبر الأقمار...")));
                              _controller.runJavaScript("window.locateMe();");
                            },
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black87, border: Border.all(color: Colors.blueAccent, width: 2)), child: const Icon(Icons.gps_fixed, color: Colors.blueAccent, size: 28)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black87.withOpacity(0.8), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.white24)),
                        child: Text("LAT: $_currentLat\nLNG: $_currentLng", style: const TextStyle(color: Color(0xFF00FF41), fontSize: 10, height: 1.3)),
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
