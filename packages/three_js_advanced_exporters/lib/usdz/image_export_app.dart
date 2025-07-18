import 'dart:typed_data';
import 'package:image/image.dart' hide Color;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class ImageExport{
  static Future<Uint8List?> decodeImageFromList(ImageElement element, bool flipY, int maxTextureSize) async {
    ByteBuffer bytes = Uint8List.fromList((element.data as Uint8Array).toDartList()).buffer;

    Image image = Image.fromBytes(
      width: element.width.toInt(), 
      height: element.height.toInt(), 
      bytes: bytes,
      numChannels: 4
    );//decodeImage(bytes);

    if(flipY) {
      image = flipVertical(image);
    }

    return encodePng(image);
  }
}