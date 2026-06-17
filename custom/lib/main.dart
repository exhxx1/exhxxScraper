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

  final String _mapHtml = '''
  <!DOCTYPE html>
  <html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.css" />
    <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.js"></script>
    <style>
      html, body { width: 100%; height: 100%; margin: 0; padding: 0; background: #030A05; overflow: hidden; }
      #map { width: 100%; height: 100%; }
      .real-tower-icon { font-size: 26px; filter: drop-shadow(0 0 12px #00FF00); }
      .leaflet-control-container { display: none; } 
    </style>
  </head>
  <body>
    <div id="map"></div>
    <script>
      var map = L.map('map', {zoomControl: false, attributionControl: false}).setView([36.2063, 44.0089], 15);
      L.tileLayer('https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}', { maxZoom: 20 }).addTo(map);

      var realTowersLayer = L.layerGroup();
      
      window.fetchRealTowers = async function(state) {
         if(!state) { map.removeLayer(realTowersLayer); realTowersLayer.clearLayers(); return; }
         map.addLayer(realTowersLayer);
         let center = map.getCenter();
         
         // استخدام سيرفر HPI الوسيط العالمي (Anti-Block)
         let query = '[out:json];(node["man_made"="mast"](around:2000,'+center.lat+','+center.lng+');node["telecom"="antenna"](around:2000,'+center.lat+','+center.lng+'););out;';
         let url = 'https://osm.hpi.de/overpass/api/interpreter?data=' + encodeURIComponent(query);
         
         if(window.ExhxxMap) window.ExhxxMap.postMessage(JSON.stringify({msg: "📡 جاري سحب الأبراج من سيرفر HPI..."}));
         
         try {
             let res = await fetch(url);
             let data = await res.json();
             realTowersLayer.clearLayers();
             data.elements.forEach(el => {
                L.marker([el.lat, el.lon], {icon: L.divIcon({className: 'real-tower-icon', html: '📡', iconSize: [26,26]})}).addTo(realTowersLayer);
             });
             if(window.ExhxxMap) window.ExhxxMap.postMessage(JSON.stringify({msg: "✅ تم رصد " + data.elements.length + " أبراج!"}));
         } catch(e) {
             if(window.ExhxxMap) window.ExhxxMap.postMessage(JSON.stringify({msg: "❌ فشل الاتصال، تأكد من إغلاق الـ VPN"}));
         }
      };

      map.on('move', function() { var c = map.getCenter(); if(window.ExhxxMap) ExhxxMap.postMessage(JSON.stringify({lat: c.lat, lng: c.lng})); });
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
        if (data['msg'] != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg'])));
        else setState(() { _currentLat = data['lat'].toStringAsFixed(5); _currentLng = data['lng'].toStringAsFixed(5); });
      })
      ..loadHtmlString(_mapHtml);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(padding: const EdgeInsets.all(10), color: Colors.black87, child: const Text("👑 exhxx78 | كاشف الأبراج", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        backgroundColor: Colors.blueAccent,
                        onPressed: () => _controller.runJavaScript("window.locateMe();"),
                        child: const Icon(Icons.gps_fixed),
                      ),
                      const SizedBox(width: 20),
                      FloatingActionButton(
                        backgroundColor: _realTowersEnabled ? Colors.green : Colors.grey,
                        onPressed: () {
                          setState(() => _realTowersEnabled = !_realTowersEnabled);
                          _controller.runJavaScript("window.fetchRealTowers($_realTowersEnabled);");
                        },
                        child: const Icon(Icons.cell_tower),
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
