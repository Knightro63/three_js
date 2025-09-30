import 'package:three_js/three_js.dart' as three;
import 'package:web/web.dart' as html;

class Atlas{
  Future<List<three.Texture>> getTexturesFromAtlasFile(String atlasImgUrl, int tilesNum ) async{
    final List<three.Texture> textures = [];

    for (int i = 0; i < tilesNum; i ++ ) {
      textures.add(three.Texture());
    }

    final loader = three.ImageLoader();
    final imageObj = await loader.fromAsset(atlasImgUrl);

      html.HTMLCanvasElement canvas;
      html.CanvasRenderingContext2D context;
      final tileWidth = imageObj!.height;

      for (int i = 0; i < textures.length; i ++ ) {
        canvas = html.document.createElement( 'canvas' ) as html.HTMLCanvasElement;
        context = canvas.getContext( '2d' ) as html.CanvasRenderingContext2D;
        canvas.height = tileWidth.toInt();
        canvas.width = tileWidth.toInt();
        context.drawImage( imageObj.data, tileWidth * i, 0, tileWidth, tileWidth, 0, 0, tileWidth, tileWidth );
        
        textures[ i ].colorSpace = three.SRGBColorSpace;
        textures[ i ].image = three.ImageElement(
          data: canvas,
          width: tileWidth.toInt(),
          height: tileWidth.toInt()
        );
        textures[ i ].needsUpdate = true;
      }

    return textures;
  }
}