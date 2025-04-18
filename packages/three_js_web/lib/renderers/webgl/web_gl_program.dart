part of three_webgl;

int programIdCount = 0;
const COMPLETION_STATUS_KHR = 0x91B1;

class DefaultProgram {
  int id = -1;
}

class WebGLProgram extends DefaultProgram with WebGLProgramExtra {
  bool _didDispose = false;
  late String name;
  WebGLRenderer renderer;
  String cacheKey;
  WebGLBindingStates bindingStates;
  int usedTimes = 1;
  late RenderingContext gl;
  WebGLParameters parameters;
  late Program? program;

  late String vertexShader;
  late String fragmentShader;
  late Map<String, dynamic> diagnostics;

  WebGLUniforms? cachedUniforms;
  Map<String, AttributeLocations>? cachedAttributes;

  late Function(WebGLProgram) onFirstUse;

  WebGLProgram(this.renderer, this.cacheKey, this.parameters, this.bindingStates) {
    name = parameters.shaderName;
    id = programIdCount++;

    gl = renderer.getContext();
    program = gl.createProgram();
    init();
  }

  void dispose(){
    if(_didDispose) return;
    _didDispose = true;
    renderer.dispose();
    bindingStates.dispose();
    parameters.dispose();
    diagnostics.clear();
    cachedUniforms?.dispose();
    cachedAttributes?.clear();
  }

