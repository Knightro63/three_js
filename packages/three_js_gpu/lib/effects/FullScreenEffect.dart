import 'dart:typed_data';
import 'UniformBlock.dart';

/// Blend modes for fullscreen effects
enum BlendMode {
  /// No blending, fully opaque
  opaque,

  /// Standard alpha blending: src * srcAlpha + dst * (1 - srcAlpha)
  alphaBlend,

  /// Additive blending: src + dst
  additive,

  /// Multiply blending: src * dst
  multiply,

  /// Screen blending: 1 - (1-src) * (1-dst), lightens the image
  screen,

  /// Overlay blending: combines multiply and screen based on base color luminance.
  /// Note: True overlay blending cannot be achieved with fixed-function blend states alone.
  /// This maps to MULTIPLY as an approximation. For accurate overlay, use shader-based
  /// implementation with WGSLLib.Color functions.
  overlay,

  /// Premultiplied alpha: src + dst * (1 - srcAlpha)
  premultipliedAlpha,
}

/// Clear color for render passes
class ClearColor {
  const ClearColor({
    this.r = 0.0,
    this.g = 0.0,
    this.b = 0.0,
    this.a = 1.0,
  });

  final double r;
  final double g;
  final double b;
  final double a;

  static const BLACK = ClearColor(r: 0.0, g: 0.0, b: 0.0, a: 1.0);
  static const TRANSPARENT = ClearColor(r: 0.0, g: 0.0, b: 0.0, a: 0.0);
  static const WHITE = ClearColor(r: 1.0, g: 1.0, b: 1.0, a: 1.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClearColor &&
          runtimeType == other.runtimeType &&
          r == other.r &&
          g == other.g &&
          b == other.b &&
          a == other.a;

  @override
  int get hashCode => Object.hash(r, g, b, a);
}

/// A fullscreen shader effect that renders to the entire canvas.
/// Uses an optimized single-triangle approach (no vertex buffer needed).
class FullScreenEffect {
  FullScreenEffect({
    required this.fragmentShader,
    UniformBlock? uniforms,
    this.blendMode = BlendMode.opaque,
    this.clearColor = ClearColor.BLACK,
  }) : uniforms = uniforms ?? UniformBlock.empty() {
    uniformBuffer = this.uniforms.createBuffer();
    _uniformUpdater = this.uniforms.createUpdater(uniformBuffer);
  }

  /// The WGSL fragment shader code
  final String fragmentShader;

  /// The uniform block for this effect
  final UniformBlock uniforms;

  /// Blend mode for rendering
  final BlendMode blendMode;

  /// Clear color for the render pass
  final ClearColor clearColor;

  /// Buffer for uniform data
  late final Float32List uniformBuffer;

  /// Updater for modifying uniform values
  late final UniformUpdater _uniformUpdater;

  /// Whether this effect has been disposed
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  /// The automatically generated vertex shader for fullscreen rendering.
  /// Uses an optimized single-triangle approach.
  final String vertexShader = FULLSCREEN_VERTEX_SHADER;

  /// Update uniform values using the DSL
  void updateUniforms(void Function(UniformUpdater) block) {
    block(_uniformUpdater);
  }

  /// Generate the complete WGSL shader module including:
  /// - Uniform struct (if uniforms are defined)
  /// - Vertex shader
  /// - Fragment shader
  String generateShaderModule() {
    final buffer = StringBuffer();

    // Uniform struct and binding (if defined)
    if (uniforms.size > 0) {
      buffer.writeln(uniforms.toWGSL('Uniforms'));
      buffer.writeln();
      buffer.writeln('@group(0) @binding(0) var<uniform> u: Uniforms;');
      buffer.writeln();
    }

    // Vertex output struct
    buffer.writeln(VERTEX_OUTPUT_STRUCT);
    buffer.writeln();

    // Vertex shader
    buffer.writeln(vertexShader);
    buffer.writeln();

    // Fragment shader
    buffer.writeln(fragmentShader);

    return buffer.toString();
  }

  /// Release resources held by this effect
  void dispose() {
    _isDisposed = true;
  }

  /// Optimized fullscreen vertex shader using a single triangle.
  /// Covers the entire screen with just 3 vertices, no vertex buffer needed.
  static const String FULLSCREEN_VERTEX_SHADER = '''
@vertex fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    // Single triangle covering entire screen
    let x = f32((vertex_index << 1u) & 2u);
    let y = f32(vertex_index & 2u);
    var output: VertexOutput;
    output.position = vec4<f32>(x * 2.0 - 1.0, 1.0 - y * 2.0, 0.0, 1.0);
    output.uv = vec2<f32>(x, y);
    return output;
}''';

  /// Vertex output struct shared between vertex and fragment shaders
  static const String VERTEX_OUTPUT_STRUCT = '''
struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}''';
}

/// Builder for creating FullScreenEffect instances with a fluent API
class FullScreenEffectBuilder {
  /// The fragment shader code
  String fragmentShader = '';

  /// The blend mode
  BlendMode blendMode = BlendMode.opaque;

  /// The clear color
  ClearColor clearColor = ClearColor.BLACK;

  /// The uniform block (built from uniforms DSL)
  UniformBlock _uniformBlock = UniformBlock.empty();

  /// Define uniforms using the DSL
  void uniforms(void Function(UniformBlockBuilder) block) {
    _uniformBlock = uniformBlock(block);
  }

  /// Build the FullScreenEffect
  FullScreenEffect build() {
    assert(fragmentShader.trim().isNotEmpty, 'Fragment shader is required');
    return FullScreenEffect(
      fragmentShader: fragmentShader,
      uniforms: _uniformBlock,
      blendMode: blendMode,
      clearColor: clearColor,
    );
  }
}

/// DSL function to create a FullScreenEffect
FullScreenEffect fullScreenEffect(void Function(FullScreenEffectBuilder) block) {
  final builder = FullScreenEffectBuilder();
  block(builder);
  return builder.build();
}
