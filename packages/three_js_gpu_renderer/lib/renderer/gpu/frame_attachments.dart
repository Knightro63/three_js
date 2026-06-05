import 'package:gpux/gpux.dart' as gpux; // Adjust based on your exact gpux library paths

/// Internal tracking class for active framebuffer view channels.
/// Replaces Kotlin's 'internal data class' with a package-private Dart signature.
class GpuFramebufferAttachments {
  final gpux.GpuTextureView colorView;
  final gpux.GpuTextureView? depthView;
  final gpux.GpuTextureView? resolveView;

  const GpuFramebufferAttachments({
    required this.colorView,
    this.depthView,
    this.resolveView
  });

  // Replaying Kotlin's automatic value equality checks if utilized by the cache layers
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GpuFramebufferAttachments &&
          runtimeType == other.runtimeType &&
          colorView == other.colorView &&
          depthView == other.depthView &&
          resolveView == other.resolveView;

  @override
  int get hashCode => colorView.hashCode ^ depthView.hashCode ^ resolveView.hashCode;

  @override
  String toString() {
    return 'GpuFramebufferAttachments(colorView: $colorView, depthView: $depthView, resolveView: $resolveView)';
  }
}
