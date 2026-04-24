import 'package:flutter/foundation.dart';
import '../models/network_call.dart';

/// Core singleton for managing network call monitoring.
///
/// [NetworkMonitorCore] maintains a list of all captured network calls and
/// provides methods to add, update, and clear them. It uses a [ValueNotifier]
/// to notify listeners when the list of calls changes.
///
/// Access the singleton instance via [NetworkMonitorCore.instance].
class NetworkMonitorCore {
  static final NetworkMonitorCore _instance = NetworkMonitorCore._internal();

  /// Gets the singleton instance of [NetworkMonitorCore].
  static NetworkMonitorCore get instance => _instance;

  NetworkMonitorCore._internal();

  /// A [ValueNotifier] containing all captured network calls.
  ///
  /// Listeners can be attached to this notifier to react to changes
  /// in the list of network calls.
  final ValueNotifier<List<NetworkCall>> calls = ValueNotifier([]);

  /// Adds a new network call to the monitoring list.
  ///
  /// The call is added to the front of the list so the most recent calls
  /// appear first.
  void addCall(NetworkCall call) {
    calls.value = [call, ...calls.value];
  }

  /// Updates an existing network call with new information.
  ///
  /// This is typically called when a request completes and response
  /// information is available. The call is matched by its [id] field.
  void updateCall(NetworkCall call) {
    final currentCalls = List<NetworkCall>.from(calls.value);
    final index = currentCalls.indexWhere((c) => c.id == call.id);
    if (index != -1) {
      currentCalls[index] = call;
      calls.value = currentCalls;
    }
  }

  /// Clears all captured network calls from the monitor.
  void clear() {
    calls.value = [];
  }
}
