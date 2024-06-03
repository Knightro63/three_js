import 'dart:io';

import 'bindings/gles_bindings.dart';
import 'dart:ffi';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'bindings/index.dart';
import '../shared/webgl.dart';
import '../shared/classes.dart';

// // The web wrapper uses this as base class everywhere

// // laong as we don't know if we need it, we use this dummy class
// class Interceptor {}

// class AngleInstancedArrays extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory AngleInstancedArrays._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE = 0x88FE;

//   void drawArraysInstancedAngle(int mode, int first, int count, int primcount);

//   void drawElementsInstancedAngle(int mode, int count, int type, int offset, int primcount);

//   void vertexAttribDivisorAngle(int index, int divisor);
// }

// class Canvas extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory Canvas._() {
//     throw new UnsupportedError("Not supported");
//   }

//   CanvasElement get canvas;

//   OffscreenCanvas? get offscreenCanvas;
// }

// class ColorBufferFloat extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory ColorBufferFloat._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// class CompressedTextureAstc extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory CompressedTextureAstc._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int COMPRESSED_RGBA_ASTC_10x10_KHR = 0x93BB;

//   static const int COMPRESSED_RGBA_ASTC_10x5_KHR = 0x93B8;

//   static const int COMPRESSED_RGBA_ASTC_10x6_KHR = 0x93B9;

//   static const int COMPRESSED_RGBA_ASTC_10x8_KHR = 0x93BA;

//   static const int COMPRESSED_RGBA_ASTC_12x10_KHR = 0x93BC;

//   static const int COMPRESSED_RGBA_ASTC_12x12_KHR = 0x93BD;

//   static const int COMPRESSED_RGBA_ASTC_4x4_KHR = 0x93B0;

//   static const int COMPRESSED_RGBA_ASTC_5x4_KHR = 0x93B1;

//   static const int COMPRESSED_RGBA_ASTC_5x5_KHR = 0x93B2;

//   static const int COMPRESSED_RGBA_ASTC_6x5_KHR = 0x93B3;

//   static const int COMPRESSED_RGBA_ASTC_6x6_KHR = 0x93B4;

//   static const int COMPRESSED_RGBA_ASTC_8x5_KHR = 0x93B5;

//   static const int COMPRESSED_RGBA_ASTC_8x6_KHR = 0x93B6;

//   static const int COMPRESSED_RGBA_ASTC_8x8_KHR = 0x93B7;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR = 0x93DB;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR = 0x93D8;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR = 0x93D9;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR = 0x93DA;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR = 0x93DC;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR = 0x93DD;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR = 0x93D0;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR = 0x93D1;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR = 0x93D2;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR = 0x93D3;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR = 0x93D4;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR = 0x93D5;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR = 0x93D6;

//   static const int COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR = 0x93D7;
// }

// // JS "WebGLCompressedTextureATC,WEBGL_compressed_texture_atc")
// class CompressedTextureAtc extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory CompressedTextureAtc._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int COMPRESSED_RGBA_ATC_EXPLICIT_ALPHA_WEBGL = 0x8C93;

//   static const int COMPRESSED_RGBA_ATC_INTERPOLATED_ALPHA_WEBGL = 0x87EE;

//   static const int COMPRESSED_RGB_ATC_WEBGL = 0x8C92;
// }

// // JS "WebGLCompressedTextureETC1,WEBGL_compressed_texture_etc1")
// class CompressedTextureETC1 extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory CompressedTextureETC1._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int COMPRESSED_RGB_ETC1_WEBGL = 0x8D64;
// }

// // JS "WebGLCompressedTextureETC")
// class CompressedTextureEtc extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory CompressedTextureEtc._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int COMPRESSED_R11_EAC = 0x9270;

//   static const int COMPRESSED_RG11_EAC = 0x9272;

//   static const int COMPRESSED_RGB8_ETC2 = 0x9274;

//   static const int COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9276;

//   static const int COMPRESSED_RGBA8_ETC2_EAC = 0x9278;

//   static const int COMPRESSED_SIGNED_R11_EAC = 0x9271;

//   static const int COMPRESSED_SIGNED_RG11_EAC = 0x9273;

//   static const int COMPRESSED_SRGB8_ALPHA8_ETC2_EAC = 0x9279;

//   static const int COMPRESSED_SRGB8_ETC2 = 0x9275;

//   static const int COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9277;
// }

// // JS "WebGLCompressedTexturePVRTC,WEBGL_compressed_texture_pvrtc")
// class CompressedTexturePvrtc extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory CompressedTexturePvrtc._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int COMPRESSED_RGBA_PVRTC_2BPPV1_IMG = 0x8C03;

//   static const int COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 0x8C02;

//   static const int COMPRESSED_RGB_PVRTC_2BPPV1_IMG = 0x8C01;

//   static const int COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 0x8C00;
// }

// // JS "WebGLCompressedTextureS3TC,WEBGL_compressed_texture_s3tc")
// class CompressedTextureS3TC extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory CompressedTextureS3TC._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

//   static const int COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;

//   static const int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

//   static const int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;
// }

// // JS "WebGLCompressedTextureS3TCsRGB")
// class CompressedTextureS3TCsRgb extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory CompressedTextureS3TCsRgb._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT = 0x8C4D;

//   static const int COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT = 0x8C4E;

//   static const int COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT = 0x8C4F;

//   static const int COMPRESSED_SRGB_S3TC_DXT1_EXT = 0x8C4C;
// }

// // JS "WebGLContextEvent")
// class ContextEvent extends Event {
//   // To suppress missing implicit constructor warnings.
//   factory ContextEvent._() {
//     throw new UnsupportedError("Not supported");
//   }

//   factory ContextEvent(String type, [Map? eventInit]) {
//     if (eventInit != null) {
//       var eventInit_1 = convertDartToNative_Dictionary(eventInit);
//       return ContextEvent._create_1(type, eventInit_1);
//     }
//     return ContextEvent._create_2(type);
//   }
//   static ContextEvent _create_1(type, eventInit) => JS('ContextEvent', 'new WebGLContextEvent(#,#)', type, eventInit);
//   static ContextEvent _create_2(type) => JS('ContextEvent', 'new WebGLContextEvent(#)', type);

//   String get statusMessage;
// }

// // JS "WebGLDebugRendererInfo,WEBGL_debug_renderer_info")
// class DebugRendererInfo extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory DebugRendererInfo._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int UNMASKED_RENDERER_WEBGL = 0x9246;

//   static const int UNMASKED_VENDOR_WEBGL = 0x9245;
// }

// // JS "WebGLDebugShaders,WEBGL_debug_shaders")
// class DebugShaders extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory DebugShaders._() {
//     throw new UnsupportedError("Not supported");
//   }

//   String? getTranslatedShaderSource(WebGLShader shader);
// }

// // JS "WebGLDepthTexture,WEBGL_depth_texture")
// class DepthTexture extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory DepthTexture._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int UNSIGNED_INT_24_8_WEBGL = 0x84FA;
// }

// // JS "WebGLDrawBuffers,WEBGL_draw_buffers")
// class DrawBuffers extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory DrawBuffers._() {
//     throw new UnsupportedError("Not supported");
//   }

//   //JS ('drawBuffersWEBGL')
//   void drawBuffersWebgl(List<int> buffers);
// }

// // JS "EXTsRGB,EXT_sRGB")
// class EXTsRgb extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory EXTsRgb._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT = 0x8210;

//   static const int SRGB8_ALPHA8_EXT = 0x8C43;

//   static const int SRGB_ALPHA_EXT = 0x8C42;

//   static const int SRGB_EXT = 0x8C40;
// }

// // JS "EXTBlendMinMax,EXT_blend_minmax")
// class ExtBlendMinMax extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory ExtBlendMinMax._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int MAX_EXT = 0x8008;

//   static const int MIN_EXT = 0x8007;
// }

// // JS "EXTColorBufferFloat")
// class ExtColorBufferFloat extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory ExtColorBufferFloat._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "EXTColorBufferHalfFloat")
// class ExtColorBufferHalfFloat extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory ExtColorBufferHalfFloat._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "EXTDisjointTimerQuery")
// class ExtDisjointTimerQuery extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory ExtDisjointTimerQuery._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int CURRENT_QUERY_EXT = 0x8865;

//   static const int GPU_DISJOINT_EXT = 0x8FBB;

//   static const int QUERY_COUNTER_BITS_EXT = 0x8864;

//   static const int QUERY_RESULT_AVAILABLE_EXT = 0x8867;

//   static const int QUERY_RESULT_EXT = 0x8866;

//   static const int TIMESTAMP_EXT = 0x8E28;

//   static const int TIME_ELAPSED_EXT = 0x88BF;

//   //JS ('beginQueryEXT')
//   void beginQueryExt(int target, TimerQueryExt query);

//   //JS ('createQueryEXT')
//   TimerQueryExt createQueryExt();

//   //JS ('deleteQueryEXT')
//   void deleteQueryExt(TimerQueryExt? query);

//   //JS ('endQueryEXT')
//   void endQueryExt(int target);

