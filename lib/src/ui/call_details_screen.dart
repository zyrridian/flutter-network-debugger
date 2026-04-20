import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/network_call.dart';

class CallDetailsScreen extends StatelessWidget {
  final NetworkCall call;

  const CallDetailsScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Call Details'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Request'),
              Tab(text: 'Response'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverview(),
            _buildRequest(),
            _buildResponse(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDetailRow('URL', call.url),
        _buildDetailRow('Method', call.method),
        _buildDetailRow('Status Code', call.statusCode?.toString() ?? 'N/A'),
        _buildDetailRow('Duration',
            '${call.durationMilliseconds > -1 ? call.durationMilliseconds : 'N/A'} ms'),
        _buildDetailRow('Time', call.requestTime.toString()),
        if (call.error != null)
          _buildDetailRow('Error', call.error.toString(), isError: true),
      ],
    );
  }

  Widget _buildRequest() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Headers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        SelectableText(_formatJson(call.requestHeaders)),
        const Divider(height: 32),
        const Text('Body',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        SelectableText(_formatJson(call.requestBody)),
      ],
    );
  }

  Widget _buildResponse() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Headers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        SelectableText(_formatJson(call.responseHeaders)),
        const Divider(height: 32),
        const Text('Body',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        SelectableText(_formatJson(call.responseBody)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: TextStyle(fontSize: 16, color: isError ? Colors.red : null),
          ),
        ],
      ),
    );
  }

  String _formatJson(dynamic data) {
    if (data == null) return 'No data';
    try {
      if (data is String) {
        final parsed = json.decode(data);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }
}
