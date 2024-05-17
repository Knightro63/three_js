import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_curves/three_js_curves.dart';
import 'package:three_js_math/three_js_math.dart';

class TubeGeometry extends BufferGeometry {
  var tangents;
  var normals;
  var binormals;

	TubeGeometry([
    Curve? path, 
    int tubularSegments = 64, 
    double radius = 1, 
    int radialSegments = 8, 
    bool closed = false 
  ]):super(){
    path ??= QuadraticBezierCurve3( Vector3( - 1, - 1, 0 ), Vector3( - 1, 1, 0 ), Vector3( 1, 1, 0 ) );
		type = 'TubeGeometry';

		parameters = {
			'path': path,
			'tubularSegments': tubularSegments,
			'radius': radius,
			'radialSegments': radialSegments,
			'closed': closed
		};

		final frames = path.computeFrenetFrames( tubularSegments, closed );

		// expose internals

		tangents = frames.tangents;
		this.normals = frames.normals;
		binormals = frames.binormals;

		// helper variables

		final vertex = Vector3.zero();
		final normal = Vector3.zero();
		final uv = Vector2.zero();
		Vector3 P = Vector3.zero();

		// buffer

		final List<double> vertices = [];
		final List<double> normals = [];
		final List<double> uvs = [];
		final List<int> indices = [];

		// create buffer data



		// functions

		void generateSegment( i ) {
			// we use getPointAt to sample evenly distributed points from the given path
			P = path!.getPointAt( i / tubularSegments, P ) as Vector3;

			// retrieve corresponding normal and binormal

			final N = frames.normals![ i ];
			final B = frames.binormals![ i ];

			// generate normals and vertices for the current segment

			for (int j = 0; j <= radialSegments; j ++ ) {
				final v = j / radialSegments * math.pi * 2;
				final sin = math.sin( v );
				final cos = - math.cos( v );

				// normal

				normal.x = ( cos * N.x + sin * B.x );
				normal.y = ( cos * N.y + sin * B.y );
				normal.z = ( cos * N.z + sin * B.z );
				normal.normalize();

				normals.addAll([ normal.x, normal.y, normal.z ]);

				// vertex

				vertex.x = P.x + radius * normal.x;
				vertex.y = P.y + radius * normal.y;
				vertex.z = P.z + radius * normal.z;
				vertices.addAll([ vertex.x, vertex.y, vertex.z ]);

			}
		}

		void generateIndices() {
			for ( int j = 1; j <= tubularSegments; j ++ ) {
				for ( int i = 1; i <= radialSegments; i ++ ) {
					final a = ( radialSegments + 1 ) * ( j - 1 ) + ( i - 1 );
					final b = ( radialSegments + 1 ) * j + ( i - 1 );
					final c = ( radialSegments + 1 ) * j + i;
					final d = ( radialSegments + 1 ) * ( j - 1 ) + i;

					// faces

					indices.addAll([ a, b, d ]);
					indices.addAll([ b, c, d ]);
				}
			}
		}

		void generateUVs() {
			for ( int i = 0; i <= tubularSegments; i ++ ) {
				for ( int j = 0; j <= radialSegments; j ++ ) {
					uv.x = i / tubularSegments;
					uv.y = j / radialSegments;
					uvs.addAll([ uv.x, uv.y ]);
				}
			}
		}

		void generateBufferData() {
			for ( int i = 0; i < tubularSegments; i ++ ) {
				generateSegment( i );
			}

			// if the geometry is not closed, generate the last row of vertices and normals
			// at the regular position on the given path
			//
			// if the geometry is closed, duplicate the first row of vertices and normals (uvs will differ)

			generateSegment( ( closed == false ) ? tubularSegments : 0 );

			// uvs are generated in a separate function.
			// this makes it easy compute correct values for closed geometries
			generateUVs();

			// finally create faces
			generateIndices();
		}

  	generateBufferData();

		// build geometry

		setIndex( indices );
		setAttributeFromString( 'position', Float32BufferAttribute.fromTypedData(Float32List.fromList(vertices), 3 ) );
		setAttributeFromString( 'normal', Float32BufferAttribute.fromTypedData(Float32List.fromList(normals), 3 ) );
		setAttributeFromString( 'uv', Float32BufferAttribute.fromTypedData(Float32List.fromList(uvs), 2 ) );
	}

  @override
	TubeGeometry copy(BufferGeometry source ) {
    source as TubeGeometry;
		super.copy( source );
		parameters = source.parameters;
		return this;
	}

  @override
	Map<String, dynamic> toJson({Object3dMeta? meta}) {
		final data = super.toJson();
		data['path'] = parameters?['path'].toJSON();
		return data;
	}

	static fromJson(Map<String, dynamic> data) {
    throw('Not Implimented');
		// This only works for built-in curves (e.g. CatmullRomCurve3).
		// User defined curves or instances of CurvePath will not be deserialized.
		// return TubeGeometry(
		// 	curves(data['path']['type'])?.fromJson( data['path'] ),
		// 	data['tubularSegments'],
		// 	data['radius'],
		// 	data['radialSegments'],
		// 	data['closed']
		// );
	}
}
