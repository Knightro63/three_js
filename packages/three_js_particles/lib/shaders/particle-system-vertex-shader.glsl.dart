const String ParticleSystemVertexShader = '''
  attribute float size;
  attribute float colorR;
  attribute float colorG;
  attribute float colorB;
  attribute float colorA;
  attribute float lifetime;
  attribute float startLifetime;
  attribute float rotation;
  attribute float startFrame;

  varying mat4 vPosition;
  varying vec4 vColor;
  varying float vLifetime;
  varying float vStartLifetime;
  varying float vRotation;
  varying float vStartFrame;

  #include <common>
  #include <logdepthbuf_pars_vertex>

  void main()
  {
    vColor = vec4(colorR, colorG, colorB, colorA);
    vLifetime = lifetime;
    vStartLifetime = startLifetime;
    vRotation = rotation;
    vStartFrame = startFrame;

    vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
    gl_PointSize = size * (100.0 / length(mvPosition.xyz));
    gl_Position = projectionMatrix * mvPosition;

    #include <logdepthbuf_vertex>
  }
''';