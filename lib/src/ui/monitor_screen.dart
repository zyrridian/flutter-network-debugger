import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/network_monitor.dart';
import '../models/network_call.dart';
import 'call_details_screen.dart';

/// Screen that displays a list of all captured network calls.
///
/// [NetworkMonitorScreen] shows HTTP and WebSocket calls with:
/// * URL and request method
/// * Status code and response duration
/// * Search functionality to filter calls
/// * Export to JSON capability
/// * Tap to view detailed call information
class NetworkMonitorScreen extends StatefulWidget {
  /// Creates a [NetworkMonitorScreen].
  const NetworkMonitorScreen({super.key});

  @override
  State<NetworkMonitorScreen> createState() => _NetworkMonitorScreenState();
}

class _NetworkMonitorScreenState extends State<NetworkMonitorScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: isDark ? Colors.white : Colors.black,
          selectionColor:
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
          selectionHandleColor: isDark ? Colors.white : Colors.black,
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
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'SEARCH URL OR STATUS...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                )
              : const Text('NETWORK DEBUGGER',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 1.2)),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search, size: 20),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchController.clear();
                    _searchQuery = '';
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              tooltip: 'Export All as JSON',
              onPressed: () => _exportAll(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Clear All',
              onPressed: () => NetworkMonitorCore.instance.clear(),
            )
          ],
        ),
        body: ValueListenableBuilder<List<NetworkCall>>(
          valueListenable: NetworkMonitorCore.instance.calls,
          builder: (context, calls, child) {
            final filteredCalls = calls.where((call) {
              final urlMatch = call.url.toLowerCase().contains(_searchQuery);
              final statusMatch =
                  call.statusCode?.toString().contains(_searchQuery) ?? false;
              final methodMatch =
                  call.method.toLowerCase().contains(_searchQuery);
              return urlMatch || statusMatch || methodMatch;
            }).toList();

            if (calls.isEmpty) {
              return const Center(
                  child: Text('NO NETWORK CALLS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0)));
            }

            if (filteredCalls.isEmpty && _searchQuery.isNotEmpty) {
              return const Center(
                  child: Text('NO RESULTS FOUND',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0)));
            }

            return ListView.builder(
              itemCount: filteredCalls.length,
              itemBuilder: (context, index) {
                final call = filteredCalls[index];
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
                        call.durationMilliseconds > -1
                            ? '${call.durationMilliseconds}ms'
                            : '...',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
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

  void _exportAll(BuildContext context) {
    final calls = NetworkMonitorCore.instance.calls.value;
    if (calls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No calls to export')),
      );
      return;
    }

    final jsonList = calls.map((c) => c.toJson()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session exported to clipboard as JSON')),
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
        return Colors.indigo[400]!;
      case 'DELETE':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
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
}
