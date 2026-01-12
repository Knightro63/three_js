final String atmosphereFragmentShader = '''
  uniform float time;
  uniform float speed;
  uniform float opacity;
  uniform float density;
  uniform float scale;

  uniform vec3 lightDirection;
  
  uniform vec3 color;
  uniform sampler2D pointTexture;

  varying vec3 fragPosition;

  vec2 rotateUV(vec2 uv, float rotation) {
      float mid = 0.5;
      return vec2(
          cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
          cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
      );
  }

  void main() {
    vec3 R = normalize(fragPosition);
    vec3 L = normalize(lightDirection);
    float light = max(0.05, dot(R, L));

    float n = simplex3((time * speed) + fragPosition / scale);
    float alpha = opacity * clamp(n + density, 0.0, 1.0);

    vec2 rotCoords = rotateUV(gl_PointCoord, n);
    gl_FragColor = vec4(light * color, alpha) * texture2D(pointTexture, gl_PointCoord);
  }
''';