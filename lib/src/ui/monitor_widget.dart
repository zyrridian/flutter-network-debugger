import 'package:flutter/material.dart';
import 'monitor_screen.dart';

class FlutterNetworkDebugger extends StatefulWidget {
  final Widget child;
  final bool isDebug;
  final GlobalKey<NavigatorState>? navigatorKey;

  const FlutterNetworkDebugger({
    super.key,
    required this.child,
    this.isDebug = true,
    this.navigatorKey,
  });

  static final ValueNotifier<bool> isVisible = ValueNotifier(true);

  @override
  State<FlutterNetworkDebugger> createState() => _FlutterNetworkDebuggerState();
}

class _FlutterNetworkDebuggerState extends State<FlutterNetworkDebugger> {
  Offset _offset = const Offset(20, 100);

  @override
  Widget build(BuildContext context) {
    if (!widget.isDebug) {
      return widget.child;
    }

    return ValueListenableBuilder<bool>(
      valueListenable: FlutterNetworkDebugger.isVisible,
      builder: (context, visible, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            widget.child,
            if (visible)
              Positioned(
                left: _offset.dx,
                top: _offset.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _offset += details.delta;
                    });
                  },
                  child: Material(
                    type: MaterialType.transparency,
                    child: FloatingActionButton(
                      heroTag: 'flutter_network_debugger_fab',
                      mini: true,
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shape: const CircleBorder(),
                      onPressed: () async {
                        FlutterNetworkDebugger.isVisible.value = false;
                        if (widget.navigatorKey != null) {
                          await widget.navigatorKey!.currentState?.push(
                            MaterialPageRoute(
                              builder: (context) => const NetworkMonitorScreen(),
                            ),
                          );
                        } else {
                          try {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const NetworkMonitorScreen(),
                              ),
                            );
                          } catch (e) {
                            debugPrint(
                                'FlutterNetworkDebugger Error: Could not find Navigator. Please pass a navigatorKey to FlutterNetworkDebugger and your MaterialApp.');
                          }
                        }
                        FlutterNetworkDebugger.isVisible.value = true;
                      },
                      child: const Icon(Icons.api, size: 20),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
