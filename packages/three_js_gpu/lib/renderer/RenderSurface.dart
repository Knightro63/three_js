/// T023: RenderSurface Actual (Dart/Flutter)
/// Feature: 019-we-should-not
///
/// Abstract specification for the RenderSurface interface.
/// Implemented by your custom WebGPUSurface and legacy surface bindings.
abstract class RenderSurface {
  
  /// The horizontal pixel resolution of the active frame surface container.
  int get width;

  /// The vertical pixel resolution of the active frame surface container.
  int get height;

  /// Returns the underlying native resource handle (e.g., Flutter Texture ID or Surface pointer).
  /// Replaces Kotlin's generic `Any` type with Dart's flexible dynamic object type.
  dynamic getHandle();
}

class WebGPUSurface implements RenderSurface {
  @override
  final int width;
  
  @override
  final int height;
  
  final int flutterTextureId;

  WebGPUSurface({
    required this.width, 
    required this.height, 
    required this.flutterTextureId,
  });

  @override
  int getHandle() {
    return flutterTextureId; // Returns the ID matching your custom GPU texture channel
  }

  int getSurfaceHandle() {
    return flutterTextureId; // Returns the ID matching your custom GPU texture channel
  }
}
