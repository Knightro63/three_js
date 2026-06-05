import 'full_screen_effect_pass.dart';
import 'full_screen_effect.dart';

/// Blend state types for pipelines.
enum BlendStateType {
  /// No blending - fully opaque
  none,

  /// Standard alpha blending: src * srcAlpha + dst * (1 - srcAlpha)
  alpha,

  /// Additive blending: src + dst
  additive,

  /// Multiply blending: src * dst
  multiply,

  /// Screen blending: srcFactor=ONE, dstFactor=ONE_MINUS_SRC, operation=ADD
  screen,

  /// Premultiplied alpha: src + dst * (1 - srcAlpha)
  premultiplied,
}

/// Describes a binding in a bind group layout.
class BindingDescriptor {
  /// The binding index.
  final int binding;

  /// The type of binding.
  final BindingType type;

  /// The shader stages where this binding is visible.
  final Set<ShaderStage> visibility;

  /// Creates a [BindingDescriptor].
  const BindingDescriptor({
    required this.binding,
    required this.type,
    required this.visibility,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BindingDescriptor &&
          runtimeType == other.runtimeType &&
          binding == other.binding &&
          type == other.type &&
          _setEquals(visibility, other.visibility);

  @override
  int get hashCode => Object.hash(binding, type, Object.hashAll(visibility));

  @override
  String toString() {
    return 'BindingDescriptor(binding: $binding, type: $type, visibility: $visibility)';
  }

  bool _setEquals(Set a, Set b) => a.length == b.length && a.containsAll(b);
}

/// Types of bindings in a bind group.
enum BindingType {
  uniformBuffer,
  texture,
  sampler,
}

/// Shader stages for binding visibility.
enum ShaderStage {
  vertex,
  fragment,
}

/// Descriptor for creating a GPU pipeline from a [FullScreenEffectPass].
///
/// This contains all the information needed to create a render pipeline:
/// - Compiled WGSL shader code
/// - Blend state configuration
/// - Bind group layouts for uniforms and textures
/// - Buffer size requirements
class EffectPipelineDescriptor {
  /// Human-readable label for debugging
  final String label;

  /// Complete WGSL shader module code
  final String shaderCode;

  /// Blend state for color attachments
  final BlendStateType blendState;

  /// Whether this effect has uniform bindings
  final bool hasUniforms;

  /// Whether this effect requires an input texture
  final bool hasInputTexture;

  /// Uniform buffer size in bytes
  final int uniformBufferSize;

  /// Binding descriptors for uniforms (group 0)
  final List<BindingDescriptor> uniformBindings;

  /// Binding descriptors for textures (group 1)
  final List<BindingDescriptor> textureBindings;

  /// Creates an [EffectPipelineDescriptor].
  const EffectPipelineDescriptor({
    required this.label,
    required this.shaderCode,
    required this.blendState,
    required this.hasUniforms,
    required this.hasInputTexture,
    required this.uniformBufferSize,
    required this.uniformBindings,
    required this.textureBindings,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EffectPipelineDescriptor &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          shaderCode == other.shaderCode &&
          blendState == other.blendState &&
          hasUniforms == other.hasUniforms &&
          hasInputTexture == other.hasInputTexture &&
          uniformBufferSize == other.uniformBufferSize &&
          _listEquals(uniformBindings, other.uniformBindings) &&
          _listEquals(textureBindings, other.textureBindings);

  @override
  int get hashCode => Object.hash(
        label,
        shaderCode,
        blendState,
        hasUniforms,
        hasInputTexture,
        uniformBufferSize,
        Object.hashAll(uniformBindings),
        Object.hashAll(textureBindings),
      );

  @override
  String toString() {
    return 'EffectPipelineDescriptor(label: $label, blendState: $blendState, hasUniforms: $hasUniforms)';
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Factory for creating GPU pipeline descriptors from [FullScreenEffectPass].
///
/// This factory generates [EffectPipelineDescriptor] objects that can be used
/// to create render pipelines. It handles:
/// - Shader code generation from the effect
/// - Blend mode translation to blend states
/// - Bind group layout generation for uniforms and input textures
///
/// Usage:
/// ```dart
/// final descriptor = EffectPipelineFactory.createDescriptor(pass, label: 'bloom');
/// final pipeline = device.createRenderPipeline(descriptor.toGpuDescriptor());
/// ```
abstract final class EffectPipelineFactory {
  /// Creates a pipeline descriptor from a [FullScreenEffectPass].
  ///
  /// [pass] The effect pass to create a pipeline for
  /// [label] Optional label for debugging
  static EffectPipelineDescriptor createDescriptor(
    FullScreenEffectPass pass, {
    String label = 'effect',
  }) {
    final shaderCode = pass.getShaderCode();
    final blendState = _mapBlendMode(pass.blendMode);
    final hasUniforms = pass.effect.uniforms.isNotEmpty;
    final uniformBufferSize = pass.effect.uniforms.length;
    final uniformBindings = _createUniformBindings(hasUniforms);
    final textureBindings = _createTextureBindings(pass);

    return EffectPipelineDescriptor(
      label: 'effect-pipeline-$label',
      shaderCode: shaderCode,
      blendState: blendState,
      hasUniforms: hasUniforms,
      hasInputTexture: textureBindings.isNotEmpty,
      uniformBufferSize: uniformBufferSize,
      uniformBindings: uniformBindings,
      textureBindings: textureBindings,
    );
  }

  /// Maps a [BlendMode] to a [BlendStateType].
  static BlendStateType _mapBlendMode(BlendMode blendMode) {
    switch (blendMode) {
      case BlendMode.opaque:
        return BlendStateType.none;
      case BlendMode.alphaBlend:
        return BlendStateType.alpha;
      case BlendMode.additive:
        return BlendStateType.additive;
      case BlendMode.multiply:
        return BlendStateType.multiply;
      case BlendMode.screen:
        return BlendStateType.screen;
      case BlendMode.overlay:
        return BlendStateType.multiply; // Overlay approximated as multiply
      case BlendMode.premultipliedAlpha:
        return BlendStateType.premultiplied;
    }
  }

  /// Creates uniform buffer binding descriptors.
  static List<BindingDescriptor> _createUniformBindings(bool hasUniforms) {
    if (!hasUniforms) return const [];

    return const [
      BindingDescriptor(
        binding: 0,
        type: BindingType.uniformBuffer,
        visibility: {ShaderStage.vertex, ShaderStage.fragment},
      ),
    ];
  }

  /// Creates texture binding descriptors for input textures.
  static List<BindingDescriptor> _createTextureBindings(FullScreenEffectPass pass) {
    // Check if the shader references input textures
    final shaderCode = pass.getShaderCode();
    final hasInputTexture = shaderCode.contains('inputTexture') || shaderCode.contains('tDiffuse');
    if (!hasInputTexture) return const [];

    return const [
      BindingDescriptor(
        binding: 0,
        type: BindingType.texture,
        visibility: {ShaderStage.fragment},
      ),
      BindingDescriptor(
        binding: 1,
        type: BindingType.sampler,
        visibility: {ShaderStage.fragment},
      ),
    ];
  }
}
