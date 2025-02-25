import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_postprocessing/shaders/dot_screen_shader.dart';
import "pass.dart";

class DotScreenPass extends Pass {
  DotScreenPass([Vector2? center, num? angle, num? scale]) : super() {
    final shader = dotScreenShader;

    uniforms = UniformsUtils.clone(shader["uniforms"]);

    if (center != null) uniforms['center']["value"].copy(center);
    if (angle != null) uniforms['angle']["value"] = angle;
    if (scale != null) uniforms['scale']["value"] = scale;

    material = ShaderMaterial.fromMap({
      "uniforms": uniforms,
      "vertexShader": shader["vertexShader"],
      "fragmentShader": shader["fragmentShader"]
    });

    fsQuad = FullScreenQuad(material);
  }

  @override
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,{double? deltaTime, bool? maskActive}) {
    uniforms['tDiffuse']["value"] = readBuffer.texture;
    uniforms['tSize']["value"].set(readBuffer.width, readBuffer.height);

    if (renderToScreen) {
      renderer.setRenderTarget(null);
      fsQuad.render(renderer);
    } else {
      renderer.setRenderTarget(writeBuffer);
      if (clear) renderer.clear();
      fsQuad.render(renderer);
    }
  }
}
