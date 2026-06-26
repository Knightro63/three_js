import 'dart:typed_data';
import 'package:image/image.dart' hide Color;
import 'package:three_js_core/three_js_core.dart';

class ImageExport{
  static Future<Uint8List?> decodeImageFromList(ImageElement element, bool flipY, int maxTextureSize) async {
    final ByteBuffer bytes = element.data.buffer;

    Image image = Image.fromBytes(
      width: element.width.toInt(), 
      height: element.height.toInt(), 
      bytes: bytes,
      numChannels: 4
    );

    if(flipY) {
      image = flipVertical(image);
    }

    return encodePng(image);
  }
}