import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

final _cb = Vector3.zero();
final _ab = Vector3.zero();

class SimplifyModifier {
	BufferGeometry modify(BufferGeometry bufferGeometry, int count) {
		BufferGeometry geometry = bufferGeometry.clone();

		// currently morphAttributes are not supported
		geometry.morphAttributes.remove('position');
		geometry.morphAttributes.remove('normal');
		final attributes = geometry.attributes;

		// this modifier can only process indexed and non-indexed geomtries with at least a position attribute

		for ( final name in attributes.keys) {
			if ( name != 'position' && name != 'uv' && name != 'normal' && name != 'tangent' && name != 'color' ) geometry.deleteAttribute( name );
		}

		geometry = BufferGeometryUtils.mergeVertices( geometry );

		//
		// put data of original geometry in different data structures
		//

		final List<Vertex> vertices = [];
		final faces = [];

		// add vertices

		final positionAttribute = geometry.getAttributeFromString( 'position' );
		final uvAttribute = geometry.getAttributeFromString( 'uv' );
		final normalAttribute = geometry.getAttributeFromString( 'normal' );
		final tangentAttribute = geometry.getAttributeFromString( 'tangent' );
		final colorAttribute = geometry.getAttributeFromString( 'color' );

		Vector4? t;
		Vector3? v2;
		Vector3? nor;
		Color? col;

		for (int i = 0; i < positionAttribute.count; i ++ ) {

			final v = Vector3.zero().fromBuffer( positionAttribute, i );
			if ( uvAttribute ) {
				v2 = Vector3.zero().fromBuffer( uvAttribute, i );
			}

			if ( normalAttribute ) {
				nor = Vector3.zero().fromBuffer( normalAttribute, i );
			}

			if ( tangentAttribute ) {
				t = Vector4.zero().fromBuffer( tangentAttribute, i );
			}

			if ( colorAttribute ) {
				col = Color().fromNativeArray( colorAttribute, i );

			}

			final vertex = Vertex(v, v2, nor, t, col );
			vertices.add( vertex );
		}

		// add faces

		BufferAttribute<NativeArray<num>>? index = geometry.getIndex();

		if ( index != null ) {
			for (int i = 0; i < index.count; i += 3 ) {
				final a = index.getX( i )!.toInt();
				final b = index.getX( i + 1 )!.toInt();
				final c = index.getX( i + 2 )!.toInt();

				final triangle = Triangle( vertices[ a ], vertices[ b ], vertices[ c ], a, b, c );
				faces.add( triangle );
			}
		} 
    else {
			for (int i = 0; i < positionAttribute.count; i += 3 ) {
				final a = i;
				final b = i + 1;
				final c = i + 2;

				final triangle = Triangle( vertices[ a ], vertices[ b ], vertices[ c ], a, b, c );
				faces.add( triangle );
			}
		}

		// compute all edge collapse costs

		for (int i = 0, il = vertices.length; i < il; i ++ ) {
			computeEdgeCostAtVertex( vertices[ i ] );
		}

		Vertex? nextVertex;

		int z = count;

		while (z != 0) {
			nextVertex = minimumCostEdge( vertices );

			if (nextVertex != null) {
				console.info( 'SimplifyModifier: No next vertex' );
				break;
			}

			collapse( vertices, faces, nextVertex, nextVertex?.collapseNeighbor );
      z--;
		}

		//

		final simplifiedGeometry = BufferGeometry();
		final List<double> position = [];
		final List<double> uv = [];
		final List<double> normal = [];
		final List<double> tangent = [];
		final List<double> color = [];
		final List<int> indx = [];

		//

		for (int i = 0; i < vertices.length; i ++ ) {
			final vertex = vertices[ i ];

			position.addAll([ vertex.position.x, vertex.position.y, vertex.position.z ]);
			if ( vertex.uv != null) {
				uv.addAll([ vertex.uv!.x, vertex.uv!.y ]);
			}

			if ( vertex.normal != null) {
				normal.addAll([ vertex.normal!.x, vertex.normal!.y, vertex.normal!.z ]);
			}

			if ( vertex.tangent != null) {
				tangent.addAll([ vertex.tangent!.x, vertex.tangent!.y, vertex.tangent!.z, vertex.tangent!.w ]);
			}

			if ( vertex.color != null) {
				color.addAll( [vertex.color!.red, vertex.color!.green, vertex.color!.blue] );
			}

			// cache final index to GREATLY speed up faces refinalruction
			vertex.id = i;
		}

		//

		for (int i = 0; i < faces.length; i ++ ) {
			final face = faces[ i ];
			indx.addAll([ face.v1.id, face.v2.id, face.v3.id ]);
		}

		simplifiedGeometry.setAttributeFromString( 'position', Float32BufferAttribute.fromList( position, 3 ) );
		if ( uv.isNotEmpty) simplifiedGeometry.setAttributeFromString( 'uv', Float32BufferAttribute.fromList( uv, 2 ) );
		if ( normal.isNotEmpty ) simplifiedGeometry.setAttributeFromString( 'normal', Float32BufferAttribute.fromList( normal, 3 ) );
		if ( tangent.isNotEmpty ) simplifiedGeometry.setAttributeFromString( 'tangent', Float32BufferAttribute.fromList( tangent, 4 ) );
		if ( color.isNotEmpty ) simplifiedGeometry.setAttributeFromString( 'color', Float32BufferAttribute.fromList( color, 3 ) );

		simplifiedGeometry.setIndex( indx );

		return simplifiedGeometry;
	}
}

