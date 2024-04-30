part of three_webgl;

class WebGLRenderState {
  late WebGLLights lights;
  WebGLExtensions extensions;
  WebGLCapabilities capabilities;
  List<Light> lightsArray = [];
  List<Light> shadowsArray = [];

  WebGLRenderState(this.extensions, this.capabilities) {
    lights = WebGLLights(extensions, capabilities);
  }

  RenderState get state {
    return RenderState(lights, lightsArray, shadowsArray);
  }

  void init() {
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
  WebGLCapabilities capabilities;
  WeakMap renderStates = WeakMap();

  WebGLRenderStates(this.extensions, this.capabilities);

  WebGLRenderState get(scene, {int renderCallDepth = 0}) {
    WebGLRenderState renderState;

    if (renderStates.has(scene) == false) {
      renderState = WebGLRenderState(extensions, capabilities);
      renderStates.add(key: scene, value: [renderState]);
    } else {
      if (renderCallDepth >= renderStates.get(scene).length) {
        renderState = WebGLRenderState(extensions, capabilities);
        renderStates.get(scene).add(renderState);
      } else {
        renderState = renderStates.get(scene)[renderCallDepth];
      }
    }

    return renderState;
  }

  void dispose() {
    renderStates = WeakMap();
  }
}

class RenderState {
  WebGLLights lights;
  List<Light> lightsArray;
  List<Light> shadowsArray;

  RenderState(this.lights, this.lightsArray, this.shadowsArray);
}
