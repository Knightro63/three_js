import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import '../shared/webgl.dart';
import '../shared/classes.dart';
import 'dart:async';
import 'dart:ui';
import 'gles_bindings.dart';

class RenderingContext{
  final LibOpenGLES gl;
  dynamic _gl;

  //final int contextId;

  RenderingContext.create(this.gl){
    _gl = gl.gl;
  }

  void scissor(int x, int y, int width, int height){
    _gl.scissor(x, y, width, height);
  }

  void viewport(int x, int y, int width, int height) {
    _gl.viewport(x, y, width, height);
  }

  ShaderPrecisionFormat getShaderPrecisionFormat() {
    return ShaderPrecisionFormat();
  }

  Object? getExtension(String key) {
    return _gl.getExtension(key);
  }

  // getParameter(key) {
  //   _gl.getParameter(key);
  // }

  // getString(String key) {
  //   _gl.getParameter(key);
  // }

  WebGLTexture createTexture() {
    return WebGLTexture(_gl.createTexture());
  }

  void bindTexture(int target, WebGLTexture? texture) {
    _gl.bindTexture(target, texture?.id);
  }

  void drawElementsInstanced(int mode, int count, int type, int offset, int instanceCount) {
    _gl.drawElementsInstanced(mode, count, type, offset, instanceCount);
  }

  void activeTexture(int v0) {
    _gl.activeTexture(v0);
  }

  void texParameteri(int target, int pname, int param) {
    _gl.texParameteri(target, pname, param);
  }
  
  void checkError([String message = '']) {
    // final glError = _gl.glGetError();
    // if (glError != WebGL.NO_ERROR) {
    //   final openGLException = OpenGLException('RenderingContext.$message', glError);
    //   assert(() {
    //     print(openGLException.toString());
    //     return true;
    //   }());
    //   throw openGLException;
    // }
  }

  int getParameter(int key) {
    List<int> _intValues = [
      WebGL.MAX_TEXTURE_IMAGE_UNITS,
      WebGL.MAX_VERTEX_TEXTURE_IMAGE_UNITS,
      WebGL.MAX_TEXTURE_SIZE,
      WebGL.MAX_CUBE_MAP_TEXTURE_SIZE,
      WebGL.MAX_VERTEX_ATTRIBS,
      WebGL.MAX_VERTEX_UNIFORM_VECTORS,
      WebGL.MAX_VARYING_VECTORS,
      WebGL.MAX_FRAGMENT_UNIFORM_VECTORS,
      WebGL.MAX_SAMPLES,
      WebGL.MAX_COMBINED_TEXTURE_IMAGE_UNITS,
      WebGL.SCISSOR_BOX,
      WebGL.VIEWPORT
    ];

    if (_intValues.contains(key)) {
      dynamic val = _gl.getParameter(key);
      if(val is List<int>){
        return ByteData.view(Uint8List.fromList(val).buffer).getUint32(0);
      }
      return val;
    } 
    else {
      return key;
      throw (" OpenGL getParameter key: ${key} is not support ");
    }
  }

  Future<Image> loadImageFromAsset(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final loadingCompleter = Completer<Image>();
    decodeImageFromList(bytes.buffer.asUint8List(), (image) {
      loadingCompleter.complete(image);
    });
    return loadingCompleter.future;
  }

  Future<void> texImage2DfromImage(
    int target,
    Image image, {
    int level = 0,
    int internalformat = WebGL.RGBA,
    int format = WebGL.RGBA,
    int type = WebGL.UNSIGNED_BYTE,
  }) async {
    final completer = Completer<void>();
    final bytes = (await image.toByteData())!;
    final hblob = html.Blob([bytes]);
    final imageDom = html.ImageElement();
    imageDom.crossOrigin = "";
    imageDom.src = html.Url.createObjectUrl(hblob);
    
    imageDom.onLoad.listen((e) {
      completer.complete();
      texImage2D_NOSIZE(target, level, internalformat, format, type, imageDom);
    });
    
    return completer.future;
  }

