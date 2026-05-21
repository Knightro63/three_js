import 'FullScreenEffect.dart';
import 'UniformBlock.dart';

class FullScreenEffectPass {
  FullScreenEffectPass({
    required this.effect,
    this.requiresInputTexture = false,
    this.autoUpdateResolution = false,
    this.renderToScreen = false,
  });

  final FullScreenEffect effect;
  final bool requiresInputTexture;
  final bool autoUpdateResolution;
  final bool renderToScreen;

  /// Whether this pass is enabled and should be executed.
  bool enabled = true;

  /// Current width of the render target in pixels.
  int _width = 0;
  int get width => _width;

  /// Current height of the render target in pixels.
  int _height = 0;
  int get height => _height;

  /// Whether the uniform buffer has been modified since the last GPU upload.
  bool _isUniformBufferDirty = false;
  bool get isUniformBufferDirty => _isUniformBufferDirty;

  /// Whether this pass has been disposed.
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  /// The blend mode inherited from the effect.
  BlendMode get blendMode => effect.blendMode;

  /// The clear color inherited from the effect.
  ClearColor get clearColor => effect.clearColor;

  // Cached shader code
  String? _cachedShaderCode;

  /// Returns the complete WGSL shader module for this pass.
  ///
  /// For standard passes, this returns the effect's generated shader.
  /// For passes requiring input textures (post-processing chain), this
  /// adds the necessary texture/sampler bindings.
  String getShaderCode() {
    if (_cachedShaderCode != null) {
      return _cachedShaderCode!;
    }

    final baseShader = effect.generateShaderModule();
    final shaderCode = requiresInputTexture
        ? _injectInputTextureBindings(baseShader)
        : baseShader;

    _cachedShaderCode = shaderCode;
    return shaderCode;
  }

  /// Updates uniform values using the DSL block.
  ///
  /// This marks the uniform buffer as dirty, indicating it needs
  /// to be uploaded to the GPU before the next render.
  void updateUniforms(void Function(UniformUpdater) block) {
    effect.updateUniforms(block);
    _isUniformBufferDirty = true;
  }

  /// Clears the dirty flag after GPU upload.
  ///
  /// Call this after uploading the uniform buffer to the GPU
  /// to reset the dirty tracking state.
  void clearDirtyFlag() {
    _isUniformBufferDirty = false;
  }

  /// Sets the size of this pass and optionally updates resolution uniforms.
  void setSize(int width, int height) {
    _width = width;
    _height = height;
    if (autoUpdateResolution) {
      _tryUpdateResolutionUniform(width, height);
    }
  }

  /// Releases all resources held by this pass.
  ///
  /// After calling dispose, the pass cannot be used for rendering.
  /// This method is idempotent - multiple calls have no effect.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    effect.dispose();
    _cachedShaderCode = null;
  }

  /// Attempts to update a "resolution" uniform if one exists.
  void _tryUpdateResolutionUniform(int width, int height) {
    // Check if the effect has a "resolution" uniform
    final hasResolution = effect.uniforms.field('resolution') != null;
    if (hasResolution) {
      effect.updateUniforms((updater) {
        updater.setVec2('resolution', width.toDouble(), height.toDouble());
      });
      _isUniformBufferDirty = true;
    }
  }

  /// Injects input texture bindings for post-processing chain usage.
  String _injectInputTextureBindings(String baseShader) {
    // Determine the next available binding group
    // If uniforms exist, they use @group(0) @binding(0)
    // Input texture uses @group(1) or the next available
    const inputBindings = '''
// Input texture from previous pass
@group(1) @binding(0) var inputTexture: texture_2d<f32>;
@group(1) @binding(1) var inputSampler: sampler;
''';

    // Insert after any existing uniform declarations
    final insertionPoint = _findInsertionPoint(baseShader);
    return baseShader.substring(0, insertionPoint) +
        inputBindings +
        baseShader.substring(insertionPoint);
  }

  /// Finds the best point to insert input texture bindings.
  int _findInsertionPoint(String shader) {
    // Look for the end of uniform declarations or vertex output struct
    const patterns = ['var<uniform>', 'struct VertexOutput'];

    for (final pattern in patterns) {
      final idx = shader.indexOf(pattern);
      if (idx >= 0) {
        // Find the end of this line/block
        final lineEnd = shader.indexOf('\n', idx);
        if (lineEnd >= 0) {
          // For var<uniform>, find the semicolon
          final semicolon = shader.indexOf(';', idx);
          if (semicolon >= 0 && semicolon < lineEnd + 50) {
            return semicolon + 1;
          }
          return lineEnd + 1;
        }
      }
    }
    // Default: insert at the beginning
    return 0;
  }

  /// Static factory method replacing the companion object builder.
  static FullScreenEffectPass create({
    bool requiresInputTexture = false,
    bool autoUpdateResolution = false,
    required void Function(FullScreenEffectBuilder) block,
  }) {
    final effect = fullScreenEffect(block);
    return FullScreenEffectPass(
      effect: effect,
      requiresInputTexture: requiresInputTexture,
      autoUpdateResolution: autoUpdateResolution,
    );
  }
}
