// ==========================================
// #1 โหมดการเชื่อมต่อเซิร์ฟเวอร์ & ธีมสี
// ==========================================

import 'dart:async';  
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart'; // <--- เพิ่มแพ็กเกจลอยนอกแอป

// ค่าสีหลักสำหรับธีม Luxury Gold & Dark Metallic
const Color kGoldPrimary = Color(0xFFFFD700); // สีทองหลัก
const Color kGoldAccent = Color(0xFFFFC107);  // สีทองสว่าง
const Color kDarkBg = Color(0xFF0D0D0D);      // พื้นหลังดำเมทัลลิก
const Color kDarkCard = Color(0xFF161616);    // การ์ดดำเข้ม
const Color kRedNeon = Color(0xFFFF1744);     // สีแดง SELL / Loss / Stop
const Color kGreenNeon = Color(0xFF00E676);   // สีเขียว BUY / Profit / Start

// ==========================================
// 🌟 ENTRY POINT สำหรับบอลลูนที่ลอยนอกแอป (System Overlay)
// ==========================================
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FloatingRobotOverlay(),
    ),
  );
}

// วิดเจ็ตที่จะไปแสดงผลลอยอยู่บนหน้าจอเครื่องภายนอกแอป
class FloatingRobotOverlay extends StatelessWidget {
  const FloatingRobotOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          // เมื่อกดที่บอลลูนนอกแอป ให้ดึงแอปหลักกลับมาแสดงผล
          FlutterOverlayWindow.shareData("open_app");
        },
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kDarkCard,
            border: Border.all(color: kGoldPrimary, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: kGreenNeon.withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                'assets/images/7.png',
                fit: BoxFit.cover,
                width: 54,
                height: 54,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.smart_toy, color: kGoldPrimary);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// #2 โหมดเมนหลัก
// ==========================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBnKyMazopUyD1k-kcIXo3bFedWfHXN0JA",
          appId: "1:155532929563:android:49d8a1e0040dc87ce766be",
          messagingSenderId: "155532929563",
          projectId: "liquidity-b8739",
          storageBucket: "liquidity-b8739.firebasestorage.app",
          databaseURL: "https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app",
        ),
      );
    }
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(const LiquiditySweepApp());
}

// Widget ช่วยทำเอฟเฟกต์พิมพ์ดีดข้อความ
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.speed = const Duration(milliseconds: 65),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = "";
  int _currentIndex = 0;
  bool _completed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _displayedText = "";
      _currentIndex = 0;
      _completed = false;
      _startTyping();
    }
  }

  void _startTyping() {
    if (widget.text.isEmpty) return;
    _timer = Timer.periodic(widget.speed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        setState(() {
          _completed = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
    );
  }
}

// ==========================================
// #3 โหมด LiquiditySweepApp
// ==========================================

class LiquiditySweepApp extends StatelessWidget {
  const LiquiditySweepApp({super.key});

  Future<bool> _checkLoginSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final login = prefs.getString('mt5_login') ??
          prefs.getString('saved_mt5_login') ??
          '';

      return login.trim().isNotEmpty;
    } catch (e) {
      debugPrint('Check login session error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GOLD PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kDarkBg,
        cardColor: kDarkCard,
        colorScheme: const ColorScheme.dark(
          primary: kGoldPrimary,
          secondary: kGoldAccent,
        ),
      ),
      home: FutureBuilder<bool>(
        future: _checkLoginSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              backgroundColor: kDarkBg,
              body: Center(
                child: CircularProgressIndicator(
                  color: kGoldPrimary,
                ),
              ),
            );
          }

          if (snapshot.data == true) {
            return const PinAuthWrapper();
          }

          return const MT5LoginWrapper();
        },
      ),
    );
  }
}

// ==========================================
// #4 โหมดการเข้าใช้งานครั้งแรก (MT5 Login Wrapper)
// ==========================================

class MT5LoginWrapper extends StatefulWidget {
  const MT5LoginWrapper({super.key});

  @override
  State<MT5LoginWrapper> createState() => _MT5LoginWrapperState();
}

