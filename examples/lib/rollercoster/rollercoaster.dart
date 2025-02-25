import 'dart:math' as math;

import 'package:three_js/three_js.dart';

class RollerCoasterCurve{
  RollerCoasterCurve({
    Vector3 Function(double)?  getPointAt,
    Vector3 Function(double)?  getTangentAt
  }){
    this.getPointAt = getPointAt ?? (t){return Vector3();};
    this.getTangentAt = getTangentAt ?? (t){return Vector3();};
  }

  late Vector3 Function(double) getPointAt;
  late Vector3 Function(double) getTangentAt;
}

class RollerCoasterGeometry extends BufferGeometry {
	RollerCoasterGeometry(RollerCoasterCurve curve, int divisions ):super() {
		final List<double> vertices = [];
		final List<double> normals = [];
		final List<double> colors = [];

		final List<double> color1 = [ 1, 1, 1 ];
		final List<double> color2 = [ 1, 1, 0 ];

		final up = Vector3( 0, 1, 0 );
		final forward = Vector3();
		final right = Vector3();

		final quaternion = Quaternion();
		final prevQuaternion = Quaternion();
		prevQuaternion.setFromAxisAngle( up, math.pi / 2 );

		final point = Vector3();
		final prevPoint = Vector3();
		prevPoint.setFrom( curve.getPointAt( 0 ) );

		// shapes

		final step = [
			Vector3( - 0.225, 0, 0 ),
			Vector3( 0, - 0.050, 0 ),
			Vector3( 0, - 0.175, 0 ),

			Vector3( 0, - 0.050, 0 ),
			Vector3( 0.225, 0, 0 ),
			Vector3( 0, - 0.175, 0 )
		];

		final PI2 = math.pi * 2;

		int sides = 5;
		final tube1 = [];

		for ( int i = 0; i < sides; i ++ ) {
			final angle = ( i / sides ) * PI2;
			tube1.add( Vector3( math.sin( angle ) * 0.06, math.cos( angle ) * 0.06, 0 ) );
		}

		sides = 6;
		final tube2 = [];

		for (int i = 0; i < sides; i ++ ) {
			final angle = ( i / sides ) * PI2;
			tube2.add( Vector3( math.sin( angle ) * 0.025, math.cos( angle ) * 0.025, 0 ) );
		}

		final vector = Vector3();
		final normal = Vector3();

		void drawShape( shape, color ) {
			normal.setValues( 0, 0, - 1 ).applyQuaternion( quaternion );

			for (int j = 0; j < shape.length; j ++ ) {
				vector.setFrom( shape[ j ] );
				vector.applyQuaternion( quaternion );
				vector.add( point );

				vertices.addAll([ vector.x, vector.y, vector.z ]);
				normals.addAll([ normal.x, normal.y, normal.z ]);
				colors.addAll([ color[ 0 ], color[ 1 ], color[ 2 ] ]);
			}

			normal.setValues( 0, 0, 1 ).applyQuaternion( quaternion );

			for (int j = shape.length - 1; j >= 0; j -- ) {
				vector.setFrom( shape[ j ] );
				vector.applyQuaternion( quaternion );
				vector.add( point );

				vertices.addAll([ vector.x, vector.y, vector.z ]);
				normals.addAll([ normal.x, normal.y, normal.z ]);
				colors.addAll([ color[ 0 ], color[ 1 ], color[ 2 ] ]);
			}
		}

		final vector1 = Vector3();
		final vector2 = Vector3();
		final vector3 = Vector3();
		final vector4 = Vector3();

		final normal1 = Vector3();
		final normal2 = Vector3();
		final normal3 = Vector3();
		final normal4 = Vector3();

		void extrudeShape( shape, Vector3 offset, List<double> color ) {

			for (int j = 0, jl = shape.length; j < jl; j ++ ) {

				final point1 = shape[ j ];
				final point2 = shape[ ( j + 1 ) % jl ];

				vector1.setFrom( point1 ).add( offset );
				vector1.applyQuaternion( quaternion );
				vector1.add( point );

				vector2.setFrom( point2 ).add( offset );
				vector2.applyQuaternion( quaternion );
				vector2.add( point );

				vector3.setFrom( point2 ).add( offset );
				vector3.applyQuaternion( prevQuaternion );
				vector3.add( prevPoint );

				vector4.setFrom( point1 ).add( offset );
				vector4.applyQuaternion( prevQuaternion );
				vector4.add( prevPoint );

				vertices.addAll([ vector1.x, vector1.y, vector1.z ]);
				vertices.addAll([ vector2.x, vector2.y, vector2.z ]);
				vertices.addAll([ vector4.x, vector4.y, vector4.z ]);

				vertices.addAll([ vector2.x, vector2.y, vector2.z ]);
				vertices.addAll([ vector3.x, vector3.y, vector3.z ]);
				vertices.addAll([ vector4.x, vector4.y, vector4.z ]);

				normal1.setFrom( point1 );
				normal1.applyQuaternion( quaternion );
				normal1.normalize();

				normal2.setFrom( point2 );
				normal2.applyQuaternion( quaternion );
				normal2.normalize();

				normal3.setFrom( point2 );
				normal3.applyQuaternion( prevQuaternion );
				normal3.normalize();

				normal4.setFrom( point1 );
				normal4.applyQuaternion( prevQuaternion );
				normal4.normalize();

				normals.addAll([ normal1.x, normal1.y, normal1.z ]);
				normals.addAll([ normal2.x, normal2.y, normal2.z ]);
				normals.addAll([ normal4.x, normal4.y, normal4.z ]);

				normals.addAll([ normal2.x, normal2.y, normal2.z ]);
				normals.addAll([ normal3.x, normal3.y, normal3.z ]);
				normals.addAll([ normal4.x, normal4.y, normal4.z ]);

				colors.addAll([ color[ 0 ], color[ 1 ], color[ 2 ] ]);
				colors.addAll([ color[ 0 ], color[ 1 ], color[ 2 ] ]);
				colors.addAll([ color[ 0 ], color[ 1 ], color[ 2 ] ]);

				colors.addAll([ color[ 0 ], color[ 1 ], color[ 2 ] ]);
				colors.addAll([ color[ 0 ], color[ 1 ], color[ 2 ] ]);
				colors.addAll([ color[ 0 ], color[ 1 ], color[ 2 ] ]);
			}
		}

		final offset = Vector3();

		for (int i = 1; i <= divisions; i ++ ) {
			point.setFrom( curve.getPointAt( i / divisions ) );
			up.setValues( 0, 1, 0 );

			forward.sub2( point, prevPoint ).normalize();
			right.cross2( up, forward ).normalize();
			up.cross2( forward, right );

			final angle = math.atan2( forward.x, forward.z );
			quaternion.setFromAxisAngle( up, angle );

			if ( i % 2 == 0 ) {
				drawShape( step, color2 );
			}

			extrudeShape( tube1, offset.setValues( 0, - 0.125, 0 ), color2 );
			extrudeShape( tube2, offset.setValues( 0.2, 0, 0 ), color1 );
			extrudeShape( tube2, offset.setValues( - 0.2, 0, 0 ), color1 );

			prevPoint.setFrom( point );
			prevQuaternion.setFrom( quaternion );

		}

		// console.log( vertices.length );

		this.setAttributeFromString( 'position', Float32BufferAttribute( Float32Array.fromList( vertices ), 3 ) );
		this.setAttributeFromString( 'normal', Float32BufferAttribute( Float32Array.fromList( normals ), 3 ) );
		this.setAttributeFromString( 'color', Float32BufferAttribute( Float32Array.fromList( colors ), 3 ) );
	}
}

