import '../core/network_monitor.dart';
import '../models/network_call.dart';

class FlutterNetworkSocketMonitor {
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
