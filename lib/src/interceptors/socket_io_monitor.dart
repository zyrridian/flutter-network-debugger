import 'package:socket_io_client/socket_io_client.dart';
import 'socket_monitor.dart';

final Expando<String> _socketIds = Expando<String>();

/// Extension to add network monitoring to [Socket] from socket_io_client.
extension SocketIoDebuggerExtension on Socket {
  /// Attaches listeners to the socket to monitor incoming events, connections, and errors.
  /// 
  /// [id] Optional unique identifier for this socket connection. If not provided,
  /// the socket's internal ID or URL will be used.
  void monitor({String? id}) {
    final socketId = id ?? this.id ?? (this.io as dynamic).uri ?? 'socket_io_${DateTime.now().millisecondsSinceEpoch}';
    _socketIds[this] = socketId;
    final url = (this.io as dynamic).uri ?? 'unknown_url';

    onConnect((_) {
      FlutterNetworkSocketMonitor.logSocketEvent(
        url: url,
        event: 'receive',
        data: 'Connected',
        id: socketId,
      );
    });

    onDisconnect((_) {
      FlutterNetworkSocketMonitor.logSocketEvent(
        url: url,
        event: 'close',
        data: 'Disconnected',
        id: socketId,
      );
    });

    onError((error) {
      FlutterNetworkSocketMonitor.logSocketEvent(
        url: url,
        event: 'error',
        data: error,
        id: socketId,
      );
    });

    onAny((event, data) {
      // Ignore internal events if you want, or log all
      FlutterNetworkSocketMonitor.logSocketEvent(
        url: url,
        event: 'receive',
        data: {'event': event, 'data': data},
        id: socketId,
      );
    });
  }

  /// Emits an event and logs it to the network debugger.
  /// 
  /// Use this instead of [emit] if you want outgoing events to be tracked.
  void emitTracked(String event, [dynamic data]) {
    final socketId = _socketIds[this] ?? this.id ?? (this.io as dynamic).uri ?? 'socket_io';
    final url = (this.io as dynamic).uri ?? 'unknown_url';
    
    FlutterNetworkSocketMonitor.logSocketEvent(
      url: url,
      event: 'send',
      data: {'event': event, 'data': data},
      id: socketId,
    );
    
    emit(event, data);
  }
}
