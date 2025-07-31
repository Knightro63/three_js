import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

final _translationObject = Vector3();
final _quaternionObject = Quaternion();
final _scaleObject = Vector3();

final _translationWorld = Vector3();
final _quaternionWorld = Quaternion();
final _scaleWorld = Vector3();

class Gyroscope extends Object3D {
	Gyroscope():super();

  @override
	void updateMatrixWorld([bool force = false]) {
		if(this.matrixAutoUpdate) this.updateMatrix();

		if ( this.matrixWorldNeedsUpdate || force ) {
			if ( this.parent != null ) {
				this.matrixWorld.multiply2( this.parent!.matrixWorld, this.matrix );

				this.matrixWorld.decompose( _translationWorld, _quaternionWorld, _scaleWorld );
				this.matrix.decompose( _translationObject, _quaternionObject, _scaleObject );
				this.matrixWorld.compose( _translationWorld, _quaternionObject, _scaleWorld );
			} 
      else {
				this.matrixWorld.setFrom( this.matrix );
			}

			this.matrixWorldNeedsUpdate = false;
			force = true;
		}

		// update children

		for (int i = 0, l = this.children.length; i < l; i ++ ) {
			this.children[ i ].updateMatrixWorld( force );
		}
	}
}