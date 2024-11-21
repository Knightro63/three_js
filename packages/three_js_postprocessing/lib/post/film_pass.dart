import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'package:three_js_postprocessing/shaders/film_shader.dart';
import 'pass.dart';

class FilmPass extends Pass {
  FilmPass({num? noiseIntensity, num? scanlinesIntensity, int? scanlinesCount, num? grayscale}): super() {
    final shader = filmShader;

    uniforms = UniformsUtils.clone(Map<String, dynamic>.from(shader["uniforms"]));

    material = ShaderMaterial.fromMap({
      "uniforms": uniforms,
      "vertexShader": shader["vertexShader"],
      "fragmentShader": shader["fragmentShader"]
    });

    if (grayscale != null) uniforms["grayscale"]["value"] = grayscale;
    if (noiseIntensity != null){
      uniforms["nIntensity"]["value"] = noiseIntensity;
    }
    if (scanlinesIntensity != null){
      uniforms["sIntensity"]["value"] = scanlinesIntensity;
    }
    if (scanlinesCount != null){
      uniforms["sCount"]["value"] = scanlinesCount;
    }

    fsQuad = FullScreenQuad(material);
  }

  @override
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,{double? deltaTime, bool? maskActive}) {
    uniforms['tDiffuse']["value"] = readBuffer.texture;
    uniforms['time']["value"] += deltaTime;

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
