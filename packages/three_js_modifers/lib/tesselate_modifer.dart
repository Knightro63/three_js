import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class TessellateModifier {
  double maxEdgeLength;
  int maxIterations;

	TessellateModifier([ this.maxEdgeLength = 0.1, this.maxIterations = 6 ]);

	BufferGeometry modify(BufferGeometry geometry ) {
		if ( geometry.index != null ) {
			geometry = geometry.toNonIndexed();
		}

		final maxIterations = this.maxIterations;
		final maxEdgeLengthSquared = maxEdgeLength * maxEdgeLength;

		final va = Vector3.zero();
		final vb = Vector3.zero();
		final vc = Vector3.zero();
		final vm = Vector3.zero();
		final vs = [ va, vb, vc, vm ];

		final na = Vector3.zero();
		final nb = Vector3.zero();
		final nc = Vector3.zero();
		final nm = Vector3.zero();
		final ns = [ na, nb, nc, nm ];

		final ca = Color();
		final cb = Color();
		final cc = Color();
		final cm = Color();
		final cs = [ ca, cb, cc, cm ];

		final ua = Vector2.zero();
		final ub = Vector2.zero();
		final uc = Vector2.zero();
		final um = Vector2.zero();
		final us = [ ua, ub, uc, um ];

		final u2a = Vector2.zero();
		final u2b = Vector2.zero();
		final u2c = Vector2.zero();
		final u2m = Vector2.zero();
		final u2s = [ u2a, u2b, u2c, u2m ];

		final attributes = geometry.attributes;
		final hasNormals = attributes['normal'] != null;
		final hasColors = attributes['color'] != null;
		final hasUVs = attributes['uv'] != null;
		final hasUV1s = attributes['uv1'] != null;

		List<double> positions = attributes['position'].array;
		List<double> normals = hasNormals ? attributes['normal'].array : null;
		List<double> colors = hasColors ? attributes['color'].array : null;
		List<double> uvs = hasUVs ? attributes['uv'].array : null;
		List<double> uv1s = hasUV1s ? attributes['uv1'].array : null;

		List<double> positions2 = positions;
		List<double> normals2 = normals;
		List<double> colors2 = colors;
		List<double> uvs2 = uvs;
		List<double> uv1s2 = uv1s;

		int iteration = 0;
		bool tessellating = true;

		void addTriangle( a, b, c ) {
			final v1 = vs[ a ];
			final v2 = vs[ b ];
			final v3 = vs[ c ];

			positions2.addAll([ v1.x, v1.y, v1.z ]);
			positions2.addAll([ v2.x, v2.y, v2.z ]);
			positions2.addAll([ v3.x, v3.y, v3.z ]);

			if ( hasNormals ) {
				final n1 = ns[ a ];
				final n2 = ns[ b ];
				final n3 = ns[ c ];

				normals2.addAll([ n1.x, n1.y, n1.z ]);
				normals2.addAll([ n2.x, n2.y, n2.z ]);
				normals2.addAll([ n3.x, n3.y, n3.z ]);
			}

			if ( hasColors ) {
				final c1 = cs[ a ];
				final c2 = cs[ b ];
				final c3 = cs[ c ];

				colors2.addAll([ c1.red, c1.green, c1.blue ]);
				colors2.addAll([ c2.red, c2.green, c2.blue ]);
				colors2.addAll([ c3.red, c3.green, c3.blue ]);
			}

			if ( hasUVs ) {
				final u1 = us[ a ];
				final u2 = us[ b ];
				final u3 = us[ c ];

				uvs2.addAll([ u1.x, u1.y ]);
				uvs2.addAll([ u2.x, u2.y ]);
				uvs2.addAll([ u3.x, u3.y ]);
			}

			if ( hasUV1s ) {
				final u21 = u2s[ a ];
				final u22 = u2s[ b ];
				final u23 = u2s[ c ];

				uv1s2.addAll([ u21.x, u21.y ]);
				uv1s2.addAll([ u22.x, u22.y ]);
				uv1s2.addAll([ u23.x, u23.y ]);
			}
		}

		while ( tessellating && iteration < maxIterations ) {
			iteration ++;
			tessellating = false;

			positions = positions2;
			positions2 = [];

			if ( hasNormals ) {
				normals = normals2;
				normals2 = [];
			}

			if ( hasColors ) {
				colors = colors2;
				colors2 = [];
			}

			if ( hasUVs ) {
				uvs = uvs2;
				uvs2 = [];
			}

			if ( hasUV1s ) {
				uv1s = uv1s2;
				uv1s2 = [];
			}

			for (int i = 0, i2 = 0, il = positions.length; i < il; i += 9, i2 += 6 ) {
				va.copyFromArray( positions, i + 0 );
				vb.copyFromArray( positions, i + 3 );
				vc.copyFromArray( positions, i + 6 );

				if ( hasNormals ) {
					na.copyFromArray( normals, i + 0 );
					nb.copyFromArray( normals, i + 3 );
					nc.copyFromArray( normals, i + 6 );
				}

				if ( hasColors ) {
					ca.copyFromArray( colors, i + 0 );
					cb.copyFromArray( colors, i + 3 );
					cc.copyFromArray( colors, i + 6 );
				}

				if ( hasUVs ) {
					ua.copyFromArray( uvs, i2 + 0 );
					ub.copyFromArray( uvs, i2 + 2 );
					uc.copyFromArray( uvs, i2 + 4 );
				}

				if ( hasUV1s ) {
					u2a.copyFromArray( uv1s, i2 + 0 );
					u2b.copyFromArray( uv1s, i2 + 2 );
					u2c.copyFromArray( uv1s, i2 + 4 );
				}

				final dab = va.distanceToSquared( vb );
				final dbc = vb.distanceToSquared( vc );
				final dac = va.distanceToSquared( vc );

				if ( dab > maxEdgeLengthSquared || dbc > maxEdgeLengthSquared || dac > maxEdgeLengthSquared ) {
					tessellating = true;

					if ( dab >= dbc && dab >= dac ) {
						vm.lerpVectors( va, vb, 0.5 );
						if ( hasNormals ) nm.lerpVectors( na, nb, 0.5 );
						if ( hasColors ) cm.lerpColors( ca, cb, 0.5 );
						if ( hasUVs ) um.lerpVectors( ua, ub, 0.5 );
						if ( hasUV1s ) u2m.lerpVectors( u2a, u2b, 0.5 );

						addTriangle( 0, 3, 2 );
						addTriangle( 3, 1, 2 );
					} else if ( dbc >= dab && dbc >= dac ) {
						vm.lerpVectors( vb, vc, 0.5 );
						if ( hasNormals ) nm.lerpVectors( nb, nc, 0.5 );
						if ( hasColors ) cm.lerpColors( cb, cc, 0.5 );
						if ( hasUVs ) um.lerpVectors( ub, uc, 0.5 );
						if ( hasUV1s ) u2m.lerpVectors( u2b, u2c, 0.5 );

						addTriangle( 0, 1, 3 );
						addTriangle( 3, 2, 0 );
					} else {
						vm.lerpVectors( va, vc, 0.5 );
						if ( hasNormals ) nm.lerpVectors( na, nc, 0.5 );
						if ( hasColors ) cm.lerpColors( ca, cc, 0.5 );
						if ( hasUVs ) um.lerpVectors( ua, uc, 0.5 );
						if ( hasUV1s ) u2m.lerpVectors( u2a, u2c, 0.5 );

						addTriangle( 0, 1, 3 );
						addTriangle( 3, 1, 2 );
					}
				} else {
					addTriangle( 0, 1, 2 );
				}
			}
		}

		final geometry2 = BufferGeometry();
		geometry2.setAttributeFromString( 'position', Float32BufferAttribute.fromList( positions2, 3 ) );

		if ( hasNormals ) {
			geometry2.setAttributeFromString( 'normal', Float32BufferAttribute.fromList( normals2, 3 ) );
		}
		if ( hasColors ) {
			geometry2.setAttributeFromString( 'color', Float32BufferAttribute.fromList( colors2, 3 ) );
		}
		if ( hasUVs ) {
			geometry2.setAttributeFromString( 'uv', Float32BufferAttribute.fromList( uvs2, 2 ) );
		}
		if ( hasUV1s ) {
			geometry2.setAttributeFromString( 'uv1', Float32BufferAttribute.fromList( uv1s2, 2 ) );
		}

		return geometry2;
	}
}


