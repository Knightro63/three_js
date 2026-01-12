final String vertexShader = '''
  attribute vec3 tangent;

  // Terrain generation parameters
  uniform int type;
  uniform float radius;
  uniform float amplitude;
  uniform float sharpness;
  uniform float offset;
  uniform float period;
  uniform float persistence;
  uniform float lacunarity;
  uniform int octaves;

  // Bump mapping
  uniform float bumpStrength;
  uniform float bumpOffset;

  varying vec3 fragPosition;
  varying vec3 fragNormal;
  varying vec3 fragTangent;
  varying vec3 fragBitangent;

  void main() {
    // Calculate terrain height
    float h = terrainHeight(
      type,
      position,
      amplitude, 
      sharpness,
      offset,
      period, 
      persistence, 
      lacunarity, 
      octaves);

    vec3 pos = position * (radius + h);

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    fragPosition = position;
    fragNormal = normal;
    fragTangent = tangent;
    fragBitangent = cross(normal, tangent);
  }
''';