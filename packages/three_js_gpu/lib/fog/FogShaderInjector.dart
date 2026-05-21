import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';


class FogShaderInjector {
  /// Generate WGSL fog uniforms.
  String generateFogUniforms(FogBase? fog) {
    if (fog == null) return '';
    if (fog is Fog) {
      return '''
struct FogUniforms {
    color: vec3<f32>,
    near: f32,
    far: f32,
}
@group(2) @binding(3) var<uniform> fog: FogUniforms;
''';
    }
    if (fog is FogExp2) {
      return '''
struct FogUniforms {
    color: vec3<f32>,
    density: f32,
}
@group(2) @binding(3) var<uniform> fog: FogUniforms;
''';
    }
    return '';
  }

  /// Generate WGSL fog calculation in vertex shader.
  String generateVertexFogCode(FogBase? fog) {
    if (fog == null) return '';
    return '''
// Calculate fog distance in view space
let mvPosition = modelViewMatrix * vec4<f32>(position, 1.0);
fogDepth = -mvPosition.z;
''';
  }

  /// Generate WGSL fog calculation in fragment shader.
  String generateFragmentFogCode(FogBase? fog) {
    if (fog == null) return '';
    if (fog is Fog) {
      return '''
// Linear fog
let fogFactor = smoothstep(fog.near, fog.far, fogDepth);
finalColor = mix(finalColor, vec4<f32>(fog.color, 1.0), fogFactor);
''';
    }
    if (fog is FogExp2) {
      return '''
// Exponential squared fog
let fogFactor = 1.0 - exp(-fog.density * fog.density * fogDepth * fogDepth);
finalColor = mix(finalColor, vec4<f32>(fog.color, 1.0), fogFactor);
''';
    }
    return '';
  }

  /// Generate complete fog shader chunk for material.
  FogShaderChunk generateFogShaderChunk(FogBase? fog) {
    if (fog == null) return FogShaderChunk.empty;

    final uniforms = generateFogUniforms(fog);
    final vertexCode = generateVertexFogCode(fog);
    final fragmentCode = generateFragmentFogCode(fog);
    
    const vertexVaryings = '  @location(5) fogDepth: f32,';
    const fragmentVaryings = '  @location(5) fogDepth: f32,';

    return FogShaderChunk(
      uniforms: uniforms,
      vertexVaryings: vertexVaryings,
      fragmentVaryings: fragmentVaryings,
      vertexCode: vertexCode,
      fragmentCode: fragmentCode,
    );
  }

  /// Inject fog code into existing WGSL shaders.
  /// Replaces Kotlin's Pair return type with a clean, modern Dart Record tuple.
  (String, String) injectFogIntoShader(
    String vertexShader,
    String fragmentShader,
    FogBase? fog,
  ) {
    if (fog == null) return (vertexShader, fragmentShader);

    final chunk = generateFogShaderChunk(fog);

    // Inject into vertex shader layout
    final vertexBuffer = StringBuffer();
    vertexBuffer.writeln(chunk.uniforms);
    
    var modifiedVertex = vertexShader.replaceFirst(
      'struct VertexOutput {',
      'struct VertexOutput {\n${chunk.vertexVaryings}',
    ).replaceFirst(
      '// END_VERTEX_MAIN',
      '${chunk.vertexCode}\n  // END_VERTEX_MAIN',
    );
    vertexBuffer.write(modifiedVertex);

    // Inject into fragment shader layout
    final fragmentBuffer = StringBuffer();
    if (!fragmentShader.contains('fog:')) {
      fragmentBuffer.writeln(chunk.uniforms);
    }

    var modifiedFragment = fragmentShader.replaceFirst(
      'struct FragmentInput {',
      'struct FragmentInput {\n${chunk.fragmentVaryings}',
    ).replaceFirst(
      '// APPLY_FOG',
      chunk.fragmentCode,
    ).replaceFirst(
      'return finalColor;',
      '${chunk.fragmentCode}\n  return finalColor;',
    );
    fragmentBuffer.write(modifiedFragment);

    return (vertexBuffer.toString(), fragmentBuffer.toString());
  }

