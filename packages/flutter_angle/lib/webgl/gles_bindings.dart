import 'dart:typed_data';
import '../shared/webgl.dart';
import '../shared/classes.dart';

class LibOpenGLES{
  late dynamic gl;
  LibOpenGLES(this.gl);

  void glScissor(int x, int y, int width, int height) {
    gl.scissor(x, y, width, height);
  }

  void glViewport(int x, int y, int width, int height){
    gl.viewport(x, y, width, height);
  }

  ShaderPrecisionFormat glGetShaderPrecisionFormat() {
    return ShaderPrecisionFormat();
  }

  // getExtension(String key) {
  //   gl.getExtension(key);
  // }

  // getParameter(key) {
  //   gl.getParameter(key);
  // }

  // getString(String key) {
  //   gl.getParameter(key);
  // }

  dynamic createTexture() {
    return gl.createTexture();
  }

  void glBindTexture(int type, int texture) {
    gl.bindTexture(type, texture);
  }

  void glDrawElementsInstanced(int mode, int count, int type, int offset, int instanceCount) {
    gl.drawElementsInstanced(mode, count, type, offset, instanceCount);
  }

  void glActiveTexture(int v0) {
    gl.activeTexture(v0);
  }

  void glTexParameteri(int target, int pname, int param) {
    gl.texParameteri(target, pname, param);
  }

  void glTexImage2D(
    int target, 
    int level, 
    int internalformat, 
    int width, 
    int height, 
    int border, 
    int format, 
    int type, 
    TypedData? pixels
  ) {    
    gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
  }

  void glTexImage2D_NOSIZE(    
    int target, 
    int level, 
    int internalformat, 
    int border, 
    int format, 
    int type, 
    TypedData? pixels
  ) { 
    gl.texImage2D(target, level, internalformat, format, type, pixels);
  }

  void glTexImage3D(int target, int level, int internalformat, int width, int height, int depth, int border, int format, int type, TypedData? pixels) {
    gl.texImage3D(target, level, internalformat, width, height, depth,border, format, type, pixels);
  }

  void glDepthFunc(int v0) {
    gl.depthFunc(v0);
  }

  void glDepthMask(bool v0) {
    gl.depthMask(v0);
  }

  void glEnable(int v0) {
    gl.enable(v0);
  }

  void glDisable(int v0) {
    gl.disable(v0);
  }

  void glBlendEquation(int v0) {
    gl.blendEquation(v0);
  }

  void glUseProgram(int program) {
    gl.useProgram(program);
  }

