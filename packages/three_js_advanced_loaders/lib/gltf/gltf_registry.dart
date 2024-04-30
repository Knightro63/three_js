class GLTFRegistry {
  Map<String,dynamic> objects = {};

  dynamic get(String key) {
    return objects[key];
  }

  void add(String key, object) {
    objects[key] = object;
  }

  void remove(String key) {
    // delete objects[ key ];
    objects.remove(key);
  }

  void removeAll() {
    objects = {};
  }
}
