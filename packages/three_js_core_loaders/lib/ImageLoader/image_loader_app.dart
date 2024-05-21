import 'dart:isolate';
import 'dart:io';
import '../utils/blob.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart';
import 'package:three_js_core/three_js_core.dart';

class ImageLoaderLoader {
  static Future<Image?> loadImage(url, bool flipY, {Function? imageDecoder}) async {
    final Image? image;
    if (imageDecoder == null) {
      final Uint8List? bytes;
      if (url is Blob) {
        bytes = url.data;
      } 
      else if (url.startsWith("http")) {
        final http.Response response = await http.get(Uri.parse(url));
        bytes = response.bodyBytes;
      } 
      else if (url.startsWith("assets") || url.startsWith("packages")) {
        final ByteData fileData = await rootBundle.load(url);
        bytes = Uint8List.view(fileData.buffer);
      } 
      else {
        final File file = File(url);
        bytes = await file.readAsBytes();
      }

      image = await compute(imageProcess, DecodeParam(bytes!, flipY, null));
    } 
    else {
      image = await imageDecoder(null, url);
    }

    return image;
  }
}

class DecodeParam {
  DecodeParam(
    this.bytes, 
    this.flipY, 
    this.sendPort
  );

  Uint8List? bytes;
  bool flipY;
  SendPort? sendPort;
}

void decodeIsolate(DecodeParam param) {
  if (param.bytes == null) {
    param.sendPort?.send(null);
    return;
  }

  // Read an image from file (webp in this case).
  // decodeImage will identify the format of the image and use the appropriate
  // decoder.
  var image2 = imageProcess(param);

  param.sendPort?.send(image2);
}

Image imageProcess(DecodeParam param) {
  Image image = decodeImage(param.bytes!)!;

  if (param.flipY) {
    image = flipVertical(image);
  }

  return image;
}

Future<ImageElement?> processImage(Uint8List? bytes, String? url, bool flipY) async{
  Image? image = bytes == null? null:decodeImage(bytes);
  if(image != null && flipY) {
    image = flipVertical(image);
  }
  image = image?.convert(format:Format.uint8,numChannels: 4);
  return image != null?ImageElement(
    url: url,
    src: url,
    data: Uint8Array.from(image.getBytes()),
    width: image.width,
    height: image.height
  ):null;
}