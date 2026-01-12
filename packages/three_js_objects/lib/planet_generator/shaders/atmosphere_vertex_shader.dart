final String atosphereVertexShader = '''
  attribute float size;

  varying vec3 fragPosition;

  void main() {
    gl_PointSize = size;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    fragPosition = (modelMatrix * vec4(position, 1.0)).xyz;
  }
''';