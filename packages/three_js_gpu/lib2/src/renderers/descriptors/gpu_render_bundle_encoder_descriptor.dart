import 'package:gpux/gpux.dart';

/// Reusable descriptor layout configuration for `GPUDevice.createRenderBundleEncoder()`.
class GPURenderBundleEncoderDescriptor {
  /// The label of the render bundle encoder.
  String label = '';

  /// The formats of the color attachments the bundle is compatible with.
  List<GpuTextureFormat>? colorFormats;

  /// The format of the depth/stencil attachment the bundle is compatible with.
  GpuTextureFormat? depthStencilFormat;

  /// The number of samples per pixel the bundle is compatible with.
  int sampleCount = 1;

  /// Whether the depth attachment is read-only.
  bool depthReadOnly = false;

  /// Whether the stencil attachment is read-only.
  bool stencilReadOnly = false;

  /// Constructs a new GPU render bundle encoder descriptor with explicit defaults.
  GPURenderBundleEncoderDescriptor() {
    this.reset();
  }

  /// Resets the descriptor fields back to its original default state 
  /// to enable safe object pooling and avoid reallocation costs.
  void reset() {
    this.label = '';
    this.colorFormats = null;
    this.depthStencilFormat = null;
    this.sampleCount = 1;
    this.depthReadOnly = false;
    this.stencilReadOnly = false;
  }
}
