import "package:three_js_core/three_js_core.dart";
import "package:three_js_math/three_js_math.dart";

/**
 * You can use this geometry to create a decal mesh, that serves different kinds of purposes.
 * e.g. adding unique details to models, performing dynamic visual environmental changes or covering seams.
 *
 * Constructor parameter:
 *
 * mesh — Any mesh object
 * position — Position of the decal projector
 * orientation — Orientation of the decal projector
 * size — Size of the decal projector
 *
 * reference: http://blog.wolfire.com/2009/06/how-to-project-decals/
 *
 */

class DecalGeometry extends BufferGeometry {

	DecalGeometry(Mesh mesh, Vector3 position, Euler orientation, Vector3 size ):super(){

		final List<double> vertices = [];
		final List<double> normals = [];
		final List<double> uvs = [];

    final plane = Vector3();

		// this matrix represents the transformation of the decal projector

		final projectorMatrix = Matrix4.identity();
		projectorMatrix.makeRotationFromEuler( orientation );
		projectorMatrix.scaleByVector( position );

		final projectorMatrixInverse = Matrix4.identity();
		projectorMatrixInverse.setFrom( projectorMatrix ).invert();



    void pushDecalVertex(List<DecalVertex> decalVertices,Vector3 vertex,Vector3 normal ) {
      // transform the vertex to world space, then to projector space
      vertex.applyMatrix4( mesh.matrixWorld );
      vertex.applyMatrix4( projectorMatrixInverse );

      normal.transformDirection( mesh.matrixWorld );
      decalVertices.add( DecalVertex( vertex.clone(), normal.clone() ) );
    }

    DecalVertex clip(DecalVertex v0, DecalVertex v1, p, s ) {
      final d0 = v0.position.dot( p ) - s;
      final d1 = v1.position.dot( p ) - s;

      final s0 = d0 / ( d0 - d1 );

      final v = DecalVertex(
        Vector3(
          v0.position.x + s0 * ( v1.position.x - v0.position.x ),
          v0.position.y + s0 * ( v1.position.y - v0.position.y ),
          v0.position.z + s0 * ( v1.position.z - v0.position.z )
        ),
        Vector3(
          v0.normal.x + s0 * ( v1.normal.x - v0.normal.x ),
          v0.normal.y + s0 * ( v1.normal.y - v0.normal.y ),
          v0.normal.z + s0 * ( v1.normal.z - v0.normal.z )
        )
      );

      // need to clip more values (texture coordinates)? do it this way:
      // intersectpoint.value = a.value + s * ( b.value - a.value );

      return v;
    }

    List<DecalVertex> clipGeometry(List<DecalVertex> inVertices, plane ) {
      final List<DecalVertex> outVertices = [];
      final s = 0.5 * size.dot( plane ).abs();

      // a single iteration clips one face,
      // which consists of three consecutive 'DecalVertex' objects

      for (int i = 0; i < inVertices.length; i += 3 ) {
        int total = 0;
        late DecalVertex nV1;
        late DecalVertex nV2;
        late DecalVertex nV3;
        late DecalVertex nV4;

        final d1 = inVertices[ i + 0 ].position.dot( plane ) - s;
        final d2 = inVertices[ i + 1 ].position.dot( plane ) - s;
        final d3 = inVertices[ i + 2 ].position.dot( plane ) - s;

        final v1Out = d1 > 0;
        final v2Out = d2 > 0;
        final v3Out = d3 > 0;

        // calculate, how many vertices of the face lie outside of the clipping plane

        total = ( v1Out ? 1 : 0 ) + ( v2Out ? 1 : 0 ) + ( v3Out ? 1 : 0 );

        switch ( total ) {
          case 0: {
            // the entire face lies inside of the plane, no clipping needed
            outVertices.add( inVertices[ i ] );
            outVertices.add( inVertices[ i + 1 ] );
            outVertices.add( inVertices[ i + 2 ] );
            break;
          }
          case 1: {
            // one vertex lies outside of the plane, perform clipping
            if ( v1Out ) {
              nV1 = inVertices[ i + 1 ];
              nV2 = inVertices[ i + 2 ];
              nV3 = clip( inVertices[ i ], nV1, plane, s );
              nV4 = clip( inVertices[ i ], nV2, plane, s );
            }

            if ( v2Out ) {
              nV1 = inVertices[ i ];
              nV2 = inVertices[ i + 2 ];
              nV3 = clip( inVertices[ i + 1 ], nV1, plane, s );
              nV4 = clip( inVertices[ i + 1 ], nV2, plane, s );

              outVertices.add( nV3 );
              outVertices.add( nV2.clone() );
              outVertices.add( nV1.clone() );

              outVertices.add( nV2.clone() );
              outVertices.add( nV3.clone() );
              outVertices.add( nV4 );
              break;
            }

            if ( v3Out ) {
              nV1 = inVertices[ i ];
              nV2 = inVertices[ i + 1 ];
              nV3 = clip( inVertices[ i + 2 ], nV1, plane, s );
              nV4 = clip( inVertices[ i + 2 ], nV2, plane, s );
            }

            outVertices.add( nV1.clone() );
            outVertices.add( nV2.clone() );
            outVertices.add( nV3 );

            outVertices.add( nV4 );
            outVertices.add( nV3.clone() );
            outVertices.add( nV2.clone() );

            break;
          }
          case 2: {
            // two vertices lies outside of the plane, perform clipping
            if ( ! v1Out ) {
              nV1 = inVertices[ i ].clone();
              nV2 = clip( nV1, inVertices[ i + 1 ], plane, s );
              nV3 = clip( nV1, inVertices[ i + 2 ], plane, s );
              outVertices.add( nV1 );
              outVertices.add( nV2 );
              outVertices.add( nV3 );
            }
            if ( ! v2Out ) {
              nV1 = inVertices[ i + 1 ].clone();
              nV2 = clip( nV1, inVertices[ i + 2 ], plane, s );
              nV3 = clip( nV1, inVertices[ i ], plane, s );
              outVertices.add( nV1 );
              outVertices.add( nV2 );
              outVertices.add( nV3 );
            }
            if ( ! v3Out ) {
              nV1 = inVertices[ i + 2 ].clone();
              nV2 = clip( nV1, inVertices[ i ], plane, s );
              nV3 = clip( nV1, inVertices[ i + 1 ], plane, s );
              outVertices.add( nV1 );
              outVertices.add( nV2 );
              outVertices.add( nV3 );

            }
            break;
          }
          case 3: {
            // the entire face lies outside of the plane, so let's discard the corresponding vertices
            break;
          }
        }
      }

      return outVertices;
    }

    void generate() {
      List<DecalVertex> decalVertices = [];

      final vertex = Vector3();
      final normal = Vector3();

      // handle different geometry types

      final geometry = mesh.geometry;

      final positionAttribute = geometry?.attributes['position'];
      final normalAttribute = geometry?.attributes['normal'];

      // first, create an array of 'DecalVertex' objects
      // three consecutive 'DecalVertex' objects represent a single face
      //
      // this data structure will be later used to perform the clipping

      if ( geometry?.index != null ) {
        // indexed BufferGeometry
        final index = geometry!.index;

        for (int i = 0; i < index!.count; i ++ ) {
          vertex.fromBuffer( positionAttribute, index.getX( i )!.toInt() );
          normal.fromBuffer( normalAttribute, index.getX( i )!.toInt() );
          pushDecalVertex( decalVertices, vertex, normal );
        }
      } 
      else {
        // non-indexed BufferGeometry
        for (int i = 0; i < positionAttribute.count; i ++ ) {
          vertex.fromBuffer( positionAttribute, i );
          normal.fromBuffer( normalAttribute, i );
          pushDecalVertex( decalVertices, vertex, normal );
        }
      }

      // second, clip the geometry so that it doesn't extend out from the projector

      decalVertices = clipGeometry( decalVertices, plane.setValues( 1, 0, 0 ) );
      decalVertices = clipGeometry( decalVertices, plane.setValues( - 1, 0, 0 ) );
      decalVertices = clipGeometry( decalVertices, plane.setValues( 0, 1, 0 ) );
      decalVertices = clipGeometry( decalVertices, plane.setValues( 0, - 1, 0 ) );
      decalVertices = clipGeometry( decalVertices, plane.setValues( 0, 0, 1 ) );
      decalVertices = clipGeometry( decalVertices, plane.setValues( 0, 0, - 1 ) );

      // third, generate final vertices, normals and uvs

      for (int i = 0; i < decalVertices.length; i ++ ) {
        final decalVertex = decalVertices[ i ];

        // create texture coordinates (we are still in projector space)
        uvs.addAll([
          0.5 + ( decalVertex.position.x / size.x ),
          0.5 + ( decalVertex.position.y / size.y )
        ]);

        // transform the vertex back to world space

        decalVertex.position.applyMatrix4( projectorMatrix );

        // now create vertex and normal buffer data

        vertices.addAll( [decalVertex.position.x, decalVertex.position.y, decalVertex.position.z] );
        normals.addAll( [decalVertex.normal.x, decalVertex.normal.y, decalVertex.normal.z] );
      }
    }
		// generate buffers
		generate();

		// build geometry
		setAttributeFromString( 'position', Float32BufferAttribute.fromList( vertices, 3 ) );
		setAttributeFromString( 'normal', Float32BufferAttribute.fromList( normals, 3 ) );
		setAttributeFromString( 'uv', Float32BufferAttribute.fromList( uvs, 2 ) );
  }
}
// helper

class DecalVertex {
  Vector3 position;
  Vector3 normal;
	DecalVertex(this.position, this.normal);

	DecalVertex clone() {
		return DecalVertex(position.clone(), normal.clone() );
	}
}
