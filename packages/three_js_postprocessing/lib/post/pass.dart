import 'package:three_js_core/three_js_core.dart';

class Pass {
  // if set to true, the pass is processed by the composer
  bool enabled = true;

  // if set to true, the pass indicates to swap read and write buffer after rendering
  bool needsSwap = true;

  // if set to true, the pass clears its buffer before rendering
  bool clear = false;

  // if set to true, the result of the pass is rendered to screen. This is set automatically by EffectComposer.
  bool renderToScreen = false;

  late Object3D scene;
  late Camera camera;
  late Map<String, dynamic> uniforms;
  late Material material;

  late FullScreenQuad fsQuad;

  Pass();

  void setProperty(String key, dynamic newValue) {
    // print(" Pass setProperty key: ${key} ");
    uniforms[key] = {"value": newValue};
  }

  void setSize(int width, int height){}

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,{double? deltaTime, bool? maskActive}) {
    throw ('THREE.Pass: .render() must be implemented in derived pass.');
  }
}

// Helper for passes that need to fill the viewport with a single quad.

// Important: It's actually a hack to put FullScreenQuad into the Pass namespace. This is only
// done to make examples/js code work. Normally, FullScreenQuad should be exported
// from this module like Pass.

class FullScreenQuad {
  Camera camera = OrthographicCamera(-1, 1, 1, -1, 0, 1);
  BufferGeometry geometry = PlaneGeometry(2, 2);
  late Mesh _mesh;

  FullScreenQuad([Material? material]) {
    geometry.name = "FullScreenQuadGeometry";
    _mesh = Mesh(geometry, material);
  }

  set mesh(Mesh value) {
    _mesh = value;
  }

  Material? get material => _mesh.material;

  set material(Material? value) {
    _mesh.material = value;
  }

  void render(renderer) {
    renderer.render(_mesh, camera);
  }

  void dispose() {
    _mesh.geometry!.dispose();
  }
}
