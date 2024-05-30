library flutter_angle;

import 'package:flutter/widgets.dart';
import 'package:flutter_angle/desktop/render_worker.dart';
import 'package:flutter_angle/flutter_angle.dart';

import '../shared/options.dart';
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'wrapper.dart';
import 'package:dylib/dylib.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'lib_egl.dart';
import 'bindings/index.dart';

class FlutterGLTexture {
  final dynamic element;
  final int textureId;
  final int rboId;
  final int metalAsGLTextureId;
  late final Pointer<Void> androidSurface;
  final int fboId;
  //static LibOpenGLES? _libOpenGLES;
  late AngleOptions options;

  LibOpenGLES get rawOpenGl {
    return FlutterAngle._rawOpenGl;
  }

  FlutterGLTexture(
    this.textureId, 
    this.rboId, 
    this.metalAsGLTextureId,
    int androidSurfaceId, 
    this.element,
    this.fboId, 
    this.options
  ) {
    androidSurface = Pointer.fromAddress(androidSurfaceId);
  }

  static FlutterGLTexture fromMap(
    dynamic map, 
    dynamic element,
    int fboId, 
    AngleOptions options
  ){    
    return FlutterGLTexture(
      map['textureId']! as int,
      map['rbo'] as int? ?? 0,
      map['metalAsGLTexture'] as int? ?? 0,
      map['surface'] as int? ?? 0,
      element,
      fboId,
      options
    );
  }

  Map<String, int> toMap() {
    return {
      'textureId': textureId,
      'rbo': rboId,
      'metalAsGLTexture': metalAsGLTextureId
    };
  }

  RenderingContext getContext() {
    assert(FlutterAngle._baseAppContext != nullptr, "OpenGL isn't initialized! Please call FlutterAngle.initOpenGL");
    return RenderingContext.create(FlutterAngle._rawOpenGl);
  }

  /// Whenever you finished your rendering you have to call this function to signal
  /// the Flutterengine that it can display the rendering
  /// Despite this being an asyc function it probably doesn't make sense to await it
  Future<void> signalNewFrameAvailable() async {
    await FlutterAngle.updateTexture(this);
  }

  /// As you can have multiple Texture objects, but WebGL allways draws in the currently
  /// active one you have to call this function if you use more than one Textureobject before
  /// you can start rendering on it. If you forget it you will render into the wrong Texture.
  void activate() {
    FlutterAngle.activateTexture(this);
    FlutterAngle._rawOpenGl.glViewport(0, 0, options.width, options.height);
  }
}

class FlutterAngle {
  static const MethodChannel _channel = const MethodChannel('flutter_angle');
  static LibOpenGLES? _libOpenGLES;
  static Pointer<Void> _display = nullptr;
  static late Pointer<Void> _EGLconfig;
  static Pointer<Void> _baseAppContext = nullptr;
  static Pointer<Void> _pluginContext = nullptr;
  static late Pointer<Void> _dummySurface;
  static int? _activeFramebuffer;
  static late RenderWorker worker; 

  static LibOpenGLES get _rawOpenGl {
    if (FlutterAngle._libOpenGLES == null) {
      if (Platform.isMacOS || Platform.isIOS) {
        FlutterAngle._libOpenGLES = LibOpenGLES(DynamicLibrary.process());
      } else if (Platform.isAndroid) {
        FlutterAngle._libOpenGLES = LibOpenGLES(DynamicLibrary.open('libGLESv3.so'));
      } else {
        FlutterAngle._libOpenGLES =
            LibOpenGLES(DynamicLibrary.open(resolveDylibPath('libGLESv2')));
      }
    }
    return FlutterAngle._libOpenGLES!;
  }

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  // Next stepps:
  // * test on all plaforms
  // * mulitple textures on Android and the other OSs

