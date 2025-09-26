import 'package:three_js/three_js.dart' as three;

class Atlas{
  List<three.Texture> getTexturesFromAtlasFile(String atlasImgUrl, int tilesNum ) {
    final List<three.Texture> textures = [];

    for (int i = 0; i < tilesNum; i ++ ) {
      textures.add(three.Texture());
    }

    final loader = three.ImageLoader();
    loader.fromAsset(atlasImgUrl).then(( imageObj ) {
      final tileWidth = imageObj!.height;

      for (int i = 0; i < textures.length; i ++ ) {
        textures[ i ].colorSpace = three.SRGBColorSpace;
        textures[ i ].image = three.ImageElement(
          data: imageObj.data,
          width: tileWidth.toInt(),
          height: tileWidth.toInt()
        );
        textures[ i ].needsUpdate = true;
      }
    });

    return textures;
  }
}