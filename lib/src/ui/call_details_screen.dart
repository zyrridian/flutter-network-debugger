import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/network_call.dart';

class CallDetailsScreen extends StatelessWidget {
  final NetworkCall call;

  const CallDetailsScreen({super.key, required this.call});

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
        splashColor: Colors.grey.withOpacity(0.1),
        highlightColor: Colors.transparent,
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
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
            elevation: 0,
            title: const Text('CALL DETAILS',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2)),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_all, size: 20),
                tooltip: 'Copy as cURL',
                onPressed: () => _copyAsCurl(context),
              ),
            ],
            bottom: TabBar(
              indicatorColor: isDark ? Colors.white : Colors.black,
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
              tabs: const [
                Tab(text: 'OVERVIEW'),
                Tab(text: 'REQUEST'),
                Tab(text: 'RESPONSE'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildOverview(context),
              _buildRequest(context),
              _buildResponse(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
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

  Widget _buildRequest(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Headers', _formatJson(call.requestHeaders)),
        const SizedBox(height: 8),
        JsonCodeBlock(json: _formatJson(call.requestHeaders)),
        const Divider(height: 32),
        _buildSectionHeader(
          'Body',
          _formatJson(call.requestBody),
          subtitle: _getContentTypeLabel(call.requestHeaders),
        ),
        const SizedBox(height: 8),
        JsonCodeBlock(json: _formatJson(call.requestBody)),
      ],
    );
  }

  Widget _buildResponse(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ExpandablePreviewSection(
          title: 'Headers',
          content: _formatJson(call.responseHeaders),
          onCopy: (content) => _copyToClipboard(context, content),
        ),
        const Divider(height: 32),
        _buildSectionHeader(
          'Body',
          _formatJson(call.responseBody),
          subtitle: _getContentTypeLabel(call.responseHeaders),
        ),
        const SizedBox(height: 8),
        JsonCodeBlock(json: _formatJson(call.responseBody)),
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

  Widget _buildSectionHeader(String title, String copyContent,
      {String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subtitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copy $title',
            onPressed: () => _copyToClipboard(context, copyContent),
          );
        }),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _copyAsCurl(BuildContext context) {
    final buffer = StringBuffer();
    buffer.write('curl -X ${call.method} "${call.url}"');

    if (call.requestHeaders != null && call.requestHeaders is Map) {
      (call.requestHeaders as Map).forEach((key, value) {
        buffer.write(' -H "$key: $value"');
      });
    }

    if (call.requestBody != null) {
      final body = call.requestBody is String
          ? call.requestBody
          : json.encode(call.requestBody);
      buffer.write(" -d '$body'");
    }

    _copyToClipboard(context, buffer.toString());
  }

  String? _getContentTypeLabel(Map<String, dynamic>? headers) {
    if (headers == null) return null;

    // Dio headers can be Map<String, dynamic> or Map<String, List<String>>
    dynamic contentType;
    headers.forEach((key, value) {
      if (key.toLowerCase() == 'content-type') {
        contentType = value;
      }
    });

    if (contentType == null) return null;

    final String typeString =
        (contentType is List) ? contentType.first.toString() : contentType.toString();

    if (typeString.contains('application/json')) return 'JSON';
    if (typeString.contains('multipart/form-data')) return 'FormData';
    if (typeString.contains('application/x-www-form-urlencoded')) return 'Form';
    if (typeString.contains('text/plain')) return 'Text';
    if (typeString.contains('text/html')) return 'HTML';
    if (typeString.contains('application/xml')) return 'XML';

    return typeString.split(';').first.split('/').last.toUpperCase();
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

class ExpandablePreviewSection extends StatefulWidget {
  final String title;
  final String content;
  final Function(String) onCopy;

  const ExpandablePreviewSection({
    super.key,
    required this.title,
    required this.content,
    required this.onCopy,
  });

  @override
  State<ExpandablePreviewSection> createState() =>
      _ExpandablePreviewSectionState();
}

class _ExpandablePreviewSectionState extends State<ExpandablePreviewSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.content.split('\n').length > 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Row(
              children: [
                if (isLong)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more),
                    label: Text(_isExpanded ? 'Show less' : 'Show more'),
                  ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => widget.onCopy(widget.content),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ClipRect(
              child: JsonCodeBlock(
                json: widget.content,
              ),
            ),
          ),
          secondChild: JsonCodeBlock(json: widget.content),
          crossFadeState: (isLong && !_isExpanded)
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class JsonCodeBlock extends StatelessWidget {
  final String json;

  const JsonCodeBlock({super.key, required this.json});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: SelectableText.rich(
        _highlightJson(json, isDark),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  TextSpan _highlightJson(String source, bool isDark) {
    final List<TextSpan> spans = [];
    final regExp = RegExp(
      r'("(?:\\"|[^"])*")(?=\s*:)|("(?:\\"|[^"])*")|(\b\d+\b)|(\btrue|false|null\b)|([\{\}\[\]\:,])',
      multiLine: true,
    );

    int lastIndex = 0;
    for (final match in regExp.allMatches(source)) {
      // Add plain text before match
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: source.substring(lastIndex, match.start)));
      }

      if (match.group(1) != null) {
        // Key
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
              color: isDark ? Colors.lightBlueAccent : Colors.indigo,
              fontWeight: FontWeight.bold),
        ));
      } else if (match.group(2) != null) {
        // String value
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(color: Colors.teal),
        ));
      } else if (match.group(3) != null) {
        // Number
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(color: Colors.orange),
        ));
      } else if (match.group(4) != null) {
        // Keyword (bool/null)
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(color: Colors.redAccent),
        ));
      } else if (match.group(5) != null) {
        // Punctuation
        spans.add(TextSpan(
          text: match.group(5),
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < source.length) {
      spans.add(TextSpan(text: source.substring(lastIndex)));
    }

    return TextSpan(
        children: spans,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87));
  }
}
