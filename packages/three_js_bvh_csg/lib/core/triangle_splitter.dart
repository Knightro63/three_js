import "package:three_js_core/three_js_core.dart";
import "package:three_js_math/three_js_math.dart";

// NOTE: these epsilons likely should all be the same since they're used to measure the
// distance from a point to a plane which needs to be done consistently
const EPSILON = 1e-10;
const COPLANAR_EPSILON = 1e-10;
const PARALLEL_EPSILON = 1e-10;
final _edge = Line3();
final _foundEdge = Line3();
final _vec = Vector3();
final _triangleNormal = Vector3.zero();
final _planeNormal = Vector3.zero();
final _plane = Plane();
final _splittingTriangle = ExtendedTriangle();

// A pool of triangles to avoid unnecessary triangle creation
class TrianglePool {
  final List<Triangle> _pool = [];
  int _index = 0;

	TrianglePool();

	Triangle getTriangle() {
		if (_index >= _pool.length ) {
			_pool.add( Triangle() );
		}
		return _pool[_index++];
	}

	void clear() {
		_index = 0;
	}

	void reset() {
		_pool.length = 0;
		_index = 0;
	}
}

// Utility class for splitting triangles
class TriangleSplitter {
  final trianglePool = TrianglePool();
  final List<Triangle> triangles = [];
  final normal = Vector3();
  bool coplanarTriangleUsed = false;

	TriangleSplitter();

	// initialize the class with a triangle
	void initializeList(List<Triangle> tri) {
		reset();

		final triangles = this.triangles;
    final trianglePool = this.trianglePool;
    final normal = this.normal;

    for (int i = 0, l = tri.length; i < l; i ++ ) {
      final t = tri[ i ];
      if ( i == 0) {
        t.getNormal( normal );
      } 
      else if(( 1.0 - t.getNormal( _vec ).dot( normal ) ).abs() > EPSILON ) {
        throw( 'Triangle Splitter: Cannot initialize with triangles that have different normals.' );
      }

      final poolTri = trianglePool.getTriangle();
      poolTri.copy( t );
      triangles.add( poolTri );
    }
	}
	void initialize(Triangle tri) {
		reset();

		final triangles = this.triangles;
    final trianglePool = this.trianglePool;
    final normal = this.normal;


    tri.getNormal( normal );
    final poolTri = trianglePool.getTriangle();
    poolTri.copy( tri );
    triangles.add( poolTri );
	}
	// Split the current set of triangles by passing a single triangle in. If the triangle is
	// coplanar it will attempt to split by the triangle edge planes
	void splitByTriangle(Triangle triangle ) {
    final normal = this.normal;
    final triangles = this.triangles;
		triangle.getNormal( _triangleNormal ).normalize();

		if (( 1.0 - ( _triangleNormal.dot( normal ) ).abs() ).abs() < PARALLEL_EPSILON ) {
			coplanarTriangleUsed = true;

			for (int i = 0, l = triangles.length; i < l; i ++ ) {
				final t = triangles[ i ];
				t.coplanarCount = 0;
			}

			// if the triangle is coplanar then split by the edge planes
			final arr = [ triangle.a, triangle.b, triangle.c ];
			for (int i = 0; i < 3; i ++ ) {
				final nexti = ( i + 1 ) % 3;

				final v0 = arr[ i ];
				final v1 = arr[ nexti ];

				// plane positive direction is toward triangle center
				_vec.sub2( v1, v0 ).normalize();
				_planeNormal.cross2( _triangleNormal, _vec );
				_plane.setFromNormalAndCoplanarPoint( _planeNormal, v0 );

				splitByPlane( _plane, triangle );
			}
		} else {
			// otherwise split by the triangle plane
			triangle.getPlane( _plane );
			splitByPlane( _plane, triangle );
		}
	}

