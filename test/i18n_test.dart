import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The map keys are English sentences, so a screen in French silently falls
/// back to English whenever a chrome string was added without an entry.
/// Reading the sources keeps this honest as the interface grows.
void main() {
  test('every L.t literal in lib has a French entry', () {
    final translated = _translatedKeys();
    final missing = <String>[];

    for (final file in _dartFiles('lib')) {
      for (final key in _literals(file)) {
        if (!translated.contains(key)) missing.add('$file: $key');
      }
    }

    expect(missing, isEmpty);
  });
}

Set<String> _translatedKeys() {
  final source = File('lib/l10n/strings.dart').readAsStringSync();
  const marker = 'const _fr = <String, String>{';
  final start = source.indexOf(marker);
  final body = source.substring(start + marker.length);
  final map = RegExp(r"'((?:[^'\\]|\\.)*)'\s*:").allMatches(body);
  return map.map((m) => _unescape(m.group(1)!)).toSet();
}

/// The `'a' 'b'` chains handed to `L.t(context, ...)` joined into one sentence.
List<String> _literals(String path) {
  final source = File(path).readAsStringSync();
  final call = RegExp(r"L\.[tf]\(\s*context,\s*((?:'(?:[^'\\]|\\.)*'\s*)+)\)");
  final chunks = RegExp(r"'((?:[^'\\]|\\.)*)'");
  return [
    for (final match in call.allMatches(source))
      chunks
          .allMatches(match.group(1)!)
          .map((chunk) => _unescape(chunk.group(1)!))
          .join(),
  ];
}

String _unescape(String text) =>
    text.replaceAll(r"\'", "'").replaceAll(r'\\', r'\');

List<String> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .where((path) => path != 'lib/l10n/strings.dart')
        .toList()
      ..sort();
