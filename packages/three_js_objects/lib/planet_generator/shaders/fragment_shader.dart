final String fragmentShader_old = '''
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

  // Layer colors
  uniform vec3 color1;
  uniform vec3 color2;
  uniform vec3 color3;
  uniform vec3 color4;
  uniform vec3 color5;
  
  // Transition points for each layer
  uniform float transition2;
  uniform float transition3;
  uniform float transition4;
  uniform float transition5;

  // Amount of blending between each layer
  uniform float blend12;
  uniform float blend23;
  uniform float blend34;
  uniform float blend45;

  // Bump mapping parameters
  uniform float bumpStrength;
  uniform float bumpOffset;

  // Lighting parameters
  uniform float ambientIntensity;
  uniform float diffuseIntensity;
  uniform float specularIntensity;
  uniform float shininess;
  uniform vec3 lightDirection;
  uniform vec3 lightColor;

  varying vec3 fragPosition;
  varying vec3 fragNormal;
  varying vec3 fragTangent;
  varying vec3 fragBitangent;

  void main() {
    // Calculate terrain height
    float h = terrainHeight(
      type,
      fragPosition,
      amplitude, 
      sharpness,
      offset,
      period, 
      persistence, 
      lacunarity, 
      octaves);

    vec3 dx = bumpOffset * fragTangent;
    float h_dx = terrainHeight(
      type,
      fragPosition + dx,
      amplitude, 
      sharpness,
      offset,
      period, 
      persistence, 
      lacunarity, 
      octaves);

    vec3 dy = bumpOffset * fragBitangent;
    float h_dy = terrainHeight(
      type,
      fragPosition + dy,
      amplitude, 
      sharpness,
      offset,
      period, 
      persistence, 
      lacunarity, 
      octaves);

    vec3 pos = fragPosition * (radius + h);
    vec3 pos_dx = (fragPosition + dx) * (radius + h_dx);
    vec3 pos_dy = (fragPosition + dy) * (radius + h_dy);

    // Recalculate surface normal post-bump mapping
    vec3 bumpNormal = normalize(cross(pos_dx - pos, pos_dy - pos));
    // Mix original normal and bumped normal to control bump strength
    vec3 N = normalize(mix(fragNormal, bumpNormal, bumpStrength));
  
    // Normalized light direction (points in direction that light travels)
    vec3 L = normalize(-lightDirection);
    // View vector from camera to fragment
    vec3 V = normalize(cameraPosition - pos);
    // Reflected light vector
    vec3 R = normalize(reflect(L, N));

    float diffuse = diffuseIntensity * max(0.0, dot(N, -L));

    // https://ogldev.org/www/tutorial19/tutorial19.html
    float specularFalloff = clamp((transition3 - h) / transition3, 0.0, 1.0);
    float specular = max(0.0, specularFalloff * specularIntensity * pow(dot(V, R), shininess));

    float light = ambientIntensity + diffuse + specular;

    // Blender colors layer by layer
    vec3 color12 = mix(
      color1, 
      color2, 
      smoothstep(transition2 - blend12, transition2 + blend12, h));

    vec3 color123 = mix(
      color12, 
      color3, 
      smoothstep(transition3 - blend23, transition3 + blend23, h));

    vec3 color1234 = mix(
      color123, 
      color4, 
      smoothstep(transition4 - blend34, transition4 + blend34, h));

    vec3 finalColor = mix(
      color1234, 
      color5, 
      smoothstep(transition5 - blend45, transition5 + blend45, h));
    
    gl_FragColor = vec4(light * finalColor * lightColor, 1.0);
  }
''';

final String fragmentShader = '''
  // Terrain generation parameters
  varying vec3 vWorldPosition; // Receive from Vertex
  uniform int type;
  uniform float radius;
  uniform float amplitude;
  uniform float sharpness;
  uniform float offset;
  uniform float period;
  uniform float persistence;
  uniform float lacunarity;
  uniform int octaves;

  // Layer colors
  uniform vec3 color1;
  uniform vec3 color2;
  uniform vec3 color3;
  uniform vec3 color4;
  uniform vec3 color5;
  
  // Transition points for each layer
  uniform float transition2;
  uniform float transition3;
  uniform float transition4;
  uniform float transition5;

  // Amount of blending between each layer
  uniform float blend12;
  uniform float blend23;
  uniform float blend34;
  uniform float blend45;

  // Bump mapping parameters
  uniform float bumpStrength;
  uniform float bumpOffset;

  // Lighting parameters
  uniform float ambientIntensity;
  uniform float diffuseIntensity;
  uniform float specularIntensity;
  uniform float shininess;
  uniform vec3 lightDirection;
  uniform vec3 lightColor;

  varying vec3 fragPosition;
  varying vec3 fragNormal;
  varying vec3 fragTangent;
  varying vec3 fragBitangent;

  varying float vHeight; // Receiving from Vertex

  void main() {
    float dist = distance(cameraPosition, vWorldPosition);
    float smoothLod = float(octaves);
    if (dist > 1000.0) {
      // Linear interpolation of the octave count
      float t = clamp((dist - 1000.0) / 300.0, 0.0, 1.0);
      smoothLod = mix(float(octaves), 2.0, t);
    }

    float h = terrainHeight(type, fragPosition, amplitude, sharpness, offset, period, persistence, lacunarity, smoothLod);

    vec3 dx = bumpOffset * fragTangent;
    float h_dx = terrainHeight(type, fragPosition + dx, amplitude, sharpness, offset, period, persistence, lacunarity, smoothLod);
    
    vec3 dy = bumpOffset * fragBitangent;
    float h_dy = terrainHeight(type, fragPosition + dy, amplitude, sharpness, offset, period, persistence, lacunarity, smoothLod);
    
    vec3 pos = fragPosition * (radius + h);
    vec3 pos_dx = (fragPosition + dx) * (radius + h_dx);
    vec3 pos_dy = (fragPosition + dy) * (radius + h_dy);
    vec3 N = normalize(mix(fragNormal, normalize(cross(pos_dx - pos, pos_dy - pos)), bumpStrength));
  
    vec3 L = normalize(-lightDirection);
    vec3 V = normalize(cameraPosition - pos);
    vec3 R = normalize(reflect(L, N));

    float diffuse = diffuseIntensity * max(0.0, dot(N, -L));
    float specularFalloff = clamp((transition3 - h) / transition3, 0.0, 1.0);
    float specular = max(0.0, specularFalloff * specularIntensity * pow(dot(V, R), shininess));
    float light = ambientIntensity + diffuse + specular;
    
    vec3 finalColor;
    if (h < transition2 + blend12) {
        finalColor = mix(color1, color2, smoothstep(transition2 - blend12, transition2 + blend12, h));
    } else if (h < transition3 + blend23) {
        finalColor = mix(color2, color3, smoothstep(transition3 - blend23, transition3 + blend23, h));
    } else if (h < transition4 + blend34) {
        finalColor = mix(color3, color4, smoothstep(transition4 - blend34, transition4 + blend34, h));
    } else {
        finalColor = mix(color4, color5, smoothstep(transition5 - blend45, transition5 + blend45, h));
    }

    gl_FragColor = vec4(light * finalColor * lightColor, 1.0);
}
''';