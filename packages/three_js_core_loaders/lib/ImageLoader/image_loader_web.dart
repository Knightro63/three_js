import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:three_js_math/three_js_math.dart';

import '../utils/blob.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:image/image.dart';

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

// TODO: Fix this
Future<ImageElement?> processImage(Uint8List? bytes, String? url, bool flipY) {
  final completer = Completer<ImageElement>();
  if(bytes != null){
    Image? image = decodeImage(bytes);
    if(image != null && flipY) {
      image = flipVertical(image);
    }
    //image = image?.convert(format:Format.uint8,numChannels: 4);
    completer.complete(
      ImageElement(
        width: image!.width,
        height: image.height,
        data: Uint8Array.fromList(bytes)
      )
    );
  }
  else{
    final imageDom = html.ImageElement();
    imageDom.crossOrigin = "";
    imageDom.src = url;

    imageDom.onLoad.listen((e) {
      completer.complete(
        ImageElement(
          url: url,
          data: imageDom,
          width: imageDom.width!.toDouble(),
          height: imageDom.height!.toDouble()
        )
      );
    });
  }
  return completer.future;
}
