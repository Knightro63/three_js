import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'pass.dart';


class ShaderPass extends Pass {
  late dynamic textureID;

  ShaderPass([ShaderMaterial? shader, String? textureID]) : super() {
    this.textureID = (textureID != null) ? textureID : 'tDiffuse';

    if (shader != null) {
      uniforms = shader.uniforms;
      material = shader;
    } 

    fsQuad = FullScreenQuad(material);
  }

  ShaderPass.fromJson([Map? shader, String? textureID]):super(){
    this.textureID = (textureID != null) ? textureID : 'tDiffuse';

    uniforms = UniformsUtils.clone(shader?["uniforms"]);
    Map<String, dynamic> _defines = {};
    _defines.addAll(shader?["defines"] ?? {});

    material = ShaderMaterial.fromMap({
      "defines": _defines,
      "uniforms": uniforms,
      "vertexShader": shader?["vertexShader"],
      "fragmentShader": shader?["fragmentShader"]
    });

    fsQuad = FullScreenQuad(material);
  }

  @override
  void render(renderer, writeBuffer, readBuffer,
      {double? deltaTime, bool? maskActive}) {
    if (uniforms[textureID] != null) {
      uniforms[textureID]["value"] = readBuffer.texture;
    }

    fsQuad.material = material;

    if (renderToScreen) {
      renderer.setRenderTarget(null);
      fsQuad.render(renderer);
    } else {
      renderer.setRenderTarget(writeBuffer);
      // TODO: Avoid using autoClear properties, see https://github.com/mrdoob/three.js/pull/15571#issuecomment-465669600
      if (clear){
        renderer.clear(renderer.autoClearColor, renderer.autoClearDepth,renderer.autoClearStencil);
      }
      fsQuad.render(renderer);
    }
  }
}
