part of three_webgl;

int _id = 0;

class WebGLShaderCache {
  final shaderCache = {};
  final materialCache = {};

  WebGLShaderCache();

  WebGLShaderCache update(Material material) {
    final vertexShader = material.vertexShader;
    final fragmentShader = material.fragmentShader;

    final vertexShaderStage = _getShaderStage(vertexShader!);
    final fragmentShaderStage = _getShaderStage(fragmentShader!);

    final materialShaders = _getShaderCacheForMaterial(material);

    if (materialShaders.contains(vertexShaderStage) == false) {
      materialShaders.add(vertexShaderStage);
      vertexShaderStage.usedTimes++;
    }

    if (materialShaders.contains(fragmentShaderStage) == false) {
      materialShaders.add(fragmentShaderStage);
      fragmentShaderStage.usedTimes++;
    }

    return this;
  }

  WebGLShaderCache remove(Material material) {
    final materialShaders = materialCache[material];

    for (final shaderStage in materialShaders) {
      shaderStage.usedTimes--;

      if (shaderStage.usedTimes == 0) shaderCache.remove(shaderStage.code);
    }

    materialCache.remove(material);

    return this;
  }

  getVertexShaderID(Material material) {
    return _getShaderStage(material.vertexShader!).id;
  }

  getFragmentShaderID(Material material) {
    return _getShaderStage(material.fragmentShader!).id;
  }

  void dispose() {
    shaderCache.clear();
    materialCache.clear();
  }

  _getShaderCacheForMaterial(Material material) {
    final cache = materialCache;

    if (cache.containsKey(material) == false) {
      cache[material] = [];
    }

    return cache[material];
  }

  _getShaderStage(String code) {
    final cache = shaderCache;

    if (cache.containsKey(code) == false) {
      final stage = WebGLShaderStage(code);
      cache[code] = stage;
    }

    return cache[code];
  }
}

class WebGLShaderStage {
  late int id;
  late int usedTimes;
  late String code;

  WebGLShaderStage(this.code) {
    id = _id++;
    usedTimes = 0;
  }
}
