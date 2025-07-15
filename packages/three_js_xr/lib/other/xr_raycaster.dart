import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_xr/three_js_xr.dart';

final _matrix = Matrix4();

extension XRRaycaster on Raycaster{
	Raycaster setFromXRController(WebXRController controller ) {
		_matrix.identity().extractRotation( controller.matrixWorld );

		ray.origin.setFromMatrixPosition( controller.matrixWorld );
		ray.direction.setValues( 0, 0, - 1 ).applyMatrix4( _matrix );

		return this;
	}
}