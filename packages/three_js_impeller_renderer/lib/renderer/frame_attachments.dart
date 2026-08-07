import 'package:flutter_gpu/gpu.dart' as gpu; // Adjust based on your exact gpu library paths

/// Internal tracking class for active framebuffer view channels.
/// Replaces Kotlin's 'internal data class' with a package-private Dart signature.
class FramebufferAttachments {
  final gpu.Texture colorView;
  final gpu.Texture? depthView;
  final gpu.Texture? resolveView;

  const FramebufferAttachments({
    required this.colorView,
    this.depthView,
    this.resolveView
  });

  // Replaying Kotlin's automatic value equality checks if utilized by the cache layers
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FramebufferAttachments &&
          runtimeType == other.runtimeType &&
          colorView == other.colorView &&
          depthView == other.depthView &&
          resolveView == other.resolveView;

  @override
  int get hashCode => colorView.hashCode ^ depthView.hashCode ^ resolveView.hashCode;

  @override
  String toString() {
    return 'FramebufferAttachments(colorView: $colorView, depthView: $depthView, resolveView: $resolveView)';
  }
}
