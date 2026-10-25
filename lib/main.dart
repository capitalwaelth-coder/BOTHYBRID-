// ==========================================
// #1 โหมดการเชื่อมต่อเซิร์ฟเวอร์ & ธีมสี & ระบบ Overlay
// ==========================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kGoldPrimary = Color(0xFFFFD700);
const Color kGoldAccent = Color(0xFFFFC107);
const Color kDarkBg = Color(0xFF0D0D0D);
const Color kDarkCard = Color(0xFF161616);
const Color kRedNeon = Color(0xFFFF1744);
const Color kGreenNeon = Color(0xFF00E676);

// ==========================================
// #0 Widget แสดงข้อความแบบพิมพ์ดีด (Typewriter) - ประกาศแค่ชุดเดียวตรงนี้เท่านั้น
// ==========================================
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 35),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
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
      _currentIndex = 0;
      _displayedText = '';
      _startTyping();
    }
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < widget.text.length) {
        if (mounted) {
          setState(() {
            _displayedText += widget.text[_currentIndex];
            _currentIndex++;
          });
        }
      } else {
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
    return SelectableText(
      _displayedText,
      style: widget.style,
    );
  }
}

// ==========================================
// #1.1 โหมดการเชื่อม ระบบ Overlay
// ==========================================

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: FullOverlayContent(),
      ),
    ),
  );
}



// ==========================================
// FULL OVERLAY CONTENT (ดีไซน์สแกนเนอร์ + โลโก้เปลี่ยนรูป + ดึง Logs อัตโนมัติ)
// ==========================================

class FullOverlayContent extends StatefulWidget {
  const FullOverlayContent({super.key});

  @override
  State<FullOverlayContent> createState() => _FullOverlayContentState();
}

