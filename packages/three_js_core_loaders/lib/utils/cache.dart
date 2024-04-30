class Cache {
  static bool enabled = false;
  static Map<String, dynamic> files = {};

  static void add(String key, dynamic file) {
    if (enabled == false) return;
    //print( 'THREE.Cache Adding key: $key');
    files[key] = file;
  }

  static dynamic get(String key) {
    if (enabled == false) return;
    //print('THREE.Cache Checking key: $key');
    return files[key];
  }

  static void remove(key) {
    files.remove(key);
  }

  static void clear() {
    files.clear();
  }
}
