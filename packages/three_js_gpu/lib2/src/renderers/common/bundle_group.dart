import 'package:three_js_core/three_js_core.dart' as core;

/// A specialized group which enables applications access to the
/// Render Bundle API of WebGPU. The group with all its descendant nodes
/// are considered as one render bundle and processed as such by
/// the renderer.
///
/// This module is only fully supported by `WebGPURenderer` with a WebGPU backend.
/// With a WebGL backend, the group can technically be rendered but without
/// any performance improvements.
class BundleGroup extends core.Group {
  /// This flag can be used for type testing.
  final bool isBundleGroup = true;

  /// Whether the bundle is static or not. When set to `true`, the structure
  /// is assumed to be static and does not change. E.g. no new objects are
  /// added to the group.
  ///
  /// If a change is required, an update can still be forced by setting the
  /// `needsUpdate` flag to `true`.
  bool staticBundle = true;

  /// The bundle group's version identifier.
  int version = 0;

  /// Constructs a new bundle group container.
  BundleGroup() : super() {
    this.type = 'BundleGroup';
    this.staticBundle = true;
    this.version = 0;
  }

  /// Set this property to `true` when the bundle group has changed.
  set needsUpdate(bool value) {
    if (value == true) {
      this.version++;
    }
  }
}
