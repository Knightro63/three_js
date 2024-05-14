import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'package:three_js_postprocessing/shaders/copy_shader.dart';
import 'package:three_js_postprocessing/shaders/luminosity_high_pass_shader.dart';
import 'pass.dart';

/**
 * UnrealBloomPass is inspired by the bloom pass of Unreal Engine. It creates a
 * mip map chain of bloom textures and blurs them with different radii. Because
 * of the weighted combination of mips, and because larger blurs are done on
 * higher mips, this effect provides good quality and performance.
 *
 * Reference:
 * - https://docs.unrealengine.com/latest/INT/Engine/Rendering/PostProcessEffects/Bloom/
 */
class UnrealBloomPass extends Pass {
  static Vector2 blurDirectionX = Vector2(1.0, 0.0);
  static Vector2 blurDirectionY = Vector2(0.0, 1.0);

  late Vector2 resolution;
  late num strength;
  late double radius;
  late double threshold;
  late Color clearColor;
  late List<WebGLRenderTarget> renderTargetsHorizontal;
  late List<WebGLRenderTarget> renderTargetsVertical;
  late num nMips;
  late WebGLRenderTarget renderTargetBright;
  late Map<String, dynamic> highPassUniforms;
  late ShaderMaterial materialHighPassFilter;
  late List<ShaderMaterial> separableBlurMaterials;
  late ShaderMaterial compositeMaterial;
  late List<Vector3> bloomTintColors;
  late Map<String, dynamic> copyUniforms;
  late ShaderMaterial materialCopy;
  late Color oldClearColor;
  late double oldClearAlpha;
  late MeshBasicMaterial basic;

  UnrealBloomPass(Vector2? resolution, num? strength, double radius, double threshold): super() {
    this.strength = strength ?? 1.0;
    radius = radius;
    threshold = threshold;
    this.resolution = (resolution != null)
        ? Vector2(resolution.x, resolution.y)
        : Vector2(256, 256);

    uniforms = {
      "strength": {"value": this.strength}
    };

    // create color only once here, reuse it later inside the render function
    clearColor = Color(0, 0, 0);

    // render targets
    final pars = WebGLRenderTargetOptions({
      "minFilter": LinearFilter,
      "magFilter": LinearFilter,
      "format": RGBAFormat
    });
    renderTargetsHorizontal = [];
    renderTargetsVertical = [];
    nMips = 5;
    int resx = (this.resolution.x ~/ 2);
    int resy = (this.resolution.y ~/ 2);

    renderTargetBright = WebGLRenderTarget(resx, resy, pars);
    renderTargetBright.texture.name = 'UnrealBloomPass.bright';
    renderTargetBright.texture.generateMipmaps = false;

    for (int i = 0; i < nMips; i++) {
      final renderTargetHorizonal = WebGLRenderTarget(resx, resy, pars);

      renderTargetHorizonal.texture.name = 'UnrealBloomPass.h $i';
      renderTargetHorizonal.texture.generateMipmaps = false;

      renderTargetsHorizontal.add(renderTargetHorizonal);

      final renderTargetVertical = WebGLRenderTarget(resx, resy, pars);

      renderTargetVertical.texture.name = 'UnrealBloomPass.v $i';
      renderTargetVertical.texture.generateMipmaps = false;

      renderTargetsVertical.add(renderTargetVertical);

      resx = (resx ~/ 2);

      resy = (resy ~/ 2);
    }


    final highPassShader = luminosityHighPassShader;
    highPassUniforms = UniformsUtils.clone(highPassShader["uniforms"]);

    highPassUniforms['luminosityThreshold']["value"] = threshold;
    highPassUniforms['smoothWidth']["value"] = 0.01;

    materialHighPassFilter = ShaderMaterial.fromMap({
      "uniforms": highPassUniforms,
      "vertexShader": highPassShader["vertexShader"],
      "fragmentShader": highPassShader["fragmentShader"],
      "defines": Map<String, dynamic>()
    });

    // Gaussian Blur Materials
    separableBlurMaterials = [];
    final kernelSizeArray = [3, 5, 7, 9, 11];
    resx = (this.resolution.x ~/ 2);
    resy = (this.resolution.y ~/ 2);

    for (int i = 0; i < nMips; i++) {
      separableBlurMaterials
          .add(getSeperableBlurMaterial(kernelSizeArray[i]));

      separableBlurMaterials[i].uniforms['texSize']["value"] =
          Vector2(resx.toDouble(), resy.toDouble());

      resx = (resx ~/ 2);

      resy = (resy ~/ 2);
    }

    // Composite material
    compositeMaterial = getCompositeMaterial(nMips);
    compositeMaterial.uniforms['blurTexture1']["value"] =
        renderTargetsVertical[0].texture;
    compositeMaterial.uniforms['blurTexture2']["value"] =
        renderTargetsVertical[1].texture;
    compositeMaterial.uniforms['blurTexture3']["value"] =
        renderTargetsVertical[2].texture;
    compositeMaterial.uniforms['blurTexture4']["value"] =
        renderTargetsVertical[3].texture;
    compositeMaterial.uniforms['blurTexture5']["value"] =
        renderTargetsVertical[4].texture;
    compositeMaterial.uniforms['bloomStrength']["value"] = this.strength;
    compositeMaterial.uniforms['bloomRadius']["value"] = 0.1;
    compositeMaterial.needsUpdate = true;

    final bloomFactors = [1.0, 0.8, 0.6, 0.4, 0.2];
    compositeMaterial.uniforms['bloomFactors']["value"] = bloomFactors;
    bloomTintColors = [
      Vector3(1, 1, 1),
      Vector3(1, 1, 1),
      Vector3(1, 1, 1),
      Vector3(1, 1, 1),
      Vector3(1, 1, 1)
    ];
    compositeMaterial.uniforms['bloomTintColors']["value"] =
        bloomTintColors;

    final postCopyShader = copyShader;

    copyUniforms = UniformsUtils.clone(postCopyShader["uniforms"]);
    copyUniforms['opacity']["value"] = 1.0;

    materialCopy = ShaderMaterial.fromMap({
      "uniforms": copyUniforms,
      "vertexShader": postCopyShader["vertexShader"],
      "fragmentShader": postCopyShader["fragmentShader"],
      "blending": AdditiveBlending,
      "depthTest": false,
      "depthWrite": false,
      "transparent": true
    });

    enabled = true;
    needsSwap = false;

    oldClearColor = Color.fromHex32(0xffffff);
    oldClearAlpha = 0.0;

    basic = MeshBasicMaterial();

    fsQuad = FullScreenQuad(null);
  }

