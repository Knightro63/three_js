import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import '../utils/blob.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:three_js_core/three_js_core.dart';

class ImageLoaderLoader {
  // flipY
  static Future<html.ImageElement> loadImage(url, bool flipY,{Function? imageDecoder}) {
    final completer = Completer<html.ImageElement>();
    final imageDom = html.ImageElement();
    imageDom.crossOrigin = "";

    imageDom.onLoad.listen((e) {
      completer.complete(imageDom);
    });

    if (url is Blob) {
      final blob = html.Blob([url.data.buffer], url.options["type"]);
      imageDom.src = html.Url.createObjectUrl(blob);
    } 
    else {
      if (url.startsWith("assets") || url.startsWith("packages")) {
        imageDom.src = "assets/$url";
      } 
      else {
        imageDom.src = url;
      }
    }

    return completer.future;
  }
}

ImageElement? imageProcess2(Uint8List? bytes, String? url, bool flipY) {
  final image = html.ImageElement(
    src: url,
  );
  return ImageElement(
    url: url,
    data: image,
    width: image.width ?? 1,
    height: image.height ?? 1
  );
}