  /// Generate GLSL fog code (for fallback/compatibility targets).
  GLSLFogCode generateGLSLFogCode(FogBase? fog) {
    if (fog == null) return GLSLFogCode.empty;
    if (fog is Fog) {
      return const GLSLFogCode(
        uniforms: 'uniform vec3 fogColor;\nuniform float fogNear;\nuniform float fogFar;',
        vertexCode: 'vFogDepth = -mvPosition.z;',
        fragmentCode: 'float fogFactor = smoothstep(fogNear, fogFar, vFogDepth);\ngl_FragColor.rgb = mix(gl_FragColor.rgb, fogColor, fogFactor);',
      );
    }
    if (fog is FogExp2) {
      return const GLSLFogCode(
        uniforms: 'uniform vec3 fogColor;\nuniform float fogDensity;',
        vertexCode: 'vFogDepth = -mvPosition.z;',
        fragmentCode: 'float fogFactor = 1.0 - exp(-fogDensity * fogDensity * vFogDepth * vFogDepth);\ngl_FragColor.rgb = mix(gl_FragColor.rgb, fogColor, fogFactor);',
      );
    }
    return GLSLFogCode.empty;
  }

  /// Check if shader needs fog injection.
  bool shaderNeedsFog(String shader) {
    return !shader.contains('fog:') && !shader.contains('fogDepth');
  }

  /// Extract fog parameters for direct upload to uniform buffers.
  Float32List getFogUniforms(FogBase? fog) {
    if (fog == null) return Float32List(0);
    if (fog is Fog) {
      return Float32List.fromList([
        fog.color.red,
        fog.color.green,
        fog.color.blue,
        fog.near,
        fog.far,
      ]);
    }
    if (fog is FogExp2) {
      return Float32List.fromList([
        fog.color.red,
        fog.color.green,
        fog.color.blue,
        fog.density,
      ]);
    }
    return Float32List(0);
  }
}

/// Container for WGSL shader code chunks.
class FogShaderChunk {
  const FogShaderChunk({
    required this.uniforms,
    required this.vertexVaryings,
    required this.fragmentVaryings,
    required this.vertexCode,
    required this.fragmentCode,
  });

  final String uniforms;
  final String vertexVaryings;
  final String fragmentVaryings;
  final String vertexCode;
  final String fragmentCode;

  static const empty = FogShaderChunk(uniforms: '', vertexVaryings: '', fragmentVaryings: '', vertexCode: '', fragmentCode: '');
}

/// Container for GLSL fog code (compatibility fallback).
class GLSLFogCode {
  const GLSLFogCode({
    required this.uniforms,
    required this.vertexCode,
    required this.fragmentCode,
  });

  final String uniforms;
  final String vertexCode;
  final String fragmentCode;

  static const empty = GLSLFogCode(uniforms: '', vertexCode: '', fragmentCode: '');
}

/// Namespace grouping static arithmetic fog calculations utilities.
abstract class FogUtils {
  /// Calculate linear fog factor.
  static double calculateLinearFogFactor(double distance, double near, double far) {
    return ((far - distance) / (far - near)).clamp(0.0, 1.0);
  }

  /// Calculate exponential squared fog factor.
  static double calculateExp2FogFactor(double distance, double density) {
    final fogExponent = density * density * distance * distance;
    return (1.0 - math.exp(-fogExponent)).clamp(0.0, 1.0);
  }

  /// Mix core target color parameters with fog values.
  static Color applyFog(Color color, Color fogColor, double fogFactor) {
    return Color(
      color.red * (1.0 - fogFactor) + fogColor.red * fogFactor,
      color.green * (1.0 - fogFactor) + fogColor.green * fogFactor,
      color.blue * (1.0 - fogFactor) + fogColor.blue * fogFactor,
    );
  }
}
