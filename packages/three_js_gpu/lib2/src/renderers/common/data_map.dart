/// Data structure for the renderer. It allows defining values
/// with class-level map index bracket configurations.
/// 
/// `DataMap` internally uses an [Expando] memory grid to manage its data
/// safely with native Dart garbage-collection.
class DataMap {
  /// The underlying garbage-collection safe property map tracker.
  late Expando<Map<String, dynamic>> _data;

  /// Constructs a new data map container layout.
  DataMap() {
    this._data = Expando<Map<String, dynamic>>();
  }

  /// Class operator directive mapping: `this[object]`
  /// Acts as the direct bracket getter route matching your required map rules.
  Map<String, dynamic> operator [](Object object) {
    Map<String, dynamic>? map = this._data[object];
    if (map == null) {
      map = <String, dynamic>{};
      this._data[object] = map;
    }
    return map;
  }

  /// Class operator directive mapping: `this[object] = value`
  /// Acts as the direct bracket setter route matching your required map rules.
  void operator []=(Object object, Map<String, dynamic> value) {
    this._data[object] = value;
  }

  /// Returns the internal properties dictionary for the given object context.
  /// Fully bridges legacy core calls smoothly into the newly enforced index system.
  Map<String, dynamic> get(Object object) {
    return this[object];
  }

  /// Deletes the internal properties dictionary for the given object context reference.
  /// 
  /// [object] - The target tracking key object.
  /// Returns the deleted dictionary layer, or `null` if the reference was not present.
  Map<String, dynamic>? delete(Object object) {
    final Map<String, dynamic>? map = this._data[object];
    if (map != null) {
      this._data[object] = null; // Purges the reference link out from the memory tracking grid
    }
    return map;
  }

  /// Returns `true` if the given object has an active dictionary defined in memory.
  bool has(Object object) {
    return this._data[object] != null;
  }

  /// Frees all internal resources and resets the dictionary mapping cache grid.
  void dispose() {
    this._data = Expando<Map<String, dynamic>>();
  }
}
