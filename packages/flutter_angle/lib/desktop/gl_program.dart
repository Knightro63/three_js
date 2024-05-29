import '../shared/webgl.dart';
import '../shared/classes.dart';
import 'wrapper.dart';

class GlProgram {
  Map<String, int> attributes = new Map<String, int>();
  Map<String, UniformLocation> uniforms = new Map<String, UniformLocation>();
  late Program program;

  late WebGLShader fragShader, vertShader;

  GlProgram(
    RenderingContext gl,
    String fragSrc, 
    String vertSrc, 
    List<String> attributeNames, 
    List<String> uniformNames
  ) {
    fragShader = gl.createShader(WebGL.FRAGMENT_SHADER);
    gl.shaderSource(fragShader, fragSrc);
    gl.compileShader(fragShader);

    vertShader = gl.createShader(WebGL.VERTEX_SHADER);
    gl.shaderSource(vertShader, vertSrc);
    gl.compileShader(vertShader);

    program = gl.createProgram();
    gl.attachShader(program, vertShader);
    gl.attachShader(program, fragShader);
    gl.linkProgram(program);

    for (String attrib in attributeNames) {
      int attributeLocation = gl.getAttribLocation(program, attrib).id;
      gl.enableVertexAttribArray(attributeLocation);
      gl.checkError(attrib);
      attributes[attrib] = attributeLocation;
    }
    for (String uniform in uniformNames) {
      var uniformLocation = gl.getUniformLocation(program, uniform);
      gl.checkError(uniform);
      uniforms[uniform] = UniformLocation(uniformLocation.id);
    }
  }
}