  void dispose() {
    for (int i = 0; i < renderTargetsHorizontal.length; i++) {
      renderTargetsHorizontal[i].dispose();
    }

    for (int i = 0; i < renderTargetsVertical.length; i++) {
      renderTargetsVertical[i].dispose();
    }

    renderTargetBright.dispose();
  }

  @override
  void setSize(int width, int height) {
    int resx = width ~/ 2;
    int resy = height ~/ 2;

    renderTargetBright.setSize(resx, resy);

    for (int i = 0; i < nMips; i++) {
      renderTargetsHorizontal[i].setSize(resx, resy);
      renderTargetsVertical[i].setSize(resx, resy);

      separableBlurMaterials[i].uniforms['texSize']["value"] =
          Vector2(resx.toDouble(), resy.toDouble());

      resx = resx ~/ 2;
      resy = resy ~/ 2;
    }
  }

  @override
  void render(renderer, writeBuffer, readBuffer,{double? deltaTime, bool? maskActive}) {
    renderer.getClearColor(oldClearColor);
    oldClearAlpha = renderer.getClearAlpha();
    final oldAutoClear = renderer.autoClear;
    renderer.autoClear = false;

    renderer.setClearColor(clearColor, 1);

    if (maskActive == true) renderer.state.buffers['stencil'].setTest(false);

    // Render input to screen

    if (renderToScreen) {
      fsQuad.material = basic;
      basic.map = readBuffer.texture;

      renderer.setRenderTarget(null);
      renderer.clear();
      fsQuad.render(renderer);
    }

    // 1. Extract Bright Areas

    highPassUniforms['tDiffuse']["value"] = readBuffer.texture;
    highPassUniforms['luminosityThreshold']["value"] = threshold;
    fsQuad.material = materialHighPassFilter;

    renderer.setRenderTarget(renderTargetBright);
    renderer.clear();
    fsQuad.render(renderer);

    // 2. Blur All the mips progressively

    RenderTarget inputRenderTarget = renderTargetBright;

    for (int i = 0; i < nMips; i++) {
      fsQuad.material = separableBlurMaterials[i];

      separableBlurMaterials[i].uniforms['colorTexture']["value"] =
          inputRenderTarget.texture;
      separableBlurMaterials[i].uniforms['direction']["value"] =
          UnrealBloomPass.blurDirectionX;
      renderer.setRenderTarget(renderTargetsHorizontal[i]);
      renderer.clear();
      fsQuad.render(renderer);

      separableBlurMaterials[i].uniforms['colorTexture']["value"] =
          renderTargetsHorizontal[i].texture;
      separableBlurMaterials[i].uniforms['direction']["value"] =
          UnrealBloomPass.blurDirectionY;
      renderer.setRenderTarget(renderTargetsVertical[i]);
      renderer.clear();
      fsQuad.render(renderer);

      inputRenderTarget = renderTargetsVertical[i];
    }

    // Composite All the mips

    fsQuad.material = compositeMaterial;
    compositeMaterial.uniforms['bloomStrength']["value"] = strength;
    compositeMaterial.uniforms['bloomRadius']["value"] = radius;
    compositeMaterial.uniforms['bloomTintColors']["value"] =
        bloomTintColors;

    renderer.setRenderTarget(renderTargetsHorizontal[0]);
    renderer.clear();
    fsQuad.render(renderer);

    // Blend it additively over the input texture

    fsQuad.material = materialCopy;
    copyUniforms['tDiffuse']["value"] =
        renderTargetsHorizontal[0].texture;

    if (maskActive == true) renderer.state.buffers['stencil'].setTest(true);

    if (renderToScreen) {
      renderer.setRenderTarget(null);
      fsQuad.render(renderer);
    } else {
      renderer.setRenderTarget(readBuffer);
      fsQuad.render(renderer);
    }

    // Restore renderer settings

    renderer.setClearColor(oldClearColor, oldClearAlpha);
    renderer.autoClear = oldAutoClear;
  }

