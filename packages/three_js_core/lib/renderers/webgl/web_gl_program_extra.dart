part of three_webgl;

mixin WebGLProgramExtra {
  String handleSource(String string, int errorLine) {
    final lines = string.split('\n');
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

  List<String> getEncodingComponents(encoding) {
    switch (encoding) {
      case LinearEncoding:
        return ['Linear', '( value )'];
      case sRGBEncoding:
        return ['sRGB', '( value )'];
      case RGBEEncoding:
        return ['RGBE', '( value )'];
      case RGBM7Encoding:
        return ['RGBM', '( value, 7.0 )'];
      case RGBM16Encoding:
        return ['RGBM', '( value, 16.0 )'];
      case RGBDEncoding:
        return ['RGBD', '( value, 256.0 )'];
      case GammaEncoding:
        return ['Gamma', '( value, float( GAMMA_FACTOR ) )'];
      default:
        console.error('WebGLProgram: Unsupported encoding: $encoding');
        return ['Linear', '( value )'];
    }
  }

  String getShaderErrors(dynamic gl, WebGLShader shader, type) {
    final status = gl.getShaderParameter(shader.shader, gl.COMPILE_STATUS);
    final errors = gl.getShaderInfoLog(shader.shader).trim();

    if (status && errors == '') return '';

    final regExp = RegExp(r"ERROR: 0:(\d+)");
    final match = regExp.firstMatch(errors);

    int errorLine = int.parse(match!.group(1)!);

    // --enable-privileged-webgl-extension
    // console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

    final source = gl.getShaderSource(shader.shader);

    return 'three.WebGLShader: gl.getShaderInfoLog() $type\n$errors\n${handleSource(source, errorLine)}';
  }

  String getTexelEncodingFunction(functionName, encoding) {
    final components = getEncodingComponents(encoding);
    return 'vec4 $functionName ( vec4 value ) { return LinearTo${components[0] + components[1]}; }';
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

      case CustomToneMapping:
        toneMappingName = 'Custom';
        break;

      default:
        console.error('three.WebGLProgram: Unsupported toneMapping: $toneMapping');
        toneMappingName = 'Linear';
    }

    return 'vec3 $functionName( vec3 color ) { return ${toneMappingName}ToneMapping( color ); }';
  }

  String generateExtensions(parameters) {
    final chunks = [
      (parameters.extensionDerivatives ||
              parameters.cubeUVHeight ||
              parameters.bumpMap ||
              parameters.tangentSpaceNormalMap ||
              parameters.clearcoatNormalMap ||
              parameters.flatShading ||
              parameters.shaderID == 'physical')
          ? '#extension GL_OES_standard_derivatives : enable'
          : '',
      (parameters.extensionFragDepth || parameters.logarithmicDepthBuffer) && parameters.rendererExtensionFragDepth
          ? '#extension GL_EXT_frag_depth : enable'
          : '',
      (parameters.extensionDrawBuffers && parameters.rendererExtensionDrawBuffers)
          ? '#extension GL_EXT_draw_buffers : require'
          : '',
      (parameters.extensionShaderTextureLOD || parameters.envMap) && parameters.rendererExtensionShaderTextureLod
          ? '#extension GL_EXT_shader_texture_lod : enable'
          : ''
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

  Map<String, dynamic> fetchAttributeLocations(gl, program) {
    Map<String, dynamic> attributes = {};

    final n = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);

    for (int i = 0; i < n; i++) {
      final info = gl.getActiveAttrib(program, i);
      final name = info.name;

      // print( "three.WebGLProgram: ACTIVE VERTEX ATTRIBUTE: name: ${name} i: ${i}");

      // attributes[name] = gl.getAttribLocation(program, name);

      int locationSize = 1;
      if (info.type == gl.FLOAT_MAT2) locationSize = 2;
      if (info.type == gl.FLOAT_MAT3) locationSize = 3;
      if (info.type == gl.FLOAT_MAT4) locationSize = 4;

      // console.log( 'three.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

      attributes[name] = {
        "type": info.type,
        "location": gl.getAttribLocation(program, name),
        "locationSize": locationSize
      };
    }

    return attributes;
  }

  filterEmptyLine(string) {
    return string != '';
  }

  String replaceLightNums(String string, WebGLParameters parameters) {
    string = string.replaceAll("NUM_DIR_LIGHTS", parameters.numDirLights.toString());
    string = string.replaceAll("NUM_SPOT_LIGHTS", parameters.numSpotLights.toString());
    string = string.replaceAll("NUM_RECT_AREA_LIGHTS", parameters.numRectAreaLights.toString());
    string = string.replaceAll("NUM_POINT_LIGHTS", parameters.numPointLights.toString());
    string = string.replaceAll("NUM_HEMI_LIGHTS", parameters.numHemiLights.toString());
    string = string.replaceAll("NUM_DIR_LIGHT_SHADOWS", parameters.numDirLightShadows.toString());
    string = string.replaceAll("NUM_SPOT_LIGHT_SHADOWS", parameters.numSpotLightShadows.toString());
    string = string.replaceAll("NUM_POINT_LIGHT_SHADOWS", parameters.numPointLightShadows.toString());

    return string;
  }

  String replaceClippingPlaneNums(String string, WebGLParameters parameters) {
    string = string.replaceAll("NUM_CLIPPING_PLANES", parameters.numClippingPlanes.toString());
    string = string.replaceAll(
        "UNION_CLIPPING_PLANES", (parameters.numClippingPlanes - parameters.numClipIntersection).toString());

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

  String includeReplacer(match, include) {
    final string = shaderChunk[include];

    if (string == null) {
      throw ('Can not resolve #include <$include>');
    }

    return resolveIncludes(string);
  }

// Unroll Loops

  final deprecatedUnrollLoopPattern =
      RegExp(r"#pragma unroll_loop[\s]+?for \( int i \= (\d+)\; i < (\d+)\; i \+\+ \) \{([\s\S]+?)(?=\})\}"); //g;
  final unrollLoopPattern = RegExp(
      r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end");

  String unrollLoops(String string) {
    string = unrollLoopPatternReplace(string);
    string = deprecatedUnrollLoopPatternReplace(string);

    // print(" unrollLoops ======================== ");
    // print(string);
    // print(" unrollLoops 2 ======================== ");

    return string;
    // return string
    //     ..replaceFirst(unrollLoopPattern, loopReplacer)
    //     ..replaceFirst(deprecatedUnrollLoopPattern, deprecatedLoopReplacer);
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
        // string += snippet
        //   .replace( /\[\s*i\s*\]/g, '[ ' + i + ' ]' )
        //   .replace( /UNROLLED_LOOP_INDEX/g, i );

        stringResult = stringResult + snippet2;
      }

      string = string.replaceFirst(match.group(0)!, stringResult);
    }

    // print(string);
    // if(match != null) {
    //   print(" unrollLoopPatternReplace  match start: ${match.start} end: ${match.end} ");

    // } else {
    //   print("unrollLoopPatternReplace match is null  ");
    // }

    return string;
  }

  String deprecatedUnrollLoopPatternReplace(String string) {
    // return unrollLoopPatternReplace(string);
    return string;
  }

  String deprecatedLoopReplacer(match, start, end, snippet) {
    console.warning('WebGLProgram: #pragma unroll_loop shader syntax is deprecated. Please use #pragma unroll_loop_start syntax instead.');
    return loopReplacer(match, start, end, snippet);
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

  String generatePrecision(parameters) {
    String precisionstring = 'precision ${parameters.precision} float;\nprecision ${parameters.precision} int;';

    if (parameters.precision == 'highp') {
      precisionstring += '\n#define HIGH_PRECISION';
    } else if (parameters.precision == 'mediump') {
      precisionstring += '\n#define MEDIUM_PRECISION';
    } else if (parameters.precision == 'lowp') {
      precisionstring += '\n#define LOW_PRECISION';
    }

    return precisionstring;
  }

  String generateShadowMapTypeDefine(parameters) {
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

  String generateEnvMapTypeDefine(parameters) {
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

   String generateEnvMapModeDefine(parameters) {
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

   String generateEnvMapBlendingDefine(parameters) {
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

  Map<String,dynamic>? generateCubeUVSize(parameters) {
    final imageHeight = parameters.cubeUVHeight;

    if (imageHeight == null) return null;

    int maxMip = MathUtils.log2(imageHeight).toInt() - 2;

    final texelHeight = 1.0 / imageHeight;

    final texelWidth = 1.0 / (3 * math.max(math.pow(2, maxMip), 7 * 16));

    return {"texelWidth": texelWidth, "texelHeight": texelHeight, "maxMip": maxMip};
  }
}
