import 'package:flutter/material.dart';

void main() => runApp(const ChannelApp());

class ChannelApp extends StatelessWidget {
  const ChannelApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'قناة حيدر عادل',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF17212B),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF2AABEE)),
      ),
      home: const ChannelScreen(),
    );
  }
}

class ChannelScreen extends StatefulWidget {
  const ChannelScreen({super.key});
  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final List<Map<String, dynamic>> _posts = [
    {
      'content': '🔥 العرض الأقوى حالياً\n\nتريد ملف نت مجاني؟ استقرار تام بدون انقطاع!\nالمدة: 6 أشهر كاملة.\nالسعر: 20 فقط!\n\nلضمان استمرار الملفات لا تنسون التفاعل 💙',
      'time': '10:30 ص',
      'views': 2600,
      'reactions': {'❤️': 84, '🔥': 42, '👍': 31},
    },
    {
      'content': '⚡ تحديث ملفات V2Ray\n\nشغال زين وخط آسيا.\nتم رفع أحدث الملفات الحصرية، تعمل ببنك ممتاز للألعاب. جربوها الآن.',
      'time': '08:15 ص',
      'views': 1100,
      'reactions': {'👍': 49, '🔥': 20},
    },
    {
      'content': '🛠️ تطبيق كاشف الأبراج\n\nتم إطلاق التطبيق الجديد.\nتحديد مباشر للأبراج الحقيقية.\nحمل التطبيق من الملف المرفق.',
      'time': 'أمس',
      'views': 5400,
      'reactions': {'❤️': 150, '👏': 88, '🔥': 60},
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF232E3C),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF2AABEE),
          child: Text('ح', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('قناة حيدر عادل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('67,100 مشترك', style: TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _buildPost(post);
        },
      ),
    );
  }

  Widget _buildPost(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF232E3C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس المنشور
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF2AABEE),
                  child: Text('ح', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('قناة حيدر عادل',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2AABEE))),
                    Text(post['time'], style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),
          // محتوى المنشور
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(post['content'],
                style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.6)),
          ),
          const SizedBox(height: 10),
          // التفاعلات والمشاهدات
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ايموجي التفاعلات
                Row(
                  children: post['reactions'].entries.map<Widget>((e) {
                    return Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17212B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${e.key} ${e.value}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    );
                  }).toList(),
                ),
                // المشاهدات
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text('${post['views']}', style: const TextStyle(fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
