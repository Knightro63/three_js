import './full_screen_effect_pass.dart'; // Example import for Disposable

/// Manages a chain of post-processing passes for rendering effects.
///
/// `EffectComposer` provides:
/// - Pass chain management (add, remove, reorder)
/// - Size propagation to all passes
/// - Enable/disable filtering
/// - Resource lifecycle management
///
/// Usage:
/// ```dart
/// final composer = EffectComposer(width: 1920, height: 1080);
///
/// composer.addPass(FullScreenEffectPass.create((pass) {
///   pass.fragmentShader = vignetteShader;
/// }));
///
/// composer.addPass(FullScreenEffectPass.create((pass) {
///   pass.fragmentShader = colorGradingShader;
/// }));
///
/// // In render loop: iterate passes and render each
/// for (final pass in composer.getEnabledPasses()) {
///   // render pass...
/// }
/// ```
class EffectComposer{
  final List<FullScreenEffectPass> _passes = [];

  int _width;
  int _height;
  bool _isDisposed = false;

  /// Creates an instance of [EffectComposer].
  EffectComposer({
    int width = 0,
    int height = 0,
  })  : _width = width,
        _height = height;

  /// Read-only list of all passes in the chain.
  List<FullScreenEffectPass> get passes => List.unmodifiable(_passes);

  /// Number of passes in the chain.
  int get passCount => _passes.length;

  /// Current width in pixels.
  int get width => _width;

  /// Current height in pixels.
  int get height => _height;

  /// Whether this composer has been disposed.
  bool get isDisposed => _isDisposed;

  /// Adds a pass to the end of the chain.
  ///
  /// Throws a [StateError] if the composer has been disposed.
  void addPass(FullScreenEffectPass pass) {
    _checkNotDisposed();
    _passes.add(pass);
    pass.setSize(_width, _height);
  }

  /// Inserts a pass at the specified index.
  ///
  /// Throws a [StateError] if the composer has been disposed.
  /// Throws a [RangeError] if [index] is out of range.
  void insertPass(FullScreenEffectPass pass, int index) {
    _checkNotDisposed();
    // Dart's insert throws RangeError if index is out of bounds [0..length]
    _passes.insert(index, pass);
    pass.setSize(_width, _height);
  }

  /// Removes a pass from the chain.
  ///
  /// Returns `true` if the pass was found and removed.
  bool removePass(FullScreenEffectPass pass) {
    return _passes.remove(pass);
  }

  /// Removes the pass at the specified index.
  ///
  /// Returns the removed pass.
  /// Throws a [RangeError] if [index] is out of range.
  FullScreenEffectPass removePassAt(int index) {
    return _passes.removeAt(index);
  }

  /// Removes all passes from the chain.
  void clearPasses() {
    _passes.clear();
  }

  /// Updates the size and propagates to all passes.
  void setSize(int width, int height) {
    _width = width;
    _height = height;
    for (final pass in _passes) {
      pass.setSize(width, height);
    }
  }

  /// Swaps the positions of two passes.
  ///
  /// Throws a [RangeError] if either index is out of range.
  void swapPasses(int index1, int index2) {
    // Range check enforced manually to match Kotlin behavior before mutation
    if (index1 < 0 || index1 >= _passes.length) throw RangeError.index(index1, _passes);
    if (index2 < 0 || index2 >= _passes.length) throw RangeError.index(index2, _passes);

    final temp = _passes[index1];
    _passes[index1] = _passes[index2];
    _passes[index2] = temp;
  }

  /// Moves a pass from one index to another.
  ///
  /// Throws a [RangeError] if either index is out of range.
  void movePass(int fromIndex, int toIndex) {
    // removeAt handles the fromIndex validation automatically
    final pass = _passes.removeAt(fromIndex);
    
    try {
      _passes.insert(toIndex, pass);
    } catch (e) {
      // Rollback list state if toIndex fails validation
      _passes.insert(fromIndex, pass);
      rethrow;
    }
  }

  /// Returns only the enabled passes.
  ///
  /// Returns a list of passes where [FullScreenEffectPass.enabled] is true.
  List<FullScreenEffectPass> getEnabledPasses() {
    return _passes.where((pass) => pass.enabled).toList();
  }

  /// Disposes all passes and releases resources.
  ///
  /// After calling dispose, the composer cannot be used.
  /// This method is idempotent - multiple calls have no effect.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final pass in _passes) {
      pass.dispose();
    }
    _passes.clear();
  }

  /// Checks that the composer has not been disposed.
  /// 
  /// Throws a [StateError] if disposed.
  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError('EffectComposer has been disposed');
    }
  }
}
