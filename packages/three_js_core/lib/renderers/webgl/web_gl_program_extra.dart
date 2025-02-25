part of three_webgl;

class AttributeLocations{
  AttributeLocations({
    this.location,
    this.locationSize = 0,
    this.type = 0
  });

  final dynamic location;
  final int type;//: info.type,
  //"location": gl.getAttribLocation(program, name),
  final int locationSize;//: locationSize
}

mixin WebGLProgramExtra {
  String handleSource(String? string, int errorLine) {
    final lines = string?.split('\n') ?? [];
    final lines2 = [];

    int from = math.max(errorLine - 6, 0);
    int to = math.min(errorLine + 6, lines.length);

    for (int i = 0; i < lines.length; i++) {
      lines[i] = "${(i + 1)}: ${lines[i]}";
    }

    for (int i = from; i < to; i++) {
      lines2.add("${(i + 1)}: ${lines[i]}");
    }

    return lines2.join('\n');
  }

  List<String> getEncodingComponents(String colorSpace) {
    final workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
    final encodingPrimaries = ColorManagement.getPrimaries(ColorSpace.fromString(colorSpace));

    String gamutMapping = '';

    if ( workingPrimaries == encodingPrimaries ) {
      gamutMapping = '';
    } else if ( workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries ) {
      gamutMapping = 'LinearDisplayP3ToLinearSRGB';
    } else if ( workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries ) {
      gamutMapping = 'LinearSRGBToLinearDisplayP3';
    }

    switch ( colorSpace ) {
      case LinearSRGBColorSpace:
      case LinearDisplayP3ColorSpace:
        return [ gamutMapping, 'LinearTransferOETF' ];
      case SRGBColorSpace:
      case DisplayP3ColorSpace:
        return [ gamutMapping, 'sRGBTransferOETF' ];
      default:
        console.warning( 'THREE.WebGLProgram: Unsupported color space: $colorSpace');
        return [ gamutMapping, 'LinearTransferOETF' ];
    }
  }

  String getShaderErrors(RenderingContext gl, WebGLShader shader, type) {
    final status = gl.getShaderParameter(shader.shader, WebGL.COMPILE_STATUS);
    final errors = (gl.getShaderInfoLog(shader.shader)??'').trim();

    if (status && errors == '') return '';

    final regExp = RegExp(r"ERROR: 0:(\d+)");
    final match = regExp.firstMatch(errors);

    int errorLine = int.parse(match!.group(1)!);

    // --enable-privileged-webgl-extension
    // console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

    final source = gl.getShaderSource(shader.shader);

    return 'three.WebGLShader: gl.getShaderInfoLog() $type\n$errors\n${handleSource(source, errorLine)}';
  }

  String getTexelEncodingFunction(String functionName, String encoding) {
    final components = getEncodingComponents(encoding);
    return 'vec4 $functionName( vec4 value ) { return ${components[ 0 ]}( ${components[ 1 ]}( value ) ); }';
  }

  String getToneMappingFunction(functionName, toneMapping) {
    String toneMappingName;

    switch (toneMapping) {
      case LinearToneMapping:
        toneMappingName = 'Linear';
        break;

      case ReinhardToneMapping:
        toneMappingName = 'Reinhard';
        break;

      case CineonToneMapping:
        toneMappingName = 'OptimizedCineon';
        break;

      case ACESFilmicToneMapping:
        toneMappingName = 'ACESFilmic';
        break;

      case AgXToneMapping:
        toneMappingName = 'AgX';
        break;

      case NeutralToneMapping:
        toneMappingName = 'Neutral';
        break;

      case CustomToneMapping:
        toneMappingName = 'Custom';
        break;

      default:
        console.error('three.WebGLProgram: Unsupported toneMapping: $toneMapping');
        toneMappingName = 'Linear';
    }

    return 'vec3 $functionName( vec3 color ) { return ${toneMappingName}ToneMapping( color ); }';
  }

  String generateVertexExtensions(WebGLParameters parameters) {
    final chunks = [
      parameters.extensionClipCullDistance ? '#extension GL_ANGLE_clip_cull_distance : require' : '',
      parameters.extensionMultiDraw ? '#extension GL_ANGLE_multi_draw : require' : '',
    ];

    return chunks.where((s) => filterEmptyLine(s)).join('\n');
  }

  String generateDefines(defines) {
    final chunks = [];

    if (defines != null) {
      for (final name in defines.keys) {
        final value = defines[name];

        if (value == false) continue;

        // print("WebGLProgramExtra generateDefines name: ${name} value: ${value} ");
        chunks.add('#define $name $value');
      }
    }

    return chunks.join('\n');
  }

  Map<String, AttributeLocations> fetchAttributeLocations(RenderingContext gl, Program program) {
    Map<String, AttributeLocations> attributes = {};

    final n = gl.getProgramParameter(program, WebGL.ACTIVE_ATTRIBUTES).id;

    for (int i = 0; i < n; i++) {
      final info = gl.getActiveAttrib(program, i);
      final name = info.name;

      // print( "three.WebGLProgram: ACTIVE VERTEX ATTRIBUTE: name: ${name} i: ${i}");

      // attributes[name] = gl.getAttribLocation(program, name);

      int locationSize = 1;
      if (info.type == WebGL.FLOAT_MAT2) locationSize = 2;
      if (info.type == WebGL.FLOAT_MAT3) locationSize = 3;
      if (info.type == WebGL.FLOAT_MAT4) locationSize = 4;

      // console.log( 'three.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

      attributes[name] = AttributeLocations(
        type: info.type,
        location: gl.getAttribLocation(program, name),
        locationSize: locationSize
      );
    }

    return attributes;
  }

  bool filterEmptyLine(string) {
    return string != '';
  }

  String replaceLightNums(String string, WebGLParameters parameters) {
    final numSpotLightCoords = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

		string = string.replaceAll("NUM_DIR_LIGHTS", parameters.numDirLights.toString() );
		string = string.replaceAll("NUM_SPOT_LIGHTS", parameters.numSpotLights.toString() );
		string = string.replaceAll("NUM_SPOT_LIGHT_MAPS", parameters.numSpotLightMaps.toString() );
		string = string.replaceAll("NUM_SPOT_LIGHT_COORDS", numSpotLightCoords.toString() );
		string = string.replaceAll("NUM_RECT_AREA_LIGHTS", parameters.numRectAreaLights.toString() );
		string = string.replaceAll("NUM_POINT_LIGHTS", parameters.numPointLights.toString() );
		string = string.replaceAll("NUM_HEMI_LIGHTS", parameters.numHemiLights.toString() );
		string = string.replaceAll("NUM_DIR_LIGHT_SHADOWS", parameters.numDirLightShadows.toString() );
		string = string.replaceAll("NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS", parameters.numSpotLightShadowsWithMaps.toString() );
		string = string.replaceAll("NUM_SPOT_LIGHT_SHADOWS", parameters.numSpotLightShadows.toString() );
		string = string.replaceAll("NUM_POINT_LIGHT_SHADOWS", parameters.numPointLightShadows.toString() );

    return string;
  }

  String replaceClippingPlaneNums(String string, WebGLParameters parameters) {
    string = string.replaceAll("NUM_CLIPPING_PLANES", parameters.numClippingPlanes.toString());
    string = string.replaceAll("UNION_CLIPPING_PLANES", (parameters.numClippingPlanes - parameters.numClipIntersection).toString());

    return string;
  }

  // Resolve Includes

  final includePattern = RegExp(r"[ \t]*#include +<([\w\d./]+)>"); //gm;

  String resolveIncludes(String string) {
    // return string.replaceAll(includePattern, includeReplacer);

    // Loop through all matches.
    for (final match in includePattern.allMatches(string)) {
      /// Returns the string matched by the given [group].
      ///
      /// If [group] is 0, returns the match of the pattern.
      ///
      /// The result may be `null` if the pattern didn't assign a value to it
      /// as part of this match.
      // print(" resolveIncludes ");
      // print(match.group(0)); // 15, then 20

      String includeString = match.group(1)!;

      // print(" includeString: ${includeString} ");

      String targetString = shaderChunk[includeString]!;

      String targetString2 = resolveIncludes(targetString);

      String fromString = match.group(0)!;

      string = string.replaceFirst(fromString, targetString2);
    }

    return string;
  }

  final shaderChunkMap = {};

  String includeReplacer(match, include) {
    String? string = shaderChunk[ include ];

    if (string == null) {
      final newInclude = shaderChunkMap[include];
      if ( newInclude != null ) {
        string = shaderChunk[ newInclude ];
        console.warning( 'THREE.WebGLRenderer: Shader chunk "$include" has been deprecated. Use "$newInclude" instead.');
      } else {
        throw( 'Can not resolve #include <$include>' );
      }
    }

    return resolveIncludes( string! );
  }

// Unroll Loops

  final unrollLoopPattern = RegExp(r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end");

  String unrollLoops(String string) {
    string = unrollLoopPatternReplace(string);
    return string;
  }

  String unrollLoopPatternReplace(String string) {
    final matches = unrollLoopPattern.allMatches(string);

    for (final match in matches) {
      String stringResult = '';

      int start = int.parse(match.group(1)!);
      int end = int.parse(match.group(2)!);
      final snippet = match.group(3)!;

      for (int i = start; i < end; i++) {
        String snippet2 = snippet.replaceAll(RegExp(r"\[\s*i\s*\]"), "[$i]");
        snippet2 = snippet2.replaceAll(RegExp(r"UNROLLED_LOOP_INDEX"), i.toString());
        stringResult = stringResult + snippet2;
      }

      string = string.replaceFirst(match.group(0)!, stringResult);
    }
    return string;
  }

  String loopReplacer(match, s, e, snippet) {
    String string = '';

    int start = int.parse(s);
    int end = int.parse(e);

    for (int i = start; i < end; i++) {
      snippet = snippet
        ..replaceAll(RegExp(r"\[\s*i\s*\]"), '[ $i ]')
        ..replaceAll(RegExp(r"UNROLLED_LOOP_INDEX"), i);

      string += snippet;
    }

    return string;
  }

//

  String generatePrecision(WebGLParameters parameters) {
    String precisionstring = '''precision ${parameters.precision} float;
    precision ${parameters.precision} int;
    precision ${parameters.precision} sampler2D;
    precision ${parameters.precision} samplerCube;
    precision ${parameters.precision} sampler3D;
    precision ${parameters.precision} sampler2DArray;
    precision ${parameters.precision} sampler2DShadow;
    precision ${parameters.precision} samplerCubeShadow;
    precision ${parameters.precision} sampler2DArrayShadow;
    precision ${parameters.precision} isampler2D;
    precision ${parameters.precision} isampler3D;
    precision ${parameters.precision} isamplerCube;
    precision ${parameters.precision} isampler2DArray;
    precision ${parameters.precision} usampler2D;
    precision ${parameters.precision} usampler3D;
    precision ${parameters.precision} usamplerCube;
    precision ${parameters.precision} usampler2DArray;
    ''';

    if ( parameters.precision == 'highp' ) {
      precisionstring += '\n#define HIGH_PRECISION';
    } else if ( parameters.precision == 'mediump' ) {
      precisionstring += '\n#define MEDIUM_PRECISION';
    } else if ( parameters.precision == 'lowp' ) {
      precisionstring += '\n#define LOW_PRECISION';
    }

    return precisionstring;
  }

  String generateShadowMapTypeDefine(WebGLParameters parameters) {
    String shadowMapTypeDefine = 'SHADOWMAP_TYPE_BASIC';

    if (parameters.shadowMapType == PCFShadowMap) {
      shadowMapTypeDefine = 'SHADOWMAP_TYPE_PCF';
    } else if (parameters.shadowMapType == PCFSoftShadowMap) {
      shadowMapTypeDefine = 'SHADOWMAP_TYPE_PCF_SOFT';
    } else if (parameters.shadowMapType == VSMShadowMap) {
      shadowMapTypeDefine = 'SHADOWMAP_TYPE_VSM';
    }

    return shadowMapTypeDefine;
  }

  String generateEnvMapTypeDefine(WebGLParameters parameters) {
    String envMapTypeDefine = 'ENVMAP_TYPE_CUBE';

    if (parameters.envMap) {
      switch (parameters.envMapMode) {
        case CubeReflectionMapping:
        case CubeRefractionMapping:
          envMapTypeDefine = 'ENVMAP_TYPE_CUBE';
          break;

        case CubeUVReflectionMapping:
          envMapTypeDefine = 'ENVMAP_TYPE_CUBE_UV';
          break;
      }
    }

    return envMapTypeDefine;
  }

   String generateEnvMapModeDefine (WebGLParameters parameters) {
    String envMapModeDefine = 'ENVMAP_MODE_REFLECTION';

    if (parameters.envMap) {
      switch (parameters.envMapMode) {
        case CubeRefractionMapping:
          envMapModeDefine = 'ENVMAP_MODE_REFRACTION';
          break;
      }
    }

    return envMapModeDefine;
  }

   String generateEnvMapBlendingDefine(WebGLParameters parameters) {
     String envMapBlendingDefine = 'ENVMAP_BLENDING_NONE';

    if (parameters.envMap) {
      switch (parameters.combine) {
        case MultiplyOperation:
          envMapBlendingDefine = 'ENVMAP_BLENDING_MULTIPLY';
          break;

        case MixOperation:
          envMapBlendingDefine = 'ENVMAP_BLENDING_MIX';
          break;

        case AddOperation:
          envMapBlendingDefine = 'ENVMAP_BLENDING_ADD';
          break;
      }
    }

    return envMapBlendingDefine;
  }

  Map<String,dynamic>? generateCubeUVSize(WebGLParameters parameters) {
    final imageHeight = parameters.envMapCubeUVHeight;

    if (imageHeight == null) return null;

    int maxMip = MathUtils.log2(imageHeight).toInt() - 2;

    final texelHeight = 1.0 / imageHeight;
    final texelWidth = 1.0 / (3 * math.max(math.pow(2, maxMip), 7 * 16));

    return {"texelWidth": texelWidth, "texelHeight": texelHeight, "maxMip": maxMip};
  }
}
