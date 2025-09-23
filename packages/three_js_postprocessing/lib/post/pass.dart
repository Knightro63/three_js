import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class Pass {
  bool enabled = true;
  bool needsSwap = true;
  bool clear = false;
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
    throw ('Pass: .render() must be implemented in derived pass.');
  }

  void dispose() {}
}

class FullScreenQuad {
  final Camera camera = OrthographicCamera(-1, 1, 1, -1, 0, 1);
  final BufferGeometry geometry = FullscreenTriangleGeometry();
  late final Mesh _mesh;

  FullScreenQuad([Material? material]) {
    _mesh = Mesh(geometry, material);
  }

  set mesh(Mesh value) {
    _mesh = value;
  }

  Material? get material => _mesh.material;

  set material(Material? value) {
    _mesh.material = value;
  }

  void render(WebGLRenderer renderer) {
    renderer.render(_mesh, camera);
  }

  void dispose() {
    _mesh.geometry!.dispose();
  }
}


class FullscreenTriangleGeometry extends BufferGeometry {
	FullscreenTriangleGeometry():super() {
		this.setAttributeFromString( 'position', Float32BufferAttribute.fromList( [ -1, 3, 0, -1, -1, 0, 3, -1 , 0 ], 3 ) );
		this.setAttributeFromString( 'uv', Float32BufferAttribute.fromList( [ 0,2,0, 0,2,0 ], 2 ) );
    this.name = "FullScreenQuadGeometry";
  }
}