//   //JS ('getQueryEXT')
//   Object? getQueryExt(int target, int pname);

//   //JS ('getQueryObjectEXT')
//   Object? getQueryObjectExt(TimerQueryExt query, int pname);

//   //JS ('isQueryEXT')
//   bool isQueryExt(TimerQueryExt? query);

//   //JS ('queryCounterEXT')
//   void queryCounterExt(TimerQueryExt query, int target);
// }

// // JS "EXTDisjointTimerQueryWebGL2")
// class ExtDisjointTimerQueryWebGL2 extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory ExtDisjointTimerQueryWebGL2._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int GPU_DISJOINT_EXT = 0x8FBB;

//   static const int QUERY_COUNTER_BITS_EXT = 0x8864;

//   static const int TIMESTAMP_EXT = 0x8E28;

//   static const int TIME_ELAPSED_EXT = 0x88BF;

//   //JS ('queryCounterEXT')
//   void queryCounterExt(Query query, int target);
// }

// // JS "EXTFragDepth,EXT_frag_depth")
// class ExtFragDepth extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory ExtFragDepth._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "EXTShaderTextureLOD,EXT_shader_texture_lod")
// class ExtShaderTextureLod extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory ExtShaderTextureLod._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "EXTTextureFilterAnisotropic,EXT_texture_filter_anisotropic")
// class ExtTextureFilterAnisotropic extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory ExtTextureFilterAnisotropic._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int MAX_TEXTURE_MAX_ANISOTROPY_EXT = 0x84FF;

//   static const int TEXTURE_MAX_ANISOTROPY_EXT = 0x84FE;
// }

// // JS "WebGLFramebuffer")
// class Framebuffer extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory Framebuffer._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "WebGLGetBufferSubDataAsync")
// class GetBufferSubDataAsync extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory GetBufferSubDataAsync._() {
//     throw new UnsupportedError("Not supported");
//   }

//   Future getBufferSubDataAsync(int target, int srcByteOffset, TypedData dstData, [int? dstOffset, int? length]) =>
//       promiseToFuture(
//           JS("", "#.getBufferSubDataAsync(#, #, #, #, #)", this, target, srcByteOffset, dstData, dstOffset, length));
// }

// // JS "WebGLLoseContext,WebGLExtensionLoseContext,WEBGL_lose_context")
// class LoseContext extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory LoseContext._() {
//     throw new UnsupportedError("Not supported");
//   }

//   void loseContext();

//   void restoreContext();
// }

// // JS "OESElementIndexUint,OES_element_index_uint")
// class OesElementIndexUint extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory OesElementIndexUint._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "OESStandardDerivatives,OES_standard_derivatives")
// class OesStandardDerivatives extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory OesStandardDerivatives._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;
// }

// // JS "OESTextureFloat,OES_texture_float")
// class OesTextureFloat extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory OesTextureFloat._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "OESTextureFloatLinear,OES_texture_float_linear")
// class OesTextureFloatLinear extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory OesTextureFloatLinear._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "OESTextureHalfFloat,OES_texture_half_float")
// class OesTextureHalfFloat extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory OesTextureHalfFloat._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int HALF_FLOAT_OES = 0x8D61;
// }

// // JS "OESTextureHalfFloatLinear,OES_texture_half_float_linear")
// class OesTextureHalfFloatLinear extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory OesTextureHalfFloatLinear._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "OESVertexArrayObject,OES_vertex_array_object")
// class OesVertexArrayObject extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory OesVertexArrayObject._() {
//     throw new UnsupportedError("Not supported");
//   }

//   static const int VERTEX_ARRAY_BINDING_OES = 0x85B5;

//   //JS ('bindVertexArrayOES')
//   void bindVertexArray(VertexArrayObjectOes? arrayObject);

//   //JS ('createVertexArrayOES')
//   VertexArrayObjectOes createVertexArray();

//   //JS ('deleteVertexArrayOES')
//   void deleteVertexArray(VertexArrayObjectOes? arrayObject);

//   //JS ('isVertexArrayOES')
//   bool isVertexArray(VertexArrayObjectOes? arrayObject);
// }

// JS "WebGLProgram")



// // JS "WebGLQuery")
// class Query extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory Query._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// JS "WebGL2RenderingContext")
class RenderingContext {
  final LibOpenGLES gl;
  RenderingContext.create(this.gl);

  /// As allocating and freeing native memory is expensive and we need regularly
  /// buffers to receive values from FFI function we create a small set here that will
  /// be reused constantly
  /// 
  void checkError([String message = '']) {
    final glError = gl.glGetError();
    if (glError != WebGL.NO_ERROR) {
      final openGLException = OpenGLException('RenderingContext.$message', glError);
      // assert(() {
        print(openGLException.toString());
      //   return true;
      // }());
      // throw openGLException;
    }
  }

  // From WebGL2RenderingContextBase

  // void beginQuery(int target, Query query);

  void beginTransformFeedback(int primitiveMode){
    gl.glBeginTransformFeedback(primitiveMode);
    // checkError('beginTransformFeedback');
  }

  // void bindBufferBase(int target, int index, Buffer? buffer);

  // void bindBufferRange(int target, int index, Buffer? buffer, int offset, int size);

  // void bindSampler(int unit, Sampler? sampler);

  void bindTransformFeedback(int target, TransformFeedback feedback){
    gl.glBindTransformFeedback(target, feedback.id);
    // checkError('bindTransformFeedback');
  }

  void bindVertexArray(VertexArrayObject array){
    gl.glBindVertexArray(array.id);
    // checkError('bindVertexArray');
  }

  void blitFramebuffer(int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, int mask, int filter){
    gl.glBlitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
    // checkError('blitFramebuffer');
  }

  // //JS ('bufferData')
  // void bufferData2(int target, TypedData srcData, int usage, int srcOffset, [int? length]);

  // //JS ('bufferSubData')
  void bufferSubData(int target, int dstByteOffset, TypedData srcData){
    Pointer<Float>? nativeBuffer;
    late int size;
    if (srcData is List<double> || srcData is Float32List) {
      nativeBuffer = floatListToArrayPointer(srcData as List<double>).cast();
      size = srcData.lengthInBytes * sizeOf<Float>();
    } 
    else if (srcData is Int32List) {
      nativeBuffer = int32ListToArrayPointer(srcData).cast();
      size = srcData.length * sizeOf<Int32>();
    } 
    else if (srcData is Uint16List) {
      nativeBuffer = uInt16ListToArrayPointer(srcData).cast();
      size = srcData.length * sizeOf<Uint16>();
    } 
    else if (srcData is Uint8List) {
      nativeBuffer = uInt8ListToArrayPointer(srcData).cast();
      size = srcData.length * sizeOf<Uint16>();
    } 

    gl.glBufferSubData(target, dstByteOffset, size, nativeBuffer != null ? nativeBuffer.cast() : nullptr);
    
    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texSubImage2D');
  }

  // void clearBufferfi(int buffer, int drawbuffer, num depth, int stencil);

  // void clearBufferfv(int buffer, int drawbuffer, value, [int? srcOffset]);

  // void clearBufferiv(int buffer, int drawbuffer, value, [int? srcOffset]);

  // void clearBufferuiv(int buffer, int drawbuffer, value, [int? srcOffset]);

  // int clientWaitSync(Sync sync, int flags, int timeout);

  // //JS ('compressedTexImage2D')
  // void compressedTexImage2D2(
  //     int target, int level, int internalformat, int width, int height, int border, TypedData data, int srcOffset,
  //     [int? srcLengthOverride]);

  // //JS ('compressedTexImage2D')
  // void compressedTexImage2D3(
  //     int target, int level, int internalformat, int width, int height, int border, int imageSize, int offset);

  // void compressedTexImage3D(
  //     int target, int level, int internalformat, int width, int height, int depth, int border, TypedData data,
  //     [int? srcOffset, int? srcLengthOverride]);

  // //JS ('compressedTexImage3D')
  // void compressedTexImage3D2(int target, int level, int internalformat, int width, int height, int depth, int border,
  //     int imageSize, int offset);

  // //JS ('compressedTexSubImage2D')
  // void compressedTexSubImage2D2(
  //     int target, int level, int xoffset, int yoffset, int width, int height, int format, TypedData data, int srcOffset,
  //     [int? srcLengthOverride]);

  // //JS ('compressedTexSubImage2D')
  // void compressedTexSubImage2D3(
  //     int target, int level, int xoffset, int yoffset, int width, int height, int format, int imageSize, int offset);

  // void compressedTexSubImage3D(int target, int level, int xoffset, int yoffset, int zoffset, int width, int height,
  //     int depth, int format, TypedData data,
  //     [int? srcOffset, int? srcLengthOverride]);

  // //JS ('compressedTexSubImage3D')
  // void compressedTexSubImage3D2(int target, int level, int xoffset, int yoffset, int zoffset, int width, int height,
  //     int depth, int format, int imageSize, int offset);

  // void copyBufferSubData(int readTarget, int writeTarget, int readOffset, int writeOffset, int size);

  // void copyTexSubImage3D(
  //     int target, int level, int xoffset, int yoffset, int zoffset, int x, int y, int width, int height);

