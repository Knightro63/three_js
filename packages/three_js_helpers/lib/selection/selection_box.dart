import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'dart:math' as math;

class SelectionBox {
  final _frustum = Frustum();
  final _center = Vector3.zero();

  final _tmpPoint = Vector3.zero();

  final _vecNear = Vector3.zero();
  final _vecTopLeft = Vector3.zero();
  final _vecTopRight = Vector3.zero();
  final _vecDownRight = Vector3.zero();
  final _vecDownLeft = Vector3.zero();

  final _vecFarTopLeft = Vector3.zero();
  final _vecFarTopRight = Vector3.zero();
  final _vecFarDownRight = Vector3.zero();
  final _vecFarDownLeft = Vector3.zero();

  final _vectemp1 = Vector3.zero();
  final _vectemp2 = Vector3.zero();
  final _vectemp3 = Vector3.zero();

  final _matrix = Matrix4();
  final _quaternion = Quaternion();
  final _scale = Vector3.zero();

  final Camera camera;
  final Scene scene;
  Vector3 startPoint = Vector3.zero();
  Vector3 endPoint = Vector3.zero();
  List<Object3D> collection = [];
  Map instances = {};
  double deep;

	SelectionBox(this.camera, this.scene, [this.deep = double.maxFinite ]);

	List<Object3D> select([Vector3? startPoint, Vector3? endPoint]) {
		this.startPoint = startPoint ?? this.startPoint;
		this.endPoint = endPoint ?? this.endPoint;
		collection = [];

		updateFrustum( this.startPoint, this.endPoint );
	  searchChildInFrustum( _frustum, scene );

		return collection;
	}

	void updateFrustum([Vector? startPoint,Vector3? endPoint]) {

		startPoint = startPoint ?? this.startPoint;
		endPoint = endPoint ?? this.endPoint;

		// Avoid invalid frustum

		if ( startPoint.x == endPoint.x ) {
			endPoint.x += MathUtils.epsilon;
		}

		if ( startPoint.y == endPoint.y ) {
			endPoint.y += MathUtils.epsilon;
		}

		camera.updateProjectionMatrix();
		camera.updateMatrixWorld();

		if (camera is PerspectiveCamera ) {
			_tmpPoint.setFrom( startPoint );
			_tmpPoint.x = math.min( startPoint.x, endPoint.x );
			_tmpPoint.y = math.max( startPoint.y, endPoint.y );
			endPoint.x = math.max( startPoint.x, endPoint.x );
			endPoint.y = math.min( startPoint.y, endPoint.y );

			_vecNear.setFromMatrixPosition( camera.matrixWorld );
			_vecTopLeft.setFrom( _tmpPoint );
			_vecTopRight.setValues( endPoint.x, _tmpPoint.y, 0 );
			_vecDownRight.setFrom( endPoint );
			_vecDownLeft.setValues( _tmpPoint.x, endPoint.y, 0 );

			_vecTopLeft.unproject( camera );
			_vecTopRight.unproject( camera );
			_vecDownRight.unproject( camera );
			_vecDownLeft.unproject( camera );

			_vectemp1.setFrom( _vecTopLeft ).sub( _vecNear );
			_vectemp2.setFrom( _vecTopRight ).sub( _vecNear );
			_vectemp3.setFrom( _vecDownRight ).sub( _vecNear );
			_vectemp1.normalize();
			_vectemp2.normalize();
			_vectemp3.normalize();

			_vectemp1.scale( deep );
			_vectemp2.scale( deep );
			_vectemp3.scale( deep );
			_vectemp1.add( _vecNear );
			_vectemp2.add( _vecNear );
			_vectemp3.add( _vecNear );

			final planes = _frustum.planes;

			planes[ 0 ].setFromCoplanarPoints( _vecNear, _vecTopLeft, _vecTopRight );
			planes[ 1 ].setFromCoplanarPoints( _vecNear, _vecTopRight, _vecDownRight );
			planes[ 2 ].setFromCoplanarPoints( _vecDownRight, _vecDownLeft, _vecNear );
			planes[ 3 ].setFromCoplanarPoints( _vecDownLeft, _vecTopLeft, _vecNear );
			planes[ 4 ].setFromCoplanarPoints( _vecTopRight, _vecDownRight, _vecDownLeft );
			planes[ 5 ].setFromCoplanarPoints( _vectemp3, _vectemp2, _vectemp1 );
			planes[ 5 ].normal.scale( - 1 );

		} else if (camera is OrthographicCamera ) {

			final left = math.min( startPoint.x, endPoint.x );
			final top = math.max( startPoint.y, endPoint.y );
			final right = math.max( startPoint.x, endPoint.x );
			final down = math.min( startPoint.y, endPoint.y );

			_vecTopLeft.setValues( left, top, - 1 );
			_vecTopRight.setValues( right, top, - 1 );
			_vecDownRight.setValues( right, down, - 1 );
			_vecDownLeft.setValues( left, down, - 1 );

			_vecFarTopLeft.setValues( left, top, 1 );
			_vecFarTopRight.setValues( right, top, 1 );
			_vecFarDownRight.setValues( right, down, 1 );
			_vecFarDownLeft.setValues( left, down, 1 );

			_vecTopLeft.unproject( camera );
			_vecTopRight.unproject( camera );
			_vecDownRight.unproject( camera );
			_vecDownLeft.unproject( camera );

			_vecFarTopLeft.unproject( camera );
			_vecFarTopRight.unproject( camera );
			_vecFarDownRight.unproject( camera );
			_vecFarDownLeft.unproject( camera );

			final planes = _frustum.planes;

			planes[ 0 ].setFromCoplanarPoints( _vecTopLeft, _vecFarTopLeft, _vecFarTopRight );
			planes[ 1 ].setFromCoplanarPoints( _vecTopRight, _vecFarTopRight, _vecFarDownRight );
			planes[ 2 ].setFromCoplanarPoints( _vecFarDownRight, _vecFarDownLeft, _vecDownLeft );
			planes[ 3 ].setFromCoplanarPoints( _vecFarDownLeft, _vecFarTopLeft, _vecTopLeft );
			planes[ 4 ].setFromCoplanarPoints( _vecTopRight, _vecDownRight, _vecDownLeft );
			planes[ 5 ].setFromCoplanarPoints( _vecFarDownRight, _vecFarTopRight, _vecFarTopLeft );
			planes[ 5 ].normal.scale( - 1 );

		} else {
			console.error( 'THREE.SelectionBox: Unsupported camera type.' );
		}
	}

	void searchChildInFrustum(Frustum frustum, Object3D object ) {
		if ( object is Mesh || object is Line || object is Points ) {
			if ( object is InstancedMesh ) {
				instances[ object.uuid ] = [];

				for (int instanceId = 0; instanceId < (object.count ?? 0); instanceId ++ ) {
					object.getMatrixAt( instanceId, _matrix );
					_matrix.decompose( _center, _quaternion, _scale );
					_center.applyMatrix4( object.matrixWorld );

					if ( frustum.containsPoint( _center ) ) {
						instances[ object.uuid ].add( instanceId );
					}
				}
			} 
      else {
				if ( object.geometry?.boundingSphere == null ) object.geometry?.computeBoundingSphere();
				_center.setFrom( object.geometry!.boundingSphere!.center );
				_center.applyMatrix4( object.matrixWorld );

				if ( frustum.containsPoint( _center ) ) {
					collection.add( object );
				}
			}
		}

		if ( object.children.isNotEmpty ) {
			for (int x = 0; x < object.children.length; x ++ ) {
				searchChildInFrustum( frustum, object.children[ x ] );
			}
		}
	}
}
