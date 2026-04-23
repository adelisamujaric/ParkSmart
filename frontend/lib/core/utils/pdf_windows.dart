import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

void openPdfInBrowser(List<int> bytes) async {
  print('>>> PDF WINDOWS called, bytes: ${bytes.length}');
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/report.pdf');
  await file.writeAsBytes(bytes);
  print('>>> PDF saved to: ${file.path}');
  await OpenFile.open(file.path);
  print('>>> PDF opened');
}