void addIfUnique(List array, object ) {
	if (!array.contains( object )) array.add( object );
}

void removeFromArray(List array, object ) {
	final k = array.indexOf( object );
	if ( k > - 1 ) array.removeAt(k);
}

double computeEdgeCollapseCost(Vertex u, Vertex v ) {
	// if we collapse edge uv by moving u to v then how
	// much different will the model change, i.e. the "error".

	final edgelength = v.position.distanceTo( u.position );
	double curvature = 0;
	final sideFaces = [];

	// find the "sides" triangles that are on the edge uv
	for (int i = 0, il = u.faces.length; i < il; i ++ ) {
		final face = u.faces[ i ];
		if ( face.hasVertex( v ) ) {
			sideFaces.add( face );
		}
	}

	// use the triangle facing most away from the sides
	// to determine our curvature term
	for (int i = 0, il = u.faces.length; i < il; i ++ ) {
		double minCurvature = 1;
		final face = u.faces[ i ];

		for (int j = 0; j < sideFaces.length; j ++ ) {
			final sideFace = sideFaces[ j ];
			// use dot product of face normals.
			final double dotProd = face.normal.dot( sideFace.normal );
			minCurvature = math.min( minCurvature, ( 1.001 - dotProd ) / 2 );
		}

		curvature = math.max( curvature, minCurvature );
	}

	// crude approach in attempt to preserve borders
	// though it seems not to be totally correct
	const borders = 0;

	if ( sideFaces.length < 2 ) {
		// we add some arbitrary cost for borders,
		// borders += 10;
		curvature = 1;
	}

	final amt = edgelength * curvature + borders;

	return amt;
}

void computeEdgeCostAtVertex(Vertex v ) {
	// compute the edge collapse cost for all edges that start
	// from vertex v.  Since we are only interested in reducing
	// the object by selecting the min cost edge at each step, we
	// only cache the cost of the least cost edge at this vertex
	// (in member variable collapse) as well as the value of the
	// cost (in member variable collapseCost).

	if ( v.neighbors.isEmpty ) {
		// collapse if no neighbors.
		v.collapseNeighbor = null;
		v.collapseCost = - 0.01;
		return;
	}

	v.collapseCost = 100000;
	v.collapseNeighbor = null;

	// search all neighboring edges for "least cost" edge
	for (int i = 0; i < v.neighbors.length; i ++ ) {

		final collapseCost = computeEdgeCollapseCost( v, v.neighbors[ i ] );

		if (v.collapseNeighbor == null) {

			v.collapseNeighbor = v.neighbors[ i ];
			v.collapseCost = collapseCost;
			v.minCost = collapseCost;
			v.totalCost = 0;
			v.costCount = 0;

		}

		v.costCount ++;
		v.totalCost += collapseCost;

		if ( collapseCost < v.minCost ) {
			v.collapseNeighbor = v.neighbors[ i ];
			v.minCost = collapseCost;
		}
	}

	// we average the cost of collapsing at this vertex
	v.collapseCost = v.totalCost / v.costCount;
	// v.collapseCost = v.minCost;
}

void removeVertex(Vertex? v, vertices ) {
	assert(v?.faces != null && v!.faces.isEmpty );

	while ( v!.neighbors.isNotEmpty ) {
		final n = v.neighbors.removeLast();
		removeFromArray( n.neighbors, v );
	}

	removeFromArray( vertices, v );
}

void removeFace(Triangle f, faces ) {
	removeFromArray( faces, f );
	if ( f.v1 != null) removeFromArray( f.v1!.faces, f );
	if ( f.v2 != null) removeFromArray( f.v2!.faces, f );
	if ( f.v3 != null) removeFromArray( f.v3!.faces, f );

	final vs = [ f.v1, f.v2, f.v3 ];

	for (int i = 0; i < 3; i ++ ) {

		final v1 = vs[ i ];
		final v2 = vs[ ( i + 1 ) % 3 ];

		if (v1 == null || v2 == null) continue;

		v1.removeIfNonNeighbor( v2 );
		v2.removeIfNonNeighbor( v1 );

	}

}

