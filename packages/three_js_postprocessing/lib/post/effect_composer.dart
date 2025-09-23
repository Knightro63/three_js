import 'package:flutter/foundation.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'package:three_js_postprocessing/shaders/copy_shader.dart';

class EffectComposer {
  late WebGLRenderer renderer;
  late WebGLRenderTarget renderTarget1;
  late WebGLRenderTarget renderTarget2;

  late WebGLRenderTarget writeBuffer;
  late WebGLRenderTarget readBuffer;
  final FlutterAngleTexture? texture;

  bool renderToScreen = true;

  double _pixelRatio = 1.0;
  late double _width;
  late double _height;

  List<Pass> passes = [];

  late Clock clock;

  late Pass copyPass;

  EffectComposer(this.renderer, [WebGLRenderTarget? renderTarget, this.texture]) {
    _pixelRatio = renderer.getPixelRatio();

    if (renderTarget == null) {
      final parameters = {
        "type": HalfFloatType
      };

      final size = renderer.getSize(Vector2());
      
      _width = size.width;
      _height = size.height;

      renderTarget = WebGLRenderTarget(
        (_width * _pixelRatio).toInt(),
        (_height * _pixelRatio).toInt(),
        WebGLRenderTargetOptions(parameters)
      );

      renderTarget.texture.name = 'EffectComposer.rt1';
    } 
    else {
      _width = renderTarget.width*1.0;
      _height = renderTarget.height*1.0;
    }

    renderTarget1 = renderTarget;
    renderTarget2 = renderTarget.clone();
    renderTarget2.texture.name = 'EffectComposer.rt2';

    writeBuffer = renderTarget1;
    readBuffer = renderTarget2;

    renderToScreen = true;

    passes = [];

    copyPass = ShaderPass.fromJson(copyShader);
    copyPass.material.blending = NoBlending;

    clock = Clock();
  }

  void swapBuffers() {
    final tmp = readBuffer;
    readBuffer = writeBuffer;
    writeBuffer = tmp;
  }

  void addPass(Pass pass) {
    passes.add(pass);
    pass.setSize((_width * _pixelRatio).toInt(), (_height * _pixelRatio).toInt());
  }

  void insertPass(Pass pass, int index) {
    passes.removeAt(index);
    passes.insert(index,pass);
    pass.setSize((_width * _pixelRatio).toInt(), (_height * _pixelRatio).toInt());
  }

  void removePass(Pass pass) {
    final index = passes.indexOf(pass);

    if (index != -1) {
      passes.removeAt(index);
    }
  }

  void clearPass() {
    passes.clear();
  }

  bool isLastEnabledPass(int passIndex) {
    for (int i = passIndex + 1; i < passes.length; i++) {
      if (passes[i].enabled) {
        return false;
      }
    }

    return true;
  }

  void render([double? deltaTime]) {
    // deltaTime value is in seconds
    deltaTime ??= clock.getDelta();
    bool maskActive = false;
    final currentRenderTarget = this.renderer.getRenderTarget();
    final il = passes.length;

    for (int i = 0; i < il; i++) {
      final pass = passes[i];

      if (pass.enabled == false) continue;
      
      pass.renderToScreen = (renderToScreen && isLastEnabledPass(i));
      if(pass.renderToScreen && !kIsWeb) texture?.activate();
      pass.render(renderer, writeBuffer, readBuffer, deltaTime: deltaTime, maskActive: maskActive);

      if (pass.needsSwap) {
        if (maskActive) {
          final context = renderer.getContext();
          final stencil = renderer.state.buffers["stencil"];

          //context.stencilFunc( context.NOTEQUAL, 1, 0xffffffff );
          stencil.setFunc(context.NOTEQUAL, 1, 0xffffffff);

          copyPass.render(renderer, writeBuffer, readBuffer, deltaTime: deltaTime);

          //context.stencilFunc( context.EQUAL, 1, 0xffffffff );
          stencil.setFunc(context.EQUAL, 1, 0xffffffff);
        }

        swapBuffers();
      }

      if (pass is MaskPass) {
        maskActive = true;
      } 
      else if (pass is ClearMaskPass) {
        maskActive = false;
      }
      if(pass.renderToScreen && !kIsWeb) texture?.signalNewFrameAvailable();
    }
    renderer.setRenderTarget(currentRenderTarget);
  }

  void reset([WebGLRenderTarget? renderTarget]) {
    if (renderTarget == null) {
      final size = renderer.getSize(Vector2());
      _pixelRatio = renderer.getPixelRatio();
      _width = size.width;
      _height = size.height;

      renderTarget = renderTarget1.clone();
      renderTarget.setSize((_width * _pixelRatio).toInt(), (_height * _pixelRatio).toInt());
    }

    renderTarget1.dispose();
    renderTarget2.dispose();
    renderTarget1 = renderTarget;
    renderTarget2 = renderTarget.clone();

    writeBuffer = renderTarget1;
    readBuffer = renderTarget2;
  }

  void setSize(double width, double height) {
    _width = width;
    _height = height;

    int effectiveWidth = (_width * _pixelRatio).toInt();
    int effectiveHeight = (_height * _pixelRatio).toInt();

    renderTarget1.setSize(effectiveWidth, effectiveHeight);
    renderTarget2.setSize(effectiveWidth, effectiveHeight);

    for (int i = 0; i < passes.length; i++) {
      passes[i].setSize(effectiveWidth, effectiveHeight);
    }
  }

  void setPixelRatio(double pixelRatio) {
    _pixelRatio = pixelRatio;

    setSize(_width, _height);
  }

	void dispose() {
		renderTarget1.dispose();
		renderTarget2.dispose();
		copyPass.dispose();
	}
}
