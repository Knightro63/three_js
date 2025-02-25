import 'line_material.dart';
import 'line_segments2.dart';
import 'line_geometry.dart';
import 'dart:math' as math;

class Line2 extends LineSegments2 {
	Line2.create(LineGeometry geometry, LineMaterial material):super.create(geometry, material){
		type = 'Line2';
	}

	factory Line2([LineGeometry? geometry, LineMaterial? material]){
		geometry ??= LineGeometry();
    material ??= LineMaterial.fromMap( { 'color': (math.Random().nextDouble() * 0xffffff).toInt() });
    return Line2.create(geometry, material);
	}
}
