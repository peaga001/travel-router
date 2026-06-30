// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

Future<void> saveJsonToFile(String content, String filename) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

// On web, FilePicker always provides bytes — this overload is never called.
Future<String> readFileByPath(String path) async =>
    throw UnsupportedError('Path-based file read is not supported on web');
