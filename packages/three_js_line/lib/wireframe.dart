import 'line_material.dart';
import 'line_segments_geometry.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

final _start = Vector3();
final _end = Vector3();

class Wireframe extends Mesh {
  Wireframe.create(super.geometry, super.material){
    this.type = 'Wireframe';
  }

	factory Wireframe([BufferGeometry? geometry, Material? material]) {
		geometry ??= LineSegmentsGeometry();
    material ??= LineMaterial.fromMap( { 'color': (math.Random().nextDouble() * 0xffffff).toInt() } );

		return Wireframe.create(geometry, material);
	}

	// for backwards-compatibility, but could be a method of LineSegmentsGeometry...

	Wireframe computeLineDistances() {
		final geometry = this.geometry!;

		final instanceStart = geometry.attributes['instanceStart'];
		final instanceEnd = geometry.attributes['instanceEnd'];
		final lineDistances = Float32Array( (2 * instanceStart.count).toInt() );

		for (int i = 0, j = 0, l = instanceStart.count; i < l; i ++, j += 2 ) {
			_start.fromBuffer( instanceStart, i );
			_end.fromBuffer( instanceEnd, i );

			lineDistances[ j ] = ( j == 0 ) ? 0 : lineDistances[ j - 1 ];
			lineDistances[ j + 1 ] = lineDistances[ j ] + _start.distanceTo( _end );
		}

		final instanceDistanceBuffer = InstancedInterleavedBuffer( lineDistances, 2, 1 ); // d0, d1

		geometry.setAttributeFromString( 'instanceDistanceStart', InterleavedBufferAttribute( instanceDistanceBuffer, 1, 0 ) ); // d0
		geometry.setAttributeFromString( 'instanceDistanceEnd', InterleavedBufferAttribute( instanceDistanceBuffer, 1, 1 ) ); // d1

		return this;
	}
}
