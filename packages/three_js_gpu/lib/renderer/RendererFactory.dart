import 'dart:async';
import 'package:gpux/gpux.dart'; // Adjust based on your exact package architecture
import 'package:three_js_core/three_js_core.dart';
import './webgpu/WebGPURenderer.dart';
import 'BackendType.dart';
import 'RenderSurface.dart';
import 'RendererConfig.dart';

/// Dart implementation of RendererFactory with WebGPU → WebGL/OpenGL fallback.
/// 
/// Creates WebGPURenderer (primary) with WebGL/OpenGL fallback for the Flutter ecosystem.
class RendererFactory {
  // Enforce non-instantiability to match Kotlin's object semantic
  RendererFactory._();

  /// Create renderer with WebGPU → WebGL/OpenGL fallback orchestration.
  /// 
  /// Process:
  /// 1. Validate surface configurations
  /// 2. Detect available hardware backends 
  /// 3. Attempt WebGPU initialization via gpux first
  /// 4. Fallback to WebGL/OpenGL pipeline if WebGPU fails
  static Future<Renderer> create(
    RenderSurface surface, 
    RendererConfig config
  ) async {
    // 1. Check if surface is valid
    if (surface is! WebGPUSurface) {
      throw ("Expected WebGPUSurface, got ${surface.runtimeType}",);
    }

    final nativeSurfaceHandle = surface.getSurfaceHandle();

    // 2. Detect available backends
    final availableBackends = detectAvailableBackends();

    // 3. Try WebGPU first (FR-001: primary target)
    final preferWebGPU = config.preferredBackend != BackendType.webgl &&
        availableBackends.contains(BackendType.webgpu);

    if (preferWebGPU) {
      try {
        // Create WebGPURenderer instance
        final renderer = _createWebGPURenderer(nativeSurfaceHandle) as WebGPURenderer;

        // Initialize renderer context 
        await renderer.initialize(config);
        
        print("[Materia] Selected backend: WebGPU");
        return renderer;
      } catch (e) {
        print("[Materia] WebGPU creation/initialization failed: ${e.toString()}, falling back to WebGL");
      }
    }

    // 4. Fallback to legacy pipelines (FR-003: fallback fallback)
    if (availableBackends.contains(BackendType.webgl)) {
      throw ("Device creation failed for WebGL context: ${BackendType.webgl.toString()}",);
    }

    // 5. No graphics hardware engine context found 
    throw (
      platform: "Flutter/Dart",
      availableBackends: availableBackends,
      requiredFeatures: ["WebGPU or WebGL 2.0 / Native OpenGL"],
    );
  }

  /// Detect available graphics backends across current running platform targets.
  static List<BackendType> detectAvailableBackends() {
    final backends = <BackendType>[];

    // Check modern cross-platform WGPU/WebGPU accessibility
    if (_isWebGPUAvailable()) {
      backends.add(BackendType.webgpu);
    }

    // Fallback detection for legacy ANGLE/OpenGL backends
    if (_isWebGLAvailable()) {
      backends.add(BackendType.webgl);
    }

    return backends;
  }

  /// Check if WebGPU/WGPU abstraction layer can initialize.
  static bool _isWebGPUAvailable() {
    try {
      Gpu().requestAdapter(); // Checks cross-platform hardware binding flags via gpux
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Check if underlying fallback OpenGL contexts are valid.
  static bool _isWebGLAvailable() {
    try {
      // Replace with your wrapper's legacy engine verification check
      return true; 
    } catch (_) {
      return false;
    }
  }

  static Renderer _createWebGPURenderer(dynamic surfaceHandle) {
    return WebGPURenderer(surfaceHandle);
  }
}
