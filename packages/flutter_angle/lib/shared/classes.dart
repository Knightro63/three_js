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
  // To suppress missing implicit constructor warnings.
  ActiveInfo(this.type,this.name,this.size);

  String name;

  int size;

  int type;
}