  void glBlendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) {
    gl.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
  }

  void glBlendFunc(int sfactor, int dfactor){
    gl.blendFunc(sfactor, dfactor);
  }

  void glBlendEquationSeparate(int modeRGB, int modeAlpha){
    gl.blendEquationSeparate(modeRGB, modeAlpha);
  }

  void glFrontFace(int mode) {
    gl.frontFace(mode);
  }

  void glCullFace(int mode) {
    gl.cullFace(mode);
  }

  void glLineWidth(double width) {
    gl.lineWidth(width);
  }

  void glPolygonOffset(double factor, double units) {
    gl.polygonOffset(factor, units);
  }

  void glStencilMask(int mask) {
    gl.stencilMask(mask);
  }

  void glStencilFunc(int func, int ref, int mask){
    gl.stencilFunc(func, ref, mask);
  }

  void glStencilOp(int fail, int zfail, int zpass){
    gl.stencilOp(fail, zfail, zpass);
  }

  void glClearStencil(int s) {
    gl.clearStencil(s);
  }

  void glClearDepthf(double depth) {
    gl.clearDepth(depth);
  }

  void glColorMask(bool red, bool green, bool blue, bool alpha) {
    gl.colorMask(red, green, blue, alpha);
  }

  void glClearColor(double red, double green, double blue, double alpha){
    gl.clearColor(red, green, blue, alpha);
  }

  void glCompressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, int imageSize, TypedData? data){
    gl.texImage2D(target, level, internalformat, width, height, border, imageSize, data);
  }

  void glGenerateMipmap(int target) {
    gl.generateMipmap(target);
  }

  void glDeleteTexture(int v0) {
    gl.deleteTexture(v0);
  }

  void glDeleteFramebuffer(int framebuffer) {
    gl.deleteFramebuffer(framebuffer);
  }

  void deleteRenderbuffer(int renderbuffer) {
    gl.deleteRenderbuffer(renderbuffer);
  }

  void texParameterf(int target, int pname, double param) {
    gl.texParameterf(target, pname, param);
  }

  void glPixelStorei(int pname, int param) {
    gl.pixelStorei(pname, param);
  }

  getContextAttributes() {
    gl.getContextAttributes();
  }

  void glGetProgramParameter(int program, int pname) {
    gl.getProgramParameter(program, pname);
  }

  //TODO
  getActiveUniform(v0, v1) {
    gl.getActiveUniform(v0, v1);
  }

  getActiveAttrib(v0, v1) {
    gl.getActiveAttrib(v0, v1);
  }

  void glGetUniformLocation(int program, String name) {
    gl.getUniformLocation(program, name);
  }

  void glClear(mask) {
    gl.clear(mask);
  }

  void glCreateBuffer() {
    gl.createBuffer();
  }

  void glBindBuffer(int target, int buffer) {
    gl.bindBuffer(target, buffer);
  }

  void glBufferData<T extends TypedData>(int target, T data, int usage) {
    gl.bufferData(target, data, usage);
  }

  void glVertexAttribPointer(int index, int size, int type, bool normalized, int stride, int offset) {
    gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
  }

  void glDrawArrays(int mode, int first, int count) {
    gl.drawArrays(mode, first, count);
  }

  void glDrawArraysInstanced(int mode, int first, int count, int instanceCount){
    gl.drawArraysInstanced(mode, first, count, instanceCount);
  }

  void glBindFramebuffer(int target, dynamic framebuffer){
    gl.bindFramebuffer(target, framebuffer);
  }

  int glCheckFramebufferStatus(int target) {
    return gl.checkFramebufferStatus(target);
  }

  void glFramebufferTexture2D(int target, int attachment, int textarget, int texture, int level){
    gl.framebufferTexture2D(target, attachment, textarget, texture, level);
  }

  void glReadPixels(int x, int y, int width, int height, int format, int type, TypedData? pixels) {
    gl.readPixels(x, y, width, height, format, type, pixels);
  }

  bool glIsProgram(int program){
    return gl.isProgram(program) != 0;
  }

  void glCopyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border){
    gl.copyTexImage2D(
        target, level, internalformat, x, y, width, height, border);
  }

  void glTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, TypedData? pixels) {
    gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
  }

  void glTexSubImage2D_NOSIZE(int target, int level, int xoffset, int yoffset, int format, int type, TypedData? pixels){
    gl.texSubImage2D(target, level, xoffset, yoffset, format, type, pixels);
  }

  void glTexSubImage3D(
    int target,
    int level,
    int xoffset,
    int yoffset,
    int zoffset,
    int width,
    int height,
    int depth,
    int format,
    int type,
    TypedData? pixels
  ) {
    gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels);
  }

  void glCompressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, TypedData? pixels) {
    gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, pixels);
  }

  void glBindRenderbuffer(int target, dynamic framebuffer){
    gl.bindRenderbuffer(target, framebuffer);
  }

  void glRenderbufferStorageMultisample(int target, int samples, int internalformat, int width, int height){
    gl.renderbufferStorageMultisample(target, samples, internalformat, width, height);
  }

  void glRenderbufferStorage(int target, int internalformat, int width, int height){
    gl.renderbufferStorage(target, internalformat, width, height);
  }

  void glFramebufferRenderbuffer(int target, int attachment, int renderbuffertarget, dynamic renderbuffer){
    gl.framebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer);
  }

  int glCreateRenderbuffer() {
    return gl.createRenderbuffer();
  }
  void glGenRenderbuffers(int count, List buffers) {
    for(int i = 0; i < count; i++){
     buffers.add(gl.createRenderbuffer());
    }
  }
  int glCreateFramebuffer() {
    return gl.createFramebuffer();
  }
  void glGenFramebuffers(int count, List buffers) {
    for(int i = 0; i < count; i++){
     buffers.add(gl.createFramebuffer());
    }
  }
  void glBlitFramebuffer(int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, int mask, int filter){
    gl.blitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
  }

  void glBufferSubData(int target, int dstByteOffset, TypedData srcData, int srcOffset, int length){
    gl.bufferSubData(target, dstByteOffset, srcData);
  }

  int glCreateVertexArray() {
    return gl.createVertexArray();
  }

  void glCreateProgram() {
    return gl.createProgram();
  }

  void glAttachShader(int program, int shader) {
    gl.attachShader(program, shader);
  }

  void glBindAttribLocation(int program, int index, String name){
    gl.bindAttribLocation(program, index, name);
  }

  void glLinkProgram(int program, [bool checkForErrors = true]) {
    gl.linkProgram(program);
  }

  String? getProgramInfoLog(int program) {
    return gl.getProgramInfoLog(program);
  }

  String? getShaderInfoLog(int shader){
    return gl.getShaderInfoLog(shader);
  }

  int glGetError() {
    return gl.getError();
  }

  void glDeleteShader(int shader) {
    gl.deleteShader(shader);
  }

  void glDeleteProgram(int program) {
    gl.deleteProgram(program);
  }

  void glDeleteBuffer(int buffer) {
    gl.deleteBuffer(buffer);
  }

  void glBindVertexArray(int array) {
    gl.bindVertexArray(array);
  }

  void glDeleteVertexArray(int array) {
    gl.deleteVertexArray(array);
  }

  void glEnableVertexAttribArray(int index) {
    gl.enableVertexAttribArray(index);
  }

  void glDisableVertexAttribArray(int index) {
    gl.disableVertexAttribArray(index);
  }

  void glVertexAttribIPointer(int index, int size, int type, int stride, int pointer){
    gl.vertexAttribIPointer(index, size, type, stride, pointer);
  }

  void glVertexAttrib2fv(int index, List<double> values) {
    gl.vertexAttrib2fv(index, values);
  }

  void glVertexAttrib3fv(int index, List<double> values) {
    gl.vertexAttrib3fv(index, values);
  }

  void glVertexAttrib4fv(int index, List<double> values) {
    gl.vertexAttrib4fv(index, values);
  }

  void glVertexAttrib1fv(int index, List<double> values) {
    gl.vertexAttrib1fv(index, values);
  }

  void glDrawElements(int mode, int count, int type, int offset) {
    gl.drawElements(mode, count, type, offset);
  }

  void glDrawBuffers(List<int> buffers) {
    gl.drawBuffers(buffers);
  }

  void glCreateShader(int type) {
    gl.createShader(type);
  }

  void glShaderSource(int shader, String shaderSource) {
    gl.shaderSource(shader, shaderSource);
  }

  void glCompileShader(int shader) {
    gl.compileShader(shader);
  }

  int glGetShaderParameter(int shader, int pname){
    return gl.getShaderParameter(shader, pname);
  }

  int glGetShaderSource(int shader) {
    return gl.getShaderSource(shader);
  }

  void glUniformMatrix4fv(int location, bool transpose, List<double> values) {
    gl.uniformMatrix4fv(location, transpose, values);
  }

  void glUniform1i(int location, int x) {
    gl.uniform1i(location, x);
  }

  void glUniform3f(int location, double x, double y, double z) {
    gl.uniform3f(location, x, y, z);
  }

  void glUniform4f(int location, double x, double y, double z, double w){
    gl.uniform4f(location, x, y, z,w);
  }

  void glUniform1fv(int location, List<double> v){
    gl.uniform1fv(location, v);
  }

  void glUniform2fv(int location, List<double> v){
    gl.uniform2fv(location, v);
  }

  void glUniform3fv(int location, List<double> v){
    gl.uniform3fv(location, v);
  }

  void glUniform1f(int location, double x){
    gl.uniform1f(location, x);
  }

  void glUniformMatrix3fv(int location, bool transpose, List<double> values) {
    gl.uniformMatrix3fv(location, transpose, values);
  }

  void glGetAttribLocation(int program, String name) {
    gl.getAttribLocation(program, name);
  }

  void glUniform2f(int location, double x, double y){
    gl.uniform2f(location, x, y);
  }

  void glUniform1iv(int location, List<int> v){
    gl.uniform1iv(location, v);
  }

  void glUniform2iv(int location, List<int> v){
    gl.uniform2iv(location, v);
  }

  void glUniform3iv(int location, List<int> v){
    gl.uniform3iv(location, v);
  }

  void glUniform4iv(int location, List<int> v){
    gl.uniform4iv(location, v);
  }

  void glUniform4fv(int location, List<double> vectors) {
    gl.uniform4fv(location, vectors);
  }

  void glVertexAttribDivisor(int index, int divisor){
    gl.vertexAttribDivisor(index, divisor);
  }

  void glFlush() {
    gl.flush();
  }

  void glFinish() {
    gl.finish();
  }

  void glTexStorage2D(int target, int levels, int internalformat, int width, int height){
    gl.texStorage2D(target, levels, internalformat, width, height);
  }

  void glTexStorage3D(int target, int levels, int internalformat, int width, int height, int depth){
    gl.texStorage3D(target, levels, internalformat, width, height, depth);
  }

  int glCreateTransformFeedback() {
    return gl.createTransformFeedback();
  }
  void glBindTransformFeedback(int target, int id){
    gl.bindTransformFeedback(target, id);
  }

  void glTransformFeedbackVaryings(int program, int count, List<String> varyings, int bufferMode) {
    gl.transformFeedbackVaryings(program, varyings, bufferMode);
  }

  void glDeleteTransformFeedback(int transformFeedback) {
    gl.deleteTransformFeedback(transformFeedback);
  }

  bool isTransformFeedback(int transformFeedback) {
    return gl.isTransformFeedback(transformFeedback);
  }

  void glBeginTransformFeedback(int primitiveMode) {
    gl.beginTransformFeedback(primitiveMode);
  }

  void glEndTransformFeedback() {
    gl.endTransformFeedback();
  }

  void glPauseTransformFeedback() {
    gl.pauseTransformFeedback();
  }

  void glResumeTransformFeedback() {
    gl.resumeTransformFeedback();
  }

  Map glGetTransformFeedbackVarying(int program, int index) {
    return gl.getTransformFeedbackVarying(program, index);
  }

  void glInvalidateFramebuffer(int target, List<int> attachments){
    gl.invalidateFramebuffer(target, attachments);
  }

  Uint8List readCurrentPixels(int x, int y, int width, int height) {
    int _len = width * height * 4;
    var buffer = Uint8List(_len);
    gl.readPixels(x, y, width, height, WebGL.RGBA, WebGL.UNSIGNED_BYTE, buffer);
    return buffer;
  }
}
