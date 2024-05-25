class OpenGLException implements Exception {
  OpenGLException(this.message, this.error);

  final String message;
  final int error;

  @override
  String toString() => '$message GLES error $error ';
}