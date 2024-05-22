import 'package:three_js_curves/three_js_curves.dart';
import 'package:three_js_geometry/lathe.dart';
import 'dart:math' as math;

import 'package:three_js_math/three_js_math.dart';

class CapsuleGeometry extends LatheGeometry {
  CapsuleGeometry.create(super.points,{double radius = 1,double length = 1,int capSegments = 4,int radialSegments = 8 }):super(segments: radialSegments){
		type = 'CapsuleGeometry';

		parameters = {
			'radius': radius,
			'length': length,
			'capSegments': capSegments,
			'radialSegments': radialSegments,
		};
  }

	factory CapsuleGeometry({double radius = 1,double length = 1,int capSegments = 4,int radialSegments = 8 }) {
		final path = Path();
		path.absarc( 0, - length / 2, radius, math.pi * 1.5, 0 );
		path.absarc( 0, length / 2, radius, 0, math.pi * 0.5 );
  
    return CapsuleGeometry.create(path.getPoints( capSegments ) as List<Vector2>, radialSegments: radialSegments);
	}

	factory CapsuleGeometry.fromJson(Map<String,dynamic> data ) {
		return CapsuleGeometry(
      radius: data['radius'], 
      length: data['length'], 
      capSegments: data['capSegments'], 
      radialSegments: data['radialSegments'] 
    );
	}
}

