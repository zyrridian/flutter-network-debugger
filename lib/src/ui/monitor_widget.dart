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

    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
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
                onPressed: () {
                  if (widget.navigatorKey != null) {
                    widget.navigatorKey!.currentState?.push(
                      MaterialPageRoute(
                        builder: (context) => const NetworkMonitorScreen(),
                      ),
                    );
                  } else {
                    try {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NetworkMonitorScreen(),
                        ),
                      );
                    } catch (e) {
                      debugPrint('FlutterNetworkDebugger Error: Could not find Navigator. Please pass a navigatorKey to FlutterNetworkDebugger and your MaterialApp.');
                    }
                  }
                },
                child: const Icon(Icons.network_check),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
