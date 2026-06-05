import 'dart:async';
import 'package:flutter_gpux/flutter_gpux.dart' as gpux;
import 'package:three_js_core/three_js_core.dart';
import '../renderer_config.dart';
import 'renderer.dart';
import 'detector.dart'; // Adjust to your project's interface locations

/// Factory for creating Gpu or WebGL/OpenGL renderer with automatic fallback.
/// 
/// NOTE: This factory is deprecated - use [RendererFactory] instead.
@Deprecated('Use RendererFactory instead. Scheduled for removal.')
class GpuRendererFactory {
  // Enforce non-instantiability to match Kotlin's object semantic
  GpuRendererFactory._();

  /// Creates a renderer, preferring Gpu but falling back to WebGL/OpenGL if unavailable.
  /// 
  /// @param surfaceHandle Platform-specific layer pointer (e.g., Flutter Texture ID channel)
  /// @return Renderer instance (GpuRenderer or WebGLRenderer)
  static Future<Renderer> create(gpux.GpuFrame frame) async {
    // 1. Evaluate cross-platform hardware access capabilities
    final gpuAvailable = GpuDetector.isAvailable();

    if (gpuAvailable) {
      console.info("INFO: Gpu available - creating GpuRenderer");
      try {
        final renderer = GpuRenderer();
        final config = RendererConfig();
        
        await renderer.init(frame,config);
        console.info("INFO: GpuRenderer initialized successfully");
        return renderer;
      } catch (e) {
        throw("WARNING: Gpu initialization failed: ${e.toString()}");
      }
    } 
    else {
      throw("INFO: Gpu not available - using legacy renderer pipeline");
    }
  }
}
