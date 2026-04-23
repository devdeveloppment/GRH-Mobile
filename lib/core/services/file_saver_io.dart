import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String?> saveFileBytes(List<int> bytes, String filename) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
