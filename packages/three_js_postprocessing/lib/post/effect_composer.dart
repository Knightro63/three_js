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

  bool renderToScreen = true;

  double _pixelRatio = 1.0;
  late int _width;
  late int _height;

  List<Pass> passes = [];

  late Clock clock;

  late Pass copyPass;

  EffectComposer(this.renderer, [WebGLRenderTarget? renderTarget]) {
    if (renderTarget == null) {
      final parameters = {
        "minFilter": LinearFilter,
        "magFilter": LinearFilter,
        "format": RGBAFormat
      };

      final size = renderer.getSize(Vector2(null, null));
      _pixelRatio = renderer.getPixelRatio();
      _width = size.width.toInt();
      _height = size.height.toInt();

      renderTarget = WebGLRenderTarget(
          (_width * _pixelRatio).toInt(),
          (_height * _pixelRatio).toInt(),
          WebGLRenderTargetOptions(parameters));
    } 
    else {
      _pixelRatio = 1;
      _width = renderTarget.width;
      _height = renderTarget.height;
    }

    renderTarget1 = renderTarget;
    renderTarget2 = renderTarget.clone();
    renderTarget2.texture.name = 'EffectComposer.rt2';

    writeBuffer = renderTarget1;
    readBuffer = renderTarget2;

    renderToScreen = true;

    passes = [];

    copyPass = ShaderPass.fromJson(copyShader);

    clock = Clock(false);
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
    final currentRenderTarget = renderer.getRenderTarget();

    bool maskActive = false;

    Pass? pass;
    final il = passes.length;

    for (int i = 0; i < il; i++) {
      pass = passes[i];

      if (pass.enabled == false) continue;

      pass.renderToScreen = (renderToScreen && isLastEnabledPass(i));
      pass.render(renderer, writeBuffer, readBuffer,deltaTime: deltaTime, maskActive: maskActive);

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

      //if (pass != null) {
        if (pass is MaskPass) {
          maskActive = true;
        } 
        else if (pass is ClearMaskPass) {
          maskActive = false;
        }
      //}
    }

    renderer.setRenderTarget(currentRenderTarget);
  }

  void reset(WebGLRenderTarget? renderTarget) {
    if (renderTarget == null) {
      final size = renderer.getSize(Vector2());
      _pixelRatio = renderer.getPixelRatio();
      _width = size.width.toInt();
      _height = size.height.toInt();

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

  void setSize(int width, int height) {
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
}
