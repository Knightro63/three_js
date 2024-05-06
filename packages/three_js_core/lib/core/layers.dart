/// A [Layers] object assigns an [Object3D] to 1 or more of 32
/// layers numbered `0` to `31` - internally the layers are stored as a
/// [bit mask](https://en.wikipedia.org/wiki/Mask_(computing)), and by
/// default all Object3Ds are a member of layer 0.
///
/// This can be used to control visibility - an object must share a layer with
/// a [Camera] to be visible when that camera's view is
/// rendered.
///
/// All classes that inherit from [Object3D] have an
/// [Object3D.layers] property which is an instance of this class.
/// 
class Layers {
  int mask = 1 | 0;

  /// Create a new Layers object, with membership initially set to layer 0.
  Layers();

  /// [channel] - an integer from 0 to 31.
  /// 
  /// Set membership to `layer`, and remove membership all other layers.
  void set(int channel) => mask = (1 << channel | 0) >> 0;

  /// [channel] - an integer from 0 to 31.
  /// 
  /// Add membership of this `layer`.
  void enable(int channel) => mask = mask | (1 << channel | 0);

  /// Add membership to all layers.
  void enableAll() => mask = 0xffffffff | 0;

  /// [channel] - an integer from 0 to 31.
  /// 
  /// Toggle membership of `layer`.
  void toggle(int channel) => mask ^= 1 << channel | 0;

  /// [channel] - an integer from 0 to 31.
  /// 
  /// Remove membership of this `layer`.
  void disable(int channel) => mask &= ~(1 << channel | 0);

  /// Remove membership from all layers.
  void disableAll() => mask = 0;

  /// [layers] - a Layers object
  /// 
  /// Returns true if this and the passed `layers` object have at least one layer in common.
  bool test(Layers layers) => (mask & layers.mask) != 0;

  /// [channel] - an integer from 0 to 31.
  ///
  /// Returns true if the given layer is enabled.
  bool isEnabled(int channel) => (mask & (1 << channel | 0)) != 0;
}