  void init() {
    final defines = parameters.defines;

    vertexShader = parameters.vertexShader;
    fragmentShader = parameters.fragmentShader;

    final shadowMapTypeDefine = generateShadowMapTypeDefine(parameters);
    final envMapTypeDefine = generateEnvMapTypeDefine(parameters);
    final envMapModeDefine = generateEnvMapModeDefine(parameters);
    final envMapBlendingDefine = generateEnvMapBlendingDefine(parameters);

    final envMapCubeUVSize = generateCubeUVSize(parameters);
    final customVertexExtensions = generateVertexExtensions( parameters );

    final customDefines = generateDefines( defines );
    
    program ??= gl.createProgram();

    String prefixVertex, prefixFragment;
    String versionString = parameters.glslVersion != null ? '#version ${parameters.glslVersion}\n' : '';

    if (parameters.isRawShaderMaterial) {
      prefixVertex = [
        '#define SHADER_TYPE ${parameters.shaderType}',
        '#define SHADER_NAME ${parameters.shaderName}',
        customDefines
      ].where((s) => filterEmptyLine(s)).join('\n');

      if (prefixVertex.isNotEmpty) {
        prefixVertex += "\n";
      }

      prefixFragment = [
        '#define SHADER_TYPE ${parameters.shaderType}',
        '#define SHADER_NAME ${parameters.shaderName}',
        customDefines
      ].where((s) => filterEmptyLine(s)).join('\n');

      if (prefixFragment.isNotEmpty) {
        prefixFragment += "\n";
      }
    } 
    else {
      prefixVertex = [
        generatePrecision(parameters),
        '#define SHADER_TYPE ${parameters.shaderType}',
        '#define SHADER_NAME ${parameters.shaderName}',

        customDefines,

        parameters.extensionClipCullDistance ? '#define USE_CLIP_DISTANCE' : '',
        parameters.batching ? '#define USE_BATCHING' : '',
        parameters.instancing ? '#define USE_INSTANCING' : '',
        parameters.instancingColor ? '#define USE_INSTANCING_COLOR' : '',
        parameters.instancingMorph ? '#define USE_INSTANCING_MORPH' : '',

        parameters.useFog && parameters.fog ? '#define USE_FOG' : '',
        parameters.useFog && parameters.fogExp2 ? '#define FOG_EXP2' : '',

        parameters.map ? '#define USE_MAP' : '',
        parameters.envMap ? '#define USE_ENVMAP' : '',
        parameters.envMap ? '#define $envMapModeDefine' : '',
        parameters.lightMap ? '#define USE_LIGHTMAP' : '',
        parameters.aoMap ? '#define USE_AOMAP' : '',
        parameters.bumpMap ? '#define USE_BUMPMAP' : '',
        parameters.normalMap ? '#define USE_NORMALMAP' : '',
        parameters.normalMapObjectSpace ? '#define USE_NORMALMAP_OBJECTSPACE' : '',
        parameters.normalMapTangentSpace ? '#define USE_NORMALMAP_TANGENTSPACE' : '',
        parameters.displacementMap ? '#define USE_DISPLACEMENTMAP' : '',
        parameters.emissiveMap ? '#define USE_EMISSIVEMAP' : '',

        parameters.anisotropy ? '#define USE_ANISOTROPY' : '',
        parameters.anisotropyMap ? '#define USE_ANISOTROPYMAP' : '',

        parameters.clearcoatMap ? '#define USE_CLEARCOATMAP' : '',
        parameters.clearcoatRoughnessMap ? '#define USE_CLEARCOAT_ROUGHNESSMAP' : '',
        parameters.clearcoatNormalMap ? '#define USE_CLEARCOAT_NORMALMAP' : '',

        parameters.iridescenceMap ? '#define USE_IRIDESCENCEMAP' : '',
        parameters.iridescenceThicknessMap ? '#define USE_IRIDESCENCE_THICKNESSMAP' : '',

        parameters.specularMap ? '#define USE_SPECULARMAP' : '',
        parameters.specularColorMap ? '#define USE_SPECULAR_COLORMAP' : '',
        parameters.specularIntensityMap ? '#define USE_SPECULAR_INTENSITYMAP' : '',

        parameters.roughnessMap ? '#define USE_ROUGHNESSMAP' : '',
        parameters.metalnessMap ? '#define USE_METALNESSMAP' : '',
        parameters.alphaMap ? '#define USE_ALPHAMAP' : '',
        parameters.alphaHash ? '#define USE_ALPHAHASH' : '',

        parameters.transmission ? '#define USE_TRANSMISSION' : '',
        parameters.transmissionMap ? '#define USE_TRANSMISSIONMAP' : '',
        parameters.thicknessMap ? '#define USE_THICKNESSMAP' : '',

        parameters.sheenColorMap ? '#define USE_SHEEN_COLORMAP' : '',
        parameters.sheenRoughnessMap ? '#define USE_SHEEN_ROUGHNESSMAP' : '',

        parameters.mapUv != null? '#define MAP_UV ${parameters.mapUv!}': '',
        parameters.alphaMapUv  != null? '#define ALPHAMAP_UV ${parameters.alphaMapUv!}': '',
        parameters.lightMapUv  != null? '#define LIGHTMAP_UV ${parameters.lightMapUv!}': '',
        parameters.aoMapUv  != null? '#define AOMAP_UV ${parameters.aoMapUv!}'  : '',
        parameters.emissiveMapUv  != null? '#define EMISSIVEMAP_UV ${parameters.emissiveMapUv!}'  : '',
        parameters.bumpMapUv  != null? '#define BUMPMAP_UV ${parameters.bumpMapUv!}' : '',
        parameters.normalMapUv  != null? '#define NORMALMAP_UV ${parameters.normalMapUv!}': '',
        parameters.displacementMapUv  != null? '#define DISPLACEMENTMAP_UV ${parameters.displacementMapUv!}': '',

        parameters.metalnessMapUv  != null? '#define METALNESSMAP_UV ${parameters.metalnessMapUv!}': '',
        parameters.roughnessMapUv  != null? '#define ROUGHNESSMAP_UV ${parameters.roughnessMapUv!}': '',

        parameters.anisotropyMapUv  != null? '#define ANISOTROPYMAP_UV ${parameters.anisotropyMapUv!}': '',

        parameters.clearcoatMapUv  != null? '#define CLEARCOATMAP_UV ${parameters.clearcoatMapUv!}': '',
        parameters.clearcoatNormalMapUv  != null? '#define CLEARCOAT_NORMALMAP_UV ${parameters.clearcoatNormalMapUv!}': '',
        parameters.clearcoatRoughnessMapUv  != null? '#define CLEARCOAT_ROUGHNESSMAP_UV ${parameters.clearcoatRoughnessMapUv!}' : '',

        parameters.iridescenceMapUv  != null? '#define IRIDESCENCEMAP_UV ${parameters.iridescenceMapUv!}': '',
        parameters.iridescenceThicknessMapUv  != null? '#define IRIDESCENCE_THICKNESSMAP_UV ${parameters.iridescenceThicknessMapUv!}': '',

        parameters.sheenColorMapUv  != null? '#define SHEEN_COLORMAP_UV ${parameters.sheenColorMapUv!}': '',
        parameters.sheenRoughnessMapUv  != null? '#define SHEEN_ROUGHNESSMAP_UV ${parameters.sheenRoughnessMapUv!}': '',

        parameters.specularMapUv  != null? '#define SPECULARMAP_UV ${parameters.specularMapUv!}': '',
        parameters.specularColorMapUv  != null? '#define SPECULAR_COLORMAP_UV ${parameters.specularColorMapUv!}': '',
        parameters.specularIntensityMapUv  != null? '#define SPECULAR_INTENSITYMAP_UV ${parameters.specularIntensityMapUv!}' : '',

        parameters.transmissionMapUv  != null? '#define TRANSMISSIONMAP_UV ${parameters.transmissionMapUv!}': '',
        parameters.thicknessMapUv  != null? '#define THICKNESSMAP_UV ${parameters.thicknessMapUv!}' : '',

        //

        parameters.vertexTangents && !parameters.flatShading? '#define USE_TANGENT' : '',
        parameters.vertexColors ? '#define USE_COLOR' : '',
        parameters.vertexAlphas ? '#define USE_COLOR_ALPHA' : '',
        parameters.vertexUv1s ? '#define USE_UV1' : '',
        parameters.vertexUv2s ? '#define USE_UV2' : '',
        parameters.vertexUv3s ? '#define USE_UV3' : '',

        parameters.pointsUvs ? '#define USE_POINTS_UV' : '',

        parameters.flatShading ? '#define FLAT_SHADED' : '',

        parameters.skinning ? '#define USE_SKINNING' : '',

        parameters.morphTargets ? '#define USE_MORPHTARGETS' : '',
        parameters.morphNormals && !parameters.flatShading? '#define USE_MORPHNORMALS' : '',
        ( parameters.morphColors ) ? '#define USE_MORPHCOLORS' : '',
        ( parameters.morphTargetsCount > 0 ) ? '#define MORPHTARGETS_TEXTURE' : '',
        ( parameters.morphTargetsCount > 0 ) ? '#define MORPHTARGETS_TEXTURE_STRIDE ${parameters.morphTextureStride}' : '',
        ( parameters.morphTargetsCount > 0 ) ? '#define MORPHTARGETS_COUNT ${parameters.morphTargetsCount}': '',
        parameters.doubleSided ? '#define DOUBLE_SIDED' : '',
        parameters.flipSided ? '#define FLIP_SIDED' : '',

        parameters.shadowMapEnabled ? '#define USE_SHADOWMAP' : '',
        parameters.shadowMapEnabled ? '#define $shadowMapTypeDefine': '',

        parameters.sizeAttenuation ? '#define USE_SIZEATTENUATION' : '',

        parameters.numLightProbes > 0 ? '#define USE_LIGHT_PROBES' : '',

        parameters.useLegacyLights ? '#define LEGACY_LIGHTS' : '',

        parameters.logarithmicDepthBuffer ? '#define USE_LOGDEPTHBUF' : '',

        'uniform mat4 modelMatrix;',
        'uniform mat4 modelViewMatrix;',
        'uniform mat4 projectionMatrix;',
        'uniform mat4 viewMatrix;',
        'uniform mat3 normalMatrix;',
        'uniform vec3 cameraPosition;',
        'uniform bool isOrthographic;',
        '#ifdef USE_INSTANCING',
        '	attribute mat4 instanceMatrix;',
        '#endif',
        '#ifdef USE_INSTANCING_COLOR',
        '	attribute vec3 instanceColor;',
        '#endif',

        '#ifdef USE_INSTANCING_MORPH',
        '	uniform sampler2D morphTexture;',
        '#endif',

        'attribute vec3 position;',
        'attribute vec3 normal;',
        'attribute vec2 uv;',

        '#ifdef USE_UV1',
        '	attribute vec2 uv1;',
        '#endif',
        '#ifdef USE_UV2',
        '	attribute vec2 uv2;',
        '#endif',
        '#ifdef USE_UV3',
        '	attribute vec2 uv3;',
        '#endif',

        '#ifdef USE_TANGENT',
        '	attribute vec4 tangent;',
        '#endif',
        '#if defined( USE_COLOR_ALPHA )',
        '	attribute vec4 color;',
        '#elif defined( USE_COLOR )',
        '	attribute vec3 color;',
        '#endif',
        '#if ( defined( USE_MORPHTARGETS ) && ! defined( MORPHTARGETS_TEXTURE ) )',
        '	attribute vec3 morphTarget0;',
        '	attribute vec3 morphTarget1;',
        '	attribute vec3 morphTarget2;',
        '	attribute vec3 morphTarget3;',
        '	#ifdef USE_MORPHNORMALS',
        '		attribute vec3 morphNormal0;',
        '		attribute vec3 morphNormal1;',
        '		attribute vec3 morphNormal2;',
        '		attribute vec3 morphNormal3;',
        '	#else',
        '		attribute vec3 morphTarget4;',
        '		attribute vec3 morphTarget5;',
        '		attribute vec3 morphTarget6;',
        '		attribute vec3 morphTarget7;',
        '	#endif',
        '#endif',
        '#ifdef USE_SKINNING',
        '	attribute vec4 skinIndex;',
        '	attribute vec4 skinWeight;',
        '#endif',
        '\n'
      ].where((s) => filterEmptyLine(s)).join('\n');
      
      prefixFragment = [
        generatePrecision(parameters),

        '#define SHADER_TYPE ${parameters.shaderType}',
        '#define SHADER_NAME ${parameters.shaderName}',

        customDefines,

        parameters.useFog && parameters.fog ? '#define USE_FOG' : '',
        parameters.useFog && parameters.fogExp2 ? '#define FOG_EXP2' : '',

        parameters.alphaToCoverage ? '#define ALPHA_TO_COVERAGE' : '',
        parameters.map ? '#define USE_MAP' : '',
        parameters.matcap ? '#define USE_MATCAP' : '',
        parameters.envMap ? '#define USE_ENVMAP' : '',
        parameters.envMap ? '#define $envMapTypeDefine': '',
        parameters.envMap ? '#define $envMapModeDefine': '',
        parameters.envMap ? '#define $envMapBlendingDefine': '',
        envMapCubeUVSize != null? '#define CUBEUV_TEXEL_WIDTH ${envMapCubeUVSize['texelWidth']}': '',
        envMapCubeUVSize != null? '#define CUBEUV_TEXEL_HEIGHT ${envMapCubeUVSize['texelHeight']}' : '',
        envMapCubeUVSize != null? '#define CUBEUV_MAX_MIP ${envMapCubeUVSize['maxMip']}.0' : '',
        
        parameters.lightMap ? '#define USE_LIGHTMAP' : '',
        parameters.aoMap ? '#define USE_AOMAP' : '',
        parameters.bumpMap ? '#define USE_BUMPMAP' : '',
        parameters.normalMap ? '#define USE_NORMALMAP' : '',
        parameters.normalMapObjectSpace ? '#define USE_NORMALMAP_OBJECTSPACE' : '',
        parameters.normalMapTangentSpace ? '#define USE_NORMALMAP_TANGENTSPACE' : '',
        parameters.emissiveMap ? '#define USE_EMISSIVEMAP' : '',

        parameters.anisotropy ? '#define USE_ANISOTROPY' : '',
        parameters.anisotropyMap ? '#define USE_ANISOTROPYMAP' : '',

        parameters.clearcoat ? '#define USE_CLEARCOAT' : '',
        parameters.clearcoatMap ? '#define USE_CLEARCOATMAP' : '',
        parameters.clearcoatRoughnessMap ? '#define USE_CLEARCOAT_ROUGHNESSMAP' : '',
        parameters.clearcoatNormalMap ? '#define USE_CLEARCOAT_NORMALMAP' : '',

        parameters.dispersion ? '#define USE_DISPERSION' : '',

        parameters.iridescence ? '#define USE_IRIDESCENCE' : '',
        parameters.iridescenceMap ? '#define USE_IRIDESCENCEMAP' : '',
        parameters.iridescenceThicknessMap ? '#define USE_IRIDESCENCE_THICKNESSMAP' : '',

        parameters.specularMap ? '#define USE_SPECULARMAP' : '',
        parameters.specularColorMap ? '#define USE_SPECULAR_COLORMAP' : '',
        parameters.specularIntensityMap ? '#define USE_SPECULAR_INTENSITYMAP' : '',

        parameters.roughnessMap ? '#define USE_ROUGHNESSMAP' : '',
        parameters.metalnessMap ? '#define USE_METALNESSMAP' : '',

        parameters.alphaMap ? '#define USE_ALPHAMAP' : '',
        parameters.alphaTest ? '#define USE_ALPHATEST' : '',
        parameters.alphaHash ? '#define USE_ALPHAHASH' : '',

        parameters.sheen ? '#define USE_SHEEN' : '',
        parameters.sheenColorMap ? '#define USE_SHEEN_COLORMAP' : '',
        parameters.sheenRoughnessMap ? '#define USE_SHEEN_ROUGHNESSMAP' : '',

        parameters.transmission ? '#define USE_TRANSMISSION' : '',
        parameters.transmissionMap ? '#define USE_TRANSMISSIONMAP' : '',
        parameters.thicknessMap ? '#define USE_THICKNESSMAP' : '',

        parameters.vertexTangents && !parameters.flatShading? '#define USE_TANGENT' : '',
        parameters.vertexColors || parameters.instancingColor ? '#define USE_COLOR' : '',
        parameters.vertexAlphas ? '#define USE_COLOR_ALPHA' : '',
        parameters.vertexUv1s ? '#define USE_UV1' : '',
        parameters.vertexUv2s ? '#define USE_UV2' : '',
        parameters.vertexUv3s ? '#define USE_UV3' : '',

        parameters.pointsUvs ? '#define USE_POINTS_UV' : '',

        parameters.gradientMap ? '#define USE_GRADIENTMAP' : '',

        parameters.flatShading ? '#define FLAT_SHADED' : '',

        parameters.doubleSided ? '#define DOUBLE_SIDED' : '',
        parameters.flipSided ? '#define FLIP_SIDED' : '',

        parameters.shadowMapEnabled ? '#define USE_SHADOWMAP' : '',
        parameters.shadowMapEnabled ? '#define $shadowMapTypeDefine': '',

        parameters.premultipliedAlpha ? '#define PREMULTIPLIED_ALPHA' : '',

        parameters.numLightProbes > 0 ? '#define USE_LIGHT_PROBES' : '',

        parameters.useLegacyLights ? '#define LEGACY_LIGHTS' : '',

        parameters.decodeVideoTexture ? '#define DECODE_VIDEO_TEXTURE' : '',

        parameters.logarithmicDepthBuffer ? '#define USE_LOGDEPTHBUF' : '',

        'uniform mat4 viewMatrix;',
        'uniform vec3 cameraPosition;',
        'uniform bool isOrthographic;',

        ( parameters.toneMapping != NoToneMapping ) ? '#define TONE_MAPPING' : '',
        ( parameters.toneMapping != NoToneMapping ) ? shaderChunk[ 'tonemapping_pars_fragment' ] : '', // this code is required here because it is used by the toneMapping() function defined below
        ( parameters.toneMapping != NoToneMapping ) ? getToneMappingFunction( 'toneMapping', parameters.toneMapping ) : '',

        parameters.dithering ? '#define DITHERING' : '',
        parameters.opaque ? '#define OPAQUE' : '',

        shaderChunk[ 'colorspace_pars_fragment' ], // this code is required here because it is used by the various encoding/decoding function defined below
        getTexelEncodingFunction( 'linearToOutputTexel', parameters.outputColorSpace ),

        parameters.useDepthPacking ? '#define DEPTH_PACKING ${parameters.depthPacking}': '',

        '\n'
      ].where((s) => filterEmptyLine(s)).join('\n');
    }

    vertexShader = resolveIncludes(vertexShader);
    vertexShader = replaceLightNums(vertexShader, parameters);
    vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

    fragmentShader = resolveIncludes(fragmentShader);
    fragmentShader = replaceLightNums(fragmentShader, parameters);
    fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

    vertexShader = unrollLoops(vertexShader);
    fragmentShader = unrollLoops(fragmentShader);

    if (!parameters.isRawShaderMaterial) {
      // GLSL 3.0 conversion for built-in materials and ShaderMaterial
      versionString = "#version 300 es\n";

      prefixVertex = '${[
        customVertexExtensions,
        '#define attribute in',
        '#define varying out',
        '#define texture2D texture'
      ].join('\n')}\n$prefixVertex';

