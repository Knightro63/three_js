/// A WebGPU backend utility module for managing the device's capabilities.
class WebGPUCapabilities {
  /// A reference to the WebGPU backend instance context.
  final dynamic backend;

  /// Constructs a new utility object.
  WebGPUCapabilities(this.backend);

  /// Returns the maximum anisotropy texture filtering value.
  int getMaxAnisotropy() {
    return 16;
  }

  /// Returns the maximum number of bytes available for uniform buffers.
  int getUniformBufferLimit() {
    // Navigates directly into the limits definition map of your active device
    return this.backend.device.limits.maxUniformBufferBindingSize.toInt();
  }
}
