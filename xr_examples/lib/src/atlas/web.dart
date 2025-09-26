import 'package:three_js/three_js.dart' as three;
import 'package:web/web.dart' as html;

class Atlas{
  List<three.Texture> getTexturesFromAtlasFile(String atlasImgUrl, int tilesNum ) {
    final List<three.Texture> textures = [];

    for (int i = 0; i < tilesNum; i ++ ) {
      textures.add(three.Texture());
    }

    final loader = three.ImageLoader();
    loader.fromAsset(atlasImgUrl).then(( imageObj ) {

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
    });

    return textures;
  }
}