class RollerCoasterLiftersGeometry extends BufferGeometry {
	RollerCoasterLiftersGeometry(RollerCoasterCurve curve, int divisions ):super() {
		final List<double> vertices = [];
		final List<double> normals = [];

		final quaternion = Quaternion();

		final up = Vector3( 0, 1, 0 );

		final point = Vector3();
		final tangent = Vector3();

		// shapes

		final tube1 = [
			Vector3( 0, 0.05, - 0.05 ),
			Vector3( 0, 0.05, 0.05 ),
			Vector3( 0, - 0.05, 0 )
		];

		final tube2 = [
			Vector3( - 0.05, 0, 0.05 ),
			Vector3( - 0.05, 0, - 0.05 ),
			Vector3( 0.05, 0, 0 )
		];

		final tube3 = [
			Vector3( 0.05, 0, - 0.05 ),
			Vector3( 0.05, 0, 0.05 ),
			Vector3( - 0.05, 0, 0 )
		];

		final vector1 = Vector3();
		final vector2 = Vector3();
		final vector3 = Vector3();
		final vector4 = Vector3();

		final normal1 = Vector3();
		final normal2 = Vector3();
		final normal3 = Vector3();
		final normal4 = Vector3();

		void extrudeShape( shape, Vector3 fromPoint, Vector3 toPoint ) {

			for (int j = 0, jl = shape.length; j < jl; j ++ ) {

				final point1 = shape[ j ];
				final point2 = shape[ ( j + 1 ) % jl ];

				vector1.setFrom( point1 );
				vector1.applyQuaternion( quaternion );
				vector1.add( fromPoint );

				vector2.setFrom( point2 );
				vector2.applyQuaternion( quaternion );
				vector2.add( fromPoint );

				vector3.setFrom( point2 );
				vector3.applyQuaternion( quaternion );
				vector3.add( toPoint );

				vector4.setFrom( point1 );
				vector4.applyQuaternion( quaternion );
				vector4.add( toPoint );

				vertices.addAll([ vector1.x, vector1.y, vector1.z ]);
				vertices.addAll([ vector2.x, vector2.y, vector2.z ]);
				vertices.addAll([ vector4.x, vector4.y, vector4.z ]);

				vertices.addAll([ vector2.x, vector2.y, vector2.z ]);
				vertices.addAll([ vector3.x, vector3.y, vector3.z ]);
				vertices.addAll([ vector4.x, vector4.y, vector4.z ]);

				//

				normal1.setFrom( point1 );
				normal1.applyQuaternion( quaternion );
				normal1.normalize();

				normal2.setFrom( point2 );
				normal2.applyQuaternion( quaternion );
				normal2.normalize();

				normal3.setFrom( point2 );
				normal3.applyQuaternion( quaternion );
				normal3.normalize();

				normal4.setFrom( point1 );
				normal4.applyQuaternion( quaternion );
				normal4.normalize();

				normals.addAll([ normal1.x, normal1.y, normal1.z ]);
				normals.addAll([ normal2.x, normal2.y, normal2.z ]);
				normals.addAll([ normal4.x, normal4.y, normal4.z ]);

				normals.addAll([ normal2.x, normal2.y, normal2.z ]);
				normals.addAll([ normal3.x, normal3.y, normal3.z ]);
				normals.addAll([ normal4.x, normal4.y, normal4.z ]);
			}
		}

		final fromPoint = Vector3();
		final toPoint = Vector3();

		for (int i = 1; i <= divisions; i ++ ) {

			point.setFrom( curve.getPointAt( i / divisions ) );
			tangent.setFrom( curve.getTangentAt( i / divisions ) );

			final angle = math.atan2( tangent.x, tangent.z );
			quaternion.setFromAxisAngle( up, angle );

			//

			if ( point.y > 10 ) {

				fromPoint.setValues( - 0.75, - 0.35, 0 );
				fromPoint.applyQuaternion( quaternion );
				fromPoint.add( point );

				toPoint.setValues( 0.75, - 0.35, 0 );
				toPoint.applyQuaternion( quaternion );
				toPoint.add( point );

				extrudeShape( tube1, fromPoint, toPoint );

				fromPoint.setValues( - 0.7, - 0.3, 0 );
				fromPoint.applyQuaternion( quaternion );
				fromPoint.add( point );

				toPoint.setValues( - 0.7, - point.y, 0 );
				toPoint.applyQuaternion( quaternion );
				toPoint.add( point );

				extrudeShape( tube2, fromPoint, toPoint );

				fromPoint.setValues( 0.7, - 0.3, 0 );
				fromPoint.applyQuaternion( quaternion );
				fromPoint.add( point );

				toPoint.setValues( 0.7, - point.y, 0 );
				toPoint.applyQuaternion( quaternion );
				toPoint.add( point );

				extrudeShape( tube3, fromPoint, toPoint );
			} 
      else {
				fromPoint.setValues( 0, - 0.2, 0 );
				fromPoint.applyQuaternion( quaternion );
				fromPoint.add( point );

				toPoint.setValues( 0, - point.y, 0 );
				toPoint.applyQuaternion( quaternion );
				toPoint.add( point );

				extrudeShape( tube3, fromPoint, toPoint );
			}
		}

		this.setAttributeFromString( 'position', Float32BufferAttribute( Float32Array.fromList( vertices ), 3 ) );
		this.setAttributeFromString( 'normal', Float32BufferAttribute( Float32Array.fromList( normals ), 3 ) );
	}
}

