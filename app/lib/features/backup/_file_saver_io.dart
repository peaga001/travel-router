import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveJsonToFile(String content, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content, encoding: utf8);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/json', name: filename)],
  );
}

Future<String> readFileByPath(String path) =>
    File(path).readAsString(encoding: utf8);
