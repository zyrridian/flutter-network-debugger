import '../core/network_monitor.dart';
import '../models/network_call.dart';

/// Monitor for WebSocket and other socket-based connections.
///
/// Use [FlutterNetworkSocketMonitor.logSocketEvent] to manually log
/// WebSocket send/receive events, errors, and connection state changes.
///
/// Example:
///
/// ```dart
/// // Log a sent message
/// FlutterNetworkSocketMonitor.logSocketEvent(
///   url: 'ws://echo.websocket.org/',
///   event: 'send',
///   data: 'Hello Server',
/// );
///
/// // Log a received message
/// FlutterNetworkSocketMonitor.logSocketEvent(
///   url: 'ws://echo.websocket.org/',
///   event: 'receive',
///   data: 'Echo from Server',
/// );
/// ```
class FlutterNetworkSocketMonitor {
  /// Logs a WebSocket or socket event.
  ///
  /// Parameters:
  /// * [url] - The WebSocket URL
  /// * [event] - One of: 'send', 'receive', 'error', or 'close'
  /// * [data] - The event data (message content, error, etc.)
  /// * [id] - Optional connection ID; auto-generated if not provided
  static void logSocketEvent({
    required String url,
    required String event,
    dynamic data,
    String? id,
  }) {
    final callId = id ?? '${DateTime.now().millisecondsSinceEpoch}_socket';
    var calls = NetworkMonitorCore.instance.calls.value;
    var callIndex = calls.indexWhere((c) => c.id == callId);

    NetworkCall call;
    if (callIndex == -1) {
      call = NetworkCall(
        id: callId,
        type: NetworkCallType.socket,
        url: url,
        method: 'SOCKET',
        requestTime: DateTime.now(),
      );
      call.requestBody = [];
      call.responseBody = [];
      NetworkMonitorCore.instance.addCall(call);
    } else {
      call = calls[callIndex];
    }

    if (event == 'send') {
      (call.requestBody as List).add({
        'time': DateTime.now().toIso8601String(),
        'data': data,
      });
    } else if (event == 'receive') {
      (call.responseBody as List).add({
        'time': DateTime.now().toIso8601String(),
        'data': data,
      });
    } else if (event == 'error') {
      call.error = data;
      call.statusCode = 500;
    } else if (event == 'close') {
      call.responseTime = DateTime.now();
      call.statusCode = 200;
    }

    NetworkMonitorCore.instance.updateCall(call);
  }
}
