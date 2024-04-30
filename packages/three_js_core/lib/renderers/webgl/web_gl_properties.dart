part of three_webgl;

class WebGLProperties {
  final properties = WeakMap<dynamic, Map<String, dynamic>?>();

  Map<String, dynamic> get(object) {
    Map<String, dynamic> map;

    if (!properties.contains(object)) {
      map = <String, dynamic>{};
      properties[object] = map;
    } else {
      map = properties[object]!;
    }

    return map;
  }

  void remove(object) {
    properties.remove(object);
  }

  void update(object, key, value) {
    final m = properties[object]!;

    m[key] = value;
  }

  void dispose() {}
}
