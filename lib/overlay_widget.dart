import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

// 🌟 สำคัญมาก: ฟังก์ชันสำหรับรันหน้าต่างบอลลูนแยกต่างหาก
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayWidget(),
    ),
  );
}

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({Key? key}) : super(key: key);

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        // เมื่อกดที่บอลลูน สามารถสั่งปิดหรือดึงหน้าแอปหลักขึ้นมาได้
        onTap: () async {
          // ตัวอย่าง: กดแล้วสั่งปิดบอลลูน
          // await FlutterOverlayWindow.closeOverlay();
        },
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF161616),
            border: Border.all(color: const Color(0xFFFFD700), width: 2.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/8.png', // รูปหุ่นยนต์ทองคำของคุณ
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.smart_toy, color: Color(0xFFFFD700), size: 30);
              },
            ),
          ),
        ),
      ),
    );
  }
}
