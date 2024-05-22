import 'package:three_js_math/three_js_math.dart';

final _vec2 = Vector2.zero();
final _vec3 = Vector3.zero();
final _vec4 = Vector4.zero();
final _hashes = [ '', '', '' ];

class HalfEdgeMap {

	HalfEdgeMap(geometry) {
		// result data
		this.data = null;
		this.disjointConnections = null;
		this.unmatchedDisjointEdges = null;
		this.unmatchedEdges = - 1;
		this.matchedEdges = - 1;

		// options
		this.useDrawRange = true;
		this.useAllAttributes = false;
		this.matchDisjointEdges = false;
		this.degenerateEpsilon = 1e-8;

		if ( geometry ) {
			updateFrom( geometry );
		}
	}

	int getSiblingTriangleIndex( triIndex, edgeIndex ) {
		final otherIndex = this.data[ triIndex * 3 + edgeIndex ];
		return otherIndex == - 1 ? - 1 : ~ ~ ( otherIndex / 3 );
	}

	int getSiblingEdgeIndex( triIndex, edgeIndex ) {
		final otherIndex = this.data[ triIndex * 3 + edgeIndex ];
		return otherIndex == - 1 ? - 1 : ( otherIndex % 3 );
	}

	List<int> getDisjointSiblingTriangleIndices( triIndex, edgeIndex ) {
		final index = triIndex * 3 + edgeIndex;
		final arr = this.disjointConnections.get( index );
		return arr ? arr.map( i => ~ ~ ( i / 3 ) ) : [];
	}

	getDisjointSiblingEdgeIndices( triIndex, edgeIndex ) {
		final index = triIndex * 3 + edgeIndex;
		final arr = this.disjointConnections.get( index );
		return arr ? arr.map( i => i % 3 ) : [];
	}

	isFullyConnected() {
		return this.unmatchedEdges == 0;
	}

	updateFrom( geometry ) {

		const { useAllAttributes, useDrawRange, matchDisjointEdges, degenerateEpsilon } = this;
		const hashFunction = useAllAttributes ? hashAllAttributes : hashPositionAttribute;

		// runs on the assumption that there is a 1 : 1 match of edges
		const map = Map();

		// attributes
		const { attributes } = geometry;
		const attrKeys = useAllAttributes ? Object.keys( attributes ) : null;
		const indexAttr = geometry.index;
		const posAttr = attributes.position;

		// get the potential number of triangles
		let triCount = getTriCount( geometry );
		const maxTriCount = triCount;

		// get the real number of triangles from the based on the draw range
		let offset = 0;
		if ( useDrawRange ) {

			offset = geometry.drawRange.start;
			if ( geometry.drawRange.count !== Infinity ) {

				triCount = ~ ~ ( geometry.drawRange.count / 3 );

			}

		}

		// initialize the connectivity buffer - 1 means no connectivity
		let data = this.data;
		if ( ! data || data.length < 3 * maxTriCount ) {

			data = Int32Array( 3 * maxTriCount );

		}

		data.fill(-1);

		// iterate over all triangles
		let matchedEdges = 0;
		let unmatchedSet = Set();
		for (int i = offset, l = triCount * 3 + offset; i < l; i += 3 ) {
			final i3 = i;

			for (int e = 0; e < 3; e ++ ) {
				int i0 = i3 + e;
				if ( indexAttr ) {
					i0 = indexAttr.getX( i0 );
				}

				_hashes[ e ] = hashFunction( i0 );
			}

			for (int e = 0; e < 3; e ++ ) {
				final nextE = ( e + 1 ) % 3;
				final vh0 = _hashes[ e ];
				final vh1 = _hashes[ nextE ];

				final reverseHash = '${ vh1 }_$vh0';
				if ( map.containsKey( reverseHash ) ) {

					// create a reference between the two triangles and clear the hash
					final index = i3 + e;
					final otherIndex = map.get( reverseHash );
					data[ index ] = otherIndex;
					data[ otherIndex ] = index;
					map.remove( reverseHash );
					matchedEdges += 2;
					unmatchedSet.remove( otherIndex );

				} else {

					// save the triangle and triangle edge index captured in one value
					// triIndex = ~ ~ ( i0 / 3 );
					// edgeIndex = i0 % 3;
					final hash = '${vh0}_$vh1';
					final index = i3 + e;
					map.set( hash, index );
					unmatchedSet.add( index );

				}

			}

		}

		if ( matchDisjointEdges ) {

			const {
				fragmentMap,
				disjointConnectivityMap,
			} = computeDisjointEdges( geometry, unmatchedSet, degenerateEpsilon );

			unmatchedSet.clear();
			fragmentMap.forEach( ( { forward, reverse } ) => {
				forward.forEach( ( { index } ) => unmatchedSet.add( index ) );
				reverse.forEach( ( { index } ) => unmatchedSet.add( index ) );
			} );

			this.unmatchedDisjointEdges = fragmentMap;
			this.disjointConnections = disjointConnectivityMap;
			matchedEdges = triCount * 3 - unmatchedSet.size;
		}

		this.matchedEdges = matchedEdges;
		this.unmatchedEdges = unmatchedSet.size;
		this.data = data;

		function hashPositionAttribute(int i ) {
			_vec3.fromBuffer( posAttr, i );
			return hashVertex3( _vec3 );
		}

		String hashAllAttributes(int i ) {
			String result = '';
			for (int k = 0, l = attrKeys.length; k < l; k ++ ) {

				final attr = attributes[ attrKeys[ k ] ];
				let str;
				switch ( attr.itemSize ) {
					case 1:
						str = hashNumber( attr.getX( i ) );
						break;
					case 2:
						str = hashVertex2( _vec2.fromBuffer( attr, i ) );
						break;
					case 3:
						str = hashVertex3( _vec3.fromBuffer( attr, i ) );
						break;
					case 4:
						str = hashVertex4( _vec4.fromBuffer( attr, i ) );
						break;
				}

				if ( result != '' ) {
					result += '|';
				}

				result += str;
			}

			return result;
		}
	}
}