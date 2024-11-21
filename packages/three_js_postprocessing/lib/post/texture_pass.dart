import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'package:three_js_postprocessing/shaders/copy_shader.dart';
import 'pass.dart';

class TexturePass extends Pass {
  late Texture map;
  late num opacity;
  // ShaderMaterial material;
  // dynamic fsQuad;

  TexturePass(this.map, [double? opacity]) : super() {
    final shader = copyShader;
    this.opacity = (opacity != null) ? opacity : 1.0;

    uniforms = UniformsUtils.clone(shader["uniforms"]);

    material =  ShaderMaterial.fromMap({
      "uniforms": uniforms,
      "vertexShader": shader["vertexShader"],
      "fragmentShader": shader["fragmentShader"],
      "depthTest": false,
      "depthWrite": false
    });

    needsSwap = false;

    fsQuad = FullScreenQuad(null);
  }

  @override
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,{double? deltaTime, bool? maskActive}) {
    final oldAutoClear = renderer.autoClear;
    renderer.autoClear = false;

    fsQuad.material = material;

    uniforms['opacity']["value"] = opacity;
    uniforms['tDiffuse']["value"] = map;
    material.transparent = (opacity < 1.0);

    renderer.setRenderTarget(renderToScreen ? null : readBuffer);
    if (clear) renderer.clear(true, true, true);
    fsQuad.render(renderer);

    renderer.autoClear = oldAutoClear;
  }
}
