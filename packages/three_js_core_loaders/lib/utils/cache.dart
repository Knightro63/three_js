/// A simple caching system, used internally by [FileLoader].
class Cache {
  static bool enabled = false;
  static Map<String, dynamic> files = {};

  /// [key] — the [key] to reference the cached file
  /// by.
  /// 
  /// [file] — The file to be cached.
  /// 
  /// Adds a cache entry with a key to reference the file. If this key already
  /// holds a file, it is overwritten.
  static void add(String key, dynamic file) {
    if (enabled == false) return;
    //print( 'THREE.Cache Adding key: $key');
    files[key] = file;
  }

  /// [key] — A string key
  /// 
  /// Get the value of [key]. If the key does not exist `null`
  /// is returned.
  static dynamic get(String key) {
    if (enabled == false) return;
    //print('THREE.Cache Checking key: $key');
    return files[key];
  }

  /// [key] — A string key that references a cached file.
  /// 
  /// Remove the cached file associated with the key.
  static void remove(key) {
    files.remove(key);
  }

  /// Remove all values from the cache.
  static void clear() {
    files.clear();
  }
}
