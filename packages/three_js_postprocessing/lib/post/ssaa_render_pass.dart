import 'dart:convert';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'package:three_js_postprocessing/shaders/copy_shader.dart';
import 'pass.dart';
import 'dart:math' as math;

/**
*
* Supersample Anti-Aliasing Render Pass
*
* This manual approach to SSAA re-renders the scene ones for each sample with camera jitter and accumulates the results.
*
* References: https://en.wikipedia.org/wiki/Supersampling
*
*/

class SSAARenderPass extends Pass {
  int sampleLevel = 4;
  bool unbiased = true;
  Color clearColor = Color.fromHex32(0x000000);
  double clearAlpha = 0;
  Color _oldClearColor = Color(0, 0, 0);
  late Map<String, dynamic> copyUniforms;
  late ShaderMaterial copyMaterial;

  WebGLRenderTarget? sampleRenderTarget;

  SSAARenderPass(Scene scene, Camera camera, Color? clearColor, this.clearAlpha) : super() {
    this.scene = scene;
    this.camera = camera;

    sampleLevel = 4; // specified as n, where the number of samples is 2^n, so sampleLevel = 4, is 2^4 samples, 16.
    unbiased = true;

    // as we need to clear the buffer in this pass, clearColor must be set to something, defaults to black.
    this.clearColor = clearColor ?? Color.fromHex32(0x000000);
    _oldClearColor = Color(0, 0, 0);

    final postCopyShader = copyShader;
    copyUniforms = UniformsUtils.clone(postCopyShader["uniforms"]);

    copyMaterial = ShaderMaterial.fromMap({
      "uniforms": copyUniforms,
      "vertexShader": postCopyShader["vertexShader"],
      "fragmentShader": postCopyShader["fragmentShader"],
      "premultipliedAlpha": true,
      "transparent": true,
      "blending": AdditiveBlending,
      "depthTest": false,
      "depthWrite": false
    });

    fsQuad = FullScreenQuad(copyMaterial);
  }

  void dispose() {
    if (sampleRenderTarget != null) {
      sampleRenderTarget!.dispose();
      sampleRenderTarget = null;
    }
  }

  @override
  void setSize(int width, int height) {
    if (sampleRenderTarget != null){
      sampleRenderTarget!.setSize(width, height);
    }
  }