  Future<void> texImage2DfromAsset(
    int target,
    String asset, {
    int level = 0,
    int internalformat = WebGL.RGBA,
    int format = WebGL.RGBA,
    int type = WebGL.UNSIGNED_BYTE,
  }) async {
    final completer = Completer<void>();
    final imageDom = html.ImageElement();
    imageDom.crossOrigin = "";
    imageDom.src = asset;
    imageDom.onLoad.listen((e) {
      texImage2D_NOSIZE(target, level, internalformat, format, type, imageDom);
      completer.complete();
    });

    return completer.future;
  }

  void texImage2D(
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
    _gl.texImage2D(target, level, internalformat, width, height, border, format, type, pixels);
  }

  void texImage2D_NOSIZE(    
    int target, 
    int level, 
    int internalformat, 
    int format, 
    int type, 
    html.Element? pixels
  ) { 
    _gl.texImage2D(target, level, internalformat, format, type, pixels);
  }

  //TODO
  void texImage3D(int target, int level, int internalformat, int width, int height, int depth, int border, int format, int type, TypedData? pixels) {
    _gl.texImage3D(target, level, internalformat, width, height, depth,border, format, type, pixels);
  }

  void depthFunc(int v0) {
    _gl.depthFunc(v0);
  }

  void depthMask(bool v0) {
    _gl.depthMask(v0);
  }

  void enable(int v0) {
    _gl.enable(v0);
  }

  void disable(int v0) {
    _gl.disable(v0);
  }

  void blendEquation(int v0) {
    _gl.blendEquation(v0);
  }

