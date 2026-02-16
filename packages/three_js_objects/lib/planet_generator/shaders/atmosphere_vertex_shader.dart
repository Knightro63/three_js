// final String atosphereVertexShader_old = '''
//   attribute float size;

//   varying vec3 fragPosition;

//   void main() {
//     vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
//     gl_PointSize = size*(300.0/length(mvPosition.z));
//     gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
//     fragPosition = (modelMatrix * vec4(position, 1.0)).xyz;
//   }
// ''';

final String atosphereVertexShader = '''
attribute float size;
varying vec3 fragPosition;

uniform float radius;
uniform float thickness;

void main() {
    // Project seed to sphere
    vec3 dir = normalize(position);
    
    // Quick pseudo-random for radius jitter
    float hash = fract(sin(dot(position, vec3(12.9, 78.2, 45.1))) * 43758.5);
    float r = radius + (hash * thickness);
    vec3 finalPos = dir * r;

    vec4 mvPosition = modelViewMatrix * vec4(finalPos, 1.0);
    gl_PointSize = size * (300.0 / length(mvPosition.z));
    gl_Position = projectionMatrix * mvPosition;

    // Pass world position for noise
    fragPosition = (modelMatrix * vec4(finalPos, 1.0)).xyz;
}
''';