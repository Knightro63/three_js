import 'dart:async';
import 'package:flutter_gpux/flutter_gpux.dart';
import 'package:three_js_core/three_js_core.dart';
import '../RendererConfig.dart';
import 'WebGPURenderer.dart';
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
  static Future<Renderer> create(GpuFrame frame) async {
    // 1. Evaluate cross-platform hardware access capabilities
    final gpuAvailable = WebGPUDetector.isAvailable();

    if (gpuAvailable) {
      console.info("INFO: WebGPU available - creating WebGPURenderer");
      try {
        final renderer = WebGPURenderer();
        final config = RendererConfig();
        
        await renderer.init(frame,config);
        console.info("INFO: WebGPURenderer initialized successfully");
        return renderer;
      } catch (e) {
        throw("WARNING: WebGPU initialization failed: ${e.toString()}");
      }
    } 
    else {
      throw("INFO: WebGPU not available - using legacy renderer pipeline");
    }
  }
}
