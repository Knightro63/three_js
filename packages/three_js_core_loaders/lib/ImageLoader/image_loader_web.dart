import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
//import 'dart:ui' as ui;
import 'package:web/web.dart' as html;
import 'dart:convert';
import 'package:three_js_core/three_js_core.dart';

import '../utils/blob.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ImageLoaderLoader {
  static Future<html.HTMLImageElement> loadImage(url, bool flipY,{Function? imageDecoder}) {
    final completer = Completer<html.HTMLImageElement>();
    final imageDom = html.HTMLImageElement();
    imageDom.crossOrigin = "anonymous";

    imageDom.onLoad.listen((e) {
      completer.complete(imageDom);
    });

    if (url is Blob) {
      final blob = html.Blob([(url.data as Uint8List).buffer.jsify()!].jsify()! as JSArray<JSAny>, url.options["type"]);
      imageDom.src = html.URL.createObjectURL(blob);
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

html.HTMLImageElement setDimensions(html.HTMLImageElement imageElement, String? dimensions) {
  if (dimensions == null || dimensions.isEmpty) {
    console.error("null or empty dimenstions String, could not set dimenstions");
    return imageElement;
  }

  List<String> dimensionsSplit = dimensions.split(',');

  if (dimensionsSplit.length != 2) {
    console.error("Error: could not split dimensions into 2 Strings");
    return imageElement;
  }

  int? width = int.tryParse(dimensionsSplit[0]);
  int? height = int.tryParse(dimensionsSplit[1]);

  if (width == null || height == null) {
    console.error("Error: could not parse dimensions from String $dimensions");
    return imageElement;
  }

  console.verbose("width is $width and height is $height");

  imageElement.width = width;
  imageElement.height = height;

  return imageElement;
}

// Future<List>? _getDimensions(Uint8List bytes) async{
//   final codec = await ui.instantiateImageCodec(bytes);
//   final frameInfo = await codec.getNextFrame();
//   final width = frameInfo.image.width;
//   final height = frameInfo.image.height;
//   frameInfo.image.dispose();

//   return [width, height];
// }

List? _getJpegDimensions(Uint8List bytes) {
  // Verify the JPEG header (SOI marker)
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
    return null; // Not a valid JPEG
  }

  int offset = 2;
  while (offset < bytes.length) {
    // Each segment in a JPEG file starts with 0xFF followed by a marker byte
    if (bytes[offset] != 0xFF) break;
    int marker = bytes[offset + 1];
    offset += 2;

    // Skip markers that do not contain size information
    if (marker == 0xC0 || marker == 0xC2) { // Start of Frame markers
      if (offset + 7 <= bytes.length) {
        // Extract height and width from the segment
        int height = (bytes[offset + 3] << 8) + bytes[offset + 4];
        int width = (bytes[offset + 5] << 8) + bytes[offset + 6];
        console.verbose("extracted width $width and height $height");
        return [width, height];
      } else {
        break;
      }
    } else {
      // Get the length of this segment
      int segmentLength = (bytes[offset] << 8) + bytes[offset + 1];
      offset += segmentLength;
    }
  }

  return null; // Dimensions not found
}

Future<html.HTMLImageElement> createImageElementFromBytes(Uint8List bytes, [String? dimensions]) async{
  // Convert bytes to a base64-encoded string
  final base64String = base64Encode(bytes);

  // Create a data URL using the base64 string
  final dataUrl = 'data:image/jpg;base64,$base64String';

  // Create an ImageElement and set its source to the data URL
  html.HTMLImageElement imageElement = html.HTMLImageElement();
  imageElement.src = dataUrl;
  //int start = DateTime.now().millisecondsSinceEpoch;
  //print(DateTime.now());
  List? dimensions = _getJpegDimensions(bytes);//await _getDimensions(bytes);//
  //print(DateTime.now().millisecondsSinceEpoch-start);
  //imageElement = setDimensions(imageElement, dimensions);
  if (dimensions != null) {
    console.verbose("extracted dimension width ${dimensions[0]} and height ${dimensions[1]}");
    imageElement.width = dimensions[0];
    imageElement.height = dimensions[1];
  } else {
    console.warning("could not extract dimensions from jpeg");
  }

  return imageElement;
}

Future<ImageElement?> processImageBlob(Blob blob, bool flipY) async{
  final hblob = html.Blob([blob.data.buffer].jsify() as JSArray<JSAny>);
  return await processImage(null, html.URL.createObjectURL(hblob),flipY);
}

// Fixed for web and bytes sent
Future<ImageElement?> processImage(Uint8List? bytes, String? url, bool flipY) async{
  final completer = Completer<ImageElement>();
  if(bytes != null){
    html.HTMLImageElement imageElement = await createImageElementFromBytes(bytes, url);
    //image = image?.convert(format:Format.uint8,numChannels: 4);
    completer.complete(
      ImageElement(
        url: url,
        data: imageElement,
        width: imageElement.width,
        height: imageElement.height
      )
    );
  }
  else{
    final imageDom = html.HTMLImageElement();
    imageDom.crossOrigin = "anonymous";
    imageDom.src = url!;

    imageDom.onLoad.listen((e) {
      completer.complete(
        ImageElement(
          url: url,
          data: imageDom,
          width: imageDom.width.toInt(),
          height: imageDom.height.toInt()
        )
      );
    });
  }
  return completer.future;
}