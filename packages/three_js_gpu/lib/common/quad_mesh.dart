import "package:three_js_core/three_js_core.dart";
import "package:three_js_math/buffer/buffer_attribute.dart";

OrthographicCamera _camera = OrthographicCamera( - 1, 1, 1, - 1, 0, 1 );

class QuadGeometry extends BufferGeometry {
	QuadGeometry([bool flipY = false ]):super() {
		final List<double> uv = flipY == false ? [ 0, - 1, 0, 1, 2, 1 ] : [ 0, 2, 0, 0, 2, 0 ];

		setAttributeFromString( 'position',Float32BufferAttribute.fromList( [ - 1, 3, 0, - 1, - 1, 0, 3, - 1, 0 ], 3 ) );
		setAttributeFromString( 'uv',Float32BufferAttribute.fromList( uv, 2 ) );
	}
}

final _geometry = QuadGeometry();

/**
 * This module is a helper for passes which need to render a full
 * screen effect which is quite common in context of post processing.
 *
 * The intended usage is to reuse a single quad mesh for rendering
 * subsequent passes by just reassigning the `material` reference.
 *
 * Note: This module can only be used with `WebGPURenderer`.
 *
 * @augments Mesh
 */
class QuadMesh extends Mesh {
  Camera camera = _camera;
	QuadMesh(Material? material):super(_geometry,material);

	Future renderAsync( renderer ) async{
		return renderer.renderAsync( this, _camera );
	}

	render(Renderer renderer ) {
		renderer.render( this, _camera );
	}
}