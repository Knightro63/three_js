import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:web/web.dart';
import 'package:image/image.dart' hide Color;
import 'package:three_js_core/three_js_core.dart' as core;
import 'package:three_js_math/three_js_math.dart';

class ImageExport{
  static Future<Uint8List?> decodeImageFromList(core.ImageElement element, bool flipY, int maxTextureSize) async {
    if(element.data is Uint8Array){
      ByteBuffer bytes = Uint8List.fromList((element.data as Uint8Array).toDartList()).buffer;
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
    else if(element.data is HTMLImageElement){
      Completer<Uint8List> c = Completer();
      final scale = maxTextureSize / math.max( element.width, element.height );

      final canvas = document.createElement( 'canvas' ) as HTMLCanvasElement;
      canvas.width = (element.width * math.min( 1, scale )).toInt();
      canvas.height = (element.height * math.min( 1, scale )).toInt();

      final context = canvas.getContext( '2d' ) as CanvasRenderingContext2D;

      if ( flipY) {
        context.translate( 0, canvas.height );
        context.scale( 1, - 1 );
      }

      context.drawImage( element.data, 0, 0, canvas.width, canvas.height );
      void Function(Blob) f = (Blob blob) async{
        JSPromise<JSArrayBuffer> jsp = blob.arrayBuffer();
        final array = await jsp.toDart;
        c.complete(array.toDart.asUint8List());
      };
			canvas.toBlob(f.toJS, 'image/png', 1.toJS );

      return c.future;
    }

    return null;
  }
}