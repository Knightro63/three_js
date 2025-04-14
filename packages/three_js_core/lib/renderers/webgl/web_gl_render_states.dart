part of three_webgl;

class WebGLRenderState {
  bool _didDispose = false;
  late WebGLLights lights;
  WebGLExtensions extensions;
  List<Light> lightsArray = [];
  List<Light> shadowsArray = [];
  Map transmissionRenderTarget = {};
  late RenderState _renderState;

  WebGLRenderState(this.extensions) {
    lights = WebGLLights(extensions);
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
    extensions.dispose();
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

class WebGLRenderStates {
  WebGLExtensions extensions;
  WeakMap renderStates = WeakMap();

  WebGLRenderStates(this.extensions);

  WebGLRenderState get(Object3D scene, {int renderCallDepth = 0}) {
    WebGLRenderState renderState;

    if (!renderStates.has(scene)) {
      renderState = WebGLRenderState(extensions);
      renderStates.add(key: scene, value: [renderState]);
    } else {
      if (renderCallDepth >= renderStates.get(scene).length) {
        renderState = WebGLRenderState(extensions);
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
  WebGLLights lights;
  List<Light> lightsArray;
  List<Light> shadowsArray;
  Camera? camera;
  Map transmissionRenderTarget;

  RenderState(this.lights, this.lightsArray, this.shadowsArray, this.camera, this.transmissionRenderTarget);
}
