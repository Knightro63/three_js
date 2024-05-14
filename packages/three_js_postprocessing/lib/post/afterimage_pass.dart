import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_postprocessing/shaders/afterimage_shader.dart';
import "pass.dart";

class AfterimagePass extends Pass {
  late Map<String, dynamic> shader;
  late ShaderMaterial shaderMaterial;
  late WebGLRenderTarget textureComp;
  late WebGLRenderTarget textureOld;
  late FullScreenQuad compFsQuad;
  late FullScreenQuad copyFsQuad;

  AfterimagePass(double? damp, bufferSizeMap) : super() {
    shader = afterimageShader;

    uniforms = UniformsUtils.clone(shader["uniforms"]);

    uniforms['damp']["value"] = damp != null ? damp : 0.96;

    textureComp = WebGLRenderTarget(
        bufferSizeMap["width"],
        bufferSizeMap["height"],
        WebGLRenderTargetOptions({
          "minFilter": LinearFilter,
          "magFilter": NearestFilter,
          "format": RGBAFormat
        }));

    textureOld = WebGLRenderTarget(
        bufferSizeMap["width"],
        bufferSizeMap["height"],
        WebGLRenderTargetOptions({
          "minFilter": LinearFilter,
          "magFilter": NearestFilter,
          "format": RGBAFormat
        }));

    shaderMaterial = ShaderMaterial.fromMap({
      "uniforms": uniforms,
      "vertexShader": shader["vertexShader"],
      "fragmentShader": shader["fragmentShader"]
    });

    compFsQuad = FullScreenQuad(shaderMaterial);

    final material = MeshBasicMaterial();
    copyFsQuad = FullScreenQuad(material);
  }

  void render(renderer, writeBuffer, readBuffer,{double? deltaTime, bool? maskActive}) {
    uniforms['tOld']["value"] = textureOld.texture;
    uniforms['tNew']["value"] = readBuffer.texture;

    renderer.setRenderTarget(textureComp);
    compFsQuad.render(renderer);

    copyFsQuad.material?.map = textureComp.texture;

    if (renderToScreen) {
      renderer.setRenderTarget(null);
      copyFsQuad.render(renderer);
    } else {
      renderer.setRenderTarget(writeBuffer);

      if (clear) renderer.clear(true, true, true);

      copyFsQuad.render(renderer);
    }

    // Swap buffers.
    final temp = textureOld;
    textureOld = textureComp;
    textureComp = temp;
    // Now textureOld contains the latest image, ready for the next frame.
  }

  @override
  void setSize(int width, int height) {
    textureComp.setSize(width, height);
    textureOld.setSize(width, height);
  }
}