  ShaderMaterial getSeperableBlurMaterial(num kernelRadius) {
    return ShaderMaterial.fromMap({
      "defines": {'KERNEL_RADIUS': kernelRadius, 'SIGMA': kernelRadius},
      "uniforms": {
        'colorTexture': {},
        'texSize': {"value": Vector2(0.5, 0.5)},
        'direction': {"value": Vector2(0.5, 0.5)}
      },
      "vertexShader": """
				varying vec2 vUv;
				void main() {
					vUv = uv;
					gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
				}
      """,
      "fragmentShader": """
				#include <common>
				varying vec2 vUv;
				uniform sampler2D colorTexture;
				uniform vec2 texSize;
				uniform vec2 direction;
				
				float gaussianPdf(in float x, in float sigma) {
					return 0.39894 * exp( -0.5 * x * x/( sigma * sigma))/sigma;
				}
				void main() {
					vec2 invSize = 1.0 / texSize;
					float fSigma = float(SIGMA);
					float weightSum = gaussianPdf(0.0, fSigma);
					vec3 diffuseSum = texture2D( colorTexture, vUv).rgb * weightSum;
					for( int i = 1; i < KERNEL_RADIUS; i ++ ) {
						float x = float(i);
						float w = gaussianPdf(x, fSigma);
						vec2 uvOffset = direction * invSize * x;
						vec3 sample1 = texture2D( colorTexture, vUv + uvOffset).rgb;
						vec3 sample2 = texture2D( colorTexture, vUv - uvOffset).rgb;
						diffuseSum += (sample1 + sample2) * w;
						weightSum += 2.0 * w;
					}
					gl_FragColor = vec4(diffuseSum/weightSum, 1.0);
				}
        
      """
    });
  }

  ShaderMaterial getCompositeMaterial(num nMips) {
    return ShaderMaterial.fromMap({
      "defines": {'NUM_MIPS': nMips},
      "uniforms": {
        'blurTexture1': {},
        'blurTexture2': {},
        'blurTexture3': {},
        'blurTexture4': {},
        'blurTexture5': {},
        'dirtTexture': {},
        'bloomStrength': {"value": 1.0},
        'bloomFactors': {},
        'bloomTintColors': {},
        'bloomRadius': {"value": 0.0}
      },
      "vertexShader": """
				varying vec2 vUv;
				void main() {
					vUv = uv;
					gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
				}
        """,
      "fragmentShader": """
				varying vec2 vUv;
				uniform sampler2D blurTexture1;
				uniform sampler2D blurTexture2;
				uniform sampler2D blurTexture3;
				uniform sampler2D blurTexture4;
				uniform sampler2D blurTexture5;
				uniform sampler2D dirtTexture;
				uniform float bloomStrength;
				uniform float bloomRadius;
				uniform float bloomFactors[NUM_MIPS];
				uniform vec3 bloomTintColors[NUM_MIPS];
				
				float lerpBloomFactor(const in float factor) {
					float mirrorFactor = 1.2 - factor;
					return mix(factor, mirrorFactor, bloomRadius);
				}
				
				void main() {
					gl_FragColor = bloomStrength * ( lerpBloomFactor(bloomFactors[0]) * vec4(bloomTintColors[0], 1.0) * texture2D(blurTexture1, vUv) + 
													 lerpBloomFactor(bloomFactors[1]) * vec4(bloomTintColors[1], 1.0) * texture2D(blurTexture2, vUv) + 
													 lerpBloomFactor(bloomFactors[2]) * vec4(bloomTintColors[2], 1.0) * texture2D(blurTexture3, vUv) + 
													 lerpBloomFactor(bloomFactors[3]) * vec4(bloomTintColors[3], 1.0) * texture2D(blurTexture4, vUv) + 
													 lerpBloomFactor(bloomFactors[4]) * vec4(bloomTintColors[4], 1.0) * texture2D(blurTexture5, vUv) );
				}
      """
    });
  }
}