class RollerCoasterShadowGeometry extends BufferGeometry {
	RollerCoasterShadowGeometry(RollerCoasterCurve curve, int divisions ):super() {
		final List<double> vertices = [];

		final up = Vector3( 0, 1, 0 );
		final forward = Vector3();

		final quaternion = Quaternion();
		final prevQuaternion = Quaternion();
		prevQuaternion.setFromAxisAngle( up, math.pi / 2 );

		final point = Vector3();

		final prevPoint = Vector3();
		prevPoint.setFrom( curve.getPointAt( 0 ) );
		prevPoint.y = 0;

		final vector1 = Vector3();
		final vector2 = Vector3();
		final vector3 = Vector3();
		final vector4 = Vector3();

		for (int i = 1; i <= divisions; i ++ ) {

			point.setFrom( curve.getPointAt( i / divisions ) );
			point.y = 0;

			forward.sub2( point, prevPoint );

			final angle = math.atan2( forward.x, forward.z );

			quaternion.setFromAxisAngle( up, angle );

			vector1.setValues( - 0.3, 0, 0 );
			vector1.applyQuaternion( quaternion );
			vector1.add( point );

			vector2.setValues( 0.3, 0, 0 );
			vector2.applyQuaternion( quaternion );
			vector2.add( point );

			vector3.setValues( 0.3, 0, 0 );
			vector3.applyQuaternion( prevQuaternion );
			vector3.add( prevPoint );

			vector4.setValues( - 0.3, 0, 0 );
			vector4.applyQuaternion( prevQuaternion );
			vector4.add( prevPoint );

			vertices.addAll([ vector1.x, vector1.y, vector1.z ]);
			vertices.addAll([ vector2.x, vector2.y, vector2.z ]);
			vertices.addAll([ vector4.x, vector4.y, vector4.z ]);

			vertices.addAll([ vector2.x, vector2.y, vector2.z ]);
			vertices.addAll([ vector3.x, vector3.y, vector3.z ]);
			vertices.addAll([ vector4.x, vector4.y, vector4.z ]);

			prevPoint.setFrom( point );
			prevQuaternion.setFrom( quaternion );
		}

		this.setAttributeFromString( 'position', Float32BufferAttribute( Float32Array.fromList( vertices ), 3 ) );
	}
}

