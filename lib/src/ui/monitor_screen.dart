import 'package:flutter/material.dart';
import '../core/network_monitor.dart';
import '../models/network_call.dart';
import 'call_details_screen.dart';

class NetworkMonitorScreen extends StatelessWidget {
  const NetworkMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              NetworkMonitorCore.instance.clear();
            },
          )
        ],
      ),
      body: ValueListenableBuilder<List<NetworkCall>>(
        valueListenable: NetworkMonitorCore.instance.calls,
        builder: (context, calls, child) {
          if (calls.isEmpty) {
            return const Center(child: Text('No network calls yet.'));
          }
          return ListView.builder(
            itemCount: calls.length,
            itemBuilder: (context, index) {
              final call = calls[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(call),
                  child: Text(
                    call.method.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  call.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${call.method} | ${call.statusCode ?? '...'} | ${call.durationMilliseconds > -1 ? '${call.durationMilliseconds}ms' : '...'}',
                ),
                trailing: Icon(
                  _getStatusIcon(call),
                  color: _getStatusColor(call),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CallDetailsScreen(call: call),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(NetworkCall call) {
    if (call.statusCode == null) {
      return Colors.grey;
    }
    if (call.statusCode! >= 200 && call.statusCode! < 300) {
      return Colors.green;
    }
    if (call.statusCode! >= 300 && call.statusCode! < 400) {
      return Colors.blue;
    }
    return Colors.red;
  }

  IconData _getStatusIcon(NetworkCall call) {
    if (call.statusCode == null) {
      return Icons.hourglass_empty;
    }
    if (call.statusCode! >= 200 && call.statusCode! < 300) {
      return Icons.check_circle;
    }
    if (call.statusCode! >= 300 && call.statusCode! < 400) {
      return Icons.info;
    }
    return Icons.error;
  }
}