  @override
  void render(renderer, writeBuffer, readBuffer,
      {num? deltaTime, bool? maskActive}) {
    if (sampleRenderTarget == null) {
      sampleRenderTarget = WebGLRenderTarget(
          readBuffer.width,
          readBuffer.height,
          WebGLRenderTargetOptions({
            "minFilter": LinearFilter,
            "magFilter": LinearFilter,
            "format": RGBAFormat
          }));
      sampleRenderTarget!.texture.name = 'SSAARenderPass.sample';
    }

    final jitterOffsets = _jitterVectors[math.max(0, math.min(sampleLevel, 5))];

    final autoClear = renderer.autoClear;
    renderer.autoClear = false;

    renderer.getClearColor(_oldClearColor);
    final oldClearAlpha = renderer.getClearAlpha();

    final baseSampleWeight = 1.0 / jitterOffsets.length;
    const roundingRange = 1 / 32;
    copyUniforms['tDiffuse']["value"] = sampleRenderTarget!.texture;

    final viewOffset = {
      "fullWidth": readBuffer.width,
      "fullHeight": readBuffer.height,
      "offsetX": 0,
      "offsetY": 0,
      "width": readBuffer.width,
      "height": readBuffer.height
    };

    Map<String, dynamic> originalViewOffset = jsonDecode(jsonEncode(camera.view ?? {}));

    if (originalViewOffset["enabled"] == true){
      viewOffset.addAll(originalViewOffset);
    }

    // render the scene multiple times, each slightly jitter offset from the last and accumulate the results.
    for (int i = 0; i < jitterOffsets.length; i++) {
      final jitterOffset = jitterOffsets[i];

      if (camera.type == "PerspectiveCamera") {
        (camera as PerspectiveCamera).setViewOffset(
            viewOffset["fullWidth"],
            viewOffset["fullHeight"],
            viewOffset["offsetX"] + jitterOffset[0] * 0.0625,
            viewOffset["offsetY"] + jitterOffset[1] * 0.0625, // 0.0625 = 1 / 16

            viewOffset["width"],
            viewOffset["height"]);
      } else if (camera.type == "OrthographicCamera") {
        (camera as OrthographicCamera).setViewOffset(
            viewOffset["fullWidth"],
            viewOffset["fullHeight"],
            viewOffset["offsetX"] + jitterOffset[0] * 0.0625,
            viewOffset["offsetY"] + jitterOffset[1] * 0.0625, // 0.0625 = 1 / 16

            viewOffset["width"],
            viewOffset["height"]);
      }

      double sampleWeight = baseSampleWeight;

      if (unbiased) {
        // the theory is that equal weights for each sample lead to an accumulation of rounding errors.
        // The following equation varies the sampleWeight per sample so that it is uniformly distributed
        // across a range of values whose rounding errors cancel each other out.

        final uniformCenteredDistribution = (-0.5 + (i + 0.5) / jitterOffsets.length);
        sampleWeight += roundingRange * uniformCenteredDistribution;
      }

      copyUniforms['opacity']["value"] = sampleWeight;
      renderer.setClearColor(clearColor, clearAlpha);
      renderer.setRenderTarget(sampleRenderTarget);
      renderer.clear(true, true, true);
      renderer.render(scene, camera);

      renderer.setRenderTarget(renderToScreen ? null : writeBuffer);

      if (i == 0) {
        renderer.setClearColor(Color.fromHex32(0x000000),  0.0);
        renderer.clear(true, true, true);
      }

      fsQuad.render(renderer);
    }

    if (camera.type == "OrthographicCamera" &&
        originalViewOffset["enabled"] == true) {
      (camera as OrthographicCamera).setViewOffset(
          originalViewOffset["fullWidth"],
          originalViewOffset["fullHeight"],
          originalViewOffset["offsetX"],
          originalViewOffset["offsetY"],
          originalViewOffset["width"],
          originalViewOffset["height"]);
    } else if (camera.type == "PerspectiveCamera" &&
        originalViewOffset["enabled"] == true) {
      (camera as PerspectiveCamera).setViewOffset(
          originalViewOffset["fullWidth"],
          originalViewOffset["fullHeight"],
          originalViewOffset["offsetX"],
          originalViewOffset["offsetY"],
          originalViewOffset["width"],
          originalViewOffset["height"]);
    } else if (camera.type == "PerspectiveCamera") {
      (camera as PerspectiveCamera).clearViewOffset();
    } else if (camera.type == "OrthographicCamera") {
      (camera as OrthographicCamera).clearViewOffset();
    }

    renderer.autoClear = autoClear;
    renderer.setClearColor(_oldClearColor, oldClearAlpha);
  }
}

// These jitter vectors are specified in integers because it is easier.
// I am assuming a [-8,8) integer grid, but it needs to be mapped onto [-0.5,0.5)
// before being used, thus these integers need to be scaled by 1/16.
//
// Sample patterns reference: https://msdn.microsoft.com/en-us/library/windows/desktop/ff476218%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396
final _jitterVectors = [
  [
    [0, 0]
  ],
  [
    [4, 4],
    [-4, -4]
  ],
  [
    [-2, -6],
    [6, -2],
    [-6, 2],
    [2, 6]
  ],
  [
    [1, -3],
    [-1, 3],
    [5, 1],
    [-3, -5],
    [-5, 5],
    [-7, -1],
    [3, 7],
    [7, -7]
  ],
  [
    [1, 1],
    [-1, -3],
    [-3, 2],
    [4, -1],
    [-5, -2],
    [2, 5],
    [5, 3],
    [3, -5],
    [-2, 6],
    [0, -7],
    [-4, -6],
    [-6, 4],
    [-8, 0],
    [7, -4],
    [6, 7],
    [-7, -8]
  ],
  [
    [-4, -7],
    [-7, -5],
    [-3, -5],
    [-5, -4],
    [-1, -4],
    [-2, -2],
    [-6, -1],
    [-4, 0],
    [-7, 1],
    [-1, 2],
    [-6, 3],
    [-3, 3],
    [-7, 6],
    [-3, 6],
    [-5, 7],
    [-1, 7],
    [5, -7],
    [1, -6],
    [6, -5],
    [4, -4],
    [2, -3],
    [7, -2],
    [1, -1],
    [4, -1],
    [2, 1],
    [6, 2],
    [0, 4],
    [4, 4],
    [2, 5],
    [7, 5],
    [5, 6],
    [3, 7]
  ]
];
