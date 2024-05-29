import 'package:three_js_core/textures/index.dart';
import 'package:three_js_math/three_js_math.dart';

/// This class can only be used in combination with
/// [WebGLRenderer.copyFramebufferToTexture]().
/// final pixelRatio = devicePixelRatio;
/// final textureSize = 128 * pixelRatio;
///
///```
/// // instantiate a framebuffer texture
/// final frameTexture = FramebufferTexture( textureSize, textureSize );
///
/// // calculate start position for copying part of the frame data
/// final vector = Vector2();
/// vector.x = (innerWidth * pixelRatio / 2 ) - ( textureSize / 2 );
/// vector.y = (innerHeight * pixelRatio / 2 ) - ( textureSize / 2 );
///
/// // render the scene
/// renderer.clear();
/// renderer.render( scene, camera );
///
/// // copy part of the rendered frame into the framebuffer texture
/// renderer.copyFramebufferToTexture( vector, frameTexture );
/// ```
/// 
/// 
class FramebufferTexture extends Texture {
  FramebufferTexture(int width, int height, [int format = RGBAFormat]):super(null, null, null, null, null, null, format) {
    this.format = format;
    image = ImageElement(
      width: width,
      height: height
    );
    magFilter = NearestFilter;
    minFilter = NearestFilter;
    generateMipmaps = false;
    needsUpdate = true;
  }
}