	// Split the triangles by the given plan. If a triangle is provided then we ensure we
	// intersect the triangle before splitting the plane
	void splitByPlane(Plane plane, clippingTriangle ) {
    final triangles = this.triangles;
    final trianglePool = this.trianglePool;

		// init our triangle to check for intersection
		_splittingTriangle.copy( clippingTriangle );
		_splittingTriangle.needsUpdate = true;

		// try to split every triangle in the class
		for (int i = 0, l = triangles.length; i < l; i ++ ) {
			final tri = triangles[ i ];
			// skip the triangle if we don't intersect with it
			if ( ! _splittingTriangle.intersectsTriangle( tri, _edge, true ) ) {
				continue;
			}

			final a = tri.a;
      final b = tri.b;
      final c = tri.c;

			int intersects = 0;
			int vertexSplitEnd = - 1;
			bool coplanarEdge = false;
			List posSideVerts = [];
			List negSideVerts = [];

			final arr = [ a, b, c ];

			for (int t = 0; t < 3; t ++ ) {
				// get the triangle edge
				final tNext = ( t + 1 ) % 3;
				_edge.start.setFrom( arr[ t ] );
				_edge.end.setFrom( arr[ tNext ] );

				// track if the start point sits on the plane or if it's on the positive side of it
				// so we can use that information to determine whether to split later.
				final startDist = plane.distanceToPoint( _edge.start );
				final endDist = plane.distanceToPoint( _edge.end );
				if (( startDist ).abs() < COPLANAR_EPSILON && ( endDist ).abs() < COPLANAR_EPSILON ) {
					coplanarEdge = true;
					break;
				}

				if ( startDist > 0 ) {
					posSideVerts.add( t );
				} else {
					negSideVerts.add( t );
				}

				// we only don't consider this an intersection if the start points hits the plane
				if (startDist.abs() < COPLANAR_EPSILON ) {
					continue;
				}

				// double check the end point since the "intersectLine" function sometimes does not
				// return it as an intersection (see issue #28)
				// Because we ignore the start point intersection above we have to make sure we check the end
				// point intersection here.
				bool didIntersect = plane.intersectLine( _edge, _vec ) != null;
				if(!didIntersect && endDist.abs() < COPLANAR_EPSILON ) {
					_vec.setFrom( _edge.end );
					didIntersect = true;
				}

				// check if we intersect the plane (ignoring the start point so we don't double count)
				if ( didIntersect && !(_vec.distanceTo( _edge.start ) < EPSILON) ) {
					// if we intersect at the end point then we track that point as one that we
					// have to split down the middle
					if ( _vec.distanceTo( _edge.end ) < EPSILON ) {
						vertexSplitEnd = t;
					}

					// track the split edge
					if ( intersects == 0 ) {
						_foundEdge.start.setFrom( _vec );
					} else {
						_foundEdge.end.setFrom( _vec );
					}
					intersects ++;
				}
			}

			// skip splitting if:
			// - we have two points on the plane then the plane intersects the triangle exactly on an edge
			// - the plane does not intersect on 2 points
			// - the intersection edge is too small
			// - we're not along a coplanar edge
			if ( ! coplanarEdge && intersects == 2 && _foundEdge.distance() > COPLANAR_EPSILON ) {

				if ( vertexSplitEnd != - 1 ) {
					vertexSplitEnd = ( vertexSplitEnd + 1 ) % 3;
					// we're splitting along a vertex
					int otherVert1 = 0;
					if ( otherVert1 == vertexSplitEnd ) {
						otherVert1 = ( otherVert1 + 1 ) % 3;
					}

					int otherVert2 = otherVert1 + 1;
					if ( otherVert2 == vertexSplitEnd ) {
						otherVert2 = ( otherVert2 + 1 ) % 3;
					}

					final nextTri = trianglePool.getTriangle();
					nextTri.a.setFrom( arr[ otherVert2 ] );
					nextTri.b.setFrom( _foundEdge.end );
					nextTri.c.setFrom( _foundEdge.start );

					if (!isTriDegenerate( nextTri ) ) {
						triangles.add( nextTri );
					}

					tri.a.setFrom( arr[ otherVert1 ] );
					tri.b.setFrom( _foundEdge.start );
					tri.c.setFrom( _foundEdge.end );

					// finish off the adjusted triangle
					if (isTriDegenerate( tri ) ) {
						triangles.removeAt(i);
						i --;
						l --;
					}

				} else {
					// we're splitting with a quad and a triangle
					// TODO: what happens when we find that about the pos and negative
					// sides have only a single vertex?
					final singleVert = posSideVerts.length >= 2 ?
							negSideVerts[ 0 ] :
							posSideVerts[ 0 ];

					// swap the direction of the intersection edge depending on which
					// side of the plane the single vertex is on to align with the
					// correct winding order.
					if ( singleVert == 0 ) {
						Vector3 tmp = _foundEdge.start;
						_foundEdge.start = _foundEdge.end;
						_foundEdge.end = tmp;
					}

					final nextVert1 = ( singleVert + 1 ) % 3;
					final nextVert2 = ( singleVert + 2 ) % 3;

					final nextTri1 = trianglePool.getTriangle();
					final nextTri2 = trianglePool.getTriangle();

					// choose the triangle that has the larger areas (shortest split distance)
					if ( arr[ nextVert1 ].distanceToSquared( _foundEdge.start ) < arr[ nextVert2 ].distanceToSquared( _foundEdge.end ) ) {
						nextTri1.a.setFrom( arr[ nextVert1 ] );
						nextTri1.b.setFrom( _foundEdge.start );
						nextTri1.c.setFrom( _foundEdge.end );

						nextTri2.a.setFrom( arr[ nextVert1 ] );
						nextTri2.b.setFrom( arr[ nextVert2 ] );
						nextTri2.c.setFrom( _foundEdge.start );
					} else {
						nextTri1.a.setFrom( arr[ nextVert2 ] );
						nextTri1.b.setFrom( _foundEdge.start );
						nextTri1.c.setFrom( _foundEdge.end );

						nextTri2.a.setFrom( arr[ nextVert1 ] );
						nextTri2.b.setFrom( arr[ nextVert2 ] );
						nextTri2.c.setFrom( _foundEdge.end );
					}

					tri.a.setFrom( arr[ singleVert ] );
					tri.b.setFrom( _foundEdge.end );
					tri.c.setFrom( _foundEdge.start );

					// don't add degenerate triangles to the list
					if ( ! isTriDegenerate( nextTri1 ) ) {
						triangles.add( nextTri1 );
					}

					if ( ! isTriDegenerate( nextTri2 ) ) {
						triangles.add( nextTri2 );
					}

					// finish off the adjusted triangle
					if ( isTriDegenerate( tri ) ) {
						triangles.removeAt(i);
						i --;
						l --;
					}
				}
			} else if ( intersects == 3 ) {
				console.warning( 'TriangleClipper: Coplanar clip not handled' );
			}
		}
	}

	void reset() {
		triangles.length = 0;
		trianglePool.clear();
		coplanarTriangleUsed = false;
	}
}