      prefixFragment = '${[
        '#define varying in',
        (parameters.glslVersion == GLSL3) ? '' : 'layout(location = 0) out highp vec4 pc_fragColor;',
        (parameters.glslVersion == GLSL3) ? '' : '#define gl_FragColor pc_fragColor',
        '#define gl_FragDepthEXT gl_FragDepth',
        '#define texture2D texture',
        '#define textureCube texture',
        '#define texture2DProj textureProj',
        '#define texture2DLodEXT textureLod',
        '#define texture2DProjLodEXT textureProjLod',
        '#define textureCubeLodEXT textureLod',
        '#define texture2DGradEXT textureGrad',
        '#define texture2DProjGradEXT textureProjGrad',
        '#define textureCubeGradEXT textureGrad'
      ].join('\n')}\n$prefixFragment';
    }

    String vertexGlsl = versionString + prefixVertex + vertexShader;
    String fragmentGlsl = versionString + prefixFragment + fragmentShader;

    final glVertexShader = WebGLShader(gl, WebGL.VERTEX_SHADER, vertexGlsl);
    final glFragmentShader = WebGLShader(gl, WebGL.FRAGMENT_SHADER, fragmentGlsl);

    gl.attachShader(program!, glVertexShader.shader);
    gl.attachShader(program!, glFragmentShader.shader);

    // Force a particular attribute to index 0.

    if (parameters.index0AttributeName != null) {
      gl.bindAttribLocation(program!, 0, parameters.index0AttributeName ?? '');
    } else if (parameters.morphTargets == true) {
      // programs with morphTargets displace position out of attribute 0
      gl.bindAttribLocation(program!, 0, 'position');
    }

    gl.linkProgram(program!);
    onFirstUse = (WebGLProgram self ) {
      // check for link errors
      if (renderer.debug["checkShaderErrors"]) {
        final programLog = gl.getProgramInfoLog(program!)?.trim();
        final vertexLog = gl.getShaderInfoLog(glVertexShader.shader)?.trim();
        final fragmentLog = gl.getShaderInfoLog(glFragmentShader.shader)?.trim();

        bool runnable = true;
        bool haveDiagnostics = true;

        if (gl.getProgramParameter(program!, WebGL.LINK_STATUS).id == 0) {
          runnable = false;

          final vertexErrors = getShaderErrors(gl, glVertexShader, 'vertex');
          final fragmentErrors = getShaderErrors(gl, glFragmentShader, 'fragment');

          console.error('WebGLProgram: shader error: ${gl.getError()} gl.VALIDATE_STATUS ${gl.getProgramParameter(program!, WebGL.VALIDATE_STATUS)} gl.getProgramInfoLog $programLog  $vertexErrors $fragmentErrors ');
        } else if (programLog != '' && programLog != null) {
          console.error('WebGLProgram: gl.getProgramInfoLog() programLog: $programLog vertexLog: $vertexLog fragmentLog: $fragmentLog ');
        } else if (vertexLog == '' || fragmentLog == '') {
          haveDiagnostics = false;
        }

        if (haveDiagnostics) {
          self.diagnostics = {
            "runnable": runnable,
            "programLog": programLog,
            "vertexShader": {"log": vertexLog, "prefix": prefixVertex},
            "fragmentShader": {"log": fragmentLog, "prefix": prefixFragment}
          };
        }
      }

      gl.deleteShader(glVertexShader.shader);
      gl.deleteShader(glFragmentShader.shader);

      cachedUniforms = WebGLUniforms( gl, this );
      cachedAttributes = fetchAttributeLocations( gl, program! );
    };
  }
  // set up caching for attribute locations

  WebGLUniforms getUniforms() {
		if ( cachedUniforms == null ) {
			onFirstUse.call(this);
		}
    return cachedUniforms!;
  }

  Map<String, AttributeLocations> getAttributes() {
		if ( cachedUniforms == null ) {
			onFirstUse.call(this);
		}

    return cachedAttributes!;
  }

	bool get programReady => ( parameters.rendererExtensionParallelShaderCompile == false );
  set programReady(value){
    return value;
  }
	bool isReady() {
		if ( programReady == false ) {
			programReady = gl.getProgramParameter( program!, COMPLETION_STATUS_KHR ).id;
		}
		return programReady;
	}

  // free resource
  void destroy() {
    bindingStates.releaseStatesOfProgram(this);
    gl.deleteProgram(program!);
    program = null;
  }
}
