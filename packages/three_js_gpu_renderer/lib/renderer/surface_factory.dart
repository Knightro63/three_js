import 'render_surface.dart'; // Adjust imports to match your project paths

/// Flutter/Dart implementation of SurfaceFactory.
/// Creates WebGPUSurface from native texture or surface handles.
class SurfaceFactory {
  // Enforce non-instantiability to match Kotlin's object semantic
  SurfaceFactory._();

  /// Create WebGPUSurface from the incoming platform handle.
  /// 
  /// @param handle The platform handle (e.g., int for Flutter Texture ID, or native Pointer)
  /// @return RenderSurface ready for the WebGPU renderer
  /// @throws ArgumentError if the handle format is unsupported
  static RenderSurface create({
    required int width,
    required int height,
    required int flutterTextureId,
  }) {
    // Return your custom WebGPUSurface wrapping the identifier
    return GpuSurface(
      flutterTextureId: flutterTextureId,
      width: width,
      height: height,
    ); 
  }
}
