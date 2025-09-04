import "package:three_js_core/three_js_core.dart";
import "pass.dart";

class MaskPass extends Pass {
  bool inverse = false;

  MaskPass(Scene scene,Camera camera) : super() {
    this.scene = scene;
    this.camera = camera;

    clear = true;
    needsSwap = false;
  }

  @override
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,{double? deltaTime, bool? maskActive}) {
    final context = renderer.getContext();
    final state = renderer.state;

    // don't update color or depth

    state.buffers['color'].setMask(false);
    state.buffers['depth'].setMask(false);

    // lock buffers

    state.buffers['color'].setLocked(true);
    state.buffers['depth'].setLocked(true);

    // set up stencil

    dynamic writeValue, clearValue;

    if (inverse) {
      writeValue = 0;
      clearValue = 1;
    } else {
      writeValue = 1;
      clearValue = 0;
    }

    state.buffers['stencil'].setTest(true);
    state.buffers['stencil']
        .setOp(context.REPLACE, context.REPLACE, context.REPLACE);
    state.buffers['stencil'].setFunc(context.ALWAYS, writeValue, 0xffffffff);
    state.buffers['stencil'].setClear(clearValue);
    state.buffers['stencil'].setLocked(true);

    // draw into the stencil buffer

    renderer.setRenderTarget(readBuffer);
    if (clear) renderer.clear();
    renderer.render(scene, camera);

    renderer.setRenderTarget(writeBuffer);
    if (clear) renderer.clear();
    renderer.render(scene, camera);

    // unlock color and depth buffer for subsequent rendering

    state.buffers['color'].setLocked(false);
    state.buffers['depth'].setLocked(false);

    // only render where stencil is set to 1

    state.buffers['stencil'].setLocked(false);
    state.buffers['stencil'].setFunc(context.EQUAL, 1, 0xffffffff); // draw if == 1
    state.buffers['stencil'].setOp(context.KEEP, context.KEEP, context.KEEP);
    state.buffers['stencil'].setLocked(true);
  }
}

class ClearMaskPass extends Pass {
  ClearMaskPass() : super() {
    needsSwap = false;
  }
  @override
  void render(WebGLRenderer renderer, writeBuffer, readBuffer,{double? deltaTime, bool? maskActive}) {
    renderer.state.buffers["stencil"].setLocked(false);
    renderer.state.buffers["stencil"].setTest(false);
  }
}
