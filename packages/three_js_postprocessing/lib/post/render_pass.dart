import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'pass.dart';

class RenderPass extends Pass {
  bool clearDepth = false;
  double? clearAlpha;
  Color? clearColor;
  Material? overrideMaterial;
  final Color _oldClearColor = Color();

  RenderPass(Object3D scene, Camera camera, [this.overrideMaterial, this.clearColor, this.clearAlpha = 0]): super() {
    this.scene = scene;
    this.camera = camera;

    clear = true;
    needsSwap = false;
  }

  @override
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, {double? deltaTime, bool? maskActive}) {
    final oldAutoClear = renderer.autoClear;
    renderer.autoClear = false;

    dynamic oldClearAlpha;
    Material? oldOverrideMaterial;

    if (overrideMaterial != null) {
      oldOverrideMaterial = scene.overrideMaterial;
      scene.overrideMaterial = overrideMaterial;
    }

    if (clearColor != null) {
      renderer.getClearColor(_oldClearColor);
      renderer.setClearColor(clearColor!, renderer.getClearAlpha());
    }

		if ( clearAlpha != null ) {
			oldClearAlpha = renderer.getClearAlpha();
			renderer.setClearAlpha( clearAlpha! );
		}

    if (clearDepth) {
      renderer.clearDepth();
    }

    renderer.setRenderTarget(renderToScreen ? null : readBuffer);

    // TODO: Avoid using autoClear properties, see https://github.com/mrdoob/three.js/pull/15571#issuecomment-465669600
    if (clear){
      renderer.clear(renderer.autoClearColor, renderer.autoClearDepth,renderer.autoClearStencil);
    }
    renderer.render(scene, camera);

    if (clearColor != null) {
      renderer.setClearColor(_oldClearColor, oldClearAlpha);
    }
		if ( clearAlpha != null ) {
			renderer.setClearAlpha( oldClearAlpha );
		}
    if (overrideMaterial != null) {
      scene.overrideMaterial = oldOverrideMaterial;
    }

    renderer.autoClear = oldAutoClear;
  }
}
