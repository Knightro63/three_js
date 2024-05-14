import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_postprocessing/shaders/convolution_shader.dart';
import 'package:three_js_postprocessing/shaders/copy_shader.dart';
import "pass.dart";

class BloomPass extends Pass {
  late WebGLRenderTarget renderTargetX;
  late WebGLRenderTarget renderTargetY;
  late ShaderMaterial materialCopy;
  late Map<String, dynamic> convolutionUniforms;
  late ShaderMaterial materialConvolution;

  BloomPass(num? strength, num? kernelSize, double? sigma, int? resolution) : super() {
    strength = (strength != null) ? strength : 1;
    kernelSize = (kernelSize != null) ? kernelSize : 25;
    sigma = (sigma != null) ? sigma : 4.0;
    resolution = (resolution != null) ? resolution : 256;

    // render targets

    final pars = {
      "minFilter": LinearFilter,
      "magFilter": LinearFilter,
      "format": RGBAFormat
    };

    renderTargetX = WebGLRenderTarget(
        resolution, resolution, WebGLRenderTargetOptions(pars));
    renderTargetX.texture.name = 'BloomPass.x';
    renderTargetY = WebGLRenderTarget(
        resolution, resolution, WebGLRenderTargetOptions(pars));
    renderTargetY.texture.name = 'BloomPass.y';

    final postCopyShader = copyShader;

    uniforms = UniformsUtils.clone(postCopyShader["uniforms"]);

    uniforms['opacity']["value"] = strength;

    materialCopy = ShaderMaterial.fromMap({
      "uniforms": uniforms,
      "vertexShader": postCopyShader["vertexShader"],
      "fragmentShader": postCopyShader["fragmentShader"],
      "blending": AdditiveBlending,
      "transparent": true
    });

    final postConvolutionShader = convolutionShader;

    convolutionUniforms = UniformsUtils.clone(postConvolutionShader["uniforms"]);

    convolutionUniforms['uImageIncrement']["value"] = BloomPass.blurX;
    convolutionUniforms['cKernel']["value"] = convolutionShaderBuildKernel(sigma);

    materialConvolution = ShaderMaterial.fromMap({
      "uniforms": convolutionUniforms,
      "vertexShader": postConvolutionShader["vertexShader"],
      "fragmentShader": postConvolutionShader["fragmentShader"],
      "defines": {
        'KERNEL_SIZE_FLOAT': kernelSize.toStringAsFixed(1),
        'KERNEL_SIZE_INT': kernelSize.toStringAsFixed(0)
      }
    });

    needsSwap = false;

    fsQuad = FullScreenQuad(null);
  }

  @override
  void render(WebGLRenderer renderer, writeBuffer, readBuffer,{double? deltaTime, bool? maskActive}) {
    if (maskActive == true) renderer.state.buffers['stencil'].setTest(false);

    // Render quad with blured scene into texture (convolution pass 1)

    fsQuad.material = materialConvolution;

    convolutionUniforms['tDiffuse']["value"] = readBuffer.texture;
    convolutionUniforms['uImageIncrement']["value"] = BloomPass.blurX;

    renderer.setRenderTarget(renderTargetX);
    renderer.clear();
    fsQuad.render(renderer);

    // Render quad with blured scene into texture (convolution pass 2)

    convolutionUniforms['tDiffuse']["value"] = renderTargetX.texture;
    convolutionUniforms['uImageIncrement']["value"] = BloomPass.blurY;

    renderer.setRenderTarget(renderTargetY);
    renderer.clear();
    fsQuad.render(renderer);

    // Render original scene with superimposed blur to texture

    fsQuad.material = materialCopy;

    uniforms['tDiffuse']["value"] = renderTargetY.texture;

    if (maskActive == true) renderer.state.buffers['stencil'].setTest(true);

    renderer.setRenderTarget(readBuffer);
    if (clear) renderer.clear();
    fsQuad.render(renderer);
  }

  static Vector2 blurX = Vector2(0.001953125, 0.0);
  static Vector2 blurY = Vector2(0.0, 0.001953125);
}
