import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

import '../../materials/node_materials.dart';

/// This class represents a cube render target. It is a special version
/// of WebGLCubeRenderTarget which is compatible with WebGPURenderer.
class CubeRenderTarget extends RenderTarget {
  /// This flag can be used for type testing.
  final bool isCubeRenderTarget = true;

  /// Constructs a new cube render target layout module.
  /// 
  /// [size] - The uniform side length dimensions of the render target.
  /// [options] - Optional Map layer configuration properties flags.
  CubeRenderTarget([int size = 1, RenderTargetOptions? options]) 
      : super(size, size, options) {

    final Map<String, int> image = {
      'width': size,
      'height': size,
      'depth': 1
    };

    final List<Map<String, int>> images = [image, image, image, image, image, image];

    // Overwritten base texture with a customized type-safe CubeTexture layout mapping
    this.texture = CubeTexture(images);
    this.setTextureOptions(options ?? const {});

    // By convention -- likely based on the RenderMan spec from the 1990's -- cube maps are specified by WebGL (and three.js)
    // in a coordinate system in which positive-x is to the right when looking up the positive-z axis -- in other words,
    // in a left-handed coordinate system. By continuing this convention, preexisting cube maps continued to render correctly.
    // three.js uses a right-handed coordinate system. So environment maps used in three.js appear to have px and nx swapped
    // and the flag isRenderTargetTexture controls this conversion. The flip is not required when using WebGLCubeRenderTarget.texture
    // as a cube texture (this is detected when isRenderTargetTexture is set to true for cube textures).
    this.texture.isRenderTargetTexture = true;
  }

  /// Converts the given equirectangular environment texture into a 6-face cube map layout layer.
  /// 
  /// [renderer] - The execution renderer instance context.
  /// [texture] - The input equirectangular source texture wrapper.
  /// Returns a fluent reference to this cube render target layout.
  CubeRenderTarget fromEquirectangularTexture(Renderer renderer, Texture texture) {
    final int currentMinFilter = texture.minFilter;
    final bool currentGenerateMipmaps = texture.generateMipmaps == true;

    texture.generateMipmaps = true;
    this.texture.type = texture.type;
    this.texture.colorSpace = texture.colorSpace;
    this.texture.generateMipmaps = texture.generateMipmaps;
    this.texture.minFilter = texture.minFilter;
    this.texture.magFilter = texture.magFilter;

    final BoxGeometry geometry = BoxGeometry(5, 5, 5);
    final dynamic uvNode = equirectUV(positionWorldDirection);
    final NodeMaterial material = NodeMaterial();

    // Invoke texture node math references via standard TSL mapping closures
    material.colorNode = texture(texture, uvNode, float(0));
    material.side = BackSide;
    material.blending = NoBlending;

    final Mesh mesh = Mesh(geometry, material);
    final Scene scene = Scene();
    scene.add(mesh);

    // Avoid blurred poles alignment artifacts across raw floating coordinates lines
    if (texture.minFilter == LinearMipmapLinearFilter) {
      texture.minFilter = LinearFilter;
    }

    final CubeCamera camera = CubeCamera(1, 10, this);
    final dynamic currentMRT = renderer.getMRT();
    
    renderer.setMRT(null);
    camera.update(renderer, scene);
    renderer.setMRT(currentMRT);

    texture.minFilter = currentMinFilter;
    texture.generateMipmaps = currentGenerateMipmaps;

    mesh.geometry?.dispose();
    mesh.material?.dispose();

    return this;
  }

  /// Clears this cube render target faces entirely.
  /// 
  /// [renderer] - The main engine renderer instance driver.
  /// [color] - Whether the color buffer should be cleared or not.
  /// [depth] - Whether the depth buffer should be cleared or not.
  /// [stencil] - Whether the stencil buffer should be cleared or not.
  @override
  void clear(dynamic renderer, [bool color = true, bool depth = true, bool stencil = true]) {
    final dynamic currentRenderTarget = renderer.getRenderTarget();

    // Separately clear every individual face within the hardware target context loops
    for (int i = 0; i < 6; i++) {
      renderer.setRenderTarget(this, i);
      renderer.clear(color, depth, stencil);
    }

    renderer.setRenderTarget(currentRenderTarget);
  }
}
