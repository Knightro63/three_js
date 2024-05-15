import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class Brush extends Mesh {
  final _previousMatrix = Matrix4.zero();
	Brush(super.geometry, super.material):super();

	void markUpdated() {
		_previousMatrix.setFrom(matrix);
	}

	bool isDirty() {
		final el1 = matrix.storage;
		final el2 = _previousMatrix.storage;
		for ( int i = 0; i < 16; i ++ ) {
			if ( el1[ i ] != el2[ i ] ) {
				return true;
			}
		}
		return false;
	}

	void prepareGeometry() {
		// generate shared array buffers
		final geometry = this.geometry;
		final attributes = geometry!.attributes;
		final useSharedArrayBuffer = areSharedArrayBuffersSupported();
		if ( useSharedArrayBuffer ) {
			for ( final key in attributes.keys ) {
				final attribute = attributes[ key ];
				if ( attribute.isInterleavedBufferAttribute ) {
					throw( 'Brush: InterleavedBufferAttributes are not supported.' );
				}
				attribute.array = convertToSharedArrayBuffer( attribute.array );
			}
		}

		// generate bounds tree
		if(!geometry.boundsTree){
			ensureIndex( geometry, { useSharedArrayBuffer } );
			geometry.boundsTree = MeshBVH( geometry, { maxLeafTris: 3, indirect: true, useSharedArrayBuffer } );
		}

		// generate half edges
		if(!geometry.halfEdges){
			geometry.halfEdges = HalfEdgeMap( geometry );
		}

		// save group indices for materials
		if ( ! geometry.groupIndices ) {
			final triCount = getTriCount( geometry );
			final array = Uint16Array( triCount );
			final groups = geometry.groups;
			for (int i = 0, l = groups.length; i < l; i ++ ) {
				const { start, count } = groups[ i ];
				for (int g = start / 3, lg = ( start + count ) / 3; g < lg; g ++ ) {
					array[ g ] = i;
				}
			}

			geometry.groupIndices = array;
		}
	}

	void disposeCacheData() {
		final geometry = this.geometry;
		geometry.halfEdges = null;
		geometry.boundsTree = null;
		geometry.groupIndices = null;
	}
}