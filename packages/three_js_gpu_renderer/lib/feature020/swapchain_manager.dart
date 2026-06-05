/// Swapchain manager for presenting rendered frames.
/// Feature 020 - Production-Ready Renderer
///
/// Provides cross-platform swapchain management for acquiring images,
/// presenting to screen, and handling window resize.
abstract class SwapchainManager {
  /// Acquire next swapchain image for rendering.
  ///
  /// Blocks until image available (vsync).
  ///
  /// Returns a [SwapchainImage] ready for rendering.
  /// Throws a [SwapchainException] if acquire fails.
  SwapchainImage acquireNextImage();

  /// Present rendered image to screen.
  ///
  /// Throws a [SwapchainException] if present fails.
  void presentImage(SwapchainImage image);

  /// Recreate swapchain on window resize.
  ///
  /// Throws an [ArgumentError] if [width] or [height] <= 0.
  void recreateSwapchain(int width, int height);

  /// Get current swapchain extent.
  ///
  /// Returns a [SwapchainExtent] containing the width and height in pixels.
  SwapchainExtent getExtent();
}

/// Swapchain image structure for rendering operations.
class SwapchainImage {
  const SwapchainImage({
    this.handle,
    required this.index,
    required this.ready,
  });

  /// The underlying platform native texture or view handle.
  final dynamic handle;

  /// Index tracking of the surface image inside the swap chain allocation.
  final int index;

  /// Flag indicating if the image pipeline status is ready.
  final bool ready;

  /// Check whether the target image is ready for execution frame pipelines.
  bool isReady() => ready;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwapchainImage &&
          runtimeType == other.runtimeType &&
          handle == other.handle &&
          index == other.index &&
          ready == other.ready;

  @override
  int get hashCode => Object.hash(handle, index, ready);
}

/// A custom structural container class matching Kotlin's Pair layout for sizes.
class SwapchainExtent {
  const SwapchainExtent(this.width, this.height);

  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwapchainExtent &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Exception thrown when swapchain acquire/present operations fail.
class SwapchainException implements Exception {
  const SwapchainException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause != null) return 'SwapchainException: $message (Cause: $cause)';
    return 'SwapchainException: $message';
  }
}