void collapse( vertices, faces, Vertex? u, Vertex? v ) {
	// Collapse the edge uv by moving vertex u onto v

	if (v == null) {
		// u is a vertex all by itself so just delete it..
		removeVertex( u, vertices );
		return;
	}

	if ( v.uv != null) {
		u?.uv?.setFrom( v.uv! );
	}

	if ( v.normal != null) {
		v.normal!.add( u!.normal! ).normalize();
	}

	if ( v.tangent != null) {
		v.tangent!.add( u!.tangent! ).normalize();
	}

	final tmpVertices = [];

	for (int i = 0; i < (u?.neighbors.length ?? 0); i ++ ) {
		tmpVertices.add( u!.neighbors[ i ] );
	}

	// delete triangles on edge uv:
	for (int i = (u?.faces.length ?? 0) - 1; i >= 0; i -- ) {
		if ( u!.faces[ i ] && u.faces[ i ].hasVertex( v ) ) {
			removeFace( u.faces[ i ], faces );
		}
	}

	// update remaining triangles to have v instead of u
	for (int i = (u?.faces.length ?? 0) - 1; i >= 0; i -- ) {
		u!.faces[ i ].replaceVertex( u, v );
	}


	removeVertex( u, vertices );

	// recompute the edge collapse costs in neighborhood
	for (int i = 0; i < tmpVertices.length; i ++ ) {
		computeEdgeCostAtVertex( tmpVertices[ i ] );
	}
}

Vertex? minimumCostEdge(List<Vertex> vertices ) {
	Vertex least = vertices[0];

	for (int i = 0; i < vertices.length; i ++ ) {
		if ( vertices[ i ].collapseCost < least.collapseCost ) {
			least = vertices[ i ];
		}
	}

	return least;
}

// we use a triangle class to represent structure of face slightly differently

class Triangle {
  final normal = Vector3.zero();
  Vertex? v1;
  Vertex? v2;
  Vertex? v3;

  int a;
  int b;
  int c;

	Triangle( this.v1, this.v2, this.v3, this.a, this.b, this.c ) {
		computeNormal();

		v1?.faces.add( this );
		v1?.addUniqueNeighbor( v2 );
		v1?.addUniqueNeighbor( v3 );

		v2?.faces.add( this );
		v2?.addUniqueNeighbor( v1 );
		v2?.addUniqueNeighbor( v3 );


		v3?.faces.add( this );
		v3?.addUniqueNeighbor( v1 );
		v3?.addUniqueNeighbor( v2 );
	}

	void computeNormal() {
		final vA = v1?.position;
		final vB = v2?.position;
		final vC = v3?.position;

		_cb.sub2( vC!, vB! );
		_ab.sub2( vA!, vB );
		_cb.cross( _ab ).normalize();

		normal.setFrom( _cb );
	}

	bool hasVertex(Vertex v ) {
		return v == v1 || v == v2 || v == v3;
	}

	void replaceVertex(Vertex oldv, Vertex newv ) {
		if ( oldv == v1 ){ 
      v1 = newv;
    }
		else if ( oldv == v2 ){ 
      v2 = newv;
    }
		else if ( oldv == v3 ){ 
      v3 = newv;
    }

		removeFromArray( oldv.faces, this );
		newv.faces.add( this );


		oldv.removeIfNonNeighbor(v1 );
		v1?.removeIfNonNeighbor( oldv );

		oldv.removeIfNonNeighbor(v2 );
		v2?.removeIfNonNeighbor( oldv );

		oldv.removeIfNonNeighbor( v3 );
	  v3?.removeIfNonNeighbor( oldv );

		v1?.addUniqueNeighbor( v2 );
		v1?.addUniqueNeighbor( v3 );

		v2?.addUniqueNeighbor( v1 );
		v2?.addUniqueNeighbor( v3 );

		v3?.addUniqueNeighbor( v1 );
		v3?.addUniqueNeighbor( v2 );

		computeNormal();
	}
}

class Vertex {
  Color? color;
  Vector3 position;
  Vector3? normal;
  Vector4? tangent;
  Vector3? uv;

  int id = -1;
  double collapseCost = 0;
  List faces = [];
  List<Vertex> neighbors = [];
  Vertex? collapseNeighbor;

  double minCost = 0;
  double totalCost = 0;
  int costCount = 0;

	Vertex( this.position, this.uv, this.normal, this.tangent, this.color );

	void addUniqueNeighbor(Vertex? vertex ) {
		addIfUnique(neighbors, vertex );
	}

	void removeIfNonNeighbor( n ) {
		final neighbors = this.neighbors;
		final faces = this.faces;

		final offset = neighbors.indexOf( n );

		if ( offset == - 1 ) return;

		for (int i = 0; i < faces.length; i ++ ) {
			if (faces[ i ].hasVertex( n ) ) return;
		}

		neighbors.removeAt(offset);
	}
}
