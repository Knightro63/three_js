final String atosphereVertexShader = '''
  attribute float size;

  varying vec3 fragPosition;

  void main() {
    vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
    gl_PointSize = size*(300.0/length(mvPosition.z));
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    fragPosition = (modelMatrix * vec4(position, 1.0)).xyz;
  }
''';