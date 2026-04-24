import 'dart:convert';
import 'package:flutter/gestures.dart';
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
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0),
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
    final contentType = _getContentTypeLabel(call.responseHeaders);
    final isImage = contentType == 'IMAGE';

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
          isImage ? call.url : _formatJson(call.responseBody),
          subtitle: contentType,
        ),
        const SizedBox(height: 8),
        if (isImage)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                call.url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('Failed to load image preview',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
            ),
          )
        else
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

    final String typeString = (contentType is List)
        ? contentType.first.toString()
        : contentType.toString();

    if (typeString.contains('application/json')) return 'JSON';
    if (typeString.contains('multipart/form-data')) return 'FormData';
    if (typeString.contains('application/x-www-form-urlencoded')) return 'Form';
    if (typeString.contains('text/plain')) return 'Text';
    if (typeString.contains('text/html')) return 'HTML';
    if (typeString.contains('application/xml')) return 'XML';
    if (typeString.contains('image/')) return 'IMAGE';

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
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: double.infinity,
                child: JsonCodeBlock(
                  json: widget.content,
                ),
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

class JsonCodeBlock extends StatefulWidget {
  final String json;

  const JsonCodeBlock({super.key, required this.json});

  @override
  State<JsonCodeBlock> createState() => _JsonCodeBlockState();
}

class _JsonCodeBlockState extends State<JsonCodeBlock> {
  final List<TapGestureRecognizer> _recognizers = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'SEARCH JSON...',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black26),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
        Stack(
          children: [
            Container(
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
                _highlightJson(context, widget.json, isDark),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            if (!_isSearching)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.search, size: 16, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<InlineSpan> _applySearchHighlight(String text, TextStyle baseStyle,
      {GestureRecognizer? recognizer}) {
    if (_searchQuery.isEmpty)
      return [TextSpan(text: text, style: baseStyle, recognizer: recognizer)];

    final lowerText = text.toLowerCase();
    int index = lowerText.indexOf(_searchQuery);
    if (index == -1)
      return [TextSpan(text: text, style: baseStyle, recognizer: recognizer)];

    final List<InlineSpan> spans = [];
    int start = 0;
    final highlightStyle =
        baseStyle.copyWith(backgroundColor: Colors.yellow, color: Colors.black);

    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(
            text: text.substring(start, index),
            style: baseStyle,
            recognizer: recognizer));
      }
      spans.add(TextSpan(
          text: text.substring(index, index + _searchQuery.length),
          style: highlightStyle,
          recognizer: recognizer));
      start = index + _searchQuery.length;
      index = lowerText.indexOf(_searchQuery, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(
          text: text.substring(start),
          style: baseStyle,
          recognizer: recognizer));
    }
    return spans;
  }

  TextSpan _highlightJson(BuildContext context, String source, bool isDark) {
    final List<InlineSpan> spans = [];
    final regExp = RegExp(
      r'("(?:\\"|[^"])*")(?=\s*:)|("(?:\\"|[^"])*")|(\b\d+\b)|(\btrue|false|null\b)|([\{\}\[\]\:,])',
      multiLine: true,
    );
    final defaultStyle =
        TextStyle(color: isDark ? Colors.white : Colors.black87);

    int lastIndex = 0;
    for (final match in regExp.allMatches(source)) {
      if (match.start > lastIndex) {
        spans.addAll(_applySearchHighlight(
            source.substring(lastIndex, match.start), defaultStyle));
      }

      if (match.group(1) != null) {
        spans.addAll(_applySearchHighlight(
          match.group(1)!,
          TextStyle(
              color: isDark ? Colors.lightBlueAccent : Colors.indigo,
              fontWeight: FontWeight.bold),
        ));
      } else if (match.group(2) != null) {
        final stringValue = match.group(2)!;
        final rawValue = stringValue.replaceAll('"', '');
        final isUrl =
            rawValue.startsWith('http://') || rawValue.startsWith('https://');

        if (isUrl) {
          final recognizer = TapGestureRecognizer()
            ..onTap = () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title:
                          Text(rawValue, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    body: Center(
                      child: InteractiveViewer(
                        child: Image.network(
                          rawValue,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Failed to load preview.\nThis URL might not be an image.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            };
          _recognizers.add(recognizer);

          spans.addAll(_applySearchHighlight(
            stringValue,
            TextStyle(
              color: isDark ? Colors.blue[300] : Colors.blue[700],
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold,
            ),
            recognizer: recognizer,
          ));
        } else {
          spans.addAll(_applySearchHighlight(
            stringValue,
            const TextStyle(color: Colors.teal),
          ));
        }
      } else if (match.group(3) != null) {
        spans.addAll(_applySearchHighlight(
          match.group(3)!,
          const TextStyle(color: Colors.orange),
        ));
      } else if (match.group(4) != null) {
        spans.addAll(_applySearchHighlight(
          match.group(4)!,
          const TextStyle(color: Colors.redAccent),
        ));
      } else if (match.group(5) != null) {
        spans.addAll(_applySearchHighlight(
          match.group(5)!,
          TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < source.length) {
      spans.addAll(
          _applySearchHighlight(source.substring(lastIndex), defaultStyle));
    }

    return TextSpan(children: spans, style: defaultStyle);
  }
}
