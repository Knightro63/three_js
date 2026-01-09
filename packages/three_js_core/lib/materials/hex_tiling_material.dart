import 'package:three_js_core/renderers/webgl/index.dart';
import 'package:three_js_core/three_js_core.dart';
import 'dart:math' as math;

/** 
Copyright (c) 2023-2024 Casey Primozic and others

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

class HexTilingParams {
  HexTilingParams({
    this.patchScale = 2,
    this.useContrastCorrectedBlending = true,
    this.lookupSkipThreshold = 0.01,
    this.textureSampleCoefficientExponent = 8
  });

  HexTilingParams.fromJson(Map<String,dynamic> json){
    patchScale = (json['patchScale'] ?? 2).toDouble();
    useContrastCorrectedBlending = json['useContrastCorrectedBlending'] ?? true;
    lookupSkipThreshold = (json['lookupSkipThreshold'] ?? 0.01).toDouble();
    textureSampleCoefficientExponent = (json['textureSampleCoefficientExponent'] ?? 8.0).toDouble();
  }

  /// Scale factor for the hexagonal tiles used to break up the texture.  This is the most important
  /// parameter for controlling the look of the hex tiling and likely needs to be adjusted for each
  /// texture.
  /// 
  /// Should be greater than zero and usually somewhere between 0.1 and 16, but the optimal
  /// value depends on the texture and the desired effect.
  /// 
  /// Larger values create smaller hexagonal tiles and break up the texture more.
  /// 
  /// **Default**: 2
  ///
  double patchScale = 2;
  
  /// If set to true, contrast-corrected blending will be used to blend between the texture samples.  This
  /// greatly improves the quality of the blending for most textures, but can sometimes create very bright
  /// or very dark patches if the texture has a lot of contrast.
  /// 
  /// See https://www.shadertoy.com/view/4dcSDr for a demo of the effect.
  /// 
  /////////Default**: `true`
  ///
  bool useContrastCorrectedBlending = true;
  
  /// The magnitude under which texture lookups will be skipped.
  /// 
  /// You probably don't need to change this.
  /// 
  /// **Default**: 0.01
  /// 
  /// ### Details
  /// 
  /// The hex tiling shader mixes between up to three texture samples per fragment.  As an optimization,
  /// if the magnitude of one particular mix is below this threshold, the texture lookup will be skipped to
  /// reduce GPU memory bandwidth usage.
  /// 
  /// If the final coefficient of a texture sample is less than `lookupSkipThreshold`, the texture lookup will
  /// be skipped.
  ///
  double lookupSkipThreshold = 0.01;
  
  /// The exponent to which texture sample coefficients are raised before comparing to `lookupSkipThreshold`.
  /// 
  /// Higher values make the shader more efficient but can make the borders between hexagonal tiles more visible.
  /// 
  /// Lower values make the shader less efficient and can cause detail to get washed out and make the texture
  /// look blurry and homogenized.
  /// 
  /// The default value works pretty well for most textures; you likely don't need to change this.
  /// 
  /// **Default**: 8
  /// 
  /// ### Details
  /// 
  /// The hex tiling shader mixes between up to three texture samples per fragment.  By raising the coefficients
  /// to a power, it's possible to make the threshold for skipping a texture lookup more or less steep.  Exponents
  /// greater than 1 make the threshold steeper, exponents less than 1 make the threshold less steep.
  /// 
  /// Higher exponents, when combined with `lookupSkipThreshold`, can be used to make the hex tiling shader
  /// more efficient by skipping some texture lookups and reducing GPU memory bandwidth usage.
  ///
  double textureSampleCoefficientExponent = 8;

  Map<String,dynamic> get json => {
    'patchScale': patchScale,
    'useContrastCorrectedBlending': useContrastCorrectedBlending,
    'lookupSkipThreshold': lookupSkipThreshold,
    'textureSampleCoefficientExponent': textureSampleCoefficientExponent,
  };

  dynamic operator [] (key) => json[key];
  void operator []=(String key, dynamic value) => setValueFromString(key, value);

  void setValueFromString(String key, dynamic value) {
    switch (key) {
      case 'patchScale':
        patchScale = value.toDouble();
        break;
      case 'useContrastCorrectedBlending':
        useContrastCorrectedBlending = value;
        break;
      case 'lookupSkipThreshold':
        lookupSkipThreshold = value.toDouble();
        break;
      case 'textureSampleCoefficientExponent':
        textureSampleCoefficientExponent = value.toInt();
        break;
      default:
    }
  }
}

class HexTilingMaterial extends MeshPhysicalMaterial {
  String generateId([int length = 13]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = math.Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  String get genRandomStringID => generateId()+generateId();

  HexTilingMaterial(this.hexTiling,[ Map<String,dynamic>? options]):super.fromMap(options){
    type = "HexTilingMaterial";
    if(hexTiling != null){
      patchMeshPhysicalMaterial();
      patchMaterial();
    }
  }
  /// Parameters for controlling the hex tiling from `three-hex-tiling`.
  ///
  /// If this parameter is not set, hex tiling will not be applied.
  ///
  /// This parameter cannot be changed after the material is created.
  ////
  HexTilingParams? hexTiling;
  String hexTilingID = 'NOT_SET';

  void patchMeshPhysicalMaterial(){
    final baseFragmentShader = shaderLib['physical']?['fragmentShader'];
    final fragmentShader = buildFragment(baseFragmentShader);
    shaderLib['physical']['fragmentShader'] = fragmentShader;

    (shaderLib['physical']['uniforms'] as Map).addAll(buildUniforms);
  }

  void patchMaterial(){
    final shaderMap = new Map<String, WebGLParameters>();

    this.onBeforeCompile = (WebGLParameters shader, WebGLRenderer renderer) {
      final hexTilingID = genRandomStringID;
      this.hexTilingID = hexTilingID;
      shaderMap[hexTilingID] = shader;

      if (this.hexTiling != null) {
        this.defines?['USE_THREE_HEX_TILING'] = "";
      }
    };

    this.customProgramCacheKey = (){
      return this.hexTiling != null? "1": "0";
    };

    // internal ID used to match the shader to the material so that the custom uniforms can be updated
    // from the material
    this.onBeforeRender = (
      WebGLRenderer? renderer,
      Scene? scene,
      Camera? camera,
      BufferGeometry? geometry,
      Object3D? object,
      Map<String, dynamic>? group
    ) {
      final shaderRef = shaderMap[hexTilingID];
      if (shaderRef == null) {
        return;
      }

      final params = this.hexTiling ?? HexTilingParams();

      shaderRef.uniforms!['hexTilingPatchScale']['value'] = params.patchScale;
      shaderRef.uniforms!['hexTilingUseContrastCorrectedBlending']['value'] = params.useContrastCorrectedBlending;
      shaderRef.uniforms!['hexTilingLookupSkipThreshold']['value'] = params.lookupSkipThreshold;
      shaderRef.uniforms!['hexTilingTextureSampleCoefficientExponent']['value'] = params.textureSampleCoefficientExponent;
    };
  }

  bool didPatchShaderChunks = false;
  final Map<String,dynamic> buildUniforms = {
    'hexTilingUseContrastCorrectedBlending': { 'value': true },
    'hexTilingPatchScale': { 'value': 6 },
    'hexTilingLookupSkipThreshold': { 'value': 0.01 },
    'hexTilingTextureSampleCoefficientExponent': { 'value': 8 },
  };

  String buildConditionalReplacer(
    String haystack,
    String toReplace,
    String replacement
  ){
    final updatedMatch = '''
      #ifdef USE_THREE_HEX_TILING
      $replacement
      #else
      $toReplace
      #endif
    ''';

    return haystack.replaceAll(toReplace, updatedMatch);
  }

  void patchShaderChunks(){
    shaderChunk['map_fragment'] = buildConditionalReplacer(
      shaderChunk['map_fragment']!,
      'vec4 sampledDiffuseColor = texture2D( map, vMapUv );',
      "vec4 sampledDiffuseColor = textureNoTileNeyret(map, vMapUv);"
    );

    shaderChunk['normal_fragment_maps'] = buildConditionalReplacer(
      shaderChunk['normal_fragment_maps']!,
      'normal = texture2D( normalMap, vNormalMapUv );',
      "normal = textureNoTileNeyret(normalMap, vNormalMapUv);"
    );

    shaderChunk['roughnessmap_fragment'] = buildConditionalReplacer(
      shaderChunk['roughnessmap_fragment']!,
      'vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );',
      "vec4 texelRoughness = textureNoTileNeyret(roughnessMap, vRoughnessMapUv);"
    );

    shaderChunk['metalnessmap_fragment'] = buildConditionalReplacer(
      shaderChunk['metalnessmap_fragment']!,
      'vec4 texelMetalness = texture2D( metalnessMap, vMetalnessMapUv );',
      "vec4 texelMetalness = textureNoTileNeyret(metalnessMap, vMetalnessMapUv);"
    );

    shaderChunk['tilebreaking_pars_fragment'] = tileBreakingNeyret;
  }

  String buildFragment(String baseFragmentShader){
    if (!didPatchShaderChunks) {
      didPatchShaderChunks = true;
      patchShaderChunks();
    }

    String fragment = baseFragmentShader;
    fragment = fragment.replaceAll(
      "void main() {",
      '''
      #include <tilebreaking_pars_fragment>

      void main() {
      '''
    );

    return fragment;
  }

  final String tileBreakingNeyret = '''
    #define rnd22(p) fract(sin((p) * mat2(127.1, 311.7, 269.5, 183.3)) * 43758.5453)
    // TODO: Figure out if this is correct for three.js
    #define srgb2rgb(V) pow(max(V, 0.), vec4(2.2)) // RGB <-> sRGB conversions
    #define rgb2srgb(V) pow(max(V, 0.), vec4(1. / 2.2))

    // (textureGrad handles MIPmap through patch borders)
    #define C(I)  (srgb2rgb(textureGrad(samp, U / hexTilingPatchScale - rnd22(I), Gx, Gy)) - meanColor * float(hexTilingUseContrastCorrectedBlending))

    uniform bool hexTilingUseContrastCorrectedBlending; // https://www.shadertoy.com/view/4dcSDr
    uniform float hexTilingPatchScale;
    uniform float hexTilingLookupSkipThreshold;
    uniform float hexTilingTextureSampleCoefficientExponent;

    vec4 textureNoTileNeyret(sampler2D samp, vec2 uv) {
        mat2 M0 = mat2(1, 0, .5, sqrt(3.) / 2.);
        mat2 M = inverse(M0);
        vec2 U = uv * hexTilingPatchScale / 8. * exp2(4. * 0.2 + 1.);
        vec2 V = M * U;
        vec2 I = floor(V);
        vec2 Gx = dFdx(U / hexTilingPatchScale), Gy = dFdy(U / hexTilingPatchScale);

        vec4 meanColor = hexTilingUseContrastCorrectedBlending ? srgb2rgb(texture(samp, U, 99.)) : vec4(0.);

        vec3 F = vec3(fract(V), 0), W;
        F.z = 1. - F.x - F.y;
        vec4 fragColor = vec4(0.);

        if (F.z > 0.) {
            W = vec3(F.z, F.y, F.x);
            W = pow(W, vec3(hexTilingTextureSampleCoefficientExponent));
            W = W / dot(W, vec3(1.));

            if (W.x > hexTilingLookupSkipThreshold) {
                fragColor += C(I) * W.x;
            }
            if (W.y > hexTilingLookupSkipThreshold) {
                fragColor += C(I + vec2(0, 1)) * W.y;
            }
            if (W.z > hexTilingLookupSkipThreshold) {
                fragColor += C(I + vec2(1, 0)) * W.z;
            }
        } else {
            W = vec3(-F.z, 1. - F.y, 1. - F.x);
            W = pow(W, vec3(hexTilingTextureSampleCoefficientExponent));
            W = W / dot(W, vec3(1.));

            if (W.x > hexTilingLookupSkipThreshold) {
                fragColor += C(I + 1.) * W.x;
            }
            if (W.y > hexTilingLookupSkipThreshold) {
                fragColor += C(I + vec2(1, 0)) * W.y;
            }
            if (W.z > hexTilingLookupSkipThreshold) {
                fragColor += C(I + vec2(0, 1)) * W.z;
            }
        }

        fragColor = hexTilingUseContrastCorrectedBlending ? meanColor + fragColor / length(W) : fragColor;

        fragColor = clamp(rgb2srgb(fragColor), 0., 1.);

        return fragColor;
    }
  ''';

  @override
  Map<String, dynamic> toJson({Object3dMeta? meta}) {
    final map = super.toJson();
    if (hexTiling != null) {
      map['hexTiling'] = hexTiling!.json;
    }
    return map;
  }
}