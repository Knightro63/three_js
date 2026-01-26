part of three_webgl;

class AngleShader {
  RenderingContext gl;
  dynamic shader;
  String content;

  AngleShader(this.gl, int type, this.content) {
    shader = gl.createShader(type);
    
    gl.shaderSource(shader, content);
    gl.compileShader(shader);

    final status = gl.getShaderParameter(shader, WebGL.COMPILE_STATUS);
    if (!status) {
      throw (" WebGLShader comile error.... _status: $content $status ${gl.getShaderInfoLog(shader)} ");
    }
  }
}
