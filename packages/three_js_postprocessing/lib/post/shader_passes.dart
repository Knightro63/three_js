import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'pass.dart';

class ShaderPasses extends Pass {
  late dynamic textureID;
  late Color oldClearColor;
  late num oldClearAlpha;
  late bool oldAutoClear;
  late Color clearColor;
  List<dynamic>? passes;
  late Map<int, WebGLRenderTarget> renderTargetsPass;

  late int resx;
  late int resy;

  ShaderPasses(Map shader, String? textureID) : super() {
    this.textureID = (textureID != null) ? textureID : 'tDiffuse';

    uniforms = UniformsUtils.clone(shader["uniforms"]);
    passes = shader["passes"];

    clearColor = Color(0, 0, 0);
    oldClearColor = Color.fromHex32(0xffffff);

    Map<String, dynamic> defines = {};
    defines.addAll(shader["defines"] ?? {});
    material = ShaderMaterial.fromMap({
      "defines": defines,
      "uniforms": uniforms,
      "vertexShader": shader["vertexShader"],
      "fragmentShader": shader["fragmentShader"]
    });

    fsQuad = FullScreenQuad(material);
    renderTargetsPass = {};
  }

  @override
  void render(renderer, writeBuffer, readBuffer,{double? deltaTime, bool? maskActive}) {
    renderer.getClearColor(oldClearColor);
    oldClearAlpha = renderer.getClearAlpha();
    oldAutoClear = renderer.autoClear;
    renderer.autoClear = false;

    renderer.setClearColor(clearColor, 0.0);

    if (maskActive == true) renderer.state.buffers['stencil'].setTest(false);

    if (uniforms[textureID] != null) {
      uniforms[textureID]["value"] = readBuffer.texture;
    }

    if (passes != null) {
      int lastPass = passes!.length - 1;
      WebGLRenderTarget? lastRenderTarget;
      for (int i = 0; i <  passes!.length; i++) {
        material.uniforms["acPass"] = {"value": i};
        if (lastRenderTarget != null) {
          material.uniforms["acPassTexture"] = {
            "value": lastRenderTarget.texture
          };
        }

       material.needsUpdate = true;

        if (renderTargetsPass[i] == null) {
          final pars = WebGLRenderTargetOptions({
            "minFilter": LinearFilter,
            "magFilter": LinearFilter,
            "format": RGBAFormat
          });
          final renderTargetPass =
              WebGLRenderTarget(readBuffer.width, readBuffer.height, pars);
          renderTargetPass.texture.name = 'renderTargetPass $i';
          renderTargetPass.texture.generateMipmaps = false;
          renderTargetsPass[i] = renderTargetPass;
        }

        if (i >= lastPass) {
          if (renderToScreen) {
            renderPass(renderer, material, null, null, null, clear);
          } else {
            renderPass(renderer, material, writeBuffer, null, null, clear);
          }
        } else {
          renderPass(renderer, material, renderTargetsPass[i], null,null, clear);
        }

        lastRenderTarget = renderTargetsPass[i];

        i = i + 1;
      }
    } 
    else {
      if (renderToScreen) {
        renderPass(renderer, material, null, null, null, clear);
      } else {
        renderPass(renderer, material, writeBuffer, null, null, clear);
      }
    }
  }

  void renderPass(renderer, passMaterial, renderTarget, clearColor, clearAlpha, bool clear) {
    // print("renderPass passMaterial: ${passMaterial} renderTarget: ${renderTarget}  ");
    // print(passMaterial.uniforms);

    // setup pass state
    renderer.autoClear = false;

    renderer.setRenderTarget(renderTarget);

    if (clearColor != null) {
      renderer.setClearColor(clearColor);
      renderer.setClearAlpha(clearAlpha ?? 0.0);
      renderer.clear();
    }

    // TODO: Avoid using autoClear properties, see https://github.com/mrdoob/three.js/pull/15571#issuecomment-465669600
    if (clear){
      renderer.clear(renderer.autoClearColor, renderer.autoClearDepth,
          renderer.autoClearStencil);
    }

    fsQuad.material = passMaterial;
    fsQuad.render(renderer);

    // restore original state
    renderer.autoClear = oldAutoClear;
    renderer.setClearColor(oldClearColor);
    renderer.setClearAlpha(oldClearAlpha);
  }
}