class SkyGeometry extends BufferGeometry {

	SkyGeometry():super(){
		final List<double> vertices = [];

		for (int i = 0; i < 100; i ++ ) {

			final x = math.Random().nextDouble() * 800 - 400;
			final y = math.Random().nextDouble() * 50 + 50;
			final z = math.Random().nextDouble() * 800 - 400;

			final size = math.Random().nextDouble() * 40 + 20;

			vertices.addAll([ x - size, y, z - size ]);
			vertices.addAll([ x + size, y, z - size ]);
			vertices.addAll([ x - size, y, z + size ]);

			vertices.addAll([ x + size, y, z - size ]);
			vertices.addAll([ x + size, y, z + size ]);
			vertices.addAll([ x - size, y, z + size ]);
		}

		this.setAttributeFromString( 'position', Float32BufferAttribute( Float32Array.fromList( vertices ), 3 ) );
	}
}

class TreesGeometry extends BufferGeometry {
	TreesGeometry(Mesh landscape ):super() {
		final List<double> vertices = [];
		final List<double> colors = [];

		final raycaster = Raycaster();
		raycaster.ray.direction.setValues( 0, - 1, 0 );

		final _color = Color();

		for (int i = 0; i < 2000; i ++ ) {

			final x = math.Random().nextDouble() * 500 - 250;
			final z = math.Random().nextDouble() * 500 - 250;

			raycaster.ray.origin.setValues( x, 50, z );

			final intersections = raycaster.intersectObject( landscape, false );

			if ( intersections.length == 0 ) continue;

			final y = intersections[ 0 ].point!.y;

			final height = math.Random().nextDouble() * 5 + 0.5;

			double angle = math.Random().nextDouble() * math.pi * 2;

			vertices.addAll([ x + math.sin( angle ), y, z + math.cos( angle ) ]);
			vertices.addAll([ x, y + height, z ]);
			vertices.addAll([ x + math.sin( angle + math.pi ), y, z + math.cos( angle + math.pi ) ]);

			angle += math.pi / 2;

			vertices.addAll([ x + math.sin( angle ), y, z + math.cos( angle ) ]);
			vertices.addAll([ x, y + height, z ]);
			vertices.addAll([ x + math.sin( angle + math.pi ), y, z + math.cos( angle + math.pi ) ]);

			final random = math.Random().nextDouble() * 0.1;

			for (int j = 0; j < 6; j ++ ) {
				_color.setRGB( 0.2 + random, 0.4 + random, 0, ColorSpace.srgb );
				colors.addAll([ _color.red, _color.green, _color.blue ]);
			}
		}

		this.setAttributeFromString( 'position', Float32BufferAttribute( Float32Array.fromList( vertices ), 3 ) );
		this.setAttributeFromString( 'color', Float32BufferAttribute( Float32Array.fromList( colors ), 3 ) );

	}

}