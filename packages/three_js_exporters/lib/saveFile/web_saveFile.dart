import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as html;
import 'dart:async';
import 'dart:typed_data';

class SaveFile{
  static Future<void> saveBytes({
    required String printName,
    required String fileType,
    required Uint8List bytes,
    String? path,
  }) async {
    final blob = html.Blob([bytes].jsify() as JSArray<JSAny>);
    final url = html.URL.createObjectURL(blob);
    final anchor = html.document.createElement('a') as html.HTMLAnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = '$printName.$fileType';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.delete(anchor);
    html.URL.revokeObjectURL(url);
  }

  static Future<void> saveString({
    required String printName,
    required String fileType,
    required String data,
    String? path,
  }) async {
    final blob = html.Blob([data].jsify() as JSArray<JSAny>);
    final url = html.URL.createObjectURL(blob);
    final anchor = html.document.createElement('a') as html.HTMLAnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = '$printName.$fileType';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.delete(anchor);
    html.URL.revokeObjectURL(url);
  }
}