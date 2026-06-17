import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:io'; // ⚡ مكتبة الاتصال المباشر من النظام لتخطي الحظر

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
      .real-tower-icon { font-size: 26px; filter: drop-shadow(0 0 12px #00FF00); animation: pulseGreen 1.5s infinite; }
      @keyframes pulseGreen { 0% {transform: scale(1);} 50% {transform: scale(1.3);} 100% {transform: scale(1);} }
      .leaflet-control-container { display: none; } 
    </style>
  </head>
  <body>
    <div id="map"></div>
    <script>
      var map = L.map('map', {zoomControl: false, attributionControl: false}).setView([36.2063, 44.0089], 15);
      L.tileLayer('https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}', { maxZoom: 20 }).addTo(map);

      var realTowersLayer = L.layerGroup();
      
      // الجسر البرمجي: نطلب من نظام الأندرويد سحب البيانات بدل المتصفح!
      window.fetchRealTowers = function(state) {
         if(!state) { map.removeLayer(realTowersLayer); realTowersLayer.clearLayers(); return; }
         map.addLayer(realTowersLayer);
         let center = map.getCenter();
         
         if(window.ExhxxMap) {
            window.ExhxxMap.postMessage(JSON.stringify({action: "fetch_towers", lat: center.lat, lng: center.lng}));
         }
      };

      // دالة استلام البيانات من النظام السري ورسمها
      window.drawTowersFromDart = function(jsonStr) {
         try {
             let data = JSON.parse(jsonStr);
             realTowersLayer.clearLayers();
             if(data.elements && data.elements.length > 0) {
                 data.elements.forEach(el => {
                     let icon = L.divIcon({className: 'real-tower-icon', html: '📡', iconSize: [26,26]});
                     L.marker([el.lat, el.lon], {icon: icon}).bindPopup("<b style='color:green;'>برج اتصالات حقيقي</b>").addTo(realTowersLayer);
                 });
                 if(window.ExhxxMap) window.ExhxxMap.postMessage(JSON.stringify({msg: "✅ تم رصد " + data.elements.length + " أبراج!"}));
             } else {
                 if(window.ExhxxMap) window.ExhxxMap.postMessage(JSON.stringify({msg: "⚠️ لا توجد أبراج مسجلة بهذا النطاق"}));
             }
         } catch(e) {
             if(window.ExhxxMap) window.ExhxxMap.postMessage(JSON.stringify({msg: "❌ خطأ في رسم البيانات"}));
         }
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
      ..addJavaScriptChannel('ExhxxMap', onMessageReceived: (msg) async {
        var data = jsonDecode(msg.message);
        
        // ⚡ التنفيذ السري عبر نظام الأندرويد مباشرة لتخطي حماية المتصفح ⚡
        if (data['action'] == 'fetch_towers') {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📡 جاري الاتصال المباشر بالقمر الصناعي...", style: TextStyle(color: Colors.greenAccent)), backgroundColor: Colors.black87));
           try {
               String query = '[out:json][timeout:15];(node["man_made"="mast"](around:3000,${data['lat']},${data['lng']});node["telecom"="antenna"](around:3000,${data['lat']},${data['lng']}););out;';
               Uri url = Uri.parse('https://overpass-api.de/api/interpreter?data=' + Uri.encodeComponent(query));
               
               HttpClient client = HttpClient();
               client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true); // تخطي أخطاء الـ SSL
               HttpClientRequest request = await client.getUrl(url);
               request.headers.set('User-Agent', 'exhxx78_CyberMap/3.0'); // بصمة مخصصة لتخطي الحظر
               
               HttpClientResponse response = await request.close();
               String reply = await response.transform(utf8.decoder).join();
               
               // إرسال البيانات الخام إلى الخريطة
               _controller.runJavaScript("window.drawTowersFromDart(${jsonEncode(reply)});");
           } catch (e) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ فشل الاتصال، تأكد من وجود إنترنت قوي.")));
           }
        } 
        else if (data['msg'] != null) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['msg']), backgroundColor: Colors.black87));
        } 
        else if (data['lat'] != null) {
           setState(() { _currentLat = data['lat'].toStringAsFixed(5); _currentLng = data['lng'].toStringAsFixed(5); });
        }
      })
      ..loadHtmlString(_mapHtml);
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
                Container(
                  padding: const EdgeInsets.all(10), margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black87, border: Border.all(color: const Color(0xFF00FF41)), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("👑 ملفات حيدر عادل", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("💻 المطور محمد عدنان", style: TextStyle(color: Color(0xFF00FF41), fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                        icon: const Icon(Icons.telegram, size: 18), label: const Text("قناتنا"),
                        onPressed: () => _controller.loadRequest(Uri.parse("https://t.me/Exhxx_channel")),
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
                      Row(
                        children: [
                          FloatingActionButton(
                            backgroundColor: _realTowersEnabled ? Colors.green : Colors.grey[800],
                            onPressed: () {
                              setState(() => _realTowersEnabled = !_realTowersEnabled);
                              _controller.runJavaScript("window.fetchRealTowers($_realTowersEnabled);");
                            },
                            child: Icon(Icons.cell_tower, color: _realTowersEnabled ? Colors.white : Colors.white54),
                          ),
                          const SizedBox(width: 15),
                          FloatingActionButton(
                            backgroundColor: Colors.blueAccent,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🛰️ جاري تحديد موقعك...")));
                              _controller.runJavaScript("window.locateMe();");
                            },
                            child: const Icon(Icons.gps_fixed, color: Colors.white),
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