  // Query? createQuery();

  // Sampler? createSampler();

  TransformFeedback createTransformFeedback() {
    final vPointer = calloc<Uint32>();
    gl.glGenTransformFeedbacks(1, vPointer);
    int _v = vPointer.value;
    calloc.free(vPointer);
    return TransformFeedback(_v);
  }
  VertexArrayObject createVertexArray(){
    final v = calloc<Uint32>();
    gl.glGenVertexArrays(1, v);
    int _v = v.value;
    calloc.free(v);
    return VertexArrayObject(_v);
  }

  // void deleteQuery(Query? query);

  // void deleteSampler(Sampler? sampler);

  // void deleteSync(Sync? sync);

  void deleteTransformFeedback(TransformFeedback feedback){
    final List<int> _texturesList = [feedback.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteTransformFeedbacks(1, ptr);
    calloc.free(ptr);
    // checkError('deleteTransformFeedback');
  }

  void deleteVertexArray(VertexArrayObject array){
    final List<int> _texturesList = [array.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteVertexArrays(1, ptr);
    calloc.free(ptr);
    // checkError('deleteFramebuffer');
  }

  void drawArraysInstanced(int mode, int first, int count, int instanceCount){
    gl.glDrawArraysInstanced(mode, first, count, instanceCount);
    // checkError('drawArraysInstanced');
  }

  void drawBuffers(List<int> buffers){
    final ptr = calloc<Uint32>(buffers.length);
    ptr.asTypedList(buffers.length).setAll(0, List<int>.from(buffers));
    gl.glDrawBuffers(buffers.length, ptr);
    calloc.free(ptr);
  }

  void drawElementsInstanced(int mode, int count, int type, int offset, int instanceCount){
    var indices = Pointer<Void>.fromAddress(offset);
    gl.glDrawElementsInstanced(mode, count, type, indices, instanceCount);
    // checkError('drawElementsInstanced');
    calloc.free(indices);
  }

  // void drawRangeElements(int mode, int start, int end, int count, int type, int offset);

  // void endQuery(int target);

  void endTransformFeedback(){
    gl.glEndTransformFeedback();
    // checkError('endTransformFeedback');
  }

  // Sync? fenceSync(int condition, int flags);

  // void framebufferTextureLayer(int target, int attachment, WebGLTexture? texture, int level, int layer);

  // String? getActiveUniformBlockName(Program program, int uniformBlockIndex);

  // Object? getActiveUniformBlockParameter(Program program, int uniformBlockIndex, int pname);

  // Object? getActiveUniforms(Program program, List<int> uniformIndices, int pname);

  // void getBufferSubData(int target, int srcByteOffset, TypedData dstData, [int? dstOffset, int? length]);

  // int getFragDataLocation(Program program, String name);

  // Object? getIndexedParameter(int target, int index);

  // Object? getInternalformatParameter(int target, int internalformat, int pname);

  // Object? getQuery(int target, int pname);

  // Object? getQueryParameter(Query query, int pname);

  // Object? getSamplerParameter(Sampler sampler, int pname);

  // Object? getSyncParameter(Sync sync, int pname);

  ActiveInfo getTransformFeedbackVarying(int program, int index) {
    int maxLen = 100;
    var length = calloc<Int32>();
    var size = calloc<Int32>();
    var type = calloc<Uint32>();
    var name = calloc<Int8>(maxLen);

    gl.glGetTransformFeedbackVarying(program, index, maxLen - 1, length, size, type, name);

    int _type = type.value;
    String _name = name.cast<Utf8>().toDartString();
    int _size = size.value;

    calloc.free(type);
    calloc.free(name);
    calloc.free(size);
    calloc.free(length);

    return ActiveInfo(_type, _name, _size);
  }

  // int getUniformBlockIndex(Program program, String uniformBlockName);

  // List<int>? getUniformIndices(Program program, List<String> uniformNames) {
  //   List uniformNames_1 = convertDartToNative_StringArray(uniformNames);
  //   return _getUniformIndices_1(program, uniformNames_1);
  // }

  // //JS ('getUniformIndices')
  // List<int>? _getUniformIndices_1(Program program, List uniformNames);

  void invalidateFramebuffer(int target, List<int> attachments){
    int count = attachments.length;
    final valuePtr = calloc<Uint32>(count);
    valuePtr.asTypedList(count).setAll(0, attachments);
    gl.glInvalidateFramebuffer(target, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('invalidateFramebuffer'); 
  }

  // void invalidateSubFramebuffer(int target, List<int> attachments, int x, int y, int width, int height);

  // bool isQuery(Query? query);

  // bool isSampler(Sampler? sampler);

  // bool isSync(Sync? sync);

  bool isTransformFeedback(TransformFeedback feedback){
    return gl.glIsTransformFeedback(feedback.id) == 0?false:true;
  }

  // bool isVertexArray(VertexArrayObject? vertexArray);

  void pauseTransformFeedback(){
    gl.glPauseTransformFeedback();
    // checkError('pauseTransformFeedback'); 
  }

  // void readBuffer(int mode);

  // //JS ('readPixels')
  // void readPixels2(int x, int y, int width, int height, int format, int type, dstData_OR_offset, [int? offset]);

  void renderbufferStorageMultisample(int target, int samples, int internalformat, int width, int height){
    gl.glRenderbufferStorageMultisample(target, samples, internalformat, width, height);
    // checkError('renderbufferStorageMultisample');
  }

  void resumeTransformFeedback(){
    gl.glResumeTransformFeedback();
    // checkError('resumeTransformFeedback');
  }

  // void samplerParameterf(Sampler sampler, int pname, num param);

  // void samplerParameteri(Sampler sampler, int pname, int param);

  // void texImage2D2(int target, int level, int internalformat, int width, int height, int border, int format, int type,
  //     bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video,
  //     [int? srcOffset]) {
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is int) && srcOffset == null) {
  //     _texImage2D2_1(target, level, internalformat, width, height, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is ImageData) && srcOffset == null) {
  //     var data_1 = convertDartToNative_ImageData(bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     _texImage2D2_2(target, level, internalformat, width, height, border, format, type, data_1);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is ImageElement) && srcOffset == null) {
  //     _texImage2D2_3(target, level, internalformat, width, height, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is CanvasElement) && srcOffset == null) {
  //     _texImage2D2_4(target, level, internalformat, width, height, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is VideoElement) && srcOffset == null) {
  //     _texImage2D2_5(target, level, internalformat, width, height, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is ImageBitmap) && srcOffset == null) {
  //     _texImage2D2_6(target, level, internalformat, width, height, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     return;
  //   }
  //   if (srcOffset != null && (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is TypedData)) {
  //     _texImage2D2_7(target, level, internalformat, width, height, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video, srcOffset);
  //     return;
  //   }
  //   throw new ArgumentError("Incorrect number or type of arguments");
  // }

  // //JS ('texImage2D')
  // void _texImage2D2_1(target, level, internalformat, width, height, border, format, type, int offset);
  // //JS ('texImage2D')
  // void _texImage2D2_2(target, level, internalformat, width, height, border, format, type, data);
  // //JS ('texImage2D')
  // void _texImage2D2_3(target, level, internalformat, width, height, border, format, type, ImageElement image);
  // //JS ('texImage2D')
  // void _texImage2D2_4(target, level, internalformat, width, height, border, format, type, CanvasElement canvas);
  // //JS ('texImage2D')
  // void _texImage2D2_5(target, level, internalformat, width, height, border, format, type, VideoElement video);
  // //JS ('texImage2D')
  // void _texImage2D2_6(target, level, internalformat, width, height, border, format, type, ImageBitmap bitmap);
  // //JS ('texImage2D')
  // void _texImage2D2_7(target, level, internalformat, width, height, border, format, type, TypedData srcData, srcOffset);

  void texImage3D(int target, int level, int internalformat, int width, int height, int depth, int border, int format, int type, TypedData? pixels) {
    Pointer<Int8>? nativeBuffer;
    if (pixels != null) {
      nativeBuffer = calloc<Int8>(pixels.lengthInBytes);
      nativeBuffer.asTypedList(pixels.lengthInBytes).setAll(0, pixels.buffer.asUint8List());
    }
    gl.glTexImage3D(target, level, internalformat, width, height, depth, border, format, type,
        nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texImage3D');
  }

  // void texImage3D(int target, int level, int internalformat, int width, int height, int depth, int border, int format,
  //     int type, bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video,
  //     [int? srcOffset]) {
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is int) && srcOffset == null) {
  //     _texImage3D_1(target, level, internalformat, width, height, depth, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is ImageData) && srcOffset == null) {
  //     var data_1 = convertDartToNative_ImageData(bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     _texImage3D_2(target, level, internalformat, width, height, depth, border, format, type, data_1);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is ImageElement) && srcOffset == null) {
  //     _texImage3D_3(target, level, internalformat, width, height, depth, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is CanvasElement) && srcOffset == null) {
  //     _texImage3D_4(target, level, internalformat, width, height, depth, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is VideoElement) && srcOffset == null) {
  //     _texImage3D_5(target, level, internalformat, width, height, depth, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is ImageBitmap) && srcOffset == null) {
  //     _texImage3D_6(target, level, internalformat, width, height, depth, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is TypedData ||
  //           bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video == null) &&
  //       srcOffset == null) {
  //     _texImage3D_7(target, level, internalformat, width, height, depth, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if (srcOffset != null && (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is TypedData)) {
  //     _texImage3D_8(target, level, internalformat, width, height, depth, border, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video, srcOffset);
  //     return;
  //   }
  //   throw new ArgumentError("Incorrect number or type of arguments");
  // }

  // //JS ('texImage3D')
  // void _texImage3D_1(target, level, internalformat, width, height, depth, border, format, type, int offset);
  // //JS ('texImage3D')
  // void _texImage3D_2(target, level, internalformat, width, height, depth, border, format, type, data);
  // //JS ('texImage3D')
  // void _texImage3D_3(target, level, internalformat, width, height, depth, border, format, type, ImageElement image);
  // //JS ('texImage3D')
  // void _texImage3D_4(target, level, internalformat, width, height, depth, border, format, type, CanvasElement canvas);
  // //JS ('texImage3D')
  // void _texImage3D_5(target, level, internalformat, width, height, depth, border, format, type, VideoElement video);
  // //JS ('texImage3D')
  // void _texImage3D_6(target, level, internalformat, width, height, depth, border, format, type, ImageBitmap bitmap);
  // //JS ('texImage3D')
  // void _texImage3D_7(target, level, internalformat, width, height, depth, border, format, type, TypedData? pixels);
  // //JS ('texImage3D')
  // void _texImage3D_8(
  //     target, level, internalformat, width, height, depth, border, format, type, TypedData pixels, srcOffset);

  void texStorage2D(int target, int levels, int internalformat, int width, int height){
    gl.glTexStorage2D(target, levels, internalformat, width, height);
  }

  void texStorage3D(int target, int levels, int internalformat, int width, int height, int depth){
    gl.glTexStorage3D(target, levels, internalformat, width, height, depth);
  }

  // void texSubImage2D2(int target, int level, int xoffset, int yoffset, int width, int height, int format, int type,
  //     bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video,
  //     [int? srcOffset]) {
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is int) && srcOffset == null) {
  //     _texSubImage2D2_1(target, level, xoffset, yoffset, width, height, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is ImageData) && srcOffset == null) {
  //     var data_1 = convertDartToNative_ImageData(bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     _texSubImage2D2_2(target, level, xoffset, yoffset, width, height, format, type, data_1);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is ImageElement) && srcOffset == null) {
  //     _texSubImage2D2_3(target, level, xoffset, yoffset, width, height, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is CanvasElement) && srcOffset == null) {
  //     _texSubImage2D2_4(target, level, xoffset, yoffset, width, height, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is VideoElement) && srcOffset == null) {
  //     _texSubImage2D2_5(target, level, xoffset, yoffset, width, height, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is ImageBitmap) && srcOffset == null) {
  //     _texSubImage2D2_6(target, level, xoffset, yoffset, width, height, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
  //     return;
  //   }
  //   if (srcOffset != null && (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video is TypedData)) {
  //     _texSubImage2D2_7(target, level, xoffset, yoffset, width, height, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video, srcOffset);
  //     return;
  //   }
  //   throw new ArgumentError("Incorrect number or type of arguments");
  // }

  // //JS ('texSubImage2D')
  // void _texSubImage2D2_1(target, level, xoffset, yoffset, width, height, format, type, int offset);
  // //JS ('texSubImage2D')
  // void _texSubImage2D2_2(target, level, xoffset, yoffset, width, height, format, type, data);
  // //JS ('texSubImage2D')
  // void _texSubImage2D2_3(target, level, xoffset, yoffset, width, height, format, type, ImageElement image);
  // //JS ('texSubImage2D')
  // void _texSubImage2D2_4(target, level, xoffset, yoffset, width, height, format, type, CanvasElement canvas);
  // //JS ('texSubImage2D')
  // void _texSubImage2D2_5(target, level, xoffset, yoffset, width, height, format, type, VideoElement video);
  // //JS ('texSubImage2D')
  // void _texSubImage2D2_6(target, level, xoffset, yoffset, width, height, format, type, ImageBitmap bitmap);
  // //JS ('texSubImage2D')
  // void _texSubImage2D2_7(target, level, xoffset, yoffset, width, height, format, type, TypedData srcData, srcOffset);

  // void texSubImage3D(int target, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth,
  //     int format, int type, bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video,
  //     [int? srcOffset]) {
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is int) && srcOffset == null) {
  //     _texSubImage3D_1(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is ImageData) && srcOffset == null) {
  //     var data_1 = convertDartToNative_ImageData(bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     _texSubImage3D_2(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, data_1);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is ImageElement) && srcOffset == null) {
  //     _texSubImage3D_3(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is CanvasElement) && srcOffset == null) {
  //     _texSubImage3D_4(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is VideoElement) && srcOffset == null) {
  //     _texSubImage3D_5(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is ImageBitmap) && srcOffset == null) {
  //     _texSubImage3D_6(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is TypedData) && srcOffset == null) {
  //     _texSubImage3D_7(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
  //     return;
  //   }
  //   if (srcOffset != null && (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video is TypedData)) {
  //     _texSubImage3D_8(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type,
  //         bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video, srcOffset);
  //     return;
  //   }
  //   throw new ArgumentError("Incorrect number or type of arguments");
  // }

  // //JS ('texSubImage3D')
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
  ){
    /// TODO this can probably optimized depending on if the length can be devided by 4 or 2
    Pointer<Int8>? nativeBuffer;
    if (pixels != null) {
      nativeBuffer = calloc<Int8>(pixels.lengthInBytes);
      nativeBuffer.asTypedList(pixels.lengthInBytes).setAll(0, pixels.buffer.asUint8List());
    }
    gl.glTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type,
      nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texSubImage2D');
  }
  // //JS ('texSubImage3D')
  // void _texSubImage3D_2(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, data);
  // //JS ('texSubImage3D')
  // void _texSubImage3D_3(
  //     target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, ImageElement image);
  // //JS ('texSubImage3D')
  // void _texSubImage3D_4(
  //     target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, CanvasElement canvas);
  // //JS ('texSubImage3D')
  // void _texSubImage3D_5(
  //     target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, VideoElement video);
  // //JS ('texSubImage3D')
  // void _texSubImage3D_6(
  //     target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, ImageBitmap bitmap);
  // //JS ('texSubImage3D')
  // void _texSubImage3D_7(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, TypedData pixels);
  // //JS ('texSubImage3D')
  // void _texSubImage3D_8(
  //     target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, TypedData pixels, srcOffset);

  // void transformFeedbackVaryings(Program program, List<String> varyings, int bufferMode) {
  //   List varyings_1 = convertDartToNative_StringArray(varyings);
  //   _transformFeedbackVaryings_1(program, varyings_1, bufferMode);
  //   return;
  // }
  void transformFeedbackVaryings(Program program, int count, List<String> varyings, int bufferMode) {
    final varyingsPtr = calloc<Pointer<Int8>>(varyings.length);
    int i = 0;
    for(final varying in varyings) {
      varyingsPtr[i] = varying.toNativeUtf8().cast<Int8>();
      i = i + 1;
    }
    gl.glTransformFeedbackVaryings(program.id, count, varyingsPtr, bufferMode);
    calloc.free(varyingsPtr);
  }
  // //JS ('transformFeedbackVaryings')
  // void _transformFeedbackVaryings_1(Program program, List varyings, bufferMode);

  // //JS ('uniform1fv')
  // void uniform1fv2(UniformLocation? location, v, int srcOffset, [int? srcLength]);

  // //JS ('uniform1iv')
  // void uniform1iv2(UniformLocation? location, v, int srcOffset, [int? srcLength]);

  void uniform1ui(UniformLocation? location, int v0){
    gl.glUniform1ui(location?.id  ?? nullptr.address, v0);
    // checkError('uniform1ui');
  }

  void uniform1uiv(UniformLocation? location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Uint32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform1uiv(location?.id  ?? nullptr.address, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform1uiv'); 
  }

  // //JS ('uniform2fv')
  // void uniform2fv2(UniformLocation? location, v, int srcOffset, [int? srcLength]);

  // //JS ('uniform2iv')
  // void uniform2iv2(UniformLocation? location, v, int srcOffset, [int? srcLength]);

  void uniform2ui(UniformLocation? location, int v0, int v1){
    gl.glUniform2ui(location?.id  ?? nullptr.address, v0, v1);
    // checkError('uniform2ui');
  }

  void uniform2uiv(UniformLocation? location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Uint32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform2uiv(location?.id  ?? nullptr.address, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform1uiv'); 
  }
  // //JS ('uniform3fv')
  // void uniform3fv2(UniformLocation? location, v, int srcOffset, [int? srcLength]);

  // //JS ('uniform3iv')
  // void uniform3iv2(UniformLocation? location, v, int srcOffset, [int? srcLength]);

  void uniform3ui(UniformLocation? location, int v0, int v1, int v2){
    gl.glUniform3ui(location?.id  ?? nullptr.address, v0, v1, v2);
    // checkError('uniform3ui');
  }

  void uniform3uiv(UniformLocation? location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Uint32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform3uiv(location?.id  ?? nullptr.address, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform1uiv'); 
  }
  // //JS ('uniform4fv')
  // void uniform4fv2(UniformLocation? location, v, int srcOffset, [int? srcLength]);

  // //JS ('uniform4iv')
  // void uniform4iv2(UniformLocation? location, v, int srcOffset, [int? srcLength]);

  void uniform4ui(UniformLocation? location, int v0, int v1, int v2, int v3){
    gl.glUniform4ui(location?.id  ?? nullptr.address, v0, v1, v2, v3);
    // checkError('uniform4ui');
  }

  void uniform4uiv(UniformLocation? location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Uint32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform4uiv(location?.id  ?? nullptr.address, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform1uiv'); 
  }
  // void uniformBlockBinding(Program program, int uniformBlockIndex, int uniformBlockBinding);

  // //JS ('uniformMatrix2fv')
  // void uniformMatrix2fv2(UniformLocation? location, bool transpose, array, int srcOffset, [int? srcLength]);

  // void uniformMatrix2x3fv(UniformLocation? location, bool transpose, value, [int? srcOffset, int? srcLength]);

  // void uniformMatrix2x4fv(UniformLocation? location, bool transpose, value, [int? srcOffset, int? srcLength]);

  // //JS ('uniformMatrix3fv')
  // void uniformMatrix3fv2(UniformLocation? location, bool transpose, array, int srcOffset, [int? srcLength]);

  // void uniformMatrix3x2fv(UniformLocation? location, bool transpose, value, [int? srcOffset, int? srcLength]);

  // void uniformMatrix3x4fv(UniformLocation? location, bool transpose, value, [int? srcOffset, int? srcLength]);

  // //JS ('uniformMatrix4fv')
  // void uniformMatrix4fv2(UniformLocation? location, bool transpose, array, int srcOffset, [int? srcLength]);

  // void uniformMatrix4x2fv(UniformLocation? location, bool transpose, value, [int? srcOffset, int? srcLength]);

  // void uniformMatrix4x3fv(UniformLocation? location, bool transpose, value, [int? srcOffset, int? srcLength]);

  void vertexAttribDivisor(int index, int divisor){
    gl.glVertexAttribDivisor(index, divisor);
  }

  // void vertexAttribI4i(int index, int x, int y, int z, int w);

  // void vertexAttribI4iv(int index, v);

  // void vertexAttribI4ui(int index, int x, int y, int z, int w);

  // void vertexAttribI4uiv(int index, v);

  void vertexAttribIPointer(int index, int size, int type, int stride, int pointer){
    var _pointer = calloc<Int32>();
    _pointer.value = pointer;
    gl.glVertexAttribIPointer(index, size, type, stride, _pointer.cast<Void>());
    calloc.free(_pointer);
    // checkError('vertexAttribIPointer');
  }

  // void waitSync(Sync sync, int flags, int timeout);

  // // From WebGLRenderingContextBase

  // int? get drawingBufferHeight;

  // int? get drawingBufferWidth;

  void activeTexture(int texture) {
    gl.glActiveTexture(texture);
    // checkError('activeTexture');
  }

  void attachShader(Program program, WebGLShader shader) {
    gl.glAttachShader(program.id, shader.id);
    // checkError('attachShader');
  }

  void bindAttribLocation(Program program, int index, String name){
    final locationName = name.toNativeUtf8();
    gl.glBindAttribLocation(program.id, index,locationName.cast());
    // checkError('bindAttribLocation');
    calloc.free(locationName);
  }

  void bindBuffer(int target, Buffer buffer) {
    gl.glBindBuffer(target, buffer.id);
    // checkError('bindBuffer');
  }

  void bindFramebuffer(int target, Framebuffer? framebuffer){
    if(framebuffer != null){
      gl.glBindFramebuffer(target, framebuffer?.id ?? nullptr.address);
    }
    // checkError('bindFramebuffer');
  }

  void bindRenderbuffer(int target, Renderbuffer? renderbuffer){
    gl.glBindRenderbuffer(target, renderbuffer?.id ?? nullptr.address);
    // checkError('bindRenderbuffer');
  }

  void bindTexture(int target, WebGLTexture texture) {
    gl.glBindTexture(target, texture.id);
    // checkError('bindTexture');
  }

  // void blendColor(num red, num green, num blue, num alpha);

  void blendEquation(int mode){
    gl.glBlendEquation(mode);
    // checkError('blendEquation');
  }

  void blendEquationSeparate(int modeRGB, int modeAlpha){
    gl.glBlendEquationSeparate(modeRGB, modeAlpha);
  }

  void blendFunc(int sfactor, int dfactor){
    gl.glBlendFunc(sfactor, dfactor);
  }

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha){
    gl.glBlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
    // checkError('blendFuncSeparate');
  }

  /// Be careful which type of integer you really pass here. Unfortunately an UInt16List
  /// is viewed by the Dart type system just as List<int>, so we jave to specify the native type
  /// here in [nativeType]
  void bufferData(int target, TypedData data, int usage) {
    late Pointer<Void> nativeData;
    late int size;
    if (data is List<double> || data is Float32List) {
      nativeData = floatListToArrayPointer(data as List<double>).cast();
      size = data.lengthInBytes * sizeOf<Float>();
    } 
    else if (data is Int32List) {
      nativeData = int32ListToArrayPointer(data).cast();
      size = data.length * sizeOf<Int32>();
    } 
    else if (data is Uint16List) {
      nativeData = uInt16ListToArrayPointer(data).cast();
      size = data.length * sizeOf<Uint16>();
    } 
    else if (data is Uint8List) {
      nativeData = uInt8ListToArrayPointer(data).cast();
      size = data.length * sizeOf<Uint16>();
    } 
    else {
      throw (OpenGLException('bufferData: unsupported native type ${data.runtimeType}', -1));
    }
    gl.glBufferData(target, size, nativeData, usage);
    calloc.free(nativeData);
    // checkError('bufferData');
  }

  Pointer<Float> floatListToArrayPointer(List<double> list) {
    final ptr = calloc<Float>(list.length);
    ptr.asTypedList(list.length).setAll(0, list);
    return ptr;
  }

  Pointer<Int32> int32ListToArrayPointer(List<int> list) {
    final ptr = calloc<Int32>(list.length);
    ptr.asTypedList(list.length).setAll(0, list);
    return ptr;
  }

  Pointer<Uint16> uInt16ListToArrayPointer(List<int> list) {
    final ptr = calloc<Uint16>(list.length);
    ptr.asTypedList(list.length).setAll(0, list);
    return ptr;
  }

  Pointer<Uint8> uInt8ListToArrayPointer(List<int> list) {
    final ptr = calloc<Uint8>(list.length);
    ptr.asTypedList(list.length).setAll(0, list);
    return ptr;
  }
  // void bufferSubData(int target, int offset, data);

  int checkFramebufferStatus(int target){
    return gl.glCheckFramebufferStatus(target);
  }

  void clear(int mask) => gl.glClear(mask);

  void clearColor(double red, double green, double blue, double alpha) {
    gl.glClearColor(red, green, blue, alpha);
    // checkError('clearColor');
  }

  void clearDepth(double depth){
    gl.glClearDepthf(depth);
    // checkError('clearDepth');
  }

  void clearStencil(int s){
    gl.glClearStencil(s);
    // checkError('clearStencil');
  }

  void colorMask(bool red, bool green, bool blue, bool alpha){
    gl.glColorMask(red?1:0, green?1:0, blue?1:0, alpha?1:0);
    // checkError('colorMask');
  }

  // Future commit() => promiseToFuture(JS("", "#.commit()", this));

  void compileShader(WebGLShader shader, [bool checkForErrors = true]) {
    gl.glCompileShader(shader.id);

    if (checkForErrors) {
      final compiled = calloc<Int32>();
      gl.glGetShaderiv(shader.id, GL_COMPILE_STATUS, compiled);
      if (compiled.value == 0) {
        final infoLen = calloc<Int32>();

        gl.glGetShaderiv(shader.id, GL_INFO_LOG_LENGTH, infoLen);

        String message = '';
        if (infoLen.value > 1) {
          final infoLog = calloc<Int8>(infoLen.value);

          gl.glGetShaderInfoLog(shader.id, infoLen.value, nullptr, infoLog);
          message = "\nError compiling shader:\n${infoLog.cast<Utf8>().toDartString()}";

          calloc.free(infoLog);
        }
        calloc.free(infoLen);
        throw OpenGLException(message, 0);
      }
      calloc.free(compiled);
    }
  }

  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, TypedData? pixels){
    Pointer<Void>? nativeBuffer; 
    late int size;

    if (pixels is List<double> || pixels is Float32List) {
      nativeBuffer = floatListToArrayPointer(pixels as List<double>).cast();
      size = pixels!.lengthInBytes * sizeOf<Float>();
    } else if (pixels is Int32List) {
      nativeBuffer = int32ListToArrayPointer(pixels).cast();
      size = pixels.length * sizeOf<Int32>();
    } else if (pixels is Uint16List) {
      nativeBuffer = uInt16ListToArrayPointer(pixels).cast();
      size = pixels.length * sizeOf<Uint16>();
    }

    gl.glCompressedTexImage2D(target, level, internalformat, width, height, border, size, nativeBuffer != null ? nativeBuffer.cast() : nullptr);
    
    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    
    // checkError('compressedTexImage2D');
  }

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format ,TypedData? pixels){
    Pointer<Void>? nativeBuffer;
    late int size;

    if (pixels is List<double> || pixels is Float32List) {
      nativeBuffer = floatListToArrayPointer(pixels as List<double>).cast();
      size = pixels!.lengthInBytes * sizeOf<Float>();
    } else if (pixels is Int32List) {
      nativeBuffer = int32ListToArrayPointer(pixels).cast();
      size = pixels.length * sizeOf<Int32>();
    } else if (pixels is Uint16List) {
      nativeBuffer = uInt16ListToArrayPointer(pixels).cast();
      size = pixels.length * sizeOf<Uint16>();
    } 

    gl.glCompressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, size,
        nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('compressedTexSubImage2D');
  }

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border){
    gl.glCopyTexImage2D(target, level, internalformat, x, y, width, height, border);
    // checkError('copyTexImage2D');
  }

  // void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height);
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height){
    gl.glCopyTexSubImage2D(target, level, xoffset, yoffset, x,y,width, height);
    // checkError('copyTexSubImage2D');
  }

  Buffer createBuffer() {
    Pointer<Uint32> id = calloc<Uint32>();
    gl.glGenBuffers(1, id);
    // checkError('createBuffer');
    int _v = id.value;
    calloc.free(id);
    return Buffer(_v);
  }

  Framebuffer createFramebuffer(){
    Pointer<Uint32> id = calloc<Uint32>();
    gl.glGenFramebuffers(1, id);
    checkError('createFramebuffer');
    int _v = id.value;
    calloc.free(id);
    return Framebuffer(_v);
  }

  Program createProgram() {
    final program = gl.glCreateProgram();
    // checkError('createProgram');
    return Program(program);
  }

  Renderbuffer createRenderbuffer(){
    final v = calloc<Uint32>();
    gl.glGenRenderbuffers(1, v);
    int _v = v.value;
    calloc.free(v);
    return Renderbuffer(_v);
  }

  WebGLShader createShader(int type) {
    final shader = gl.glCreateShader(type);
    // checkError('createShader');
    return WebGLShader(shader);
  }

  WebGLTexture createTexture() {
    Pointer<Uint32> vPointer = calloc<Uint32>();
    gl.glGenTextures(1, vPointer);
    // checkError('createBuffer');
    int _v = vPointer.value;
    calloc.free(vPointer);
    return WebGLTexture(_v);
  }

  int getParameter(int key) {
    // print("OpenGL getParameter key: ${key} ");

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
      WebGL.VIEWPORT,
      WebGL.MAX_TEXTURE_MAX_ANISOTROPY_EXT
    ];

    if (_intValues.indexOf(key) >= 0) {
      final v = calloc<Int32>(4);
      gl.glGetIntegerv(key, v);
      return v.value;
    } else {
      throw (" OpenGL getParameter key: ${key} is not support ");
    }
  }

  void cullFace(int mode){
    gl.glCullFace(mode);
    // checkError('cullFace');
  }

  void deleteBuffer(Buffer buffer){
    final List<int> _texturesList = [buffer.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteBuffers(1, ptr);
    calloc.free(ptr);
    // checkError('deleteBuffer');
  }

  void deleteFramebuffer(Framebuffer framebuffer){
    final List<int> _texturesList = [framebuffer.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteFramebuffers(1, ptr);
    calloc.free(ptr);
    // checkError('deleteFramebuffer');
  }

  void deleteProgram(Program program){
    gl.glDeleteProgram(program.id);
  }

  void deleteRenderbuffer(Renderbuffer renderbuffer){
    final List<int> _texturesList = [renderbuffer.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteRenderbuffers(1, ptr);
    calloc.free(ptr);
    // checkError('deleteFramebuffer');
  }

  void deleteShader(WebGLShader shader){
    gl.glDeleteShader(shader.id);
  }

  void deleteTexture(WebGLTexture texture){
    final List<int> _texturesList = [texture.id];
    final ptr = calloc<Uint32>(_texturesList.length);
    ptr.asTypedList(1).setAll(0, _texturesList);
    gl.glDeleteTextures(1, ptr);
    calloc.free(ptr);
    // checkError('deleteTexture');
  }

  void depthFunc(int func){
    gl.glDepthFunc(func);
    // checkError('depthFunc');
  }

  void depthMask(bool flag){
    gl.glDepthMask(flag?1:0);
    // checkError('depthMask');
  }

  // void depthRange(num zNear, num zFar);

  // void detachShader(Program program, WebGLShader shader);

  void disable(int cap) {
    gl.glDisable(cap);
    // checkError('disable');
  }

  void disableVertexAttribArray(int index){
    gl.glDisableVertexAttribArray(index);
  }

  void drawArrays(int mode, int first, int count) {
    gl.glDrawArrays(mode, first, count);
    // checkError('drawArrays');
  }

  void drawElements(int mode, int count, int type, int offset) {
    var offSetPointer = Pointer<Void>.fromAddress(offset);
    gl.glDrawElements(mode, count, type, offSetPointer.cast());
    // checkError('drawElements');
    calloc.free(offSetPointer);
  }

  void enable(int cap) {
    gl.glEnable(cap);
    // checkError('enable');
  }

  void enableVertexAttribArray(int index) {
    gl.glEnableVertexAttribArray(index);
    // checkError('enableVertexAttribArray');
  }

  void finish(){
    gl.glFinish();
  }

  void flush(){
    gl.glFlush();
  }

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, Renderbuffer? renderbuffer){
    gl.glFramebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer?.id  ?? nullptr.address);
    // checkError('framebufferRenderbuffer');
  }

  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level){
    gl.glFramebufferTexture2D(target, attachment, textarget, texture.id, level);
  }

  void frontFace(int mode){
    gl.glFrontFace(mode);
    // checkError('frontFace');
  }

  void generateMipmap(int target) {
    gl.glGenerateMipmap(target);
    // checkError('generateMipmap');
  }

  ActiveInfo getActiveAttrib(Program v0, int v1) {
    var length = calloc<Int32>();
    var size = calloc<Int32>();
    var type = calloc<Uint32>();
    var name = calloc<Int8>(100);

    gl.glGetActiveAttrib(v0.id, v1, 99, length, size, type, name);

    int _type = type.value;
    String _name = name.cast<Utf8>().toDartString();
    int _size = size.value;

    calloc.free(type);
    calloc.free(name);
    calloc.free(size);
    calloc.free(length);

    return ActiveInfo(_type, _name, _size);
  }

  ActiveInfo getActiveUniform(Program v0, int v1) {
    var length = calloc<Int32>();
    var size = calloc<Int32>();
    var type = calloc<Uint32>();
    var name = calloc<Int8>(100);

    gl.glGetActiveUniform(v0.id, v1, 99, length, size, type, name);

    int _type = type.value;
    String _name = name.cast<Utf8>().toDartString();
    int _size = size.value;

    calloc.free(type);
    calloc.free(name);
    calloc.free(size);
    calloc.free(length);

    return ActiveInfo(_type, _name, _size);
  }
  // List<WebGLShader>? getAttachedShaders(Program program);

  UniformLocation getAttribLocation(Program program, String name) {
    final locationName = name.toNativeUtf8();
    final location = gl.glGetAttribLocation(program.id, locationName.cast());
    // checkError('getAttribLocation');
    calloc.free(locationName);
    return UniformLocation(location);
  }
  // Object? getBufferParameter(int target, int pname);

  dynamic getContextAttributes() {
    return null;
  }

  // //JS ('getContextAttributes')
  // _getContextAttributes_1();

  int getError(){
    return gl.glGetError();
  }

  Object? getExtension(String key) {
    if (Platform.isMacOS) {
      return getExtensionMacos(key);
    }
    Pointer _v = gl.glGetString(WebGL.EXTENSIONS);

    String _vstr = _v.cast<Utf8>().toDartString();
    List<String> _extensions = _vstr.split(" ");

    return _extensions;
  }

  List<String> getExtensionMacos(String key) {
    List<String> _extensions = [];
    var nExtension = getIntegerv(33309);
    for (int i = 0; i < nExtension; i++) {
      _extensions.add(getStringi(GL_EXTENSIONS, i));
    }

    return _extensions;
  }

  String getStringi(int key, int index) {
    Pointer _v = gl.glGetStringi(key, index);
    return _v.cast<Utf8>().toDartString();
  }

  int getIntegerv(int v0) {
    Pointer<Int32> ptr = calloc<Int32>();
    gl.glGetIntegerv(v0, ptr);

    int _v = ptr.value;
    calloc.free(ptr);

    return _v;
  }
  
  // Object? getFramebufferAttachmentParameter(int target, int attachment, int pname);

  // Object? getParameter(int pname);

  String? getProgramInfoLog(Program program){
    var infoLen = calloc<Int32>();

    gl.glGetProgramiv(program.id, 35716, infoLen);

    int _len = infoLen.value;
    calloc.free(infoLen);

    String message = '';

    if (_len > 0) {
      final infoLog = calloc<Int8>(_len);
      gl.glGetProgramInfoLog(program.id, _len, nullptr, infoLog);

      message = "\nError compiling shader:\n${infoLog.cast<Utf8>().toDartString()}";
      calloc.free(infoLog);
      return message;
    } 

    return null;
  }

  WebGLParameter getProgramParameter(Program program, int pname) {
    final status = calloc<Int32>();
    gl.glGetProgramiv(program.id, pname, status);
    final _v = status.value;
    calloc.free(status);
    // checkError('getProgramParameter');
    return WebGLParameter(_v);
  }

  // Object? getRenderbufferParameter(int target, int pname);

  String? getShaderInfoLog(WebGLShader shader){
    final infoLen = calloc<Int32>();
    gl.glGetShaderiv(shader.id, 35716, infoLen);

    int _len = infoLen.value;
    calloc.free(infoLen);

    String message = '';
    if (_len > 1) {
      final infoLog = calloc<Int8>(_len);

      gl.glGetShaderInfoLog(shader.id, _len, nullptr, infoLog);
      message = "\nError compiling shader:\n${infoLog.cast<Utf8>().toDartString()}";
      calloc.free(infoLog);
      return message;
    }
    return null;
  }

  bool getShaderParameter(WebGLShader shader, int pname){
    var _pointer = calloc<Int32>();
    gl.glGetShaderiv(shader.id, pname, _pointer);
    final _v = _pointer.value;
    calloc.free(_pointer);
    return _v == 0?false:true;
  }

  ShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype){
    return ShaderPrecisionFormat();
  }

  String? getShaderSource(int shader){
    // var sourceString = shaderSource.toNativeUtf8();
    // var arrayPointer = calloc<Int32>();
    // arrayPointer.value = Pointer.fromAddress(sourceString.address);
    // String temp = gl.glGetShaderSource(shader, 1, arrayPointer, nullptr);
    // calloc.free(arrayPointer);
    // calloc.free(sourceString);
    return null;
  }

  // List<String>? getSupportedExtensions();

  // Object? getTexParameter(int target, int pname);

  // Object? getUniform(Program program, UniformLocation location);

  UniformLocation getUniformLocation(Program program, String name) {
    final locationName = name.toNativeUtf8();
    final location = gl.glGetUniformLocation(program.id, locationName.cast());
    // checkError('getProgramParameter');
    calloc.free(locationName);
    return UniformLocation(location);
  }

  // Object? getVertexAttrib(int index, int pname);

  // int getVertexAttribOffset(int index, int pname);

  // void hint(int target, int mode);

  // bool isBuffer(Buffer? buffer);

  // bool isContextLost();

  // bool isEnabled(int cap);

  // bool isFramebuffer(Framebuffer? framebuffer);

  bool isProgram(Program program){
    return gl.glIsProgram(program.id) != 0;
  }

  // bool isRenderbuffer(Renderbuffer? renderbuffer);

  // bool isShader(WebGLShader? shader);

  // bool isTexture(WebGLTexture? texture);

  void lineWidth(double width){
    gl.glLineWidth(width);
    // checkError('lineWidth');
  }

  void linkProgram(Program program, [bool checkForErrors = true]) {
    gl.glLinkProgram(program.id);
    if (checkForErrors) {
      final linked = calloc<Int32>();
      gl.glGetProgramiv(program.id, GL_LINK_STATUS, linked);
      if (linked.value == 0) {
        final infoLen = calloc<Int32>();

        gl.glGetProgramiv(program.id, GL_INFO_LOG_LENGTH, infoLen);

        String message = '';
        if (infoLen.value > 1) {
          final infoLog = calloc<Int8>(infoLen.value);

          gl.glGetProgramInfoLog(program.id, infoLen.value, nullptr, infoLog);
          message = "\nError linking program:\n${infoLog.cast<Utf8>().toDartString()}";

          calloc.free(infoLog);
        }
        calloc.free(infoLen);
        throw OpenGLException(message, 0);
      }
      calloc.free(linked);
    }
  }

  void pixelStorei(int pname, int param) {
    gl.glPixelStorei(pname, param);
    // checkError('pixelStorei');
  }

  void polygonOffset(double factor, double units){
    gl.glPolygonOffset(factor, units);
  }

  // //JS ('readPixels')
  // void _readPixels(int x, int y, int width, int height, int format, int type, TypedData? pixels);

  void renderbufferStorage(int target, int internalformat, int width, int height){
    gl.glRenderbufferStorage(target, internalformat, width, height);
  }

  // void sampleCoverage(num value, bool invert);

  void scissor(int x, int y, int width, int height){
    gl.glScissor(x, y, width, height);
    // checkError('scissor');
  }

  void shaderSource(WebGLShader shader, String shaderSource) {
    var sourceString = shaderSource.toNativeUtf8();
    var arrayPointer = calloc<Pointer<Int8>>();
    arrayPointer.value = Pointer.fromAddress(sourceString.address);
    gl.glShaderSource(shader.id, 1, arrayPointer, nullptr);
    calloc.free(arrayPointer);
    calloc.free(sourceString);
    // checkError('shaderSource');
  }

  void stencilFunc(int func, int ref, int mask){
    gl.glStencilFunc(func, ref, mask);
  }

  // void stencilFuncSeparate(int face, int func, int ref, int mask);

  void stencilMask(int mask){
    gl.glStencilMask(mask);
    // checkError('stencilMask');
  }

  // void stencilMaskSeparate(int face, int mask);

  void stencilOp(int fail, int zfail, int zpass){
    gl.glStencilOp(fail, zfail, zpass);
    // checkError('stencilOp');
  }

  // void stencilOpSeparate(int face, int fail, int zfail, int zpass);

  // //JS ('texImage2D')
  /// passing null for pixels is perfectly fine, in that case an empty WebGLTexture is allocated
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
    /// TODO this can probably optimized depending on if the length can be devided by 4 or 2
    Pointer<Int8>? nativeBuffer;
    if (pixels != null) {
      nativeBuffer = calloc<Int8>(pixels.lengthInBytes);
      nativeBuffer.asTypedList(pixels.lengthInBytes).setAll(0, pixels.buffer.asUint8List());
    }
    gl.glTexImage2D(target, level, internalformat, width, height, border, format, type,
        nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texImage2D');
  }

  void texImage2D_NOSIZE(
    int target, 
    int level, 
    int internalformat, 
    int format, 
    int type, 
    TypedData? pixels
  ) {  
    texImage2D(target, level, internalformat, 0, 0, 0, format, type, pixels);
  }

  Future<void> texImage2DfromImage(
    int target,
    Image image, {
    int level = 0,
    int internalformat = WebGL.RGBA,
    int format = WebGL.RGBA,
    int type = WebGL.UNSIGNED_BYTE,
  }) async {
    texImage2D(target, level, internalformat, image.width, image.height, 0, format, type, (await image.toByteData())!);
  }

  Future<void> texImage2DfromAsset(
    int target,
    String assetPath, {
    int level = 0,
    int internalformat = WebGL.RGBA32UI,
    int format = WebGL.RGBA,
    int type = WebGL.UNSIGNED_INT,
  }) async {
    final image = await loadImageFromAsset(assetPath);
    texImage2D(target, level, internalformat, image.width, image.height, 0, format, type, (await image.toByteData())!);
  }

  Future<Image> loadImageFromAsset(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final loadingCompleter = Completer<Image>();
    decodeImageFromList(bytes.buffer.asUint8List(), (image) {
      loadingCompleter.complete(image);
    });
    return loadingCompleter.future;
  }

  void texParameterf(int target, int pname, double param) {
    gl.glTexParameterf(target, pname, param);
    // checkError('texParameterf');
  }

  void texParameteri(int target, int pname, int param) {
    gl.glTexParameteri(target, pname, param);
    // checkError('texParameteri');
  }

  // void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type,
  //     bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video,
  //     [int? type, TypedData? pixels]) {
  //   if (type != null && (bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is int)) {
  //     _texSubImage2D_1(target, level, xoffset, yoffset, format_OR_width, height_OR_type,
  //         bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData) && type == null && pixels == null) {
  //     var pixels_1 = convertDartToNative_ImageData(bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
  //     _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width, height_OR_type, pixels_1);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement) && type == null && pixels == null) {
  //     _texSubImage2D_3(target, level, xoffset, yoffset, format_OR_width, height_OR_type,
  //         bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement) && type == null && pixels == null) {
  //     _texSubImage2D_4(target, level, xoffset, yoffset, format_OR_width, height_OR_type,
  //         bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement) && type == null && pixels == null) {
  //     _texSubImage2D_5(target, level, xoffset, yoffset, format_OR_width, height_OR_type,
  //         bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
  //     return;
  //   }
  //   if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is ImageBitmap) && type == null && pixels == null) {
  //     _texSubImage2D_6(target, level, xoffset, yoffset, format_OR_width, height_OR_type,
  //         bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
  //     return;
  //   }
  //   throw new ArgumentError("Incorrect number or type of arguments");
  // }

  // //JS ('texSubImage2D')
  void texSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, int type, TypedData? pixels){
    /// TODO this can probably optimized depending on if the length can be devided by 4 or 2
    Pointer<Int8>? nativeBuffer;
    if (pixels != null) {
      nativeBuffer = calloc<Int8>(pixels.lengthInBytes);
      nativeBuffer.asTypedList(pixels.lengthInBytes).setAll(0, pixels.buffer.asUint8List());
    }
    gl.glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type,
        nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texImage2D');
  }

  void texSubImage2D_NOSIZE(int target, int level, int xoffset, int yoffset, int format, int type, TypedData? pixels){
    texSubImage2D(target, level, xoffset, yoffset, 0, 0, format, type, pixels);
  }
  // //JS ('texSubImage2D')
  // void _texSubImage2D_2(target, level, xoffset, yoffset, format, type, pixels);
  // //JS ('texSubImage2D')
  // void _texSubImage2D_3(target, level, xoffset, yoffset, format, type, ImageElement image);
  // //JS ('texSubImage2D')
  // void _texSubImage2D_4(target, level, xoffset, yoffset, format, type, CanvasElement canvas);
  // //JS ('texSubImage2D')
  // void _texSubImage2D_5(target, level, xoffset, yoffset, format, type, VideoElement video);
  // //JS ('texSubImage2D')
  // void _texSubImage2D_6(target, level, xoffset, yoffset, format, type, ImageBitmap bitmap);

  void uniform1f(UniformLocation location, double x){
    gl.glUniform1f(location.id, x);
    // checkError('uniform1f');
  }

  void uniform1fv(UniformLocation location, List<double> v){
    var arrayPointer = floatListToArrayPointer(v);
    gl.glUniform1fv(location.id, v.length ~/ 1, arrayPointer);
    calloc.free(arrayPointer);
    // checkError('uniform1fv');  
  }

  void uniform1i(UniformLocation location, int x) {
    gl.glUniform1i(location.id, x);
    // checkError('uniform1i');
  }

  void uniform1iv(UniformLocation location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Int32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform1iv(location.id, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform1iv'); 
  }

  void uniform2f(UniformLocation location, double x, double y){
    gl.glUniform2f(location.id, x, y);
    // checkError('uniform2f'); 
  }

  void uniform2fv(UniformLocation location, List<double> v){
    var arrayPointer = floatListToArrayPointer(v);
    gl.glUniform2fv(location.id, v.length ~/ 1, arrayPointer);
    calloc.free(arrayPointer);
    // checkError('uniform2fv'); 
  }

  // void uniform2i(UniformLocation? location, int x, int y);

  void uniform2iv(UniformLocation location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Int32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform2iv(location.id, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform2iv'); 
  }

  void uniform3f(UniformLocation location, double x, double y, double z) {
    gl.glUniform3f(location.id, x, y, z);
    // checkError('uniform3f');
  }

  void uniform3fv(UniformLocation location, List<double> vectors) {
    var arrayPointer = floatListToArrayPointer(vectors);
    gl.glUniform3fv(location.id, vectors.length ~/ 3, arrayPointer);
    // checkError('uniform3fv');
    calloc.free(arrayPointer);
  }

  // void uniform3i(UniformLocation? location, int x, int y, int z);

  void uniform3iv(UniformLocation location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Int32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform3iv(location.id, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform2iv'); 
  }

  void uniform4f(UniformLocation location, double x, double y, double z, double w){
    gl.glUniform4f(location.id, x, y, z,w);
    // checkError('uniform4f');
  }

  void uniform4fv(UniformLocation location, List<double> vectors) {
    var arrayPointer = floatListToArrayPointer(vectors);
    gl.glUniform4fv(location.id, vectors.length ~/ 3, arrayPointer);
    // checkError('uniform4fv');
    calloc.free(arrayPointer);
  }

  // void uniform4i(UniformLocation? location, int x, int y, int z, int w);

  void uniform4iv(UniformLocation location, List<int> v){
    int count = v.length;
    final valuePtr = calloc<Int32>(count);
    valuePtr.asTypedList(count).setAll(0, v);
    gl.glUniform4iv(location.id, count, valuePtr);
    calloc.free(valuePtr);
    // checkError('uniform2iv'); 
  }

  // void uniformMatrix2fv(UniformLocation? location, bool transpose, array);
  void uniformMatrix2fv(UniformLocation location, bool transpose, List<double> values) {
    var arrayPointer = floatListToArrayPointer(values);
    gl.glUniformMatrix2fv(location.id, values.length ~/ 9, transpose ? 1 : 0, arrayPointer);
    // checkError('uniformMatrix2fv');
    calloc.free(arrayPointer);
    
  }

  void uniformMatrix3fv(UniformLocation location, bool transpose, List<double> values) {
    var arrayPointer = floatListToArrayPointer(values);
    gl.glUniformMatrix3fv(location.id, values.length ~/ 9, transpose ? 1 : 0, arrayPointer);
    // checkError('uniformMatrix3fv');
    calloc.free(arrayPointer);
  }

  /// be careful, data always has a length that is a multiple of 16
  void uniformMatrix4fv(UniformLocation location, bool transpose, List<double> values) {
    var arrayPointer = floatListToArrayPointer(values);
    gl.glUniformMatrix4fv(location.id, values.length ~/ 16, transpose ? 1 : 0, arrayPointer);
    // checkError('uniformMatrix4fv');
    calloc.free(arrayPointer);
  }

  void useProgram(Program? program) {
    gl.glUseProgram(program?.id  ?? nullptr.address);
    // checkError('useProgram');
  }

  // void validateProgram(Program program);

  // void vertexAttrib1f(int indx, num x);

  void vertexAttrib1fv(int index, List<double> values){
    var arrayPointer = floatListToArrayPointer(values);
    gl.glVertexAttrib1fv(index, arrayPointer);
    // checkError('vertexAttrib2fv');
    calloc.free(arrayPointer);
  }

  // void vertexAttrib2f(int indx, num x, num y);

  void vertexAttrib2fv(int index, List<double> values){
    var arrayPointer = floatListToArrayPointer(values);
    gl.glVertexAttrib2fv(index, arrayPointer);
    // checkError('vertexAttrib2fv');
    calloc.free(arrayPointer);
  }

  // void vertexAttrib3f(int indx, num x, num y, num z);

  void vertexAttrib3fv(int index, List<double> values){
    var arrayPointer = floatListToArrayPointer(values);
    gl.glVertexAttrib3fv(index, arrayPointer);
    // checkError('vertexAttrib3fv');
    calloc.free(arrayPointer);
  }

  // void vertexAttrib4f(int indx, num x, num y, num z, num w);

  void vertexAttrib4fv(int index, List<double> values){
    var arrayPointer = floatListToArrayPointer(values);
    gl.glVertexAttrib4fv(index, arrayPointer);
    // checkError('vertexAttrib4fv');
    calloc.free(arrayPointer);
  }

  void vertexAttribPointer(int index, int size, int type, bool normalized, int stride, int offset) {
    var offsetPointer = Pointer<Void>.fromAddress(offset);
    gl.glVertexAttribPointer(index, size, type, normalized ? 1 : 0, stride, offsetPointer.cast<Void>());
    // checkError('vertexAttribPointer');
    //calloc.free(offsetPointer);
  }

  void viewport(int x, int y, int width, int height) {
    gl.glViewport(x, y, width, height);
    // checkError('viewPort');
  }

  void readPixels(int x, int y, int width, int height, int format, int type, TypedData? pixels) {
    /// TODO this can probably optimized depending on if the length can be devided by 4 or 2
    Pointer<Int8>? nativeBuffer;
    if (pixels != null) {
      nativeBuffer = calloc<Int8>(pixels.lengthInBytes);
      nativeBuffer.asTypedList(pixels.lengthInBytes).setAll(0, pixels.buffer.asUint8List());
    }
    gl.glReadPixels(x, y, width, height, format, type, 
        nativeBuffer != null ? nativeBuffer.cast() : nullptr);

    if (nativeBuffer != null) {
      calloc.free(nativeBuffer);
    }
    // checkError('texImage2D');
  }
}

// // JS "WebGLSampler")
// class Sampler extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory Sampler._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "WebGLShaderPrecisionFormat")
// class ShaderPrecisionFormat extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory ShaderPrecisionFormat._() {
//     throw new UnsupportedError("Not supported");
//   }

//   int get precision;

//   int get rangeMax;

//   int get rangeMin;
// }

// // JS "WebGLSync")
// class Sync extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory Sync._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "WebGLTimerQueryEXT")
// class TimerQueryExt extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory TimerQueryExt._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "WebGLTransformFeedback")
// class TransformFeedback extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory TransformFeedback._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "WebGLVertexArrayObject")
// class VertexArrayObject extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory VertexArrayObject._() {
//     throw new UnsupportedError("Not supported");
//   }
// }

// // JS "WebGLVertexArrayObjectOES")
// class VertexArrayObjectOes extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory VertexArrayObjectOes._() {
//     throw new UnsupportedError("Not supported");
//   }
// }
// // Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.