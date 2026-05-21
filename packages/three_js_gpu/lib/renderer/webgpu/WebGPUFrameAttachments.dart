import 'package:gpux/gpux.dart'; // Adjust based on your exact gpux library paths

/// Internal tracking class for active framebuffer view channels.
/// Replaces Kotlin's 'internal data class' with a package-private Dart signature.
class WebGPUFramebufferAttachments {
  final GpuTextureView colorView;
  final GpuTextureView? depthView;

  const WebGPUFramebufferAttachments({
    required this.colorView,
    this.depthView,
  });

  // Replaying Kotlin's automatic value equality checks if utilized by the cache layers
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebGPUFramebufferAttachments &&
          runtimeType == other.runtimeType &&
          colorView == other.colorView &&
          depthView == other.depthView;

  @override
  int get hashCode => colorView.hashCode ^ depthView.hashCode;

  @override
  String toString() {
    return 'WebGPUFramebufferAttachments(colorView: $colorView, depthView: $depthView)';
  }
}