class _FullOverlayContentState extends State<FullOverlayContent>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isMoving = false;

  String currentLogin = '53049695';

  bool isRunning = false;
  bool isConnected = false;

  double _overlayX = 0;
  double _overlayY = 0;

  List<Map<String, dynamic>> _botLogs = [];

  DatabaseReference? _logsRef;

  StreamSubscription<DatabaseEvent>? _logsSubscription;
  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  StreamSubscription? _overlaySubscription;

  final ScrollController _scrollController = ScrollController();

  static const Color _gold = Color(0xFFFFD700);
  static const Color _background = Color(0xFF121212);
  static const Color _green = Color(0xFF00E676);
  static const Color _red = Color(0xFFFF1744);

  // รายการรูปภาพสำหรับทำสไลด์โชว์ในสแกนเนอร์
  final List<String> _images = [
    'assets/images/2.png',
    'assets/images/4.png',
    'assets/images/6.png',
  ];
  int _imageIndex = 0;
  Timer? _imageTimer;

  late final AnimationController _overlayBounceController =
      AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _overlayBounceAnimation =
      Tween<double>(
    begin: -7.0,
    end: 7.0,
  ).animate(
    CurvedAnimation(
      parent: _overlayBounceController,
      curve: Curves.easeInOut,
    ),
  );

  // Animation สำหรับเส้นสแกนเนอร์วิ่งขึ้นลง
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

    _initFirebaseForOverlay();

    // ตัวสลับภาพแบนเนอร์ทุกๆ 3วินาที
    _imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _imageIndex = (_imageIndex + 1) % _images.length;
        });
      }
    });

    _overlaySubscription =
        FlutterOverlayWindow.overlayListener.listen((event) {
      if (!mounted || event == null) return;

      try {
        dynamic decoded = event;

        if (decoded is String) {
          decoded = jsonDecode(decoded);
        }

        if (decoded is! Map) return;

        final data = Map<String, dynamic>.from(decoded);

        final String? newLogin =
            (data['login'] ?? data['currentLogin'])?.toString();

        final dynamic runningValue = data['isRunning'] ??
            data['running'];

        final dynamic connectedValue = data['isConnected'] ??
            data['connected'];

        setState(() {
          if (newLogin != null && newLogin.isNotEmpty) {
            currentLogin = newLogin;
          }

          if (runningValue is bool) {
            isRunning = runningValue;
          }

          if (connectedValue is bool) {
            isConnected = connectedValue;
          }

          final dynamic logsValue = data['logs'];

          if (logsValue is List) {
            _botLogs = logsValue.map((item) {
              if (item is Map) {
                return Map<String, dynamic>.from(item);
              }

              return <String, dynamic>{
                'message': item.toString(),
              };
            }).toList();
          }
        });

        if (newLogin != null &&
            newLogin.isNotEmpty &&
            _logsRef?.key != newLogin) {
          _watchLogs(newLogin);
        }
      } catch (e) {
        debugPrint('Overlay data error: $e');
      }
    });

    FlutterOverlayWindow.shareData({
      'type': 'command',
      'command': 'request_snapshot',
    });
  }

  Future<void> _initFirebaseForOverlay() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      await _connectionSubscription?.cancel();

      _connectionSubscription = database
          .ref('.info/connected')
          .onValue
          .listen((event) {
        if (!mounted) return;

        final bool online = event.snapshot.value == true;

        if (isConnected != online) {
          setState(() {
            isConnected = online;
          });
        }
      }, onError: (error) {
        debugPrint('Firebase connection error: $error');

        if (mounted) {
          setState(() {
            isConnected = false;
          });
        }
      });

      _watchLogs(currentLogin, database: database);
    } catch (e, stackTrace) {
      debugPrint('Overlay Firebase initialization error: $e');
      debugPrint('$stackTrace');

      if (mounted) {
        setState(() {
          isConnected = false;
        });
      }
    }
  }

  void _watchLogs(
    String login, {
    FirebaseDatabase? database,
  }) {
    if (login.isEmpty) return;

    _logsSubscription?.cancel();

    try {
      final db = database ??
          FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
          );

      _logsRef = db.ref('accounts/$login/logs');

      _logsSubscription = _logsRef!.onValue.listen((event) {
        if (!mounted) return;

        final dynamic value = event.snapshot.value;
        final List<Map<String, dynamic>> parsedLogs = [];

        if (value is Map) {
          final sortedEntries = value.entries.toList()
            ..sort((a, b) => b.key.toString().compareTo(a.key.toString()));

          for (final entry in sortedEntries) {
            final item = entry.value;
            if (item != null) {
              if (item is Map) {
                final map = Map<String, dynamic>.from(item);
                final String message = map['message']?.toString() ??
                    map['text']?.toString() ??
                    map['log']?.toString() ??
                    map['msg']?.toString() ??
                    item.toString();
                parsedLogs.add({'key': entry.key.toString(), 'message': message});
              } else {
                parsedLogs.add({'key': entry.key.toString(), 'message': item.toString()});
              }
            }
          }
        } else if (value is List) {
          for (int i = value.length - 1; i >= 0; i--) {
            final item = value[i];
            if (item != null) {
              if (item is Map) {
                final map = Map<String, dynamic>.from(item);
                final String message = map['message']?.toString() ??
                    map['text']?.toString() ??
                    map['log']?.toString() ??
                    map['msg']?.toString() ??
                    item.toString();
                parsedLogs.add({'key': i.toString(), 'message': message});
              } else {
                parsedLogs.add({'key': i.toString(), 'message': item.toString()});
              }
            }
          }
        }

        setState(() {
          _botLogs = parsedLogs;
        });
      }, onError: (error) {
        debugPrint('Firebase LOG error: $error');
      });
    } catch (e) {
      debugPrint('Watch LOG error: $e');
    }
  }

  Future<void> _setExpanded(bool expanded) async {
    if (!mounted) return;

    setState(() {
      _isExpanded = expanded;
    });

    try {
      if (expanded) {
        // ขยายขนาดหน้าต่าง Overlay ให้กว้างและสูงขึ้นเพื่อรองรับ Scanner และ Logs
        await FlutterOverlayWindow.resizeOverlay(
          350,
          480,
          true,
        );
      } else {
        await FlutterOverlayWindow.resizeOverlay(
          90,
          90,
          true,
        );
      }
    } catch (e) {
      debugPrint('Resize overlay error: $e');
    }
  }

  Future<void> _hideOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('Close overlay error: $e');
    }
  }

  Future<void> _moveBalloon(DragUpdateDetails details) async {
    if (_isExpanded || _isMoving) return;

    _isMoving = true;

    try {
      _overlayX += details.delta.dx;
      _overlayY += details.delta.dy;

      if (_overlayX < -600) _overlayX = -600;
      if (_overlayX > 600) _overlayX = 600;

      if (_overlayY < -1200) _overlayY = -1200;
      if (_overlayY > 1200) _overlayY = 1200;

      await FlutterOverlayWindow.moveOverlay(
        OverlayPosition(_overlayX, _overlayY),
      );
    } catch (e) {
      debugPrint('Move overlay error: $e');
    } finally {
      _isMoving = false;
    }
  }

  Future<void> _clearAllLogs() async {
    try {
      await _logsRef?.remove();

      if (mounted) {
        setState(() {
          _botLogs.clear();
        });
      }
    } catch (e) {
      debugPrint('Clear LOG error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentScanImage = _images[_imageIndex];
    final bool isServerActive = isConnected && isRunning;

    return Material(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: _isExpanded
              ? Container(
                  width: 340,
                  height: 450,
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _gold.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ส่วนหัวและปุ่มควบคุม
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'GOLD PRO ROBOT',
                              style: TextStyle(
                                color: _gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _clearAllLogs,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.7),
                                      border: Border.all(color: _gold.withOpacity(0.6)),
                                    ),
                                    child: const Icon(
                                      Icons.delete_sweep,
                                      color: _gold,
                                      size: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _setExpanded(false),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.7),
                                      border: Border.all(color: _gold.withOpacity(0.6)),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0x33FFD700), height: 1),

                      // ส่วนแสดงภาพสแกนเนอร์ (Scanner Banner + เปลี่ยนรูปภาพอัตโนมัติ)
                      Container(
                        height: 140,
                        width: double.infinity,
                        color: Colors.black,
                        child: AnimatedBuilder(
                          animation: _scannerAnimation,
                          builder: (context, child) {
                            final double scanValue = _scannerAnimation.value * 140;

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 800),
                                  child: Image.asset(
                                    currentScanImage,
                                    key: ValueKey<String>(currentScanImage),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 140,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.black,
                                        child: const Center(
                                          child: Icon(Icons.smart_toy, color: _gold, size: 40),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // เส้นสแกนเนอร์สีทองเลื่อนผ่าน
                                Positioned(
                                  top: scanValue.clamp(0.0, 137.0),
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: _gold,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _gold,
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

                      // สถานะเซิร์ฟเวอร์ย่อย
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: kDarkCard,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isServerActive ? _green : _red,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isServerActive ? _green : _red).withOpacity(0.8),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isServerActive ? 'EA SERVER ONLINE & RUNNING' : 'SERVER DISCONNECTED',
                              style: TextStyle(
                                color: isServerActive ? _green : _red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(color: Color(0x33FFD700), height: 1),

                      // ส่วนแสดงรายการ Logs ด้านล่าง
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black.withOpacity(0.4),
                          child: _botLogs.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No logs available',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.zero,
                                  itemCount: _botLogs.length,
                                  itemBuilder: (context, index) {
                                    final item = _botLogs[index];
                                    final String message =
                                        (item['message'] ?? '').toString();

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: TypewriterText(
                                        text: '> $message',
                                        duration: const Duration(milliseconds: 30),
                                        style: const TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _setExpanded(true),
                  onLongPress: _hideOverlay,
                  onPanUpdate: (details) {
                    _moveBalloon(details);
                  },
                  child: AnimatedBuilder(
                    animation: _overlayBounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          _overlayBounceAnimation.value,
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _background,
                        border: Border.all(
                          color: _gold,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isConnected ? _green : _red)
                                .withOpacity(0.8),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/7.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return const Icon(
                                    Icons.smart_toy,
                                    color: _gold,
                                    size: 34,
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 17,
                              height: 17,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConnected ? _green : _red,
                                border: Border.all(
                                  color: _background,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isConnected ? _green : _red)
                                        .withOpacity(0.85),
                                    blurRadius: 7,
                                    spreadRadius: 1,
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _scannerController.dispose();
    _scrollController.dispose();
    _overlayBounceController.dispose();
    _logsSubscription?.cancel();
    _connectionSubscription?.cancel();
    _overlaySubscription?.cancel();
    super.dispose();
  }
}





// ==========================================
// #2 โหมดเมนหลักของแอป
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
// #4 MT5LoginWrapper
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
                        'ROBOT ALGO TRADING',
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
// #5 PinAuthWrapper
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
                      'ROBOT ALGO TRADING',
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
                            color: filled ? kGoldPrimary : Colors.transparent,
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
// #6 MainNavigationScreen (ฉบับอัปเดตซิงค์ Logs ไปยัง Overlay)
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

  bool isRunning = false;
  bool isConnected = false;
  int unreadAlertsCount = 0;

  bool _isLaunchingOverlay = false;

  DatabaseReference? _dbRef;
  DatabaseReference? _alertsRef;
  DatabaseReference? _logsRef;

  List<Map<String, dynamic>> _botLogs = [];

  Offset _robotBubbleOffset = const Offset(20, 120);
  bool _isRobotBubblePressed = false;

  late final AnimationController _bounceController =
      AnimationController(
    duration: const Duration(milliseconds: 1200),
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _bounceAnimation =
      Tween<double>(
    begin: 0,
    end: 5,
  ).animate(
    CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ),
  );

  @override
  void initState() {
    super.initState();

    _loadSavedLogin().then((_) {
      if (!mounted) return;

      _listenToActiveAccount();
      _listenToAlertsCount();
      _initFirebaseAndListen();
      _listenToConnectionStatus();
      _listenToLogs(); // เพิ่มการฟังข้อมูล Logs จาก Firebase
    });

    // เพิ่มตัวรับคำสั่งขอ Snapshot จากหน้าต่าง Overlay ภายนอก
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event != null && event is Map && event['command'] == 'request_snapshot') {
        _shareSnapshotToOverlay();
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
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
          });
          
          // ส่งสถานะอัปเดตไปที่ Overlay ด้วย
          _shareSnapshotToOverlay();
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
        final connected = event.snapshot.value as bool? ?? false;

        if (mounted) {
          setState(() {
            isConnected = connected;
          });
          
          _shareSnapshotToOverlay();
        }
      });
    } catch (e) {
      debugPrint("Connection listen error: $e");
    }
  }

  // ฟังก์ชันดึง Logs จาก Firebase และซิงค์ออกไปยัง Overlay ภายนอก
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

        // ส่งข้อมูล Logs ล่าสุดไปแสดงที่หน้าต่าง Overlay ทันทีที่มีการเปลี่ยนแปลง
        _shareSnapshotToOverlay();
      });
    } catch (e) {
      debugPrint("Logs listen error: $e");
    }
  }

  // ส่งข้อมูล Snapshot ปัจจุบันไปให้ Overlay
  void _shareSnapshotToOverlay() {
    try {
      FlutterOverlayWindow.shareData({
        'type': 'snapshot',
        'login': currentLogin,
        'currentLogin': currentLogin,
        'isRunning': isRunning,
        'isConnected': isConnected,
        'connected': isConnected,
        'logs': _botLogs,
      });
    } catch (e) {
      debugPrint('Share snapshot error: $e');
    }
  }

  Future<void> _launchExternalOverlay() async {
    if (_isLaunchingOverlay || !mounted) return;

    _isLaunchingOverlay = true;

    try {
      bool granted =
          await FlutterOverlayWindow.isPermissionGranted() ?? false;

      if (!granted) {
        final result =
            await FlutterOverlayWindow.requestPermission();

        if (result != true) {
          debugPrint('Overlay permission not granted');
          return;
        }
      }

      if (!mounted) return;

      await FlutterOverlayWindow.showOverlay(
        height: 620,
        width: 380,
        enableDrag: true,
        overlayTitle: 'GOLD PRO',
        overlayContent: 'LOGS',
        alignment: OverlayAlignment.topRight,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none,
      );

      await Future.delayed(
        const Duration(milliseconds: 1000),
      );

      if (!mounted) return;

      // ส่งข้อมูล Snapshot ทันทีที่เปิด Overlay สำเร็จ
      _shareSnapshotToOverlay();

      await FlutterOverlayWindow.shareData({
        'type': 'command',
        'command': 'request_snapshot',
      });
    } catch (e, stackTrace) {
      debugPrint('Error launching external overlay: $e');
      debugPrint('$stackTrace');
    } finally {
      _isLaunchingOverlay = false;
    }
  }

  Future<bool> _handleBackButton() async {
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

    final screenSize = MediaQuery.of(context).size;

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
            Positioned(
              left: _robotBubbleOffset.dx,
              top: _robotBubbleOffset.dy,
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      _bounceAnimation.value,
                    ),
                    child: child,
                  );
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    setState(() {
                      _robotBubbleOffset = Offset(
                        (_robotBubbleOffset.dx +
                                details.delta.dx)
                            .clamp(
                              0.0,
                              screenSize.width - 60,
                            ),
                        (_robotBubbleOffset.dy +
                                details.delta.dy)
                            .clamp(
                              0.0,
                              screenSize.height - 60,
                            ),
                      );
                    });
                  },
                  onTapDown: (_) {
                    setState(() {
                      _isRobotBubblePressed = true;
                    });
                  },
                  onTapCancel: () {
                    setState(() {
                      _isRobotBubblePressed = false;
                    });
                  },
                  onTap: () {
                    setState(() {
                      _isRobotBubblePressed = false;
                    });

                    _launchExternalOverlay();
                  },
                  child: AnimatedScale(
                    scale: _isRobotBubblePressed ? 0.85 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: _buildRobotBubbleWidget(),
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
                  return const Icon(
                    Icons.smart_toy,
                    color: kGoldPrimary,
                  );
                },
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 12,
              height: 12,
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
            color: isSelected
                ? kGoldPrimary
                : Colors.transparent,
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
                  color: isSelected
                      ? kGoldPrimary
                      : Colors.white70,
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
                color: isSelected
                    ? kGoldPrimary
                    : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ==========================================
// #7 HomeScreen
// ==========================================

