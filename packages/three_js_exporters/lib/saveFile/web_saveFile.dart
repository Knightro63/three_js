import 'package:universal_html/html.dart' as html;
import 'dart:async';
import 'dart:typed_data';

class SaveFile{
  static Future<void> saveBytes({
    required String printName,
    required String fileType,
    required Uint8List bytes,
    String? path,
  }) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = '$printName.$fileType';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> saveString({
    required String printName,
    required String fileType,
    required String data,
    String? path,
  }) async {
    final blob = html.Blob([data]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = '$printName.$fileType';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}