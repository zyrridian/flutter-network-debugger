import 'package:flutter/material.dart';
import 'monitor_screen.dart';

/// A widget that wraps your app to display a network debugging interface.
///
/// [FlutterNetworkDebugger] displays a draggable floating action button (FAB)
/// that opens the network monitor screen when tapped. It captures all network
/// calls made through registered interceptors.
///
/// The debug interface can be toggled on/off using the [isVisible] property
/// or by setting [isDebug] to false.
class FlutterNetworkDebugger extends StatefulWidget {
  /// The child widget tree to wrap (typically your MaterialApp).
  final Widget child;

  /// Whether to enable the debug interface.
  ///
  /// If false, [FlutterNetworkDebugger] passes through the child widget
  /// without any debugging UI overlay.
  final bool isDebug;

  /// Navigator key for the app.
  ///
  /// If provided, this key is used to navigate to the monitor screen.
  /// If not provided, the widget attempts to use the current context's navigator.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Creates a [FlutterNetworkDebugger].
  ///
  /// The [child] parameter is required and should typically be your [MaterialApp].
  /// The [isDebug] parameter defaults to true, enabling the debug interface.
  const FlutterNetworkDebugger({
    super.key,
    required this.child,
    this.isDebug = true,
    this.navigatorKey,
  });

  /// Controls the visibility of the debug floating action button.
  ///
  /// Set to false to hide the FAB, or true to show it.
  /// This is useful for temporarily hiding the debug interface without recreating
  /// the widget tree.
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
                              builder: (context) =>
                                  const NetworkMonitorScreen(),
                            ),
                          );
                        } else {
                          try {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NetworkMonitorScreen(),
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
