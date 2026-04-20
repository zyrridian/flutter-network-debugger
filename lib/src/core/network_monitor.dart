import 'package:flutter/foundation.dart';
import '../models/network_call.dart';

class NetworkMonitorCore {
  static final NetworkMonitorCore _instance = NetworkMonitorCore._internal();
  static NetworkMonitorCore get instance => _instance;

  NetworkMonitorCore._internal();

  final ValueNotifier<List<NetworkCall>> calls = ValueNotifier([]);

  void addCall(NetworkCall call) {
    calls.value = [call, ...calls.value];
  }

  void updateCall(NetworkCall call) {
    final currentCalls = List<NetworkCall>.from(calls.value);
    final index = currentCalls.indexWhere((c) => c.id == call.id);
    if (index != -1) {
      currentCalls[index] = call;
      calls.value = currentCalls;
    }
  }

  void clear() {
    calls.value = [];
  }
}
