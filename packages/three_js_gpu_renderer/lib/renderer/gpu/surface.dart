import '../render_surface.dart'; // To extend RenderSurface interface

/// Gpu surface implementation wrapping a Flutter texture/surface platform resource.
///
/// Usage:
/// ```dart
/// final surface = GpuSurface(textureId: 1, initialWidth: 1024, initialHeight: 768);
/// final renderer = await RendererFactory.create(surface, config);
/// ```
class GpuSurface implements RenderSurface {
  final dynamic _platformHandle; // Holds the native Pointer or Flutter Texture ID integer
  
  int _width;
  int _height;

  GpuSurface({
    required dynamic handle,
    required int initialWidth,
    required int initialHeight,
  })  : _platformHandle = handle,
        _width = initialWidth,
        _height = initialHeight;

  /// Surface width in pixels.
  @override
  int get width => _width;

  /// Surface height in pixels.
  @override
  int get height => _height;

  /// Returns the underlying native handle (implements RenderSurface contract).
  @override
  dynamic getHandle() => _platformHandle;

  /// Get surface handle (typed alternative accessor matching layout conventions).
  dynamic getPlatformHandle() => _platformHandle;

  // /// Get Gpu context matching this surface handle hook.
  // /// @return [GpuContext] instance via gpux architecture hooks.
  // GpuContext? getGpuContext() {
  //   try {
  //     // Replaces canvas.getContext("Gpu") with cross-platform native context initialization
  //     return Gpu.createContextFromNativeHandle(_platformHandle);
  //   } catch (e) {
  //     console.error("ERROR: Failed to create Gpu canvas context: ${e.toString()}");
  //     return null;
  //   }
  // }

  /// Get WebGL2/OpenGL context (legacy rendering fallback).
  dynamic getWebGLContext() {
    try {
      // Return your wrapper package's legacy canvas context object or OpenGL interface target
      return _platformHandle; 
    } catch (_) {
      return null;
    }
  }

  /// Resize surface to new dimensional boundaries.
  ///
  /// @param width New width constraints in pixels.
  /// @param height New height constraints in pixels.
  void resize(int width, int height) {
    _width = width;
    _height = height;
    
    // If your underlying gpux backend tracks layout context updates,
    // push a viewport update down to your native platform channel thread here.
  }
}
