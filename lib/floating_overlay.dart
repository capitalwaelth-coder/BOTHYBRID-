
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

const Color overlayGold = Color(0xFFFFD700);
const Color overlayGreen = Color(0xFF00E887);
const Color overlayRed = Color(0xFFFF1744);
const Color overlayBg = Color(0xF2111111);

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FloatingRobotOverlay(),
    ),
  );
}

class FloatingRobotOverlay extends StatefulWidget {
  const FloatingRobotOverlay({super.key});

  @override
  State<FloatingRobotOverlay> createState() =>
      _FloatingRobotOverlayState();
}

class _FloatingRobotOverlayState
    extends State<FloatingRobotOverlay> {
  StreamSubscription<dynamic>? _subscription;

  bool _showLogs = false;
  bool _showStatus = true;
  bool _dragging = false;

  Map<String, dynamic> _data = {
    'connected': false,
    'running': false,
    'symbol': 'XAUUSD',
    'timeframe': 'M1',
    'profit': 0.0,
    'orders': 0,
    'lots': 0.0,
    'logs': <dynamic>[],
  };

  @override
  void initState() {
    super.initState();

    _subscription =
        FlutterOverlayWindow.overlayListener.listen((event) {
      if (!mounted || event is! Map) return;

      final message = Map<String, dynamic>.from(event);

      if (message['type'] == 'toggle_logs') {
        setState(() => _showLogs = !_showLogs);
        _resizeForCurrentView();
        return;
      }

      if (message['type'] == 'close_logs') {
        setState(() => _showLogs = false);
        _resizeForCurrentView();
        return;
      }

      if (message['type'] == 'close_overlay') {
        FlutterOverlayWindow.closeOverlay();
        return;
      }

      if (message['type'] == 'clear_logs') {
        FlutterOverlayWindow.shareData({
          'type': 'clear_logs',
        });
        return;
      }

      if (message['type'] == 'delete_log') {
        FlutterOverlayWindow.shareData({
          'type': 'delete_log',
          'key': message['key'],
        });
        return;
      }

      if (message['type'] == 'state') {
        setState(() {
          _data = {
            ..._data,
            ...message,
          };
        });
      }
    });
  }

  Future<void> _resizeForCurrentView() async {
    try {
      if (_showLogs) {
        await FlutterOverlayWindow.resizeOverlay(
          360,
          620,
          enableDrag: false,
        );
      } else {
        await FlutterOverlayWindow.resizeOverlay(
          76,
          76,
          enableDrag: false,
        );
      }
    } catch (e) {
      debugPrint('Overlay resize error: $e');
    }
  }

  Future<void> _moveOverlay(DragUpdateDetails details) async {
    // Drag the overlay window from its header or bubble.
    try {
      final position =
          await FlutterOverlayWindow.getOverlayPosition();

      await FlutterOverlayWindow.moveOverlay(
        OverlayPosition(
          position.x + details.delta.dx.toInt(),
          position.y + details.delta.dy.toInt(),
        ),
      );
    } catch (e) {
      debugPrint('Overlay move error: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLogs) {
      return Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onPanStart: (_) => _dragging = true,
            onPanUpdate: _moveOverlay,
            onPanEnd: (_) => _dragging = false,
            onTap: () async {
              if (_dragging) return;

              setState(() => _showLogs = true);
              await _resizeForCurrentView();
            },
            child: _robotBubble(),
          ),
        ),
      );
    }

    final logs = (_data['logs'] as List?) ?? [];
    final connected = _data['connected'] == true;
    final running = _data['running'] == true;
    final totalProfit =
        (_data['profit'] as num?)?.toDouble() ?? 0.0;
    final lots = (_data['lots'] as num?)?.toDouble() ?? 0.0;
    final orders = (_data['orders'] as num?)?.toInt() ?? 0;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: overlayBg,
            border: Border.all(color: overlayGold, width: 2),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            children: [
              GestureDetector(
                onPanUpdate: _moveOverlay,
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: overlayGold,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.terminal,
                        color: overlayGold,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'STATUS & LOGS',
                          style: TextStyle(
                            color: overlayGold,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _showStatus = !_showStatus);
                        },
                        icon: Icon(
                          _showStatus
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: overlayGreen,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          FlutterOverlayWindow.shareData({
                            'type': 'clear_logs',
                          });
                        },
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: overlayRed,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          setState(() => _showLogs = false);
                          await _resizeForCurrentView();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showStatus) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF191919),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: overlayGold,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LIVE STATUS',
                                style: TextStyle(
                                  color: overlayGold,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: connected && running
                                        ? overlayGreen
                                        : overlayRed,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      connected && running
                                          ? 'EA SERVER ONLINE & RUNNING'
                                          : 'EA SERVER OFFLINE / STOPPED',
                                      style: TextStyle(
                                        color: connected && running
                                            ? overlayGreen
                                            : overlayRed,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Symbol: ${_data['symbol']}  |  '
                                'TF: ${_data['timeframe']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const Divider(color: Colors.white24),
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  Text(
                                    'Orders: $orders',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    'Lots: ${lots.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    'P/L: ${totalProfit >= 0 ? '+' : ''}'
                                    '\$${totalProfit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: totalProfit >= 0
                                          ? overlayGreen
                                          : overlayRed,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const Text(
                        'ACTIVITY LOGS',
                        style: TextStyle(
                          color: overlayGold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: logs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No log records...',
                                  style: TextStyle(
                                    color: Colors.white54,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final item = Map<String, dynamic>.from(
                                    logs[index] as Map,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${index == 0 ? '➜ ' : '> '}${item['message'] ?? ''}',
                                            style: TextStyle(
                                              color: index == 0
                                                  ? overlayGreen
                                                  : Colors.white,
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            FlutterOverlayWindow.shareData({
                                              'type': 'delete_log',
                                              'key': item['key'],
                                            });
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(
                                              Icons.delete_outline,
                                              color: overlayRed,
                                              size: 18,
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
    );
  }

  Widget _robotBubble() {
    final active =
        _data['connected'] == true && _data['running'] == true;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        shape: BoxShape.circle,
        border: Border.all(color: overlayGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: (active ? overlayGreen : overlayRed).withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/7.png',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.smart_toy,
                color: overlayGold,
                size: 34,
              ),
            ),
          ),
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: active ? overlayGreen : overlayRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