  void useProgram(Program? program) {
    _gl.useProgram(program?.id);
  }

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) {
    _gl.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
  }

  void blendFunc(int sfactor, int dfactor){
    _gl.blendFunc(sfactor, dfactor);
  }

  void blendEquationSeparate(int modeRGB, int modeAlpha){
    _gl.blendEquationSeparate(modeRGB, modeAlpha);
  }

  void frontFace(int mode) {
    _gl.frontFace(mode);
  }

  void cullFace(int mode) {
    _gl.cullFace(mode);
  }

  void lineWidth(double width) {
    _gl.lineWidth(width);
  }

  void polygonOffset(double factor, double units) {
    _gl.polygonOffset(factor, units);
  }

  void stencilMask(int mask) {
    _gl.stencilMask(mask);
  }

  void stencilFunc(int func, int ref, int mask){
    _gl.stencilFunc(func, ref, mask);
  }

  void stencilOp(int fail, int zfail, int zpass){
    _gl.stencilOp(fail, zfail, zpass);
  }

  void clearStencil(int s) {
    _gl.clearStencil(s);
  }

  void clearDepth(double depth){
    _gl.clearDepth(depth);
  }

  void colorMask(bool red, bool green, bool blue, bool alpha){
    _gl.colorMask(red, green, blue, alpha);
  }

  void clearColor(double red, double green, double blue, double alpha){
    _gl.clearColor(red, green, blue, alpha);
  }

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, TypedData? data){
    _gl.compressedTexImage2D(target, level, internalformat, width, height, border, data);
  }

  void generateMipmap(int target) {
    _gl.generateMipmap(target);
  }

  void deleteTexture(WebGLTexture? texture) {
    _gl.deleteTexture(texture?.id);
  }

  void deleteFramebuffer(Framebuffer? framebuffer) {
    _gl.deleteFramebuffer(framebuffer?.id);
  }

  void deleteRenderbuffer(Renderbuffer? renderbuffer) {
    _gl.deleteRenderbuffer(renderbuffer?.id);
  }

  void texParameterf(int target, int pname, double param) {
    _gl.texParameterf(target, pname, param);
  }

  void pixelStorei(int pname, int param) {
    _gl.pixelStorei(pname, param);
  }

  dynamic getContextAttributes() {
    return _gl.getContextAttributes();
  }

  WebGLParameter getProgramParameter(Program program, int pname) {
    return WebGLParameter(_gl.getProgramParameter(program.id, pname));
  }

  //TODO
  ActiveInfo getActiveUniform(Program v0, v1) {
    final val = _gl.getActiveUniform(v0.id, v1);
    return ActiveInfo(
      val.type,
      val.name,
      val.size
    );
  }
  
  ActiveInfo getActiveAttrib(Program v0, v1) {
    final val = _gl.getActiveAttrib(v0.id, v1);
    return ActiveInfo(
      val.type,
      val.name,
      val.size
    );
  }

  UniformLocation getUniformLocation(Program program, String name) {
    return UniformLocation(_gl.getUniformLocation(program.id, name));
  }

  void clear(int mask) {
    _gl.clear(mask);
  }

  Buffer createBuffer() {
    return Buffer(_gl.createBuffer());
  }

  void bindBuffer(int target, Buffer buffer) {
    _gl.bindBuffer(target, buffer.id);
  }

  void bufferData<T extends TypedData>(int target, T data, int usage) {
    _gl.bufferData(target, data, usage);
  }

  void vertexAttribPointer(int index, int size, int type, bool normalized, int stride, int offset) {
    _gl.vertexAttribPointer(index, size, type, normalized, stride, offset);
  }

  void drawArrays(int mode, int first, int count) {
    _gl.drawArrays(mode, first, count);
  }

  void drawArraysInstanced(int mode, int first, int count, int instanceCount){
    _gl.drawArraysInstanced(mode, first, count, instanceCount);
  }

  void bindFramebuffer(int target, Framebuffer? framebuffer){
    _gl.bindFramebuffer(target, framebuffer?.id);
  }

  int checkFramebufferStatus(int target) {
    return _gl.checkFramebufferStatus(target);
  }

  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level){
    _gl.framebufferTexture2D(target, attachment, textarget, texture.id, level);
  }

  void readPixels(int x, int y, int width, int height, int format, int type,pixels) {
    _gl.readPixels(x, y, width, height, format, type, pixels);
  }

  bool isProgram(Program program){
    return _gl.isProgram(program.id) != 0;
  }

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border){
    _gl.copyTexImage2D(
        target, level, internalformat, x, y, width, height, border);
  }

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height){
    _gl.copyTexSubImage2D(target, level, xoffset, yoffset, x,y,width, height);
  }

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, pixels) {
    _gl.texSubImage2D(target, level, xoffset, yoffset, width, height, format,type, pixels);
  }

  void texSubImage2D_NOSIZE(int target, int level, int xoffset, int yoffset, int format, int type, pixels){
    _gl.texSubImage2D(target, level, xoffset, yoffset, format, type, pixels);
  }

  void texSubImage3D(
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
    _gl.texSubImage3D(target, level, xoffset, yoffset, zoffset, width,height, depth, format, type, pixels);
  }

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, TypedData? pixels) {
    _gl.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, pixels);
  }

  void bindRenderbuffer(int target, Renderbuffer? framebuffer){
    _gl.bindRenderbuffer(target, framebuffer?.id);
  }

  void renderbufferStorageMultisample(int target, int samples, int internalformat, int width, int height){
    _gl.renderbufferStorageMultisample(target, samples, internalformat, width, height);
  }

  void renderbufferStorage(int target, int internalformat, int width, int height){
    _gl.renderbufferStorage(target, internalformat, width, height);
  }

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, Renderbuffer? renderbuffer){
    _gl.framebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer?.id);
  }

  Renderbuffer createRenderbuffer() {
    return Renderbuffer(_gl.createRenderbuffer());
  }

  Framebuffer createFramebuffer() {
    return Framebuffer(_gl.createFramebuffer());
  }

  void blitFramebuffer(int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, int mask, int filter){
    _gl.blitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
  }

  void bufferSubData(int target, int dstByteOffset, TypedData srcData, int srcOffset, int length){
    _gl.bufferSubData(target, dstByteOffset, srcData);
  }

  VertexArrayObject createVertexArray() {
    return VertexArrayObject(_gl.createVertexArray());
  }

  Program createProgram() {
    return Program(_gl.createProgram());
  }

  void attachShader(Program program, WebGLShader shader) {
    _gl.attachShader(program.id, shader.id);
  }

  void bindAttribLocation(Program program, int index, String name){
    _gl.bindAttribLocation(program.id, index, name);
  }

  void linkProgram(Program program, [bool checkForErrors = true]) {
    _gl.linkProgram(program.id);
  }

  String? getProgramInfoLog(Program program){
    return _gl.getProgramInfoLog(program.id);
  }

  String? getShaderInfoLog(WebGLShader shader) {
    return _gl.getShaderInfoLog(shader.id);
  }

  int getError() {
    return _gl.getError();
  }

  void deleteShader(WebGLShader shader) {
    _gl.deleteShader(shader.id);
  }

  void deleteProgram(Program program) {
    _gl.deleteProgram(program.id);
  }

  void deleteBuffer(Buffer buffer) {
    _gl.deleteBuffer(buffer.id);
  }

  void bindVertexArray(VertexArrayObject array) {
    _gl.bindVertexArray(array.id);
  }

  void deleteVertexArray(VertexArrayObject array) {
    _gl.deleteVertexArray(array.id);
  }

  void enableVertexAttribArray(int index) {
    _gl.enableVertexAttribArray(index);
  }

  void disableVertexAttribArray(int index) {
    _gl.disableVertexAttribArray(index);
  }

  void vertexAttribIPointer(int index, int size, int type, int stride, int pointer){
    _gl.vertexAttribIPointer(index, size, type, stride, pointer);
  }

  void vertexAttrib2fv(int index, List<double> values) {
    _gl.vertexAttrib2fv(index, values);
  }

  void vertexAttrib3fv(int index, List<double> values) {
    _gl.vertexAttrib3fv(index, values);
  }

  void vertexAttrib4fv(int index, List<double> values) {
    _gl.vertexAttrib4fv(index, values);;
  }

  void vertexAttrib1fv(int index, List<double> values) {
    _gl.vertexAttrib1fv(index, values);
  }

  void drawElements(int mode, int count, int type, int offset) {
    _gl.drawElements(mode, count, type, offset);
  }

  void drawBuffers(List<int> buffers) {
    _gl.drawBuffers(buffers);
  }

  WebGLShader createShader(int type) {
    return WebGLShader(_gl.createShader(type));
  }

  void shaderSource(WebGLShader shader, String shaderSource) {
    _gl.shaderSource(shader.id, shaderSource);
  }

  void compileShader(WebGLShader shader) {
    _gl.compileShader(shader.id);
  }

  bool getShaderParameter(WebGLShader shader, int pname){
    return _gl.getShaderParameter(shader.id, pname) == 0?false:true;
  }

  String? getShaderSource(WebGLShader shader) {
    return _gl.getShaderSource(shader.id);
  }

  void uniform1i(UniformLocation location, int x) {
    _gl.uniform1i(location.id, x);
  }

  void uniform3f(UniformLocation location, double x, double y, double z) {
    _gl.uniform3f(location.id, x, y, z);
  }

  void uniform4f(UniformLocation location, double x, double y, double z, double w){
    _gl.uniform4f(location.id, x, y, z,w);
  }

  void uniform1fv(UniformLocation location, List<double> v){
    _gl.uniform1fv(location.id, v);
  }

  void uniform2fv(UniformLocation location, List<double> v){
    _gl.uniform2fv(location.id, v);
  }

  void uniform3fv(UniformLocation location, List<double> v){
    _gl.uniform3fv(location.id, v);
  }

  void uniform1f(UniformLocation location, double x){
    _gl.uniform1f(location.id, x);
  }
  void uniformMatrix2fv(UniformLocation location, bool transpose, List<double> values) {
    _gl.uniformMatrix2fv(location.id, transpose, values);
  }

  void uniformMatrix3fv(UniformLocation location, bool transpose, List<double> values) {
    _gl.uniformMatrix3fv(location.id, transpose, values);
  }

  void uniformMatrix4fv(UniformLocation location, bool transpose, List<double> values) {
    _gl.uniformMatrix4fv(location.id, transpose, values);
  }

  UniformLocation getAttribLocation(Program program, String name) {
    return UniformLocation(_gl.getAttribLocation(program.id, name));
  }

  void uniform2f(UniformLocation location, double x, double y){
    _gl.uniform2f(location.id, x, y);
  }

  void uniform1iv(UniformLocation location, List<int> v){
    _gl.uniform1iv(location.id, v);
  }

  void uniform2iv(UniformLocation location, List<int> v){
    _gl.uniform2iv(location.id, v);
  }

  void uniform3iv(UniformLocation location, List<int> v){
    _gl.uniform3iv(location.id, v);
  }

  void uniform4iv(UniformLocation location, List<int> v){
    _gl.uniform4iv(location.id, v);
  }

  void uniform1uiv(UniformLocation? location, List<int> v){
    _gl.uniform1uiv(location?.id, v);
  }
  
  void uniform2uiv(UniformLocation? location, List<int> v){
    _gl.uniform2uiv(location?.id, v);
  }

  void uniform3uiv(UniformLocation? location, List<int> v){
    _gl.uniform3uiv(location?.id, v);
  }

  void uniform4uiv(UniformLocation? location, List<int> v){
    _gl.uniform4uiv(location?.id, v);
  }

  void uniform1ui(UniformLocation? location, int v0){
    _gl.uniform1ui(location?.id, v0);
  }

  void uniform2ui(UniformLocation? location, int v0, int v1){
    _gl.uniform2ui(location?.id, v0, v1);
    checkError('uniform2ui');
  }

  void uniform3ui(UniformLocation? location, int v0, int v1, int v2){
    _gl.uniform3ui(location?.id, v0, v1, v2);
    checkError('uniform2ui');
  }

  void uniform4ui(UniformLocation? location, int v0, int v1, int v2, int v3){
    _gl.uniform4ui(location?.id, v0, v1, v2, v3);
    checkError('uniform2ui');
  }

  void uniform4fv(UniformLocation location, List<double> vectors) {
    _gl.uniform4fv(location.id, vectors);
  }

  void vertexAttribDivisor(int index, int divisor){
    _gl.vertexAttribDivisor(index, divisor);
  }

  void flush() {
    _gl.flush();
  }

  void finish() {
    _gl.finish();
  }

  void texStorage2D(int target, int levels, int internalformat, int width, int height){
    _gl.texStorage2D(target, levels, internalformat, width, height);
  }

  void texStorage3D(int target, int levels, int internalformat, int width, int height, int depth){
    _gl.texStorage3D(target, levels, internalformat, width, height, depth);
  }

  TransformFeedback createTransformFeedback() {
    return TransformFeedback(_gl.createTransformFeedback());
  }
  
  void bindTransformFeedback(int target, TransformFeedback feedbeck){
    _gl.bindTransformFeedback(target, feedbeck.id);
  }

  void transformFeedbackVaryings(Program program, int count, List<String> varyings, int bufferMode) {
    _gl.transformFeedbackVaryings(program.id, varyings, bufferMode);
  }

  void deleteTransformFeedback(TransformFeedback transformFeedback) {
    _gl.deleteTransformFeedback(transformFeedback.id);
  }

  bool isTransformFeedback(TransformFeedback transformFeedback) {
    return _gl.isTransformFeedback(transformFeedback.id);
  }

  void beginTransformFeedback(int primitiveMode) {
    _gl.beginTransformFeedback(primitiveMode);
  }

  void endTransformFeedback() {
    _gl.endTransformFeedback();
  }

  void pauseTransformFeedback() {
    _gl.pauseTransformFeedback();
  }

  void resumeTransformFeedback() {
    _gl.resumeTransformFeedback();
  }

  ActiveInfo getTransformFeedbackVarying(int program, int index) {
    Map temp = _gl.getTransformFeedbackVarying(program, index);
    return ActiveInfo(temp['type'], temp['name'], temp['size']);
  }

  void invalidateFramebuffer(int target, List<int> attachments){
    _gl.invalidateFramebuffer(target, attachments);
  }

  Uint8List readCurrentPixels(int x, int y, int width, int height) {
    int _len = width * height * 4;
    var buffer = Uint8List(_len);
    _gl.readPixels(x, y, width, height, WebGL.RGBA, WebGL.UNSIGNED_BYTE, buffer);
    return buffer;
  }
}
