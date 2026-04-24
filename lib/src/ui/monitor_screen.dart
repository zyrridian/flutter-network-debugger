import 'package:flutter/material.dart';
import '../core/network_monitor.dart';
import '../models/network_call.dart';
import 'call_details_screen.dart';

class NetworkMonitorScreen extends StatelessWidget {
  const NetworkMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: Colors.black,
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: isDark ? Colors.white : Colors.black,
              secondary: Colors.grey,
              surfaceTint: Colors.transparent,
            ),
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Colors.black),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          elevation: 0,
          title: const Text('NETWORK DEBUGGER',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1.2)),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => NetworkMonitorCore.instance.clear(),
            )
          ],
        ),
        body: ValueListenableBuilder<List<NetworkCall>>(
          valueListenable: NetworkMonitorCore.instance.calls,
          builder: (context, calls, child) {
            if (calls.isEmpty) {
              return const Center(
                  child: Text('NO NETWORK CALLS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0)));
            }
            return ListView.builder(
              itemCount: calls.length,
              itemBuilder: (context, index) {
                final call = calls[index];
                final methodColor = _getMethodColor(call.method);
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 60,
                    height: 32,
                    decoration: BoxDecoration(
                      color: methodColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        call.method.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    call.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        '${call.statusCode ?? 'PENDING'}',
                        style: TextStyle(
                          color: _getStatusColor(call),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: Colors.grey)),
                      Text(
                        '${call.durationMilliseconds > -1 ? '${call.durationMilliseconds}ms' : '...'}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      size: 20, color: Colors.grey),
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
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green[700]!;
      case 'POST':
        return Colors.blue[700]!;
      case 'PUT':
        return Colors.orange[700]!;
      case 'PATCH':
        return Colors.deepPurple[400]!;
      case 'DELETE':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  int min(int a, int b) => a < b ? a : b;

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
