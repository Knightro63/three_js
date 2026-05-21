import 'package:three_js_core/three_js_core.dart'; // Adjust imports to match your scene/camera locations

/// T022: Renderer Actual (Dart/Flutter)
/// Feature: 019-we-should-not
///
/// Interface declaration for the Renderer system.
/// Implemented by WebGPURenderer (primary) or WebGLRenderer (fallback).
abstract class Renderer {
  
  /// Identifies whether this is running on WebGPU or WebGL2
  BackendType get backend;

  /// Holds hardware capabilities discovered by the adapter
  RendererCapabilities get capabilities;

  /// Tracks active performance numbers (draw calls, triangles, textures)
  RenderStats get stats;

  /// Asynchronously hooks up contexts, devices, and swaps.
  /// Replaces Kotlin's `suspend fun` and custom `Result<Unit>` with a standard Dart Future.
  Future<void> initialize(RendererConfig config);

  /// Executes the core frame drawing loop
  void render(Scene scene, Camera camera);

  /// Resizes the frame buffers and swapchain constraints
  void resize(int width, int height);

  /// Frees buffers, pipelines, textures, and context bindings from memory
  void dispose();
}