  static Future<void> initOpenGL([bool useDebugContext = false]) async {
    /// make sure we don't call this twice
    if (_display != nullptr) {
      return;
    }
    loadEGL();
    // Initialize native part of he plugin
    final result = await _channel.invokeMethod('initOpenGL');

    if (result == null) {
      throw EglException(
          'Plugin.initOpenGL didn\'t return anything. Something is really wrong!');
    }

    final pluginContextAdress = result['context'] as int?;
    if (pluginContextAdress == null) {
      throw EglException(
          'Plugin.initOpenGL didn\'t return a Context. Something is really wrong!');
    }

    _pluginContext = Pointer<Void>.fromAddress(pluginContextAdress);

    final dummySurfacePointer = result['dummySurface'] as int?;
    if (dummySurfacePointer == null) {
      throw EglException(
          'Plugin.initOpenGL didn\'t return a dummy surface. Something is really wrong!');
    }
    _dummySurface = Pointer<Void>.fromAddress(dummySurfacePointer);

    /// Init OpenGL on the Dart side too
    _display = eglGetDisplay();
    final initializeResult = eglInitialize(_display);

    debugPrint('EGL version: $initializeResult');

    late final Map<EglConfigAttribute, int> eglAttributes;

    /// In case the plugin returns its selected EGL config we use it.
    /// Finally this should be how all platforms behave. Till all platforms
    /// support this we leave this check here
    final eglConfigId = result['eglConfigId'] as int?;
    if (eglConfigId != null) {
      eglAttributes = {
        EglConfigAttribute.configId: eglConfigId,
      };
    } else {
      eglAttributes = {
        EglConfigAttribute.renderableType: EglValue.openglEs3Bit.toIntValue(),
        EglConfigAttribute.redSize: 8,
        EglConfigAttribute.greenSize: 8,
        EglConfigAttribute.blueSize: 8,
        EglConfigAttribute.alphaSize: 8,
        EglConfigAttribute.depthSize: 16,
        EglConfigAttribute.samples: 4
      };
    }
    final chooseConfigResult = eglChooseConfig(
      _display,
      attributes: eglAttributes,
      maxConfigs: 1,
    );
    _EGLconfig = chooseConfigResult[0];

    // The following code is helpful to debug EGL issues
    // final existingConfigs = eglGetConfigs(_display, maxConfigs: 50);
    // print('Number of configs ${existingConfigs.length}');
    // for (int i = 0; i < existingConfigs.length; i++) {
    //   print('\nConfig No: $i');
    //   printConfigAttributes(_display, existingConfigs[i]);
    // }

    _baseAppContext = eglCreateContext(_display, _EGLconfig,
        // we link both contexts so that app and plugin can share OpenGL Objects
        shareContext: _pluginContext,
        contextClientVersion: 3,
        // Android does not support debugContexts
        isDebugContext: useDebugContext && !Platform.isAndroid);

    /// bind context to this thread. All following OpenGL calls from this thread will use this context
    eglMakeCurrent(_display, _dummySurface, _dummySurface, _baseAppContext);

    if (useDebugContext && Platform.isWindows) {
      _rawOpenGl.glEnable(GL_DEBUG_OUTPUT);
      _rawOpenGl.glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
      _rawOpenGl.glDebugMessageCallback(Pointer.fromFunction<GLDEBUGPROC>(glDebugOutput), nullptr);
      _rawOpenGl.glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, nullptr, GL_TRUE);
    }
  }

  static void glDebugOutput(int source, int type, int id, int severity,
      int length, Pointer<Int8> pMessage, Pointer<Void> pUserParam) {
    final message = pMessage.cast<Utf8>().toDartString();
    // ignore non-significant error/warning codes
    // if (id == 131169 || id == 131185 || id == 131218 || id == 131204) return;

    print("---------------");
    print("Debug message $id  $message");

    switch (source) {
      case GL_DEBUG_SOURCE_API:
        print("Source: API");
        break;
      case GL_DEBUG_SOURCE_WINDOW_SYSTEM:
        print("Source: Window System");
        break;
      case GL_DEBUG_SOURCE_SHADER_COMPILER:
        print("Source: Shader Compiler");
        break;
      case GL_DEBUG_SOURCE_THIRD_PARTY:
        print("Source: Third Party");
        break;
      case GL_DEBUG_SOURCE_APPLICATION:
        print("Source: Application");
        break;
      case GL_DEBUG_SOURCE_OTHER:
        print("Source: Other");
        break;
    }
    switch (type) {
      case GL_DEBUG_TYPE_ERROR:
        print("Type: Error");
        break;
      case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
        print("Type: Deprecated Behaviour");
        break;
      case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
        print("Type: Undefined Behaviour");
        break;
      case GL_DEBUG_TYPE_PORTABILITY:
        print("Type: Portability");
        break;
      case GL_DEBUG_TYPE_PERFORMANCE:
        print("Type: Performance");
        break;
      case GL_DEBUG_TYPE_MARKER:
        print("Type: Marker");
        break;
      case GL_DEBUG_TYPE_PUSH_GROUP:
        print("Type: Push Group");
        break;
      case GL_DEBUG_TYPE_POP_GROUP:
        print("Type: Pop Group");
        break;
      case GL_DEBUG_TYPE_OTHER:
        print("Type: Other");
        break;
    }

    switch (severity) {
      case GL_DEBUG_SEVERITY_HIGH:
        print("Severity: high");
        break;
      case GL_DEBUG_SEVERITY_MEDIUM:
        print("Severity: medium");
        break;
      case GL_DEBUG_SEVERITY_LOW:
        print("Severity: low");
        break;
      case GL_DEBUG_SEVERITY_NOTIFICATION:
        print("Severity: notification");
        break;
    }
    print('\n');
  }

  static Future<FlutterGLTexture> createTexture(AngleOptions options) async {
    final textureTarget = GL_TEXTURE_RECTANGLE;//GL_TEXTURE_RECTANGLE;//GL_TEXTURE_2D
    final height = (options.height*options.dpr).toInt();
    final width = (options.width*options.dpr).toInt();
    final result = await _channel.invokeMethod('createTexture', {"width": width, "height": height});

    if (Platform.isAndroid) {
      final newTexture = FlutterGLTexture.fromMap(result, null, 0, options);
      _rawOpenGl.glViewport(0, 0, width, height);
      return newTexture;
    }

    Pointer<Uint32> fbo = calloc();
    _rawOpenGl.glGenFramebuffers(1, fbo);
    _rawOpenGl.glBindFramebuffer(GL_FRAMEBUFFER, fbo.value);

    final newTexture = FlutterGLTexture.fromMap(result, null, fbo.value, options);
  
    print(_rawOpenGl.glGetError());
    _rawOpenGl.glActiveTexture(WebGL.TEXTURE0);

    if (newTexture.metalAsGLTextureId != 0) {
      // Draw to metal interop texture directly
      _rawOpenGl.glBindTexture(textureTarget, newTexture.metalAsGLTextureId);
      _rawOpenGl.glTexParameteri(textureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      _rawOpenGl.glTexParameteri(textureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      _rawOpenGl.glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, textureTarget, newTexture.metalAsGLTextureId, 0);
    } 
    else {
      _rawOpenGl.glBindRenderbuffer(GL_RENDERBUFFER, newTexture.rboId);
      _rawOpenGl.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, newTexture.rboId);
    }

    var frameBufferCheck = _rawOpenGl.glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (frameBufferCheck != GL_FRAMEBUFFER_COMPLETE) {
      print("Framebuffer (color) check failed: $frameBufferCheck");
    }

    _rawOpenGl.glViewport(0, 0, width, height);

    Pointer<Int32> depthBuffer = calloc();
    _rawOpenGl.glGenRenderbuffers(1, depthBuffer.cast());
    _rawOpenGl.glBindRenderbuffer(GL_RENDERBUFFER, depthBuffer.value);
    _rawOpenGl.glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);

    _rawOpenGl.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthBuffer.value);
    _rawOpenGl.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, depthBuffer.value);

    frameBufferCheck = _rawOpenGl.glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (frameBufferCheck != GL_FRAMEBUFFER_COMPLETE) {
      print("Framebuffer (depth) check failed: $frameBufferCheck");
    }
    
    _activeFramebuffer = fbo.value;
    calloc.free(fbo);

    if(!options.customRenderer){
      worker = RenderWorker(newTexture);
    }
    
    return newTexture;
  }

  static Future<void> updateTexture(FlutterGLTexture texture, [WebGLTexture? sourceTexture]) async {
    if (Platform.isAndroid) {
      eglSwapBuffers(_display, _dummySurface);
      return;
    }

    if(sourceTexture != null){
      _rawOpenGl.glBindFramebuffer(GL_FRAMEBUFFER, texture.fboId);
      _rawOpenGl.glClearColor(0.0, 0.0, 0.0, 0.0);
      _rawOpenGl.glClear(GL_COLOR_BUFFER_BIT);
      _rawOpenGl.glViewport(0, 0, (texture.options.width*texture.options.dpr).toInt(),( texture.options.height*texture.options.dpr).toInt());
      worker.renderTexture(sourceTexture);
      _rawOpenGl.glFinish();
    }

    _rawOpenGl.glFlush();

    assert(_activeFramebuffer != null,'There is no active FlutterGL Texture to update');
    await _channel.invokeMethod('updateTexture', {"textureId": texture.textureId});
  }

  static Future<void> deleteTexture(FlutterGLTexture texture) async {
    assert(_activeFramebuffer != null, 'There is no active FlutterGL Texture to delete');
    if (_activeFramebuffer == texture.fboId) {
      _rawOpenGl.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, 0);

      Pointer<Uint32> fbo = calloc();
      fbo.value = texture.fboId;
      _rawOpenGl.glDeleteBuffers(1, fbo);
      calloc.free(fbo);
    }
    worker.dispose();
    await _channel.invokeMethod('deleteTexture', {"textureId": texture.textureId});
  }

  static void activateTexture(FlutterGLTexture texture) {
    if (Platform.isAndroid) {
      eglMakeCurrent(_display, texture.androidSurface, texture.androidSurface,_baseAppContext);
      return;
    }
    _rawOpenGl.glBindFramebuffer(GL_FRAMEBUFFER, texture.fboId);
    if (texture.metalAsGLTextureId != 0) {
      // Draw to metal interop texture directly
      _rawOpenGl.glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D, texture.metalAsGLTextureId, 0);
    } 
    else {
      _rawOpenGl.glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, texture.rboId);
    }
    printOpenGLError('activateTextue ${texture.textureId}');
    _activeFramebuffer = texture.fboId;
  }

  static void printOpenGLError(String message) {
    var glGetError = _rawOpenGl.glGetError();
    if (glGetError != GL_NO_ERROR) {
      print('$message: $glGetError');
    }
  }
}
