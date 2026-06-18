import 'package:flutter/material.dart';

void main() => runApp(const ExhxxChannelApp());

class ExhxxChannelApp extends StatelessWidget {
  const ExhxxChannelApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ملفات حيدر عادل',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030A05),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF06140A), elevation: 0),
        cardColor: const Color(0xFF0B1F10),
      ),
      home: const FeedScreen(),
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // بيانات وهمية لمحاكاة المنشورات الحقيقية (بديل مؤقت لقاعدة البيانات)
  final List<Map<String, dynamic>> _posts = [
    {
      'title': '🔥 العرض الأقوى حالياً 🖤',
      'content': 'تريد ملف "نـ.ـت مجـ.ـاني"؟ استقرار تام بدون انقطاع!\n\nالمدة: 6 أشهر كاملة.\nالسعر: 20 فقط!\n\nلضمان استمرار الملفات لا تنسون التفاعل 💙',
      'views': 2600,
      'likes': 84,
      'isLiked': false,
    },
    {
      'title': '⚡ تحديث ملفات V2Ray',
      'content': 'ملاحظة: شغال زين وخط آسيا.\nتم رفع أحدث الملفات الحصرية، تعمل ببنك ممتاز للألعاب. جربوها الآن.',
      'views': 1100,
      'likes': 49,
      'isLiked': true,
    },
    {
      'title': '🛠️ تطبيق كاشف الأبراج (نسخة المتابعين)',
      'content': 'تم إطلاق تطبيق exhxx78 الجديد.\nتحديد مباشر للأبراج الحقيقية وربط مع الأقمار الصناعية.\nحمل التطبيق من الملف المرفق.',
      'views': 5400,
      'likes': 150,
      'isLiked': false,
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: const [
            Text("👑 ملفات حيدر عادل", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("67100 مشترك", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFF00FF41).withOpacity(0.3), height: 1.0),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 80),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          var post = _posts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: const Color(0xFF00FF41).withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['title'], style: const TextStyle(color: Color(0xFF00FF41), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(post['content'], style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 15),
                  const Divider(color: Colors.white12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // عداد المشاهدات
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye, color: Colors.grey, size: 18),
                          const SizedBox(width: 5),
                          Text("${post['views']} مشاهدة", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      // زر التفاعل (اللايك)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                              color: post['isLiked'] ? Colors.redAccent : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                post['isLiked'] = !post['isLiked'];
                                post['isLiked'] ? post['likes']++ : post['likes']--;
                              });
                            },
                          ),
                          Text("${post['likes']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // زر الإدارة (خاص بك فقط لنشر الملفات)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00FF41),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("🛠️ هذا الزر مخصص للمدير (حيدر عادل) لرفع المنشورات والملفات!", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.black87,
          ));
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
