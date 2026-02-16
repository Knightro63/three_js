final String vertexShader_old = '''
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

final String vertexShader = '''
  attribute vec3 tangent;

  // Terrain generation parameters
  varying vec3 vWorldPosition; // Add this varying
  uniform int type;
  uniform float radius;
  uniform float amplitude;
  uniform float sharpness;
  uniform float offset;
  uniform float period;
  uniform float persistence;
  uniform float lacunarity;
  uniform int octaves;

  varying vec3 fragPosition;
  varying vec3 fragNormal;
  varying vec3 fragTangent;
  varying vec3 fragBitangent;
  varying float vHeight; // New: Pass height to fragment to save CPU/GPU cycles

  void main() {
    float worldDist = distance(cameraPosition, modelMatrix[3].xyz);
    float smoothLod = float(octaves);
    if (worldDist > 1000.0) {
      // Linear interpolation of the octave count
      float t = clamp((worldDist - 1000.0) / 300.0, 0.0, 1.0);
      smoothLod = mix(float(octaves), 2.0, t);
    }

    vHeight = terrainHeight(
      type, position, amplitude, sharpness, offset, 
      period, persistence, lacunarity, smoothLod
    );

    vec3 displacedPos = position * (radius + vHeight);

    vec4 worldPos = modelMatrix * vec4(displacedPos, 1.0);
    vWorldPosition = worldPos.xyz;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(displacedPos, 1.0);

    fragPosition = position;
    fragNormal = normal;
    fragTangent = tangent;
    fragBitangent = cross(normal, tangent);
  }
''';