class _MT5LoginWrapperState extends State<MT5LoginWrapper> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serverController = TextEditingController(); 
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  void _submitMT5Login() async {
    ScaffoldMessenger.of(context).clearSnackBars();

    String login = _loginController.text.trim();
    String password = _passwordController.text.trim();
    String server = _serverController.text.trim().isEmpty ? 'ICMarketsSC-Demo' : _serverController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกเลขพอร์ต MT5 และ Investor Password ให้ครบถ้วน'),
          backgroundColor: kDarkCard,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      FirebaseApp app;
      if (Firebase.apps.isEmpty) {
        app = await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyBnKyMazopUyD1k-kcIXo3bFedWfHXN0JA",
            appId: "1:155532929563:android:49d8a1e0040dc87ce766be",
            messagingSenderId: "155532929563",
            projectId: "liquidity-b8739",
            storageBucket: "liquidity-b8739.firebasestorage.app",
            databaseURL: "https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app",
          ),
        );
      } else {
        app = Firebase.app();
      }

      final database = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL: 'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      final accountRef = database.ref('accounts/$login');
      final snapshot = await accountRef.get();

      if (snapshot.exists) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mt5_login', login);
        await prefs.setString('saved_mt5_login', login);
        await prefs.setString('mt5_server', server);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PinAuthWrapper()),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบหมายเลขบัญชีนี้ในระบบ Firebase'),
            backgroundColor: kDarkCard,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: kRedNeon,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/5.png',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.25),
            errorBuilder: (context, error, stackTrace) => Container(color: kDarkBg),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kGoldPrimary, width: 2.0),
                          boxShadow: [
                            BoxShadow(
                              color: kGoldPrimary.withOpacity(0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Opacity(
                            opacity: 0.9,
                            child: Image.asset(
                              'assets/images/5.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'GOLD PRO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: kGoldPrimary,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        ' ROBOT ALGO TRADING',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _loginController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Account Login (เช่น 53049695)',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontStyle: FontStyle.italic, fontSize: 13),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kGoldPrimary.withOpacity(0.6), width: 1.5)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kGoldPrimary, width: 2.0)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                          filled: true,
                          fillColor: kDarkCard.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Investor Password',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontStyle: FontStyle.italic, fontSize: 13),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kGoldPrimary.withOpacity(0.6), width: 1.5)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kGoldPrimary, width: 2.0)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                          filled: true,
                          fillColor: kDarkCard.withOpacity(0.75),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: kGoldPrimary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [kGoldPrimary, kGoldAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kGoldPrimary.withOpacity(0.6),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitMT5Login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text(
                                    'VERIFY & CONNECT',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Powered By Algohost',
                        style: TextStyle(color: kGoldPrimary, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// #5 PIN AUTH WRAPPER
// ==========================================

class PinAuthWrapper extends StatefulWidget {
  const PinAuthWrapper({super.key});

  @override
  State<PinAuthWrapper> createState() => _PinAuthWrapperState();
}

class _PinAuthWrapperState extends State<PinAuthWrapper> {
  bool isAuthorized = false;
  bool hasStoredPin = false;
  bool isConfirming = false;
  bool isLoading = true;
  bool _isProcessing = false;

  String firstEnteredPin = '';
  String currentPinInput = '';

  @override
  void initState() {
    super.initState();
    _checkPinExists();
  }

  Future<void> _checkPinExists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final pin = prefs.getString('saved_user_pin');

      setState(() {
        hasStoredPin = pin != null && pin.isNotEmpty;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Check PIN error: $e');
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อ่านข้อมูล PIN ไม่สำเร็จ กรุณาปิดแล้วเปิดแอปใหม่'),
          backgroundColor: kRedNeon,
        ),
      );
    }
  }

  Future<bool> _saveNewPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString('saved_user_pin', pin);
      return saved && prefs.getString('saved_user_pin') == pin;
    } catch (e) {
      debugPrint('Save PIN error: $e');
      return false;
    }
  }

  Future<void> _verifyPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString('saved_user_pin');

      if (!mounted) return;

      if (storedPin == pin && storedPin != null) {
        setState(() {
          isAuthorized = true;
          currentPinInput = '';
        });
      } else {
        setState(() {
          currentPinInput = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รหัส PIN ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: kRedNeon,
          ),
        );
      }
    } catch (e) {
      debugPrint('Verify PIN error: $e');
      if (!mounted) return;

      setState(() {
        currentPinInput = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ตรวจสอบ PIN ไม่สำเร็จ กรุณาลองใหม่'),
          backgroundColor: kRedNeon,
        ),
      );
    }
  }

  Future<void> _onNumberTap(String number) async {
    if (isLoading || _isProcessing || currentPinInput.length >= 6) {
      return;
    }

    setState(() {
      currentPinInput += number;
    });

    if (currentPinInput.length != 6) return;

    _isProcessing = true;

    try {
      final enteredPin = currentPinInput;

      if (hasStoredPin) {
        await _verifyPin(enteredPin);
        return;
      }

      if (!isConfirming) {
        setState(() {
          firstEnteredPin = enteredPin;
          currentPinInput = '';
          isConfirming = true;
        });
        return;
      }

      if (firstEnteredPin != enteredPin) {
        setState(() {
          currentPinInput = '';
          firstEnteredPin = '';
          isConfirming = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รหัส PIN ไม่ตรงกัน กรุณาตั้งค่าใหม่อีกครั้ง'),
            backgroundColor: kRedNeon,
          ),
        );
        return;
      }

      final saved = await _saveNewPin(enteredPin);

      if (!mounted) return;

      if (saved) {
        setState(() {
          hasStoredPin = true;
          isAuthorized = true;
          currentPinInput = '';
          firstEnteredPin = '';
          isConfirming = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึก PIN สำเร็จ'),
            backgroundColor: kGreenNeon,
          ),
        );
      } else {
        setState(() {
          currentPinInput = '';
          firstEnteredPin = '';
          isConfirming = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึก PIN ไม่สำเร็จ กรุณาตั้งค่าใหม่'),
            backgroundColor: kRedNeon,
          ),
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _onDeleteTap() {
    if (isLoading || _isProcessing || currentPinInput.isEmpty) return;

    setState(() {
      currentPinInput = currentPinInput.substring(0, currentPinInput.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: kDarkBg,
        body: Center(
          child: CircularProgressIndicator(
            color: kGoldPrimary,
          ),
        ),
      );
    }

    if (isAuthorized) {
      return const MainNavigationScreen();
    }

    String titleText = 'กรุณากรอก PIN เพื่อเข้าใช้งานระบบ';

    if (!hasStoredPin) {
      titleText = isConfirming
          ? 'ยืนยันรหัส PIN 6 หลักอีกครั้ง'
          : 'ตั้งค่ารหัส PIN 6 หลักความปลอดภัย';
    }

    return Scaffold(
      backgroundColor: kDarkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/1.jpg',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.25),
            errorBuilder: (ctx, err, stack) => Container(color: kDarkBg),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kGoldPrimary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: kGoldPrimary.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Opacity(
                          opacity: 0.9,
                          child: Image.asset(
                            'assets/images/1.jpg',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.smart_toy,
                              color: kGoldPrimary,
                              size: 80,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'GOLD PRO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: kGoldPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      ' ROBOT ALGO TRADING',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final filled = index < currentPinInput.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 7),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? kGoldPrimary
                                : Colors.transparent,
                            border: Border.all(
                              color: kGoldPrimary,
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    for (final row in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: row.map(_buildPinButton).toList(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 84),
                          _buildPinButton('0'),
                          _buildPinButton('del'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Powered By Algohost',
                      style: TextStyle(
                        color: kGoldPrimary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinButton(String val) {
    return Container(
      width: 64,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kDarkCard.withOpacity(0.75),
        border: Border.all(
          color: kGoldPrimary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: kGoldPrimary.withOpacity(0.15),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (val == 'del') {
              _onDeleteTap();
            } else {
              _onNumberTap(val);
            }
          },
          customBorder: const CircleBorder(),
          child: Center(
            child: val == 'del'
                ? const Icon(
                    Icons.backspace_outlined,
                    color: kGoldPrimary,
                    size: 20,
                  )
                : Text(
                    val,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// #6 โหมดควบคุมแดชบอร์ด (MainNavigationScreen)
// ==========================================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 2;
  String currentLogin = "235305975";
  int unreadAlertsCount = 0;

  DatabaseReference? _alertsRef;
  DatabaseReference? _dbRef;
  DatabaseReference? _logsRef;
  DatabaseReference? _ordersRef;

  Offset _robotBubbleOffset = const Offset(320, 600);
  Offset _modalOffset = const Offset(16, 80);

  bool _isLiveStatusVisible = true;
  bool _isRobotBubblePressed = false;
  bool _isLargeLogsModalOpen = false;
  bool isRunning = false;
  bool isConnected = false;

  String symbol = "XAUUSD";
  String timeframe = "M1";
  double profit = 0.0;

  List<Map<String, dynamic>> _botLogs = [];
  List<Map<dynamic, dynamic>> activeOrders = [];

  final List<String> _images = [
    'assets/images/2.png',
    'assets/images/4.png',
    'assets/images/6.png',
  ];
  int _imageIndex = 0; 
  Timer? _imageTimer; 

  late final AnimationController _bounceController =
      AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _bounceAnimation =
      Tween<double>(begin: 0.0, end: -10.0).animate(
    CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ),
  );

  late final AnimationController _scannerController =
      AnimationController(
    duration: const Duration(seconds: 3),
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _scannerAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _scannerController,
      curve: Curves.easeInOut,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initOverlayPermissionAndListener(); // <--- ขอสิทธิ์และเปิดบอลลูนลอยนอกแอป

    _loadSavedLogin().then((_) {
      if (!mounted) return;

      _listenToActiveAccount();
      _listenToAlertsCount();
      _initFirebaseAndListen();
      _listenToLogs();
      _listenToConnectionStatus();
      _listenToOrdersForDialog();
    });

    _imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _imageIndex = (_imageIndex + 1) % _images.length;
        });
      }
    });
  }

  // ขอสิทธิ์แสดงทับแอปอื่น และเปิดใช้งานบอลลูนลอยนอกแอปอัตโนมัติ
  Future<void> _initOverlayPermissionAndListener() async {
    try {
      bool? isGranted = await FlutterOverlayWindow.isPermissionGranted();
      if (isGranted == false) {
        await FlutterOverlayWindow.requestPermission();
      } else if (isGranted == true) {
        if (!await FlutterOverlayWindow.isActive()) {
          await FlutterOverlayWindow.showOverlay(
            height: 70,
            width: 70,
            alignment: OverlayAlignment.centerRight,
            flag: OverlayFlag.defaultFlag,
            visibility: NotificationVisibility.visibilityPublic,
            positionGravity: PositionGravity.none,
          );
        }
      }

      // ฟังการกดคลิกที่บอลลูนนอกแอปเพื่อให้ดึงแอปกลับมาหน้าหลัก
      FlutterOverlayWindow.overlayListener.listen((event) {
        if (event == "open_app") {
          // สามารถเพิ่มโค้ดนำทางหน้าจอเพิ่มเติมตรงนี้ได้
        }
      });
    } catch (e) {
      debugPrint("Overlay init error: $e");
    }
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _bounceController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('mt5_login');

    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() {
        currentLogin = saved;
      });
    }
  }

  void _listenToActiveAccount() {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      database.ref('status/login').onValue.listen((event) {
        final val = event.snapshot.value?.toString();

        if (val != null &&
            val.isNotEmpty &&
            mounted &&
            val != currentLogin) {
          setState(() {
            currentLogin = val;
          });

          _listenToAlertsCount();
          _initFirebaseAndListen();
          _listenToLogs();
          _listenToOrdersForDialog();
        }
      });
    } catch (e) {
      debugPrint("Account listen error: $e");
    }
  }

  void _listenToAlertsCount() {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      _alertsRef = database.ref('accounts/$currentLogin/alerts');

      _alertsRef?.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value;

        if (data != null && mounted) {
          int total = 0;

          if (data is Map) {
            total = data.length;
          } else if (data is List) {
            total = data.where((e) => e != null).length;
          }

          setState(() {
            if (_currentIndex != 4) {
              unreadAlertsCount = total;
            }
          });
        } else if (data == null && mounted) {
          setState(() {
            unreadAlertsCount = 0;
          });
        }
      });
    } catch (e) {
      debugPrint("Alerts count error: $e");
    }
  }

  void _initFirebaseAndListen() {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      _dbRef = database.ref('accounts/$currentLogin/status');

      _dbRef?.onValue.listen((DatabaseEvent event) {
        final rawData = event.snapshot.value;

        if (rawData is Map && mounted) {
          final data = Map<dynamic, dynamic>.from(rawData);

          setState(() {
            isRunning = data['is_running'] == true;

            final rawProfit = data['profit'];
            profit = rawProfit is num
                ? rawProfit.toDouble()
                : double.tryParse(rawProfit?.toString() ?? '0') ?? 0.0;

            symbol = data['symbol']?.toString() ?? 'BTCUSD';
            timeframe = data['timeframe']?.toString() ?? 'M1';
          });
        }
      });
    } catch (e) {
      debugPrint("Database listen error: $e");
    }
  }

  void _listenToConnectionStatus() {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      database.ref('.info/connected').onValue.listen((event) {
        final connected =
            event.snapshot.value as bool? ?? false;

        if (mounted) {
          setState(() {
            isConnected = connected;
          });
        }
      });
    } catch (e) {
      debugPrint("Connection listen error: $e");
    }
  }

  void _listenToLogs() {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      _logsRef = database.ref('accounts/$currentLogin/logs');

      _logsRef?.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value;

        if (!mounted) return;

        List<Map<String, dynamic>> tempLogs = [];

        if (data is Map) {
          final sortedEntries = data.entries.toList()
            ..sort(
              (a, b) => b.key.toString().compareTo(
                    a.key.toString(),
                  ),
            );

          for (final entry in sortedEntries) {
            if (entry.value != null) {
              final rawMsg = entry.value.toString();
              final cleanMsg = rawMsg.replaceAll(
                RegExp(r'command\s*', caseSensitive: false),
                '',
              );

              tempLogs.add({
                'key': entry.key.toString(),
                'message': cleanMsg,
              });
            }
          }
        } else if (data is List) {
          for (int i = data.length - 1; i >= 0; i--) {
            if (data[i] != null) {
              final rawMsg = data[i].toString();
              final cleanMsg = rawMsg.replaceAll(
                RegExp(r'command\s*', caseSensitive: false),
                '',
              );

              tempLogs.add({
                'key': i.toString(),
                'message': cleanMsg,
              });
            }
          }
        }

        setState(() {
          _botLogs = tempLogs;
        });
      });
    } catch (e) {
      debugPrint("Logs listen error: $e");
    }
  }

  void _listenToOrdersForDialog() {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      _ordersRef = database.ref('accounts/$currentLogin/orders');

      _ordersRef?.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value;

        if (!mounted) return;

        List<Map<dynamic, dynamic>> newOrders = [];

        if (data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              newOrders.add(Map<dynamic, dynamic>.from(value));
            }
          });
        } else if (data is List) {
          for (final item in data) {
            if (item is Map) {
              newOrders.add(Map<dynamic, dynamic>.from(item));
            }
          }
        }

        setState(() {
          activeOrders = newOrders;
        });
      });
    } catch (e) {
      debugPrint("Orders listen error: $e");
    }
  }

  void _clearLogItem(String key) async {
    try {
      if (_logsRef != null) {
        await _logsRef!.child(key).remove();
      }
    } catch (e) {
      debugPrint("Clear log item error: $e");
    }
  }

  void _clearAllLogs() async {
    try {
      if (_logsRef != null) {
        await _logsRef!.remove();

        if (mounted) {
          setState(() {
            _botLogs.clear();
          });
        }
      }
    } catch (e) {
      debugPrint("Clear all logs error: $e");
    }
  }

  Future<bool> _handleBackButton() async {
    if (_isLargeLogsModalOpen) {
      setState(() {
        _isLargeLogsModalOpen = false;
      });
      return false;
    }

    if (_currentIndex != 2) {
      setState(() {
        _currentIndex = 2;
      });
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const SettingsScreen(),
      OrdersScreen(accountLogin: currentLogin),
      HomeScreen(accountLogin: currentLogin),
      HistoryScreen(accountLogin: currentLogin),
      AlertsScreen(
        accountLogin: currentLogin,
        onAlertsRead: () {
          if (!mounted) return;

          setState(() {
            unreadAlertsCount = 0;
          });
        },
      ),
    ];

    final double totalOrdersProfit = activeOrders.fold(
      0.0,
      (sum, item) {
        return sum +
            (double.tryParse(
                  item['profit']?.toString() ?? '0.0',
                ) ??
                0.0);
      },
    );

    final double totalLots = activeOrders.fold(
      0.0,
      (sum, item) {
        return sum +
            (double.tryParse(
                  item['lot']?.toString() ?? '0.0',
                ) ??
                0.0);
      },
    );

    final bool isTotalProfit = totalOrdersProfit >= 0;

    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/8.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.25),
              errorBuilder: (context, error, stackTrace) {
                return Container(color: kDarkBg);
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 65.0),
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: kDarkCard.withOpacity(0.8),
                    border: Border(
                      top: BorderSide(
                        color: kGoldPrimary.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCustomNavItem(0, Icons.tune, 'Settings'),
                      _buildCustomNavItem(1, Icons.list_alt, 'Orders'),
                      _buildCustomNavItem(2, Icons.home_filled, 'Home'),
                      _buildCustomNavItem(3, Icons.history, 'History'),
                      _buildCustomNavItem(
                        4,
                        Icons.notifications_active,
                        'Alerts',
                        badgeCount: unreadAlertsCount,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLargeLogsModalOpen)
              Positioned(
                left: _modalOffset.dx,
                top: _modalOffset.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _modalOffset += details.delta;
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.92,
                    height: MediaQuery.of(context).size.height * 0.72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: kGoldPrimary,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                      color: kDarkCard.withOpacity(0.85),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.terminal,
                                    color: kGoldPrimary,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'STATUS & LOGS',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: kGoldPrimary,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _isLiveStatusVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: _isLiveStatusVisible
                                          ? kGreenNeon
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isLiveStatusVisible =
                                            !_isLiveStatusVisible;
                                      });
                                    },
                                    tooltip: _isLiveStatusVisible
                                        ? 'Hide Live Status'
                                        : 'Show Live Status',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                  ),
                                  if (_botLogs.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_sweep,
                                        color: kRedNeon,
                                        size: 20,
                                      ),
                                      onPressed: _clearAllLogs,
                                      tooltip: 'Clear All Logs',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isLargeLogsModalOpen = false;
                                      });
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          color: kGoldPrimary,
                          height: 1,
                          thickness: 1.5,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isLiveStatusVisible) ...[
                                  _buildStatusReportBox(
                                    symbol,
                                    timeframe,
                                    totalOrdersProfit,
                                    activeOrders.length,
                                    totalLots,
                                    isTotalProfit,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.show_chart,
                                      color: kGoldPrimary,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'ACTIVITY LOGS',
                                      style: TextStyle(
                                        color: kGoldPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_botLogs.isEmpty)
                                  const Expanded(
                                    child: Center(
                                      child: Text(
                                        'No log records...',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _botLogs.length,
                                      itemBuilder: (context, index) {
                                        final log = _botLogs[index];
                                        final bool isLatest = index == 0;

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: isLatest
                                                    ? Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                            '➔ ',
                                                            style: TextStyle(
                                                              color: kGreenNeon,
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: TypewriterText(
                                                              text:
                                                                  '${log['message']}',
                                                              speed:
                                                                  const Duration(
                                                                milliseconds: 65,
                                                              ),
                                                              style:
                                                                  const TextStyle(
                                                                color: kGreenNeon,
                                                                fontFamily:
                                                                    'monospace',
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight.bold,
                                                                height: 1.4,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Text(
                                                        "> ${log['message']}",
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontFamily: 'monospace',
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          height: 1.4,
                                                        ),
                                                      ),
                                              ),
                                              GestureDetector(
                                                onTap: () =>
                                                    _clearLogItem(
                                                  log['key'].toString(),
                                                ),
                                                child: const Padding(
                                                  padding: EdgeInsets.only(
                                                    left: 8.0,
                                                  ),
                                                  child: Icon(
                                                    Icons.delete_outline,
                                                    color: kRedNeon,
                                                    size: 15,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: _robotBubbleOffset.dx,
              top: _robotBubbleOffset.dy,
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: child,
                  );
                },
                child: Draggable(
                  feedback: Material(
                    color: Colors.transparent,
                    child: _buildRobotBubbleWidget(),
                  ),
                  childWhenDragging: const SizedBox.shrink(),
                  onDragEnd: (details) {
                    setState(() {
                      _robotBubbleOffset = details.offset;
                    });
                  },
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _isRobotBubblePressed = true;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isRobotBubblePressed = false;
                        _isLargeLogsModalOpen = !_isLargeLogsModalOpen;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        _isRobotBubblePressed = false;
                      });
                    },
                    child: AnimatedScale(
                      scale: _isRobotBubblePressed ? 0.85 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: _buildRobotBubbleWidget(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRobotBubbleWidget() {
    final bool isServerActive = isConnected && isRunning;

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kDarkCard,
        border: Border.all(
          color: kGoldPrimary,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isServerActive ? kGreenNeon : kRedNeon)
                .withOpacity(0.6),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                'assets/images/7.png',
                fit: BoxFit.cover,
                width: 54,
                height: 54,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.smart_toy, color: kGoldPrimary);
                },
              ),
            ),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isServerActive ? kGreenNeon : kRedNeon,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusReportBox(
    String symbol,
    String tf,
    double totalOrdersProfit,
    int orderCount,
    double totalLots,
    bool isTotalProfit,
  ) {
    final bool isServerActive = isConnected && isRunning;
    final String scanImage = _images[_imageIndex];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kDarkCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kGoldPrimary,
          width: 2.0,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.black,
                  child: AnimatedBuilder(
                    animation: _scannerAnimation,
                    builder: (context, child) {
                      final double scanValue =
                          _scannerAnimation.value * 150;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 800),
                            child: Image.asset(
                              scanImage,
                              key: ValueKey<String>(scanImage),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('GOLD PRO image error: $error');
                                return const ColoredBox(
                                  color: Colors.black,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.amber,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: scanValue.clamp(0.0, 147.0),
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: const BoxDecoration(
                                color: kGoldPrimary,
                                boxShadow: [
                                  BoxShadow(
                                    color: kGoldPrimary,
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIVE STATUS',
                      style: TextStyle(
                        color: kGoldPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isServerActive ? kGreenNeon : kRedNeon,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isServerActive
                                        ? kGreenNeon
                                        : kRedNeon)
                                    .withOpacity(0.8),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isServerActive
                                ? 'EA SERVER ONLINE & RUNNING'
                                : 'EA SERVER OFFLINE / STOPPED',
                            style: TextStyle(
                              color:
                                  isServerActive ? kGreenNeon : kRedNeon,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(
                      color: Colors.white24,
                      height: 6,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Orders: $orderCount',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Lots: ${totalLots.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            'P/L: ${isTotalProfit ? "+" : ""}\$${totalOrdersProfit.toStringAsFixed(2)}',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: isTotalProfit
                                  ? kGreenNeon
                                  : kRedNeon,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isLiveStatusVisible = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kGoldPrimary,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNavItem(
    int index,
    IconData icon,
    String label, {
    int badgeCount = 0,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;

          if (index == 4) {
            unreadAlertsCount = 0;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? kDarkCard.withOpacity(0.85)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? kGoldPrimary : Colors.transparent,
            width: isSelected ? 1.5 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kGoldPrimary.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? kGoldPrimary : Colors.white70,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: kGoldPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? kGoldPrimary : Colors.white70,
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