class HomeScreen extends StatefulWidget {
  final String accountLogin;
  const HomeScreen({super.key, required this.accountLogin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool isRunning = false;
  DatabaseReference? _dbRef;
  
  double balance = 0.0;
  double equity = 0.0;
  double profit = 0.0;
  String symbol = "XAUUSD";
  String timeframe = "M1";

  int cycleWins = 0;
  int cycleLosses = 0;
  double cycleWinRate = 0.0;

  List<Map<dynamic, dynamic>> activeOrders = [];
  DatabaseReference? _ordersRef;

  List<Map<dynamic, dynamic>> _historyTrades = [];
  DatabaseReference? _historyRef;

  bool isConnected = false;

  int _currentImageIndex = 0;
  Timer? _imageTimer;

  late final AnimationController _titleGlowController = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  )..repeat(reverse: true);

  double realTimeBid = 0.0;
  double realTimeAsk = 0.0;

  bool _isChartModalOpen = false;

  @override
  void initState() {
    super.initState();
    _initFirebaseAndListen(widget.accountLogin);
    _listenToOrdersForDialog(widget.accountLogin);
    _listenToConnectionStatus();
    _listenToHistoryForStats(widget.accountLogin);

    _imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex == 0) ? 1 : 0;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountLogin != widget.accountLogin) {
      _initFirebaseAndListen(widget.accountLogin);
      _listenToOrdersForDialog(widget.accountLogin);
      _listenToHistoryForStats(widget.accountLogin);
    }
  }

  @override
  void dispose() {
    _titleGlowController.dispose();
    _imageTimer?.cancel();
    super.dispose();
  }

  void _listenToConnectionStatus() {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      database.ref('.info/connected').onValue.listen((event) {
        final connected = event.snapshot.value as bool? ?? false;
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

  void _initFirebaseAndListen(String login) {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      _dbRef = database.ref('accounts/$login/status');
      _dbRef?.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && mounted) {
          setState(() {
            isRunning = data['is_running'] ?? false;
            balance = (data['balance'] ?? 0.0).toDouble();
            equity = (data['equity'] ?? 0.0).toDouble();
            profit = (data['profit'] ?? 0.0).toDouble();
            symbol = data['symbol']?.toString() ?? 'XAUUSD';
            timeframe = data['timeframe']?.toString() ?? 'M1';
            
            if (data['bid'] != null) {
              realTimeBid = double.tryParse(data['bid'].toString()) ?? realTimeBid;
            }
            if (data['ask'] != null) {
              realTimeAsk = double.tryParse(data['ask'].toString()) ?? realTimeAsk;
            }

            cycleWins = int.tryParse(data['cycle_wins']?.toString() ?? '0') ?? 0;
            cycleLosses = int.tryParse(data['cycle_losses']?.toString() ?? '0') ?? 0;
            cycleWinRate = (data['cycle_win_rate'] ?? 0.0).toDouble();
          });
        }
      });
    } catch (e) {
      debugPrint("Database listen error: $e");
    }
  }

  void _listenToHistoryForStats(String login) {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      _historyRef = database.ref('accounts/$login/history');
      _historyRef?.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value;
        if (mounted) {
          List<Map<dynamic, dynamic>> tempHistory = [];
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                tempHistory.add(Map<dynamic, dynamic>.from(value));
              } else if (value is List) {
                for (var item in value) {
                  if (item is Map) {
                    tempHistory.add(Map<dynamic, dynamic>.from(item));
                  }
                }
              }
            });
          } else if (data is List) {
            for (var e in data) {
              if (e is Map) {
                tempHistory.add(Map<dynamic, dynamic>.from(e));
              }
            }
          }
          setState(() {
            _historyTrades = tempHistory;
          });
        }
      });
    } catch (e) {
      debugPrint("History stats listen error: $e");
    }
  }

  void _listenToOrdersForDialog(String login) {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      _ordersRef = database.ref('accounts/$login/orders');
      _ordersRef?.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value;
        if (mounted) {
          List<Map<dynamic, dynamic>> newOrders = [];
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                newOrders.add(Map<dynamic, dynamic>.from(value));
              }
            });
          } else if (data is List) {
            for (var e in data) {
              if (e is Map) {
                newOrders.add(Map<dynamic, dynamic>.from(e));
              }
            }
          }
          setState(() {
            activeOrders = newOrders;
          });
        }
      });
    } catch (e) {
      debugPrint("Orders listen error: $e");
    }
  }

  void _toggleBotStatus(bool status) {
    try {
      _dbRef?.update({
        'is_running': status,
        'command_timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint("Toggle bot error: $e");
    }
  }

  void _closeAllOrders() {
    try {
      _dbRef?.update({
        'close_all': true,
        'command_timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent Close All Command to EA!'), backgroundColor: kDarkCard),
      );
    } catch (e) {
      debugPrint("Close all error: $e");
    }
  }

  void _showTradingCalendarDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return TradingCalendarDialog(historyTrades: _historyTrades);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color startStopColor = isRunning ? kGreenNeon : kRedNeon;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kGoldPrimary, width: 2.0),
                          boxShadow: [
                            BoxShadow(
                              color: kGoldPrimary.withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 800),
                            child: Opacity(
                              key: ValueKey<int>(_currentImageIndex),
                              opacity: 0.9,
                              child: Image.asset(
                                'assets/images/8.png',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.black,
                                    child: const Center(
                                      child: Icon(Icons.smart_toy, color: kGoldPrimary, size: 80),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _titleGlowController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_titleGlowController.value * 0.05),
                          child: Text(
                            'GOLD PRO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: kGoldPrimary,
                              letterSpacing: 3.0,
                              shadows: [
                                BoxShadow(
                                  color: kGoldPrimary.withOpacity(0.4 + (_titleGlowController.value * 0.5)),
                                  blurRadius: 10 + (_titleGlowController.value * 10),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ROBOT ALGO TRADING',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kGoldPrimary, width: 1.2),
                        color: Colors.black.withOpacity(0.75),
                      ),
                      child: const Text(
                        'Powered By Algohost',
                        style: TextStyle(color: kGoldPrimary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircularButton(
                          label: 'CLOSE',
                          icon: Icons.delete_outline,
                          borderColor: kGoldPrimary,
                          onPressed: _closeAllOrders,
                        ),
                        const SizedBox(width: 25),
                        _buildCircularButton(
                          label: isRunning ? 'STOP' : 'START',
                          icon: isRunning ? Icons.stop : Icons.play_arrow,
                          borderColor: startStopColor,
                          glowColor: startStopColor,
                          iconColor: startStopColor,
                          labelColor: startStopColor,
                          onPressed: () => _toggleBotStatus(!isRunning),
                          isLarge: true,
                        ),
                        const SizedBox(width: 25),
                        _buildCircularButton(
                          label: 'STATS', 
                          icon: Icons.bar_chart,
                          borderColor: kGoldPrimary,
                          onPressed: () {
                            setState(() {
                              _isChartModalOpen = true;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildBidAskBoxContent(context),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _showTradingCalendarDialog(context),
                            child: Container(
                              width: 65,
                              height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: kGoldPrimary, width: 1.8),
                                boxShadow: [
                                  BoxShadow(
                                    color: kGoldPrimary.withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.5),
                                child: Image.asset(
                                  'assets/images/8.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: kDarkCard,
                                      child: const Center(
                                        child: Icon(Icons.smart_toy, color: kGoldPrimary, size: 20),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'TRADING JOURNAL',
                            style: TextStyle(
                              color: kGoldPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_isChartModalOpen)
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isChartModalOpen = false;
                    });
                  },
                  child: Container(color: Colors.black54),
                ),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.92,
                    height: MediaQuery.of(context).size.height * 0.52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kGoldPrimary, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                      color: kDarkCard.withOpacity(0.9),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.dashboard_outlined, color: kGoldPrimary, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'DASHBOARD STATS',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: kGoldPrimary,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _isChartModalOpen = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: kGoldPrimary, height: 1, thickness: 1.5),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: _buildDashboardStatsContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardStatsContent() {
    double totalProfitLoss = 0.0;
    double maxProfit = 0.0;
    double maxLoss = 0.0;

    for (var trade in _historyTrades) {
      double p = double.tryParse(trade['profit']?.toString() ?? '0.0') ?? 0.0;
      totalProfitLoss += p;
      if (p > 0) {
        if (p > maxProfit) maxProfit = p;
      } else if (p < 0) {
        if (p < maxLoss) maxLoss = p;
      }
    }

    int displayWins = cycleWins;
    int displayLosses = cycleLosses;
    int totalCycles = displayWins + displayLosses;
    double displayWinRate = totalCycles > 0 ? (displayWins / totalCycles) * 100 : cycleWinRate;
    double lossRate = 100.0 - displayWinRate;

    double peak = balance > 0 ? balance : 1000.0;
    double maxDDAmount = 0.0;
    for (var trade in _historyTrades) {
      double p = double.tryParse(trade['profit']?.toString() ?? '0.0') ?? 0.0;
      peak += p;
      double currentDD = peak > 0 ? (maxLoss.abs() / peak) * 100 : 0.0;
      if (currentDD > maxDDAmount) {
        maxDDAmount = currentDD;
      }
    }
    if (maxDDAmount == 0 && displayLosses > 0) {
      maxDDAmount = (maxLoss.abs() / (balance > 0 ? balance : 1000.0)) * 100;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'WIN RATE',
                  value: '${displayWinRate.toStringAsFixed(1)}%',
                  subText: '$displayWins Win / $displayLosses Loss',
                  color: kGreenNeon,
                  icon: Icons.pie_chart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'MAX DRAWDOWN',
                  value: '${maxDDAmount.toStringAsFixed(2)}%',
                  subText: 'Max Loss: \$${maxLoss.toStringAsFixed(2)}',
                  color: kRedNeon,
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'TOTAL CYCLES',
                  value: '$totalCycles',
                  subText: '',
                  color: kGoldPrimary,
                  icon: Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'NET PROFIT',
                  value: '${totalProfitLoss >= 0 ? "+" : ""}\$${totalProfitLoss.toStringAsFixed(2)}',
                  subText: 'Balance: \$${balance.toStringAsFixed(2)}',
                  color: totalProfitLoss >= 0 ? kGreenNeon : kRedNeon,
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kDarkCard.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGoldPrimary, width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'WIN RATE & CYCLES',
                  style: TextStyle(
                    color: kGoldPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kDarkBg.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kGoldPrimary.withOpacity(0.5), width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('WIN RATE', style: TextStyle(color: kGreenNeon, fontSize: 9, fontWeight: FontWeight.bold)),
                              Text('${displayWinRate.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('LOSS RATE', style: TextStyle(color: kRedNeon, fontSize: 9, fontWeight: FontWeight.bold)),
                              Text('${lossRate.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 10,
                          width: double.infinity,
                          color: kRedNeon.withOpacity(0.4),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (displayWinRate / 100).clamp(0.0, 1.0),
                            child: Container(color: kGreenNeon),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required String subText, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: kDarkBg.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              value, 
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 1),
          Text(subText, style: const TextStyle(color: Colors.white54, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildBidAskBoxContent(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double boxWidth = screenWidth - 32;
    double spreadVal = (realTimeAsk > 0 && realTimeBid > 0) ? (realTimeAsk - realTimeBid) * 100 : 500.0;

    return Container(
      width: boxWidth,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGoldPrimary, width: 1.5),
        color: kDarkCard.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: kGoldPrimary.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kDarkBg.withOpacity(0.75),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.show_chart, color: kGoldPrimary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      symbol,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kGoldPrimary, width: 1),
                  ),
                  child: Text(
                    'Spread: ${spreadVal.toStringAsFixed(1)}',
                    style: const TextStyle(color: kGoldPrimary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            const Divider(color: kGoldPrimary, height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('BID', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    const SizedBox(height: 6),
                    Text(
                      realTimeBid > 0 ? realTimeBid.toStringAsFixed(2) : '0.00',
                      style: const TextStyle(color: kRedNeon, fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Container(height: 35, width: 1, color: kGoldPrimary.withOpacity(0.3)),
                Column(
                  children: [
                    const Text('ASK', style: TextStyle(color: kGoldPrimary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    const SizedBox(height: 6),
                    Text(
                      realTimeAsk > 0 ? realTimeAsk.toStringAsFixed(2) : '0.00',
                      style: const TextStyle(color: kGreenNeon, fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required String label,
    required IconData icon,
    required Color borderColor,
    Color? glowColor,
    Color? iconColor,
    Color? labelColor,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    double size = isLarge ? 82 : 70;
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kDarkCard.withOpacity(0.85),
              border: Border.all(color: borderColor, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: (glowColor ?? borderColor).withOpacity(0.6),
                  blurRadius: isLarge ? 16 : 10,
                  spreadRadius: isLarge ? 3 : 1,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor ?? kGoldPrimary, size: isLarge ? 34 : 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: labelColor ?? kGoldPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// #8 TradingCalendarDialog
// ==========================================

class TradingCalendarDialog extends StatefulWidget {
  final List<Map<dynamic, dynamic>> historyTrades;
  const TradingCalendarDialog({Key? key, required this.historyTrades}) : super(key: key);

  @override
  State<TradingCalendarDialog> createState() => _TradingCalendarDialogState();
}

class _TradingCalendarDialogState extends State<TradingCalendarDialog> {
  int selectedTimeframe = 1; 
  DateTime currentDate = DateTime.now();
  double monthlyGoal = 2000.0;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      monthlyGoal = prefs.getDouble('saved_monthly_goal') ?? 2000.0;
    });
  }

  Future<void> _saveGoal(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saved_monthly_goal', value);
    setState(() {
      monthlyGoal = value;
    });
  }

  void _showEditGoalDialog() {
    TextEditingController goalController = TextEditingController(
      text: monthlyGoal > 0 ? monthlyGoal.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
        title: const Text(
          'ตั้งเป้าหมายกำไร (\$)',
          style: TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: goalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: 'กรอกจำนวนเงิน (\$)',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E676), width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            onPressed: () {
              double? newGoal = double.tryParse(goalController.text.trim());
              if (newGoal != null && newGoal >= 0) {
                _saveGoal(newGoal);
              }
              Navigator.pop(ctx);
            },
            child: const Text('บันทึก', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  DateTime? _parseTradeDate(dynamic rawTime) {
    if (rawTime == null) return null;
    if (rawTime is int) {
      int ms = rawTime < 10000000000 ? rawTime * 1000 : rawTime;
      return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    }
    if (rawTime is String) {
      String clean = rawTime.trim();
      if (clean.isEmpty) return null;

      DateTime? parsed = DateTime.tryParse(clean);
      if (parsed != null) return parsed.toLocal();

      try {
        List<String> dateTimeParts = clean.split(' ');
        List<String> dateParts = dateTimeParts[0].replaceAll('/', '.').replaceAll('-', '.').split('.');

        if (dateParts.length == 3) {
          int d = int.parse(dateParts[0]);
          int m = int.parse(dateParts[1]);
          int y = int.parse(dateParts[2]);
          if (y < 100) y += 2000;

          int hour = 0, minute = 0, second = 0;
          if (dateTimeParts.length > 1) {
            List<String> timeParts = dateTimeParts[1].split(':');
            if (timeParts.length >= 2) {
              hour = int.tryParse(timeParts[0]) ?? 0;
              minute = int.tryParse(timeParts[1]) ?? 0;
              if (timeParts.length >= 3) {
                second = int.tryParse(timeParts[2]) ?? 0;
              }
            }
          }
          return DateTime(y, m, d, hour, minute, second);
        }
      } catch (_) {}
    }
    return null;
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Map<String, double> _calculateData() {
    Map<String, double> pnlMap = {};

    for (var trade in widget.historyTrades) {
      double profit = double.tryParse(trade['profit']?.toString() ?? '0.0') ?? 0.0;
      DateTime? tradeDate = _parseTradeDate(
        trade['close_time'] ?? trade['timestamp'] ?? trade['time'] ?? trade['open_time']
      );

      if (tradeDate == null) continue;

      if (selectedTimeframe == 0) {
        DateTime startOfWeek = _getStartOfWeek(currentDate);
        DateTime endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        if (tradeDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
            tradeDate.isBefore(endOfWeek)) {
          String key = '${tradeDate.day}';
          pnlMap[key] = (pnlMap[key] ?? 0.0) + profit;
        }
      } else if (selectedTimeframe == 1) {
        if (tradeDate.month == currentDate.month && tradeDate.year == currentDate.year) {
          String key = '${tradeDate.day}';
          pnlMap[key] = (pnlMap[key] ?? 0.0) + profit;
        }
      } else if (selectedTimeframe == 2) {
        if (tradeDate.year == currentDate.year) {
          String key = '${tradeDate.month}';
          pnlMap[key] = (pnlMap[key] ?? 0.0) + profit;
        }
      }
    }
    return pnlMap;
  }

  void _navigateTime(bool isNext) {
    setState(() {
      if (selectedTimeframe == 0) {
        currentDate = isNext 
            ? currentDate.add(const Duration(days: 7)) 
            : currentDate.subtract(const Duration(days: 7));
      } else if (selectedTimeframe == 1) {
        currentDate = DateTime(currentDate.year, isNext ? currentDate.month + 1 : currentDate.month - 1);
      } else if (selectedTimeframe == 2) {
        currentDate = DateTime(isNext ? currentDate.year + 1 : currentDate.year - 1);
      }
    });
  }

  String _getHeaderTitle() {
    if (selectedTimeframe == 0) {
      DateTime start = _getStartOfWeek(currentDate);
      DateTime end = start.add(const Duration(days: 6));
      return '${start.day} ${_getMonthName(start.month, true)} - ${end.day} ${_getMonthName(end.month, true)} ${currentDate.year}';
    } else if (selectedTimeframe == 1) {
      return '${_getMonthName(currentDate.month, false)} ${currentDate.year}';
    } else {
      return 'YEAR ${currentDate.year}';
    }
  }

  String _getMonthName(int month, bool isShort) {
    const shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const fullMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return isShort ? shortMonths[month - 1] : fullMonths[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> dataMap = _calculateData();
    double totalPnL = dataMap.values.fold(0.0, (sum, val) => sum + val);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 12, spreadRadius: 2),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, color: Color(0xFFFFD700), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'TRADING JOURNAL',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFFFD700), thickness: 0.5),
              const SizedBox(height: 10),

              _buildTimeframeSelector(),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                    onPressed: () => _navigateTime(false),
                  ),
                  Text(
                    _getHeaderTitle(),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                    onPressed: () => _navigateTime(true),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      'Total P&L',
                      '${totalPnL >= 0 ? "+" : ""}\$${totalPnL.toStringAsFixed(2)}',
                      totalPnL >= 0 ? const Color(0xFF00E676) : const Color(0xFFFF1744),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildGoalCard(
                      'Goal Target',
                      totalPnL,
                      monthlyGoal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (selectedTimeframe != 2) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                      .map((day) => Expanded(
                            child: Center(
                              child: Text(
                                day, 
                                style: TextStyle(
                                  color: (day == 'SAT' || day == 'SUN') ? const Color(0xFFFFD700) : Colors.grey, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],

              _buildDynamicGrid(dataMap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    List<String> options = ['Week', 'Month', 'Year'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          bool isSelected = selectedTimeframe == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTimeframe = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2EA043) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    options[index],
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String title, double currentProfit, double targetGoal) {
    double progress = (targetGoal > 0) ? (currentProfit / targetGoal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              GestureDetector(
                onTap: _showEditGoalDialog,
                child: const Icon(Icons.edit_note, color: Colors.cyan, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            color: const Color(0xFF00E676),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentProfit >= 0 ? "+" : ""}\$${currentProfit.toStringAsFixed(1)}',
                style: const TextStyle(color: Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.bold),
              ),
              Text(
                targetGoal > 0 ? '\$${targetGoal.toStringAsFixed(0)}' : 'Set goal',
                style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicGrid(Map<String, double> dataMap) {
    if (selectedTimeframe == 0) {
      DateTime start = _getStartOfWeek(currentDate);
      List<DateTime> weekDays = List.generate(7, (i) => start.add(Duration(days: i)));

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.8,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 7,
        itemBuilder: (context, index) {
          DateTime dayDate = weekDays[index];
          double? pnl = dataMap['${dayDate.day}'];
          return _buildGridCell(label: '${dayDate.day}', pnl: pnl);
        },
      );
    } 
    else if (selectedTimeframe == 1) {
      DateTime firstDayOfMonth = DateTime(currentDate.year, currentDate.month, 1);
      int daysInMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day;
      int firstWeekday = firstDayOfMonth.weekday; 

      List<int?> gridItems = [];
      for (int i = 1; i < firstWeekday; i++) {
        gridItems.add(null);
      }

      for (int day = 1; day <= daysInMonth; day++) {
        gridItems.add(day);
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.8,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: gridItems.length,
        itemBuilder: (context, index) {
          int? day = gridItems[index];
          if (day == null) {
            return const SizedBox.shrink();
          }
          double? pnl = dataMap['$day'];
          return _buildGridCell(label: '$day', pnl: pnl);
        },
      );
    } 
    else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          int monthNum = index + 1;
          double? pnl = dataMap['$monthNum'];
          String monthName = _getMonthName(monthNum, true);
          return _buildGridCell(label: monthName, pnl: pnl, isYearMode: true);
        },
      );
    }
  }

  Widget _buildGridCell({required String label, double? pnl, bool isYearMode = false}) {
    Color cardColor = const Color(0xFF161B22);
    if (pnl != null) {
      if (pnl > 0) {
        cardColor = const Color(0xFF137333);
      } else if (pnl < 0) {
        cardColor = const Color(0xFFA50E0E);
      }
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label, 
            style: TextStyle(
              color: Colors.white, 
              fontSize: isYearMode ? 12 : 9, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 2),
          if (pnl != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${pnl > 0 ? "+" : ""}\$${pnl.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            )
          else
            const Text('-', style: TextStyle(color: Colors.grey, fontSize: 9)),
        ],
      ),
    );
  }
}

// ==========================================
// #9 OrdersScreen
// ==========================================

class OrdersScreen extends StatefulWidget {
  final String accountLogin;
  const OrdersScreen({super.key, required this.accountLogin});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<dynamic, dynamic>> activeOrders = [];
  DatabaseReference? _ordersRef;
  DatabaseReference? _dbRef;
  String activeSymbol = 'XAUUSD';
  String activeTimeframe = 'M1';
  String accountServer = 'ICMarketsSC-Demo';

  double balance = 4989877.98;
  double equity = 4989877.86;
  double margin = 2.06;
  double freeMargin = 4989875.80;
  double profitLoss = -0.12;

  @override
  void initState() {
    super.initState();
    _listenToOrders(widget.accountLogin);
    _listenToStatusForSymbol(widget.accountLogin);
  }

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountLogin != widget.accountLogin) {
      _listenToOrders(widget.accountLogin);
      _listenToStatusForSymbol(widget.accountLogin);
    }
  }

  void _listenToStatusForSymbol(String login) {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      _dbRef = database.ref('accounts/$login/status');
      _dbRef?.onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && mounted) {
          setState(() {
            activeSymbol = data['symbol']?.toString() ?? 'XAUUSD';
            activeTimeframe = data['timeframe']?.toString() ?? 'M1';
            accountServer = data['server']?.toString() ?? 'ICMarketsSC-Demo';
            
            balance = (data['balance'] ?? 4989877.98).toDouble();
            equity = (data['equity'] ?? 4989877.86).toDouble();
            margin = (data['margin'] ?? 2.06).toDouble();
            freeMargin = (data['free_margin'] ?? 4989875.80).toDouble();
            profitLoss = (data['profit'] ?? -0.12).toDouble();
          });
        }
      });
    } catch (e) {
      debugPrint("Status symbol listen error: $e");
    }
  }

  void _listenToOrders(String login) {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      _ordersRef = database.ref('accounts/$login/orders');
      _ordersRef?.onValue.listen((event) {
        final data = event.snapshot.value;
        if (mounted) {
          _parseOrdersData(data);
        }
      });
    } catch (e) {
      debugPrint("Orders listen error: $e");
    }
  }

  void _parseOrdersData(Object? data) {
    List<Map<dynamic, dynamic>> newOrders = [];
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map) {
          newOrders.add(Map<dynamic, dynamic>.from(value));
        }
      });
    } else if (data is List) {
      for (var e in data) {
        if (e is Map) {
          newOrders.add(Map<dynamic, dynamic>.from(e));
        }
      }
    }
    setState(() {
      activeOrders = newOrders;
    });
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: kDarkBg.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGoldPrimary.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kGoldAccent, size: 14),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: kGoldPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalOrdersProfit = activeOrders.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item['profit']?.toString() ?? '0.0') ?? 0.0);
    });
    bool isTotalProfit = totalOrdersProfit >= 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Orders & Portfolio', style: TextStyle(fontFamily: 'monospace', color: kGoldPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: kDarkBg.withOpacity(0.8),
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/0.png',
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
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kDarkCard.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: kGoldPrimary,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kGoldPrimary.withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance, color: kGoldPrimary, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'TRADING ACCOUNT INFO',
                                style: TextStyle(color: kGoldPrimary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kGoldPrimary, width: 1),
                            ),
                            child: Text(
                              activeSymbol,
                              style: const TextStyle(color: kGoldPrimary, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Account Login', style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                              const SizedBox(height: 2),
                              Text(
                                widget.accountLogin,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Server', style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                              const SizedBox(height: 2),
                              Text(
                                accountServer,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: kGoldPrimary.withOpacity(0.8),
                      width: 1.5,
                    ),
                    color: kDarkCard.withOpacity(0.85),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildMetricCard('Balance', '\$${balance.toStringAsFixed(2)}', Icons.account_balance_wallet)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildMetricCard('Equity', '\$${equity.toStringAsFixed(2)}', Icons.show_chart)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildMetricCard('Margin', '\$${margin.toStringAsFixed(2)}', Icons.lock_outline)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildMetricCard('Free Margin', '\$${freeMargin.toStringAsFixed(2)}', Icons.lock_open)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kDarkBg.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isTotalProfit ? kGreenNeon : kRedNeon,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL OPEN PROFIT',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                              ),
                              Text(
                                '${isTotalProfit ? "+" : ""}\$${totalOrdersProfit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isTotalProfit ? kGreenNeon : kRedNeon,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                            child: Text(
                              'ACTIVE ORDERS (${activeOrders.length})',
                              style: const TextStyle(color: kGoldPrimary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1, fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                        activeOrders.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: Center(
                                  child: Text('No active orders currently', style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'monospace')),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: activeOrders.length,
                                itemBuilder: (context, index) {
                                  final order = activeOrders[index];
                                  final String type = order['type']?.toString() ?? 'BUY';
                                  final double lot = double.tryParse(order['lot']?.toString() ?? '0.01') ?? 0.01;
                                  final double profit = double.tryParse(order['profit']?.toString() ?? '0.0') ?? 0.0;
                                  final double priceOpen = double.tryParse(order['price']?.toString() ?? '0.0') ?? 0.0;
                                  final String symbol = order['symbol']?.toString() ?? activeSymbol;
                                  
                                  bool isBuy = type.toUpperCase().contains('BUY');
                                  bool orderProfit = profit >= 0;

                                  Color typeColor = isBuy ? kGreenNeon : kRedNeon;
                                  Color profitColor = orderProfit ? kGreenNeon : kRedNeon;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: kDarkBg.withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: typeColor.withOpacity(0.6),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: typeColor.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: typeColor, width: 1),
                                              ),
                                              child: Text(
                                                type,
                                                style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                                                const SizedBox(height: 2),
                                                Text('Lot: $lot | Open: ${priceOpen.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace')),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${orderProfit ? "+" : ""}\$${profit.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: profitColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// #10 HistoryScreen
// ==========================================

class HistoryScreen extends StatefulWidget {
  final String accountLogin;
  const HistoryScreen({super.key, required this.accountLogin});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<dynamic, dynamic>> allTradeHistory = [];
  DatabaseReference? _historyRef;
  
  String selectedFilter = 'วันนี้';
  final List<String> filterOptions = ['วันนี้', 'สัปดาห์ล่าสุด', 'เดือนล่าสุด', '3 เดือนล่าสุด', 'ทั้งหมด'];

  @override
  void initState() {
    super.initState();
    _listenToHistory(widget.accountLogin);
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountLogin != widget.accountLogin) {
      _listenToHistory(widget.accountLogin);
    }
  }

  void _listenToHistory(String login) {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      _historyRef = database.ref('accounts/$login/history');

      _historyRef?.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value;
        if (mounted) {
          setState(() {
            allTradeHistory.clear();
            if (data is Map) {
              data.forEach((key, value) {
                if (value is Map) {
                  allTradeHistory.add(Map<dynamic, dynamic>.from(value));
                } else if (value is List) {
                  for (var item in value) {
                    if (item is Map) {
                      allTradeHistory.add(Map<dynamic, dynamic>.from(item));
                    }
                  }
                }
              });
            } else if (data is List) {
              for (var e in data) {
                if (e is Map) {
                  allTradeHistory.add(Map<dynamic, dynamic>.from(e));
                }
              }
            }

            allTradeHistory.sort((a, b) {
              String timeA = a['close_time']?.toString() ?? a['time']?.toString() ?? '';
              String timeB = b['close_time']?.toString() ?? b['time']?.toString() ?? '';
              return timeB.compareTo(timeA);
            });
          });
        }
      });
    } catch (e) {
      debugPrint("History listen error: $e");
    }
  }

  List<Map<dynamic, dynamic>> _getFilteredHistory() {
    if (selectedFilter == 'ทั้งหมด') return allTradeHistory;

    DateTime now = DateTime.now();
    return allTradeHistory.where((trade) {
      String timeStr = trade['close_time']?.toString() ?? trade['time']?.toString() ?? '';
      if (timeStr.isEmpty) return false;

      String formattedTime = timeStr.replaceAll('.', '-').replaceAll('/', '-');
      DateTime? tradeDate;

      try {
        List<String> parts = formattedTime.split(' ')[0].split('-');
        if (parts.length == 3) {
          int? p1 = int.tryParse(parts[0]);
          int? p2 = int.tryParse(parts[1]);
          int? p3 = int.tryParse(parts[2]);

          if (p1 != null && p2 != null && p3 != null) {
            if (p1 > 1000) {
              tradeDate = DateTime(p1, p2, p3);
            } else {
              int year = p3;
              if (year < 100) year += 2000;
              tradeDate = DateTime(year, p2, p1);
            }
          }
        }
      } catch (e) {
        tradeDate = null;
      }

      tradeDate ??= DateTime.tryParse(formattedTime);
      if (tradeDate == null && formattedTime.length >= 10) {
        tradeDate = DateTime.tryParse(formattedTime.substring(0, 10));
      }

      if (tradeDate == null) return false;

      if (selectedFilter == 'วันนี้') {
        return tradeDate.year == now.year && tradeDate.month == now.month && tradeDate.day == now.day;
      } else if (selectedFilter == 'สัปดาห์ล่าสุด') {
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        DateTime startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return tradeDate.isAfter(startDate) || tradeDate.isAtSameMomentAs(startDate);
      } else if (selectedFilter == 'เดือนล่าสุด') {
        return tradeDate.year == now.year && tradeDate.month == now.month;
      } else if (selectedFilter == '3 เดือนล่าสุด') {
        DateTime threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return tradeDate.isAfter(threeMonthsAgo);
      }
      return true;
    }).toList();
  }

  String _formatDisplayDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      List<String> spaceSplit = rawDate.split(' ');
      String datePart = spaceSplit[0];
      String timePart = spaceSplit.length > 1 ? ' ${spaceSplit[1]}' : '';

      String cleanDate = datePart.replaceAll('.', '-').replaceAll('/', '-');
      List<String> parts = cleanDate.split('-');
      
      if (parts.length == 3) {
        int? p1 = int.tryParse(parts[0]);
        int? p2 = int.tryParse(parts[1]);
        int? p3 = int.tryParse(parts[2]);

        if (p1 != null && p2 != null && p3 != null) {
          String day, month, year;
          if (p1 > 1000) {
            year = p1.toString();
            month = p2.toString().padLeft(2, '0');
            day = p3.toString();
          } else {
            day = p1.toString();
            month = p2.toString().padLeft(2, '0');
            year = p3 < 100 ? '${2000 + p3}' : p3.toString();
          }
          return '$day.$month.$year$timePart';
        }
      }
    } catch (e) {}
    return rawDate;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<dynamic, dynamic>> filteredHistory = _getFilteredHistory();

    double totalProfit = filteredHistory.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item['profit']?.toString() ?? '0.0') ?? 0.0);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('History', style: TextStyle(fontFamily: 'monospace', color: kGoldPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: kDarkBg.withOpacity(0.8),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/0.png',
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
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: filterOptions.length,
                  itemBuilder: (context, index) {
                    String filter = filterOptions[index];
                    bool isSelected = selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter, style: const TextStyle(fontFamily: 'monospace')),
                        selected: isSelected,
                        selectedColor: kGoldPrimary,
                        backgroundColor: kDarkCard.withOpacity(0.85),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        onSelected: (bool selected) {
                          setState(() {
                            selectedFilter = filter;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kDarkCard.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: kGoldPrimary,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Realized P/L ($selectedFilter)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${totalProfit >= 0 ? "+" : ""}\$${totalProfit.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: totalProfit >= 0 ? kGreenNeon : kRedNeon,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: kDarkCard.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: kGoldPrimary.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: filteredHistory.isEmpty
                        ? const Center(
                            child: Text('No closed trade history for this account', style: TextStyle(color: Colors.grey, fontFamily: 'monospace')),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredHistory.length,
                            itemBuilder: (context, index) {
                              final trade = filteredHistory[index];
                              final String type = trade['type']?.toString() ?? 'BUY';
                              final String symbol = trade['symbol']?.toString() ?? 'BTCUSD';
                              final double lot = double.tryParse(trade['lot']?.toString() ?? '0.01') ?? 0.01;
                              final double priceOpen = double.tryParse(trade['price_open']?.toString() ?? '0.0') ?? 0.0;
                              final double priceClose = double.tryParse(trade['price_close']?.toString() ?? '0.0') ?? 0.0;
                              final double profit = double.tryParse(trade['profit']?.toString() ?? '0.0') ?? 0.0;
                              
                              final String rawCloseTime = trade['close_time']?.toString() ?? trade['time']?.toString() ?? '';
                              final String closeTime = _formatDisplayDate(rawCloseTime);

                              bool isBuy = type.toUpperCase().contains('BUY');
                              bool isProfit = profit >= 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kDarkBg.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: (isBuy ? kGreenNeon : kRedNeon).withOpacity(0.4),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (isBuy ? kGreenNeon : kRedNeon).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            type,
                                            style: TextStyle(
                                              color: isBuy ? kGreenNeon : kRedNeon,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('$symbol, lot: $lot', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${priceOpen.toStringAsFixed(2)} -> ${priceClose.toStringAsFixed(2)}',
                                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(closeTime, style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace')),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${isProfit ? "+" : ""}\$${profit.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isProfit ? kGreenNeon : kRedNeon,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// #11 AlertsScreen
// ==========================================

class AlertsScreen extends StatefulWidget {
  final String accountLogin;
  final VoidCallback onAlertsRead;
  const AlertsScreen({super.key, required this.accountLogin, required this.onAlertsRead});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> alertItems = [];
  DatabaseReference? _alertsRef;

  @override
  void initState() {
    super.initState();
    widget.onAlertsRead();
    _listenToAlerts(widget.accountLogin);
  }

  @override
  void didUpdateWidget(covariant AlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountLogin != widget.accountLogin) {
      _listenToAlerts(widget.accountLogin);
    }
  }

  DateTime? _extractDateTime(String message) {
    try {
      final regExp = RegExp(r'\[(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2})\]');
      final match = regExp.firstMatch(message);
      if (match != null) {
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        int hour = int.parse(match.group(4)!);
        int minute = int.parse(match.group(5)!);
        int second = int.parse(match.group(6)!);
        return DateTime(year, month, day, hour, minute, second);
      }
    } catch (e) {}
    return null;
  }

  bool _isAllowedAlert(String upperMsg) {
    bool isFirstOrder = upperMsg.contains('SMART BUY') || upperMsg.contains('SMART SELL') || upperMsg.contains('FIRST') || (upperMsg.contains('OPEN') && !upperMsg.contains('RECOVERY'));
    bool isRecovery = upperMsg.contains('RECOVERY');
    bool isProfitClose = upperMsg.contains('PROFIT') || upperMsg.contains('TP') || upperMsg.contains('CLOSE WIN');
    bool isLossClose = upperMsg.contains('LOSS') && !upperMsg.contains('DAILY LOSS');
    bool isDailyTarget = upperMsg.contains('DAILY TARGET') || upperMsg.contains('TARGET REACHED');
    bool isDailyLoss = upperMsg.contains('DAILY LOSS') || upperMsg.contains('MAX LOSS');
    bool isCloseTime = upperMsg.contains('TIME') || upperMsg.contains('EXCEED') || upperMsg.contains('SESSION');

    return isFirstOrder || isRecovery || isProfitClose || isLossClose || isDailyTarget || isDailyLoss || isCloseTime;
  }

  void _listenToAlerts(String login) {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      _alertsRef = database.ref('accounts/$login/alerts');

      _alertsRef?.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value;
        if (mounted) {
          setState(() {
            List<Map<String, dynamic>> tempList = [];
            if (data is Map) {
              data.forEach((key, value) {
                if (value != null) {
                  String rawMsg = value.toString();
                  String cleanMsg = rawMsg.replaceAll(RegExp(r'command\s*', caseSensitive: false), '');
                  String upperMsg = cleanMsg.toUpperCase();
                  
                  if (_isAllowedAlert(upperMsg)) {
                    tempList.add({
                      'key': key.toString(),
                      'message': cleanMsg,
                      'time': _extractDateTime(cleanMsg),
                    });
                  }
                }
              });
            } else if (data is List) {
              for (int i = 0; i < data.length; i++) {
                if (data[i] != null) {
                  String rawMsg = data[i].toString();
                  String cleanMsg = rawMsg.replaceAll(RegExp(r'command\s*', caseSensitive: false), '');
                  String upperMsg = cleanMsg.toUpperCase();
                  
                  if (_isAllowedAlert(upperMsg)) {
                    tempList.add({
                      'key': i.toString(),
                      'message': cleanMsg,
                      'time': _extractDateTime(cleanMsg),
                    });
                  }
                }
              }
            }

            tempList.sort((a, b) {
              DateTime? timeA = a['time'];
              DateTime? timeB = b['time'];
              if (timeA == null && timeB == null) return 0;
              if (timeA == null) return 1;
              if (timeB == null) return -1;
              return timeB.compareTo(timeA);
            });

            alertItems = tempList;
          });
        }
      });
    } catch (e) {
      debugPrint("Alerts listen error: $e");
    }
  }

  void _clearAlertItem(String key) async {
    try {
      if (_alertsRef != null) {
        await _alertsRef!.child(key).remove();
      }
    } catch (e) {
      debugPrint("Clear alert error: $e");
    }
  }

  void _clearAllAlerts() async {
    try {
      if (_alertsRef != null) {
        await _alertsRef!.remove();
        if (mounted) {
          setState(() {
            alertItems.clear();
          });
        }
      }
    } catch (e) {
      debugPrint("Clear all alerts error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Alerts & Notifications', style: TextStyle(fontFamily: 'monospace', color: kGoldPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: kDarkBg.withOpacity(0.8),
        actions: [
          if (alertItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: kRedNeon),
              onPressed: _clearAllAlerts,
              tooltip: 'Clear All Alerts',
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/0.png',
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
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kDarkCard.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: kGoldPrimary,
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: alertItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No trading alerts available',
                        style: TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: alertItems.length,
                      itemBuilder: (context, index) {
                        var alert = alertItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kDarkBg.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: kGoldPrimary.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notifications_active, color: kGoldPrimary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  alert['message'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _clearAlertItem(alert['key']),
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(Icons.delete_outline, color: kRedNeon, size: 18),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// #12 SettingsScreen
// ==========================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedSymbol = 'XAUUSD';
  String tradingMode = 'All Mode';
  String lotMode = 'Fixed';
  
  final List<String> timeframes = ["M1", "M2", "M3", "M4", "M5", "M15", "M30", "H1"];
  String selectedTf = "M1";

  bool enableTrendFilter = true;

  final List<String> symbolOptions = ['XAUUSD', 'BTCUSD', 'EURUSD'];
  final List<String> tradingModeOptions = ['All Mode', 'Liquidity', 'Breakout', 'Enqulfing'];
  final List<String> lotModeOptions = ['Fixed', 'Step', 'Double'];
  
  final TextEditingController initialLotController = TextEditingController(text: "0.01");
  final TextEditingController maxRecoveryController = TextEditingController(text: "10");
  final TextEditingController maxOrdersController = TextEditingController(text: "10"); 
  final TextEditingController slPointsController = TextEditingController(text: "500");
  final TextEditingController riskRewardController = TextEditingController(text: "2.0");
  
  final TextEditingController recoveryStepController = TextEditingController(text: "500");
  final TextEditingController startTimeController = TextEditingController(text: "08:00");
  final TextEditingController endTimeController = TextEditingController(text: "22:00");

  bool enableDailyTarget = true;
  final TextEditingController dailyTargetController = TextEditingController(text: "100.0");
  
  bool enableDailyLoss = false;
  final TextEditingController dailyLossController = TextEditingController(text: "50.0");

  bool enableBasketControl = true;
  bool enableBasketTp = true;
  final TextEditingController basketTpController = TextEditingController(text: "1.50");
  
  bool enableBasketSl = false;
  final TextEditingController basketSlController = TextEditingController(text: "5.00");

  DatabaseReference? _statusRef;
  String currentLogin = "";

  bool _isEditing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLoginAndSettings();
  }

  @override
  void dispose() {
    initialLotController.dispose();
    maxRecoveryController.dispose();
    maxOrdersController.dispose();
    slPointsController.dispose();
    riskRewardController.dispose();
    recoveryStepController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    dailyTargetController.dispose();
    dailyLossController.dispose();
    basketTpController.dispose();
    basketSlController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLoginAndSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('mt5_login');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        currentLogin = saved;
      });
    }
    _loadAllSettingsFromFirebase();
  }

  void _loadAllSettingsFromFirebase() {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://liquidity-b8739-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );

      _statusRef = database.ref('accounts/$currentLogin/status');
      _statusRef?.onValue.listen((DatabaseEvent event) {
        if (_isEditing) return;

        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && mounted) {
          setState(() {
            selectedSymbol = data['symbol']?.toString() ?? 'XAUUSD';
            tradingMode = data['trading_mode']?.toString() ?? 'All Mode';
            lotMode = data['lot_mode']?.toString() ?? 'Fixed';
            selectedTf = data['timeframe']?.toString() ?? 'M1';
            enableTrendFilter = data['enable_trend_filter'] ?? true;

            enableBasketControl = data['enable_basket_control'] ?? true;
            enableBasketTp = data['enable_basket_tp'] ?? true;
            basketTpController.text = (data['basket_tp'] ?? 10).toString();

            enableBasketSl = data['enable_basket_sl'] ?? false;
            basketSlController.text = (data['basket_sl'] ?? 5).toString();

            enableDailyTarget = data['enable_daily_target'] ?? true;
            dailyTargetController.text = (data['daily_target'] ?? 100.0).toString();

            enableDailyLoss = data['enable_daily_loss'] ?? false;
            dailyLossController.text = (data['daily_loss'] ?? 50.0).toString();

            initialLotController.text = (data['initial_lot'] ?? 0.01).toString();
            maxRecoveryController.text = (data['max_recovery'] ?? 10).toString();
            maxOrdersController.text = (data['max_orders'] ?? 10).toString();
            recoveryStepController.text = (data['recovery_step'] ?? 500).toString();
            slPointsController.text = (data['sl_points'] ?? 500).toString();
            riskRewardController.text = (data['risk_reward'] ?? 2.0).toString();
            startTimeController.text = data['start_time_th']?.toString() ?? '08:00';
            endTimeController.text = data['end_time_th']?.toString() ?? '22:00';

            _isInitialized = true;
          });
        }
      });
    } catch (e) {
      debugPrint("Load settings error: $e");
    }
  }

  void _saveBotParametersToFirebase() {
    try {
      final double? basketTpVal = double.tryParse(basketTpController.text.trim());
      final double? basketSlVal = double.tryParse(basketSlController.text.trim());
      final double? dailyTargetVal = double.tryParse(dailyTargetController.text.trim());
      final double? dailyLossVal = double.tryParse(dailyLossController.text.trim());
      final double? initialLotVal = double.tryParse(initialLotController.text.trim());
      final int? maxRecoveryVal = int.tryParse(maxRecoveryController.text.trim());
      final int? maxOrdersVal = int.tryParse(maxOrdersController.text.trim());
      final int? recoveryStepVal = int.tryParse(recoveryStepController.text.trim());
      final double? slPointsVal = double.tryParse(slPointsController.text.trim());
      final double? riskRewardVal = double.tryParse(riskRewardController.text.trim());

      final Map<String, dynamic> payload = {
        'symbol': selectedSymbol,
        'trading_mode': tradingMode,
        'lot_mode': lotMode,
        'timeframe': selectedTf,
        'enable_trend_filter': enableTrendFilter,

        'enable_basket_control': enableBasketControl,
        'enable_basket_tp': enableBasketTp,
        'basket_tp': basketTpVal ?? 10,

        'enable_basket_sl': enableBasketSl,
        'basket_sl': basketSlVal ?? 5,

        'enable_daily_target': enableDailyTarget,
        'daily_target': dailyTargetVal ?? 100.0,

        'enable_daily_loss': enableDailyLoss,
        'daily_loss': dailyLossVal ?? 50.0,

        'initial_lot': initialLotVal ?? 0.01,
        'max_recovery': maxRecoveryVal ?? 10,
        'max_orders': maxOrdersVal ?? 10,
        'recovery_step': recoveryStepVal ?? 500,
        'sl_points': slPointsVal ?? 500,
        'risk_reward': riskRewardVal ?? 2.0,
        'start_time_th': startTimeController.text.trim(),
        'end_time_th': endTimeController.text.trim(),

        'command_timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _statusRef?.update(payload);

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 10,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: kDarkCard.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kGoldPrimary, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: kGoldPrimary.withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGreenNeon.withOpacity(0.2),
                    border: Border.all(color: kGreenNeon, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: kGreenNeon.withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: kGreenNeon,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SYNC & SAVE SUCCESS!',
                        style: TextStyle(
                          color: kGoldPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.2,
                          fontFamily: 'monospace',
                          shadows: [
                            Shadow(
                              color: kGoldPrimary,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'อัปเดตพารามิเตอร์ส่งไปยัง EA เรียบร้อยแล้ว',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Save bot parameters error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving parameters: $e'),
          backgroundColor: kRedNeon,
        ),
      );
    }
  }

  Future<void> _resetPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_user_pin');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PinAuthWrapper()),
      (route) => false,
    );
  }

  Future<void> _logoutToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_user_pin');
    await prefs.remove('mt5_login');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MT5LoginWrapper()),
      (route) => false,
    );
  }

  Widget _buildControllerInputField(String label, TextEditingController controller, TextInputType keyboardType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: kDarkBg.withOpacity(0.75),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kGoldPrimary.withOpacity(0.3), width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
            onChanged: (val) => setState(() { _isEditing = true; }),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Color _getSymbolBorderColor(String sym, bool isSelected) {
    if (isSelected) return kRedNeon;
    if (sym == 'BTCUSD') return kGreenNeon;
    if (sym == 'EURUSD') return kRedNeon;
    return kGoldPrimary.withOpacity(0.4);
  }

  Color _getTradingModeBorderColor(String mode, bool isSelected) {
    if (isSelected) return kRedNeon;
    if (mode == 'All Mode') return kRedNeon;
    if (mode == 'Liquidity') return const Color(0xFFE91E63);
    if (mode == 'Breakout') return const Color(0xFF00E5FF);
    if (mode == 'Enqulfing') return const Color(0xFFFF9100);
    return kGoldPrimary.withOpacity(0.4);
  }

  Color _getLotModeBorderColor(String mode, bool isSelected) {
    if (isSelected) return kRedNeon;
    if (mode == 'Fixed') return const Color(0xFF00E5FF);
    if (mode == 'Step') return const Color(0xFF9C27B0);
    if (mode == 'Double') return const Color(0xFFFF9100);
    return kGoldPrimary.withOpacity(0.4);
  }

  @override
  Widget build(BuildContext context) {
    double sl = double.tryParse(slPointsController.text) ?? 500;
    double rr = double.tryParse(riskRewardController.text) ?? 2.0;
    double calculatedTP = sl * rr;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings Bot Parameters', style: TextStyle(fontFamily: 'monospace', color: kGoldPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: kDarkBg.withOpacity(0.8),
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/0.png',
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
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kDarkCard.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: kGoldPrimary,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kGoldPrimary.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PARAMETERS BOT',
                        style: TextStyle(color: kGoldPrimary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 12),

                      const Text('Trading Symbol', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 8),
                      Row(
                        children: symbolOptions.map((sym) {
                          bool isSelected = selectedSymbol == sym;
                          Color borderColor = _getSymbolBorderColor(sym, isSelected);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: SizedBox(
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: () => setState(() {
                                    _isEditing = true;
                                    selectedSymbol = sym;
                                  }),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? kRedNeon : kDarkBg.withOpacity(0.75),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide(color: borderColor, width: isSelected ? 2.0 : 1.5),
                                    elevation: isSelected ? 4 : 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    sym,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      const Text('Trading Mode', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 8),
                      Row(
                        children: tradingModeOptions.map((mode) {
                          bool isSelected = tradingMode == mode;
                          Color borderColor = _getTradingModeBorderColor(mode, isSelected);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0),
                              child: SizedBox(
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: () => setState(() {
                                    _isEditing = true;
                                    tradingMode = mode;
                                  }),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? kRedNeon : kDarkBg.withOpacity(0.75),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: BorderSide(color: borderColor, width: isSelected ? 2.0 : 1.5),
                                    elevation: isSelected ? 4 : 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    mode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      const Text('Lot Mode', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 8),
                      Row(
                        children: lotModeOptions.map((mode) {
                          bool isSelected = lotMode == mode;
                          Color borderColor = _getLotModeBorderColor(mode, isSelected);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: SizedBox(
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: () => setState(() {
                                    _isEditing = true;
                                    lotMode = mode;
                                  }),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? kRedNeon : kDarkBg.withOpacity(0.75),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    side: BorderSide(color: borderColor, width: isSelected ? 2.0 : 1.5),
                                    elevation: isSelected ? 4 : 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    mode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: kGoldPrimary),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kDarkBg.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kRedNeon, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Daily Trend Filter (D1)', style: TextStyle(color: kRedNeon, fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                                Switch(
                                  value: enableTrendFilter,
                                  activeColor: Colors.white,
                                  activeTrackColor: kRedNeon,
                                  onChanged: (val) => setState(() {
                                    _isEditing = true;
                                    enableTrendFilter = val;
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text('Trading Timeframe', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 2.2,
                              ),
                              itemCount: timeframes.length,
                              itemBuilder: (context, index) {
                                String tf = timeframes[index];
                                bool isSelected = selectedTf == tf;
                                return ElevatedButton(
                                  onPressed: () => setState(() {
                                    _isEditing = true;
                                    selectedTf = tf;
                                  }),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? kRedNeon : Colors.black.withOpacity(0.75),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: const BorderSide(
                                      color: kRedNeon,
                                      width: 1.5,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    tf,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(child: _buildControllerInputField('Initial Lot', initialLotController, TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildControllerInputField('Max Recovery', maxRecoveryController, TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildControllerInputField('Max Orders', maxOrdersController, TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildControllerInputField('Recovery Step (Pts)', recoveryStepController, TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildControllerInputField('SL Points', slPointsController, TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildControllerInputField('Risk Reward', riskRewardController, TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Calculated TP', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            height: 46,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: kDarkBg.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kGoldPrimary.withOpacity(0.3), width: 1),
                            ),
                            child: Text(
                              '${calculatedTP.toStringAsFixed(1)} Pts',
                              style: const TextStyle(color: kGoldPrimary, fontWeight: FontWeight.bold, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildControllerInputField('Start Time (เวลาไทย)', startTimeController, TextInputType.text)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildControllerInputField('End Time (เวลาไทย)', endTimeController, TextInputType.text)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: kGoldPrimary),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('BASKET CONTROL', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          Row(
                            children: [
                              const Text('Enable Basket', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              Switch(
                                value: enableBasketControl,
                                activeColor: Colors.blueAccent,
                                onChanged: (val) => setState(() { enableBasketControl = val; }),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kDarkBg.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blueAccent, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Basket TP', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                      Switch(
                                        value: enableBasketTp,
                                        activeColor: Colors.blueAccent,
                                        onChanged: (val) => setState(() { enableBasketTp = val; }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _buildControllerInputField('Target (\$)', basketTpController, TextInputType.number),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kDarkBg.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kRedNeon, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Basket SL', style: TextStyle(color: kRedNeon, fontSize: 11, fontWeight: FontWeight.bold)),
                                      Switch(
                                        value: enableBasketSl,
                                        activeColor: kRedNeon,
                                        onChanged: (val) => setState(() { enableBasketSl = val; }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _buildControllerInputField('Limit (\$)', basketSlController, TextInputType.number),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('DAILY TARGET & LOSS CONTROL', style: TextStyle(color: kGreenNeon, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kDarkBg.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kGreenNeon, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Daily Target', style: TextStyle(color: kGreenNeon, fontSize: 11, fontWeight: FontWeight.bold)),
                                      Switch(
                                        value: enableDailyTarget,
                                        activeColor: kGreenNeon,
                                        onChanged: (val) => setState(() { enableDailyTarget = val; }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _buildControllerInputField('Target (\$)', dailyTargetController, TextInputType.number),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kDarkBg.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kRedNeon, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Daily Loss', style: TextStyle(color: kRedNeon, fontSize: 11, fontWeight: FontWeight.bold)),
                                      Switch(
                                        value: enableDailyLoss,
                                        activeColor: kRedNeon,
                                        onChanged: (val) => setState(() { enableDailyLoss = val; }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _buildControllerInputField('Limit (\$)', dailyLossController, TextInputType.number),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveBotParametersToFirebase,
                          icon: const Icon(Icons.save, color: kGoldPrimary),
                          label: const Text('SYNC & SAVE TO EA', style: TextStyle(color: kGoldPrimary, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDarkBg.withOpacity(0.75),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: kGoldPrimary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: kGoldPrimary, height: 24),
                      const SizedBox(height: 8),
                      const Text(
                        'SECURITY & PRIVACY', 
                        style: TextStyle(color: kGoldPrimary, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Reset Security PIN / Login', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
                                SizedBox(height: 2),
                                Text('ตั้งค่ารหัส PIN ใหม่', style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kDarkBg.withOpacity(0.75),
                              side: const BorderSide(color: kGoldPrimary, width: 1),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: _resetPin,
                            child: const Text('Reset', style: TextStyle(color: kGoldPrimary, fontSize: 12, fontFamily: 'monospace')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Log Out (เปลี่ยนบัญชี MT5)', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
                                SizedBox(height: 2),
                                Text('ออกจากระบบเพื่อกลับไปหน้าล็อกอิน', style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: const BorderSide(color: kGoldPrimary, width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: _logoutToLoginScreen,
                            child: const Text('Log Out', style: TextStyle(color: kGoldPrimary, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
