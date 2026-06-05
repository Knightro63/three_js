/// # Materia Effects Module
///
/// High-level APIs for fullscreen shader effects and WebGPU rendering.
///
/// ## Features
///
/// ### UniformBlock - Type-safe uniform buffer management
/// ```dart
/// final uniforms = uniformBlock((block) {
///   block.float('time');
///   block.vec2('resolution');
///   block.vec4('color');
/// });
/// ```
///
/// ### FullScreenEffect - Simplified fullscreen shader effects
/// ```dart
/// final effect = fullScreenEffect((fx) {
///   fx.fragmentShader = '''
/// @fragment
/// fn main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
///   return vec4<f32>(uv, 0.0, 1.0);
/// }
/// ''';
///   fx.uniforms((block) {
///     block.float('time');
///   });
/// });
/// ```
///
/// ### WGSLLib - Reusable shader snippets
/// ```dart
/// final shader = '''
/// \${WGSLLib.hash.hash22}
/// \${WGSLLib.noise.value2D}
/// \${WGSLLib.fractal.fbm}
/// \${WGSLLib.color.cosinePalette}
///
/// @fragment
/// fn main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
///   let n = fbm(uv * 10.0, 6);
///   let color = cosinePalette(n, ...);
///   return vec4<f32>(color, 1.0);
/// }
/// ''';
/// ```
///
/// ### RenderLoop - Animation loop management
/// ```dart
/// final loop = RenderLoop((frame) {
///   effect.updateUniforms((uniforms) {
///     uniforms.set('time', frame.totalTime);
///   });
/// });
/// loop.timeScale = 0.5; // Slow motion
/// loop.start();
/// ```
///
/// ### GpuCanvasConfig - Canvas configuration
/// ```dart
/// final config = GpuCanvasConfig(
///   options: GpuCanvasOptions(
///     alphaMode: AlphaMode.premultiplied,
///     powerPreference: PowerPreference.highPerformance,
///   ),
/// );
/// ```

// Export all public APIs for convenience.
// Users can import 'package:materia_effects/materia_effects.dart' to get everything.
export './full_screen_effect.dart';
export './full_screen_effect_pass.dart';
export './effect_composer.dart';
export './effect_pipeline_factory.dart';
export './uniform_block.dart';
// Add additional structural file exports below as your project expands...
