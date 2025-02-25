import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

final _box = BoundingBox();
final _vector = Vector3();

class LineSegmentsGeometry extends InstancedBufferGeometry {

	LineSegmentsGeometry():super(){
		this.type = 'LineSegmentsGeometry';

		const List<double> positions = [ - 1, 2, 0, 1, 2, 0, - 1, 1, 0, 1, 1, 0, - 1, 0, 0, 1, 0, 0, - 1, - 1, 0, 1, - 1, 0 ];
		const List<double> uvs = [ - 1, 2, 1, 2, - 1, 1, 1, 1, - 1, - 1, 1, - 1, - 1, - 2, 1, - 2 ];
		const index = [ 0, 2, 1, 2, 3, 1, 2, 4, 3, 4, 5, 3, 4, 6, 5, 6, 7, 5 ];

		this.setIndex( index );
		this.setAttributeFromString( 'position', new Float32BufferAttribute.fromList( positions, 3 ) );
		this.setAttributeFromString( 'uv', new Float32BufferAttribute.fromList( uvs, 2 ) );
	}

	LineSegmentsGeometry applyMatrix4(Matrix4 matrix ) {
		final start = this.attributes['instanceStart'] as InterleavedBufferAttribute?;
		final end = this.attributes['instanceEnd'] as InterleavedBufferAttribute?;

		if ( start != null ) {
			start.applyMatrix4( matrix );
			end?.applyMatrix4( matrix );
			start.needsUpdate = true;
		}

		if ( this.boundingBox != null ) {
			this.computeBoundingBox();
		}

		if ( this.boundingSphere != null ) {
			this.computeBoundingSphere();
		}

		return this;
	}

	LineSegmentsGeometry setPositions(Float32Array lineSegments ) {
		final instanceBuffer = new InstancedInterleavedBuffer( lineSegments, 6, 1 ); // xyz, xyz

		this.setAttributeFromString( 'instanceStart', new InterleavedBufferAttribute( instanceBuffer, 3, 0 ) ); // xyz
		this.setAttributeFromString( 'instanceEnd', new InterleavedBufferAttribute( instanceBuffer, 3, 3 ) ); // xyz

		this.computeBoundingBox();
		this.computeBoundingSphere();

		return this;
	}

	LineSegmentsGeometry setColors(Float32Array colors ) {
		final instanceColorBuffer = new InstancedInterleavedBuffer( colors, 6, 1 ); // rgb, rgb

		this.setAttributeFromString( 'instanceColorStart', new InterleavedBufferAttribute( instanceColorBuffer, 3, 0 ) ); // rgb
		this.setAttributeFromString( 'instanceColorEnd', new InterleavedBufferAttribute( instanceColorBuffer, 3, 3 ) ); // rgb

		return this;
	}

	LineSegmentsGeometry fromWireframeGeometry(BufferGeometry geometry ) {
		this.setPositions( geometry.attributes['position'].array );
		return this;
	}

	LineSegmentsGeometry fromEdgesGeometry(BufferGeometry geometry ) {
		this.setPositions( geometry.attributes['position'].array );
		return this;
	}

	LineSegmentsGeometry fromMesh( Mesh mesh ) {
		this.fromWireframeGeometry( new WireframeGeometry( mesh.geometry! ) );
		// set colors, maybe
		return this;
	}

	LineSegmentsGeometry fromLineSegments(LineSegments lineSegments ) {
		final geometry = lineSegments.geometry;
		this.setPositions( geometry!.attributes['position'].array ); // assumes non-indexed
		// set colors, maybe
		return this;
	}

	void computeBoundingBox() {
		if ( this.boundingBox == null ) {
			this.boundingBox = BoundingBox();
		}

		final start = this.attributes['instanceStart'];
		final end = this.attributes['instanceEnd'];

		if ( start != null && end != null ) {
			this.boundingBox?.setFromBuffer( start );
			_box.setFromBuffer( end );
      this.boundingBox?.min.min( _box.min );
      this.boundingBox?.max.max( _box.max );
		}
	}

	void computeBoundingSphere() {
		if ( this.boundingSphere == null ) {
			this.boundingSphere = new BoundingSphere();
		}

		if ( this.boundingBox == null ) {
			this.computeBoundingBox();
		}

		final start = this.attributes['instanceStart'];
		final end = this.attributes['instanceEnd'];

		if ( start != null && end != null ) {
			final center = this.boundingSphere!.center;

			this.boundingBox?.getCenter( center );

			double maxRadiusSq = 0;

			for (int i = 0, il = start.count; i < il; i ++ ) {
				_vector.fromBuffer( start, i );
				maxRadiusSq = math.max( maxRadiusSq, center.distanceToSquared( _vector ) );

				_vector.fromBuffer( end, i );
				maxRadiusSq = math.max( maxRadiusSq, center.distanceToSquared( _vector ) );
			}

			this.boundingSphere?.radius = math.sqrt( maxRadiusSq );

			if (this.boundingSphere!.radius.isNaN) {
				console.error( 'THREE.LineSegmentsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values.');
			}
		}
	}

	toJSON() {

		// todo

	}

	LineSegmentsGeometry applyMatrix(Matrix4 matrix ) {
		console.warning( 'THREE.LineSegmentsGeometry: applyMatrix() has been renamed to applyMatrix4().' );
		return this.applyMatrix4( matrix );
	}
}


