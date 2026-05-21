import 'dart:async';
import 'package:three_js_core/three_js_core.dart';
import 'WebGPUDetector.dart'; // Adjust to your project's interface locations

/// Factory for creating WebGPU or WebGL/OpenGL renderer with automatic fallback.
/// 
/// NOTE: This factory is deprecated - use [RendererFactory] instead.
@Deprecated('Use RendererFactory instead. Scheduled for removal.')
class WebGPURendererFactory {
  // Enforce non-instantiability to match Kotlin's object semantic
  WebGPURendererFactory._();

  /// Creates a renderer, preferring WebGPU but falling back to WebGL/OpenGL if unavailable.
  /// 
  /// @param surfaceHandle Platform-specific layer pointer (e.g., Flutter Texture ID channel)
  /// @return Renderer instance (WebGPURenderer or WebGLRenderer)
  static Future<Renderer> create(dynamic surfaceHandle) async {
    // 1. Evaluate cross-platform hardware access capabilities
    final gpuAvailable = WebGPUDetector.isAvailable();

    if (gpuAvailable) {
      print("INFO: WebGPU available - creating WebGPURenderer");
      try {
        final renderer = WebGPURenderer(surfaceHandle);
        final config = RendererConfig();
        
        await renderer.initialize(config);
        print("INFO: WebGPURenderer initialized successfully");
        return renderer;
      } catch (e) {
        print("WARNING: WebGPU initialization failed: ${e.toString()}");
        print("WARNING: Falling back to legacy backend renderer");
        return await _createWebGLFallback(surfaceHandle);
      }
    } else {
      print("INFO: WebGPU not available - using legacy renderer pipeline");
      return await _createWebGLFallback(surfaceHandle);
    }
  }

  /// Creates a WebGL/OpenGL renderer as fallback target workspace.
  static Future<Renderer> _createWebGLFallback(dynamic surfaceHandle) async {
    try {
      final renderer = WebGLRenderer(surfaceHandle);
      final config = RendererConfig();
      
      await renderer.initialize(config);
      print("INFO: WebGL/OpenGL renderer initialized successfully (fallback)");
      return renderer;
    } catch (e) {
      print("ERROR: Fallback graphics framework initialization failed: ${e.toString()}");
      rethrow; // Bounces the execution crash up to application layers
    }
  }
}
