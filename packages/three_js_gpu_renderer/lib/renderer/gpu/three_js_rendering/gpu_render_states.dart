import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu_renderer/renderer/gpu/three_js_rendering/gpu_lights.dart';

class GpuRenderState {
  bool _didDispose = false;
  late GpuLights lights;
  List<Light> lightsArray = [];
  List<Light> shadowsArray = [];
  Map transmissionRenderTarget = {};
  late RenderState _renderState;

  GpuRenderState() {
    lights = GpuLights();
    _renderState = RenderState(lights, lightsArray, shadowsArray, null, {});
  }

  RenderState get state {
    return _renderState;
  }

  void dispose(){
    if(_didDispose) return;
    _didDispose = true;
    lightsArray.clear();
    shadowsArray.clear();
    lights.dispose();
    lights.dispose();
  }

  void init(Camera camera) {
    state.camera = camera;

    lightsArray.length = 0;
    shadowsArray.length = 0;
  }

  void pushLight(Light light) {
    lightsArray.add(light);
  }

  void pushShadow(Light shadowLight) {
    shadowsArray.add(shadowLight);
  }

  void setupLights([bool? physicallyCorrectLights]) {
    lights.setup(lightsArray, physicallyCorrectLights);
  }

  void setupLightsView(Camera camera) {
    lights.setupView(lightsArray, camera);
  }
}

class GpuRenderStates {
  WeakMap renderStates = WeakMap();

  GpuRenderStates();

  GpuRenderState get(Object3D scene, {int renderCallDepth = 0}) {
    GpuRenderState renderState;

    if (!renderStates.has(scene)) {
      renderState = GpuRenderState();
      renderStates.add(key: scene, value: [renderState]);
    } else {
      if (renderCallDepth >= renderStates.get(scene).length) {
        renderState = GpuRenderState();
        renderStates.get(scene).add(renderState);
      } else {
        renderState = renderStates.get(scene)[renderCallDepth];
      }
    }

    return renderState;
  }

  void dispose() {
    renderStates.clear();
  }
}

class RenderState {
  GpuLights lights;
  List<Light> lightsArray;
  List<Light> shadowsArray;
  Camera? camera;
  Map transmissionRenderTarget;

  RenderState(this.lights, this.lightsArray, this.shadowsArray, this.camera, this.transmissionRenderTarget);
}
