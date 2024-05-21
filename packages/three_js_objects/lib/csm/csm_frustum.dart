import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;
final inverseProjectionMatrix = Matrix4.identity();

class CSMFrustumVerts{
  CSMFrustumVerts({
    required this.near,
    required this.far
  });

  List<Vector3> near;
  List<Vector3> far;
}

class CSMFrustumData{
  CSMFrustumData({
    this.projectionMatrix,
    this.maxFar
  });

  Matrix4? projectionMatrix;
  double? maxFar;
}

class CSMFrustum {
  late CSMFrustumVerts vertices;
  late CSMFrustumData data;

	CSMFrustum([CSMFrustumData? data]) {

		this.data = data ?? CSMFrustumData();

		vertices = CSMFrustumVerts(
			near: [
				Vector3(),
				Vector3(),
				Vector3(),
				Vector3()
			],
			far: [
				Vector3(),
				Vector3(),
				Vector3(),
				Vector3()
			]
    );

		if (this.data.projectionMatrix != null ) {
			setFromProjectionMatrix(this.data.projectionMatrix!, this.data.maxFar ?? 10000 );
		}
	}

	CSMFrustumVerts setFromProjectionMatrix(Matrix4 projectionMatrix, double maxFar) {
		final isOrthographic = projectionMatrix.storage[ 2 * 4 + 3 ] == 0;

		inverseProjectionMatrix.setFrom( projectionMatrix ).invert();

		// 3 --- 0  vertices.near/far order
		// |     |
		// 2 --- 1
		// clip space spans from [-1, 1]

		vertices.near[ 0 ].setValues( 1, 1, - 1 );
		vertices.near[ 1 ].setValues( 1, - 1, - 1 );
		vertices.near[ 2 ].setValues( - 1, - 1, - 1 );
		vertices.near[ 3 ].setValues( - 1, 1, - 1 );
		vertices.near.forEach(( v ) {
			v.applyMatrix4( inverseProjectionMatrix );
		});

		vertices.far[ 0 ].setValues( 1, 1, 1 );
	  vertices.far[ 1 ].setValues( 1, - 1, 1 );
		vertices.far[ 2 ].setValues( - 1, - 1, 1 );
		vertices.far[ 3 ].setValues( - 1, 1, 1 );
		vertices.far.forEach(( v ) {
			v.applyMatrix4( inverseProjectionMatrix );

			final absZ = v.z.abs();
			if ( isOrthographic ) {
				v.z *= math.min( maxFar / absZ, 1.0 );
			} else {
				v.scale( math.min( maxFar / absZ, 1.0 ) );
			}
		} );

		return vertices;
	}

	void split(List<double> breaks, List<CSMFrustum> target ) {
		while ( breaks.length > target.length ) {
			target.add( CSMFrustum() );
		}

		target.length = breaks.length;

		for ( int i = 0; i < breaks.length; i ++ ) {
			final cascade = target[ i ];
			if ( i == 0 ) {
				for ( int j = 0; j < 4; j ++ ) {
					cascade.vertices.near[ j ].setFrom( vertices.near[ j ] );
				}
			} else {
				for ( int j = 0; j < 4; j ++ ) {
					cascade.vertices.near[ j ].lerpVectors( vertices.near[ j ], vertices.far[ j ], breaks[ i - 1 ] );
				}
			}

			if ( i == breaks.length - 1 ) {
				for ( int j = 0; j < 4; j ++ ) {
					cascade.vertices.far[ j ].setFrom( vertices.far[ j ] );
				}

			} else {
				for ( int j = 0; j < 4; j ++ ) {
					cascade.vertices.far[ j ].lerpVectors( vertices.near[ j ], vertices.far[ j ], breaks[ i ] );
				}
			}
		}
	}

	void toSpace(Matrix4 cameraMatrix, CSMFrustum target ) {
		for (int i = 0; i < 4; i ++ ) {
			target.vertices.near[ i ]
				.setFrom(vertices.near[ i ] )
				.applyMatrix4( cameraMatrix );

			target.vertices.far[ i ]
				.setFrom(vertices.far[ i ] )
				.applyMatrix4( cameraMatrix );
		}
	}
}
