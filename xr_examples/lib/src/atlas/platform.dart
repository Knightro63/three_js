import 'package:three_js/three_js.dart' as three;
import 'dart:typed_data';
import 'package:image/image.dart' hide Color;
import 'package:three_js_math/three_js_math.dart';

class Atlas{
  List<three.Texture> getTexturesFromAtlasFile(String atlasImgUrl, int tilesNum ) {
    final List<three.Texture> textures = [];

    for (int i = 0; i < tilesNum; i ++ ) {
      textures.add(three.Texture());
    }

    final loader = three.ImageLoader(null,true);
    loader.fromAsset(atlasImgUrl).then(( imageObj ) {
      final int tileWidth = imageObj!.height.toInt();
      
      ByteBuffer bytes = Uint8List.fromList((imageObj.data as Uint8Array).toDartList()).buffer;
      Image image = Image.fromBytes(
        bytes: bytes,
        width: imageObj.width.toInt(),
        height: imageObj.height.toInt(),
        numChannels: 4
      );

      for (int i = 0; i < textures.length; i ++ ) {
        final canvas = copyCrop(
          image,
          x: tileWidth * i,
          y: 0,
          width: tileWidth,
          height: tileWidth,
        ).getBytes();
        textures[ i ].colorSpace = three.SRGBColorSpace;
        textures[ i ].image = three.ImageElement(
          data: Uint8Array.fromList(canvas),
          width: tileWidth,
          height: tileWidth
        );
        textures[ i ].needsUpdate = true;
      }
    });

    return textures;
  }
}