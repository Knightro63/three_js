class OpenGLException implements Exception {
  OpenGLException(this.message, this.error);

  final String message;
  final int error;

  @override
  String toString() => '$message GLES error $error ';
}

class ShaderPrecisionFormat{
  int rangeMin;
  int rangeMax;
  int precision;

  ShaderPrecisionFormat({
    this.rangeMin = 1, 
    this.rangeMax = 1, 
    this.precision = 1
  });
} 

class ActiveInfo{
  ActiveInfo(this.type,this.name,this.size);
  String name;
  int size;
  int type;
}

class WebGLTexture {
  final dynamic id;
  WebGLTexture(this.id);
}

class Program {
  final dynamic id;
  Program(this.id);
}

class Buffer {
  final dynamic id;
  Buffer(this.id);
}

class Renderbuffer {
  final dynamic id;
  Renderbuffer(this.id);
}

class Framebuffer{
  final dynamic id;
  Framebuffer(this.id);
}

class TransformFeedback{
  final dynamic id;
  TransformFeedback(this.id);
}

class VertexArrayObject{
  final dynamic id;
  VertexArrayObject(this.id);
}

class WebGLShader{
  final dynamic id;
  WebGLShader(this.id);
}

class UniformLocation{
  final dynamic id;
  UniformLocation(this.id);
}

class WebGLParameter{
  final dynamic id;
  WebGLParameter(this.id);
}