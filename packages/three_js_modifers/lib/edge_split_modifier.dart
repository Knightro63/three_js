import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import './buffergeometry_utils.dart';
import 'dart:math' as math;

final _A = Vector3.zero();
final _B = Vector3.zero();
final _C = Vector3.zero();

class EdgeSplitModifier {

	BufferGeometry modify(BufferGeometry geometry, cutOffAngle, [bool tryKeepNormals = true ]) {
		bool hadNormals = false;
		List<double>? oldNormals;

		if ( geometry.attributes['normal'] != null) {
			hadNormals = true;

			geometry = geometry.clone();

			if ( tryKeepNormals == true && geometry.index != null ) {
				oldNormals = geometry.attributes['normal'].array;
			}

			geometry.deleteAttributeFromString( 'normal' );
		}

		if ( geometry.index == null ) {
			geometry = BufferGeometryUtils.mergeVertices( geometry );
		}

		final NativeArray<int> indexes = geometry.index!.array as NativeArray<int>;
		final positions = geometry.getAttributeFromString( 'position' ).array;

		late Float32Array normals;
		late List pointToIndexMap;

		final splitIndexes = [];
		void computeNormals() {
			normals = Float32Array( indexes.length * 3 );

			for (int i = 0; i < indexes.length; i += 3 ) {
				num index = indexes[ i ];

				_A.setValues(
					positions[ 3 * index ],
					positions[ 3 * index + 1 ],
					positions[ 3 * index + 2 ] );

				index = indexes[ i + 1 ];
				_B.setValues(
					positions[ 3 * index ],
					positions[ 3 * index + 1 ],
					positions[ 3 * index + 2 ] );

				index = indexes[ i + 2 ];
				_C.setValues(
					positions[ 3 * index ],
					positions[ 3 * index + 1 ],
					positions[ 3 * index + 2 ] );

				_C.sub( _B );
				_A.sub( _B );

				final normal = _C.cross( _A ).normalize();

				for (int j = 0; j < 3; j ++ ) {
					normals[ 3 * ( i + j ) ] = normal.x;
					normals[ 3 * ( i + j ) + 1 ] = normal.y;
					normals[ 3 * ( i + j ) + 2 ] = normal.z;
				}
			}
		}


		void mapPositionsToIndexes() {
			pointToIndexMap = List.filled( positions.length ~/ 3, null);

			for (int i = 0; i < indexes.length; i ++ ) {
				final index = indexes[ i ];

				if ( pointToIndexMap[ index ] == null ) {
					pointToIndexMap[ index ] = [];
				}

				pointToIndexMap[index].add( i );
			}
		}


		Map<String, List<dynamic>> edgeSplitToGroups(List<int> indexes, double cutOff, int firstIndex ) {
			_A.setValues( normals[ 3 * firstIndex ], normals[ 3 * firstIndex + 1 ], normals[ 3 * firstIndex + 2 ] ).normalize();

			final result = {
				'splitGroup': [],
				'currentGroup': [ firstIndex ]
			};

			for ( final j in indexes ) {
				if ( j != firstIndex ) {
					_B.setValues( normals[ 3 * j ], normals[ 3 * j + 1 ], normals[ 3 * j + 2 ] ).normalize();

					if ( _B.dot( _A ) < cutOff ) {
						result['splitGroup']!.add( j );
					} else {
						result['currentGroup']!.add( j );
					}
				}
			}

			return result;
		}

		void edgeSplit( indexes, cutOff, [original]) {
			if ( indexes.length == 0 ) return;

			final List<Map<String,List>> groupResults = [];

			for ( final index in indexes ) {
				groupResults.add( edgeSplitToGroups( indexes, cutOff, index ) );
			}

			Map<String,List> result = groupResults[ 0 ];

			for ( final groupResult in groupResults ) {
				if ( groupResult['currentGroup']!.length > result['currentGroup']!.length ) {
					result = groupResult;
				}
			}


			if ( original != null ) {
				splitIndexes.add( {
					'original': original,
					'indexes': result['currentGroup']
				} );
			}

			if ( result['splitGroup']!.isNotEmpty ) {
				edgeSplit( result['splitGroup'], cutOff, original || result['currentGroup']![ 0 ] );
			}
		}

		computeNormals();
		mapPositionsToIndexes();

		for ( final vertexIndexes in pointToIndexMap ) {
			edgeSplit( vertexIndexes, math.cos( cutOffAngle ) - 0.001 );
		}

		final newAttributes = {};
		for ( final name in geometry.attributes.keys) {
			final oldAttribute = geometry.attributes[ name ];
			final newArray = oldAttribute.array.constructor( ( indexes.length + splitIndexes.length ) * oldAttribute.itemSize );
			newArray.set( oldAttribute.array );
			newAttributes[name] = Float32BufferAttribute( newArray, oldAttribute.itemSize, oldAttribute.normalized );
		}

		final newIndexes = Uint32Array( indexes.length );
		newIndexes.set( indexes.toDartList() );

		for (int i = 0; i < splitIndexes.length; i ++ ) {

			final split = splitIndexes[ i ];
			final index = indexes[ split.original ];

			for ( final attribute in newAttributes.values) {
				for (int j = 0; j < attribute.itemSize; j ++ ) {
					attribute.array[ ( indexes.length + i ) * attribute.itemSize + j ] =
						attribute.array[ index * attribute.itemSize + j ];
				}
			}

			for ( final j in split.indexes ) {
				newIndexes[ j ] = indexes.length + i;
			}
		}

		geometry = BufferGeometry();
		geometry.setIndex( Uint32BufferAttribute( newIndexes, 1 ) );

		for ( final name in newAttributes.keys) {
			geometry.setAttribute( name, newAttributes[ name ] );
		}

		if ( hadNormals ) {
			geometry.computeVertexNormals();

			if ( oldNormals != null ) {
				final changedNormals = List.filled(oldNormals.length ~/ 3, false);

				for ( final splitData in splitIndexes ){
					changedNormals[ splitData.original ] = true;
        }

				for (int i = 0; i < changedNormals.length; i ++ ) {
					if ( changedNormals[ i ] == false ) {
						for (int j = 0; j < 3; j ++ ){
							geometry.attributes['normal'].array[ 3 * i + j ] = oldNormals[ 3 * i + j ];
            }
					}
				}
			}
		}

		return geometry;
	}
}
