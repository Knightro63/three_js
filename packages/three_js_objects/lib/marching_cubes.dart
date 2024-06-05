import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class MarchingCubes extends Mesh{
  final vlist = Float32List( 12 * 3 );
  final nlist = Float32List( 12 * 3 );
  final clist = Float32List( 12 * 3 );

  double resolution;
  double isolation = 80.0;

  late double size;
  late double size2;
  late double size3;
  late double halfsize;
  late double delta;

  late Float32Array field;
  late Float32Array normalCache;
  late Float32Array palette;
  late Float32Array positionArray;
  late Float32Array normalArray;
  late Float32Array uvArray;
  late Float32Array colorArray;

  int maxPolyCount;
  late int yd;
  late int zd;

  bool enableColors;
  bool enableUvs;

  bool isMarchingCubes = true;

	MarchingCubes(this.resolution, [Material? material, this.enableUvs = false, this.enableColors = false, this.maxPolyCount = 10000 ]):super(BufferGeometry(), material ){
    _init();
  }

  void _init() {
    geometry = BufferGeometry();
    count = 0;
    // parameters
    size = resolution;
    size2 = size * size;
    size3 = size2 * size;
    halfsize = size / 2.0;

    // deltas
    delta = 2.0 / size;
    yd = size.toInt();
    zd = size2.toInt();

    field = Float32Array(size3.toInt());
    normalCache = Float32Array(size3.toInt() * 3);
    palette = Float32Array(size3.toInt() * 3);

    final maxVertexCount = maxPolyCount * 3;

    positionArray = Float32Array(maxVertexCount * 3);
    geometry!.setAttributeFromString('position', Float32BufferAttribute(positionArray,3));

    normalArray = Float32Array( maxVertexCount * 3);
    geometry!.setAttributeFromString('normal', Float32BufferAttribute(normalArray,3));

    if(enableUvs){
      uvArray = Float32Array(maxVertexCount * 2 );
      geometry!.setAttributeFromString('uv', Float32BufferAttribute(uvArray,3));
    }

    if (enableColors){
      colorArray = Float32Array(maxVertexCount * 3 );
      geometry!.setAttributeFromString('color',Float32BufferAttribute(colorArray,3));
    }

    geometry!.boundingSphere = BoundingSphere(Vector3(), 1);
  }

  ///////////////////////
  // Polygonization
  ///////////////////////

  double lerp( a, b, t ) {
    return a + ( b - a ) * t;
  }

  void vIntX(int q, int offset, isol, x, y, z, valp1, valp2,int cOffset1,int cOffset2 ) {
    double mu = ( isol - valp1 ) / ( valp2 - valp1 );
    final nc = normalCache;

    vlist[ offset + 0 ] = x + mu * delta;
    vlist[ offset + 1 ] = y;
    vlist[ offset + 2 ] = z;

    nlist[ offset + 0 ] = lerp( nc[ q + 0 ], nc[ q + 3 ], mu );
    nlist[ offset + 1 ] = lerp( nc[ q + 1 ], nc[ q + 4 ], mu );
    nlist[ offset + 2 ] = lerp( nc[ q + 2 ], nc[ q + 5 ], mu );

    clist[ offset + 0 ] = lerp( palette[ cOffset1 * 3 + 0 ], palette[ cOffset2 * 3 + 0 ], mu );
    clist[ offset + 1 ] = lerp( palette[ cOffset1 * 3 + 1 ], palette[ cOffset2 * 3 + 1 ], mu );
    clist[ offset + 2 ] = lerp( palette[ cOffset1 * 3 + 2 ], palette[ cOffset2 * 3 + 2 ], mu );
  }

  void vIntY(int q,int offset, isol, x, y, z, valp1, valp2,int cOffset1,int cOffset2 ) {
    double mu = ( isol - valp1 ) / ( valp2 - valp1 );
    final nc = normalCache;

    vlist[ offset + 0 ] = x;
    vlist[ offset + 1 ] = y + mu * delta;
    vlist[ offset + 2 ] = z;

    int q2 = q + yd * 3;

    nlist[ offset + 0 ] = lerp( nc[ q + 0 ], nc[q2 + 0], mu );
    nlist[ offset + 1 ] = lerp( nc[ q + 1 ], nc[q2 + 1], mu );
    nlist[ offset + 2 ] = lerp( nc[ q + 2 ], nc[q2 + 2], mu );

    clist[ offset + 0 ] = lerp( palette[ cOffset1 * 3 + 0 ], palette[ cOffset2 * 3 + 0 ], mu );
    clist[ offset + 1 ] = lerp( palette[ cOffset1 * 3 + 1 ], palette[ cOffset2 * 3 + 1 ], mu );
    clist[ offset + 2 ] = lerp( palette[ cOffset1 * 3 + 2 ], palette[ cOffset2 * 3 + 2 ], mu );

  }

  void vIntZ(int q,int offset, isol, x, y, z, valp1, valp2,int cOffset1,int cOffset2 ) {
    double mu = ( isol - valp1 ) / ( valp2 - valp1 );
    final nc = normalCache;

    vlist[ offset + 0 ] = x;
    vlist[ offset + 1 ] = y;
    vlist[ offset + 2 ] = z + mu * delta;

    int q2 = q + zd * 3;

    nlist[ offset + 0 ] = lerp( nc[ q + 0 ], nc[ q2 + 0 ], mu );
    nlist[ offset + 1 ] = lerp( nc[ q + 1 ], nc[ q2 + 1 ], mu );
    nlist[ offset + 2 ] = lerp( nc[ q + 2 ], nc[ q2 + 2 ], mu );

    clist[ offset + 0 ] = lerp( palette[ cOffset1 * 3 + 0 ], palette[ cOffset2 * 3 + 0 ], mu );
    clist[ offset + 1 ] = lerp( palette[ cOffset1 * 3 + 1 ], palette[ cOffset2 * 3 + 1 ], mu );
    clist[ offset + 2 ] = lerp( palette[ cOffset1 * 3 + 2 ], palette[ cOffset2 * 3 + 2 ], mu );
  }

  void compNorm(int q ) {
    int q3 = q * 3;
    if (normalCache[ q3 ] == 0.0 ) {
      normalCache[ q3 + 0 ] = field[ q - 1 ] - field[ q + 1 ];
      normalCache[ q3 + 1 ] =
        field[ q - yd ] - field[ q + yd ];
      normalCache[ q3 + 2 ] =
        field[ q - zd ] - field[ q + zd ];
    }
  }

  // Returns total number of triangles. Fills triangles.
  // (this is where most of time is spent - it's inner work of O(n3) loop )
  int polygonize( fx, fy, fz,int q, isol ) {
    // cache indices
    final q1 = q + 1;
    final qy = q + yd;
    final qz = q + zd;
    final q1y = q1 + yd;
    final q1z = q1 + zd;
    final qyz = q + yd + zd;
    final q1yz = q1 + yd + zd;

    int cubeindex = 0;
    final field0 = field[q],
    field1 = field[ q1 ],
    field2 = field[ qy ],
    field3 = field[ q1y ],
    field4 = field[ qz ],
    field5 = field[ q1z ],
    field6 = field[ qyz ],
    field7 = field[ q1yz ];

    if ( field0 < isol ) cubeindex |= 1;
    if ( field1 < isol ) cubeindex |= 2;
    if ( field2 < isol ) cubeindex |= 8;
    if ( field3 < isol ) cubeindex |= 4;
    if ( field4 < isol ) cubeindex |= 16;
    if ( field5 < isol ) cubeindex |= 32;
    if ( field6 < isol ) cubeindex |= 128;
    if ( field7 < isol ) cubeindex |= 64;

    // if cube is entirely in/out of the surface - bail, nothing to draw

    final bits = edgeTable[ cubeindex ];
    if ( bits == 0 ) return 0;

    final d = delta,
      fx2 = fx + d,
      fy2 = fy + d,
      fz2 = fz + d;

    // top of the cube
    if(bits & 1 != 0){
      compNorm( q );
      compNorm( q1 );
      vIntX( q * 3, 0, isol, fx, fy, fz, field0, field1, q, q1 );
    }

    if(bits & 2 != 0){
      compNorm( q1 );
      compNorm( q1y );
      vIntY( q1 * 3, 3, isol, fx2, fy, fz, field1, field3, q1, q1y );
    }

    if(bits & 4 != 0){
      compNorm( qy );
      compNorm( q1y );
      vIntX( qy * 3, 6, isol, fx, fy2, fz, field2, field3, qy, q1y );
    }

    if(bits & 8 != 0){
      compNorm( q );
      compNorm( qy );
      vIntY( q * 3, 9, isol, fx, fy, fz, field0, field2, q, qy );
    }

    // bottom of the cube

    if(bits & 16 != 0){
      compNorm( qz );
      compNorm( q1z );
      vIntX( qz * 3, 12, isol, fx, fy, fz2, field4, field5, qz, q1z );
    }

    if(bits & 32 != 0){
      compNorm( q1z );
      compNorm( q1yz );
      vIntY(
        q1z * 3,
        15,
        isol,
        fx2,
        fy,
        fz2,
        field5,
        field7,
        q1z,
        q1yz
      );
    }

    if(bits & 64 != 0){
      compNorm( qyz );
      compNorm( q1yz );
      vIntX(
        qyz * 3,
        18,
        isol,
        fx,
        fy2,
        fz2,
        field6,
        field7,
        qyz,
        q1yz
      );
    }

    if(bits & 128 != 0){
      compNorm( qz );
      compNorm( qyz );
      vIntY( qz * 3, 21, isol, fx, fy, fz2, field4, field6, qz, qyz );
    }

    // vertical lines of the cube
    if(bits & 256 != 0){
      compNorm( q );
      compNorm( qz );
      vIntZ( q * 3, 24, isol, fx, fy, fz, field0, field4, q, qz );
    }

    if(bits & 512 != 0){
      compNorm( q1 );
      compNorm( q1z );
      vIntZ( q1 * 3, 27, isol, fx2, fy, fz, field1, field5, q1, q1z );
    }

    if(bits & 1024 != 0){
      compNorm( q1y );
      compNorm( q1yz );
      vIntZ(
        q1y * 3,
        30,
        isol,
        fx2,
        fy2,
        fz,
        field3,
        field7,
        q1y,
        q1yz
      );
    }

    if(bits & 2048 != 0){
      compNorm( qy );
      compNorm( qyz );
      vIntZ( qy * 3, 33, isol, fx, fy2, fz, field2, field6, qy, qyz );
    }

    cubeindex <<= 4; // re-purpose cubeindex into an offset into triTable

    int numtris = 0;
    int i = 0;

    // here is where triangles are created

    while ( triTable[ cubeindex + i ] != - 1 ) {
      int o1 = cubeindex + i;
      int o2 = o1 + 1;
      int o3 = o1 + 2;

      posnormtriv(
        vlist,
        nlist,
        clist,
        3 * triTable[ o1 ],
        3 * triTable[ o2 ],
        3 * triTable[ o3 ]
      );

      i += 3;
      numtris ++;
    }

    return numtris;
  }

  void posnormtriv( pos, norm, colors,int o1,int o2,int o3 ) {
    final c = count! * 3;

    // positions

    positionArray[ c + 0 ] = pos[ o1 ];
    positionArray[ c + 1 ] = pos[ o1 + 1 ];
    positionArray[ c + 2 ] = pos[ o1 + 2 ];

    positionArray[ c + 3 ] = pos[ o2 ];
    positionArray[ c + 4 ] = pos[ o2 + 1 ];
    positionArray[ c + 5 ] = pos[ o2 + 2 ];

    positionArray[ c + 6 ] = pos[ o3 ];
    positionArray[ c + 7 ] = pos[ o3 + 1 ];
    positionArray[ c + 8 ] = pos[ o3 + 2 ];

    // normals

    if (material?.flatShading == true){
      final nx = ( norm[ o1 + 0 ] + norm[ o2 + 0 ] + norm[ o3 + 0 ] ) / 3;
      final ny = ( norm[ o1 + 1 ] + norm[ o2 + 1 ] + norm[ o3 + 1 ] ) / 3;
      final nz = ( norm[ o1 + 2 ] + norm[ o2 + 2 ] + norm[ o3 + 2 ] ) / 3;

      normalArray[ c + 0 ] = nx;
      normalArray[ c + 1 ] = ny;
      normalArray[ c + 2 ] = nz;

      normalArray[ c + 3 ] = nx;
      normalArray[ c + 4 ] = ny;
      normalArray[ c + 5 ] = nz;

      normalArray[ c + 6 ] = nx;
      normalArray[ c + 7 ] = ny;
      normalArray[ c + 8 ] = nz;

    } 
    else {
      normalArray[ c + 0 ] = norm[ o1 + 0 ];
      normalArray[ c + 1 ] = norm[ o1 + 1 ];
      normalArray[ c + 2 ] = norm[ o1 + 2 ];

      normalArray[ c + 3 ] = norm[ o2 + 0 ];
      normalArray[ c + 4 ] = norm[ o2 + 1 ];
      normalArray[ c + 5 ] = norm[ o2 + 2 ];

      normalArray[ c + 6 ] = norm[ o3 + 0 ];
      normalArray[ c + 7 ] = norm[ o3 + 1 ];
      normalArray[ c + 8 ] = norm[ o3 + 2 ];
    }

    // uvs

    if ( enableUvs ) {
      final d = count! * 2;

      uvArray[ d + 0 ] = pos[ o1 + 0 ];
      uvArray[ d + 1 ] = pos[ o1 + 2 ];

      uvArray[ d + 2 ] = pos[ o2 + 0 ];
      uvArray[ d + 3 ] = pos[ o2 + 2 ];

      uvArray[ d + 4 ] = pos[ o3 + 0 ];
      uvArray[ d + 5 ] = pos[ o3 + 2 ];

    }

    // colors

    if (enableColors) {
      colorArray[ c + 0 ] = colors[ o1 + 0 ];
      colorArray[ c + 1 ] = colors[ o1 + 1 ];
      colorArray[ c + 2 ] = colors[ o1 + 2 ];

      colorArray[ c + 3 ] = colors[ o2 + 0 ];
      colorArray[ c + 4 ] = colors[ o2 + 1 ];
      colorArray[ c + 5 ] = colors[ o2 + 2 ];

      colorArray[ c + 6 ] = colors[ o3 + 0 ];
      colorArray[ c + 7 ] = colors[ o3 + 1 ];
      colorArray[ c + 8 ] = colors[ o3 + 2 ];
    }

    count = count!+3;
  }

  /////////////////////////////////////
  // Metaballs
  /////////////////////////////////////

  // Adds a reciprocal ball (nice and blobby) that, to be fast, fades to zero after
  // a fixed distance, determined by strength and subtract.

  void addBall(double ballx,double bally,double ballz, double strength,int subtract, [dynamic colors]) {
    final sign = strength.sign;
    strength = strength.abs();
    bool userDefineColor = colors != null;
    Color ballColor = Color( ballx, bally, ballz );

    if ( userDefineColor ) {
      try {
        ballColor = colors is Color
            ? colors
            :(colors is List<double>)
              ?Color(
                math.min(colors[0].abs().toDouble(), 1),
                math.min(colors[1].abs().toDouble(), 1),
                math.min(colors[2].abs().toDouble(), 1)
              ):Color(colors);

      } 
      catch(err){
        ballColor = Color( ballx, bally, ballz );
      }
    }

    // Let's solve the equation to find the radius:
    // 1.0 / (0.000001 + radius^2) * strength - subtract = 0
    // strength / (radius^2) = subtract
    // strength = subtract * radius^2
    // radius^2 = strength / subtract
    // radius = sqrt(strength / subtract)

    final radius = size * math.sqrt( strength / subtract );
    final zs = ballz * size;
    final ys = bally * size;
    final xs = ballx * size;

    int minZ = ( zs - radius ).floor();
    if ( minZ < 1 ) minZ = 1;
    int maxZ = ( zs + radius ).floor();
    if ( maxZ > size - 1 ) maxZ = size.toInt() - 1;
    int minY = ( ys - radius ).floor();
    if ( minY < 1 ) minY = 1;
    int maxY = ( ys + radius ).floor();
    if ( maxY > size - 1 ) maxY = size.toInt() - 1;
    int minX = ( xs - radius ).floor();
    if ( minX < 1 ) minX = 1;
    int maxX = (xs + radius).floor();
    if ( maxX > size - 1 ) maxX = size.toInt() - 1;

    // Don't polygonize in the outer layer because normals aren't
    // well-defined there.
    for (int z = minZ; z < maxZ; z ++ ) {
      double zOffset = size2 * z;
      double fz = z / size - ballz;
      double fz2 = fz * fz;

      for (int y = minY; y < maxY; y ++ ) {
        double yOffset = zOffset + size * y;
        double fy = y / size - bally;
        double fy2 = fy * fy;

        for (int x = minX; x < maxX; x ++ ) {
          double fx = x / size - ballx;
          double val = strength / ( 0.000001 + fx * fx + fy2 + fz2 ) - subtract;
          if ( val > 0.0 ) {
            field[ yOffset.toInt() + x ] += val * sign;

            // optimization
            // http://www.geisswerks.com/ryan/BLOBS/blobs.html
            final  ratio = math.sqrt( ( x - xs ) * ( x - xs ) + ( y - ys ) * ( y - ys ) + ( z - zs ) * ( z - zs ) ) / radius;
            final contrib = 1 - ratio * ratio * ratio * ( ratio * ( ratio * 6 - 15 ) + 10 );

            palette[(yOffset + x).toInt() * 3 + 0] += ballColor.red * contrib;
            palette[(yOffset + x).toInt() * 3 + 1] += ballColor.green * contrib;
            palette[(yOffset + x).toInt() * 3 + 2] += ballColor.blue * contrib;
          }
        }
      }
    }
  }

  void addPlaneX( strength, subtract ) {
    // cache attribute lookups
    final size = this.size;
    final yd = this.yd;
    final zd = this.zd;
    final field = this.field;

    double dist = size * math.sqrt( strength / subtract );

    if ( dist > size ) dist = size;

    for(int x = 0; x < dist; x ++ ) {
      double xdiv = x / size;
      double xx = xdiv * xdiv;
      double val = strength / ( 0.0001 + xx ) - subtract;
      if ( val > 0.0 ) {
        for (int y = 0; y < size; y ++ ) {
          int cxy = x + y * yd;
          for (int z = 0; z < size; z ++ ) {
            field[ zd * z + cxy ] += val;
          }
        }
      }
    }
  }

  void addPlaneY( strength, subtract ) {
    // cache attribute lookups
    final size = this.size;
    final yd = this.yd;
    final zd = this.zd;
    final field = this.field;

    double dist = size * math.sqrt( strength / subtract );
    if ( dist > size ) dist = size;

    for (int y = 0; y < dist; y ++ ) {
      double ydiv = y / size;
      double yy = ydiv * ydiv;
      double val = strength / ( 0.0001 + yy ) - subtract;
      if ( val > 0.0 ) {
        int cy = y * yd;
        for (int x = 0; x < size; x ++ ) {
          int cxy = cy + x;
          for (int z = 0; z < size; z ++ ){ 
            field[ zd * z + cxy ] += val;
          }
        }
      }
    }
  }

  void addPlaneZ( strength, subtract ) {
    // cache attribute lookups
    final size = this.size;
    final yd = this.yd;
    final zd = this.zd;
    final field = this.field;

    double dist = size * math.sqrt( strength / subtract );

    if ( dist > size ) dist = size;

    for (int z = 0; z < dist; z ++ ) {
      double zdiv = z / size;
      double zz = zdiv * zdiv;
      double val = strength / ( 0.0001 + zz ) - subtract;
      if ( val > 0.0 ) {
        int cz = zd * z;
        for (int y = 0; y < size; y ++ ) {
          int cyz = cz + y * yd;
          for (int x = 0; x < size; x ++ ){ 
            field[ cyz + x ] += val;
          }
        }
      }
    }
  }

  /////////////////////////////////////
  // Updates
  /////////////////////////////////////

  void setCell(int x,int y,int z, value){
    final index = (size2 * z + size * y + x).toInt();
    field[index] = value;
  }

  double getCell(int x,int y,int z){
    final index = (size2 * z + size * y + x).toInt();
    return field[index];
  }

  void blur([double intensity = 1]){
    final field = this.field;
    final fieldCopy = field.sublist(0);
    final size = this.size;
    final size2 = this.size2;

    for(int x = 0; x < size; x ++){
      for(int y = 0; y < size; y ++){
        for(int z = 0; z < size; z ++){
          final index = (size2 * z + size * y + x).toInt();
          double val = fieldCopy[index];
          int count = 1;

          for(int x2 = - 1; x2 <= 1; x2 += 2 ) {
            final x3 = x2 + x;
            if ( x3 < 0 || x3 >= size ) continue;

            for(int y2 = - 1; y2 <= 1; y2 += 2 ) {
              final y3 = y2 + y;
              if( y3 < 0 || y3 >= size ) continue;

              for(int z2 = - 1; z2 <= 1; z2 += 2){
                final z3 = z2 + z;
                if( z3 < 0 || z3 >= size ) continue;

                final index2 = (size2 * z3 + size * y3 + x3).toInt();
                final val2 = fieldCopy[ index2 ];

                count ++;
                val += intensity * ( val2 - val ) / count;
              }
            }
          }
          field[index] = val;
        }
      }
    }
  }

  void reset(){
    // wipe the normal cache
    for (int i = 0; i < size3; i ++ ) {
      normalCache[ i * 3 ] = 0.0;
      field[ i ] = 0.0;
      palette[ i * 3 ] = palette[ i * 3 + 1 ] = palette[i * 3 + 2] = 0.0;
    }
  }

  void update() {
    count = 0;
    // Triangulate. Yeah, this is slow.
    final smin2 = size - 2;

    for(int z = 1; z < smin2; z ++){
      final zOffset = size2.toInt() * z;
      final fz = ( z - halfsize ) / halfsize; //+ 1
      for (int y = 1; y < smin2; y ++ ) {

        final yOffset = zOffset + size.toInt() * y;
        final fy = ( y - halfsize ) / halfsize; //+ 1

        for (int x = 1; x < smin2; x ++ ) {
          final fx = ( x - halfsize ) / halfsize; //+ 1
          final q = yOffset + x;
          polygonize( fx, fy, fz, q, isolation );
        }
      }
    }

    // set the draw range to only the processed triangles

    geometry!.setDrawRange( 0, count! );

    // update geometry data
    geometry!.getAttributeFromString('position').needsUpdate = true;
    geometry!.getAttributeFromString('normal').needsUpdate = true;

    if (enableUvs ) geometry!.getAttributeFromString( 'uv' ).needsUpdate = true;
    if (enableColors ) geometry!.getAttributeFromString( 'color' ).needsUpdate = true;

    // safety check
    if (count! / 3 > maxPolyCount ){ 
      throw( 'THREE.MarchingCubes: Geometry buffers too small for rendering. Please create an instance with a higher poly count.' );
    }
  }
}

/////////////////////////////////////
// Marching cubes lookup tables
/////////////////////////////////////

// These tables are straight from Paul Bourke's page:
// http://paulbourke.net/geometry/polygonise/
// who in turn got them from Cory Gene Bloyd.

final edgeTable = Int32List.fromList( [
	0x0, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
	0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
	0x190, 0x99, 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
	0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
	0x230, 0x339, 0x33, 0x13a, 0x636, 0x73f, 0x435, 0x53c,
	0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
	0x3a0, 0x2a9, 0x1a3, 0xaa, 0x7a6, 0x6af, 0x5a5, 0x4ac,
	0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
	0x460, 0x569, 0x663, 0x76a, 0x66, 0x16f, 0x265, 0x36c,
	0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
	0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff, 0x3f5, 0x2fc,
	0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
	0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55, 0x15c,
	0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
	0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc,
	0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
	0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
	0xcc, 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
	0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
	0x15c, 0x55, 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
	0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
	0x2fc, 0x3f5, 0xff, 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
	0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
	0x36c, 0x265, 0x16f, 0x66, 0x76a, 0x663, 0x569, 0x460,
	0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
	0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa, 0x1a3, 0x2a9, 0x3a0,
	0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
	0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33, 0x339, 0x230,
	0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
	0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99, 0x190,
	0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
	0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x0 ] );

final triTable = Int32List.fromList( [
	- 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 8, 3, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 1, 9, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 8, 3, 9, 8, 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 2, 10, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 8, 3, 1, 2, 10, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 2, 10, 0, 2, 9, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	2, 8, 3, 2, 10, 8, 10, 9, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 11, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 11, 2, 8, 11, 0, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 9, 0, 2, 3, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 11, 2, 1, 9, 11, 9, 8, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 10, 1, 11, 10, 3, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 10, 1, 0, 8, 10, 8, 11, 10, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 9, 0, 3, 11, 9, 11, 10, 9, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 8, 10, 10, 8, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 7, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 3, 0, 7, 3, 4, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 1, 9, 8, 4, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 1, 9, 4, 7, 1, 7, 3, 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 2, 10, 8, 4, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 4, 7, 3, 0, 4, 1, 2, 10, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 2, 10, 9, 0, 2, 8, 4, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4, - 1, - 1, - 1, - 1,
	8, 4, 7, 3, 11, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	11, 4, 7, 11, 2, 4, 2, 0, 4, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 0, 1, 8, 4, 7, 2, 3, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1, - 1, - 1, - 1, - 1,
	3, 10, 1, 3, 11, 10, 7, 8, 4, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4, - 1, - 1, - 1, - 1,
	4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3, - 1, - 1, - 1, - 1,
	4, 7, 11, 4, 11, 9, 9, 11, 10, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 5, 4, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 5, 4, 0, 8, 3, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 5, 4, 1, 5, 0, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	8, 5, 4, 8, 3, 5, 3, 1, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 2, 10, 9, 5, 4, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 0, 8, 1, 2, 10, 4, 9, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	5, 2, 10, 5, 4, 2, 4, 0, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8, - 1, - 1, - 1, - 1,
	9, 5, 4, 2, 3, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 11, 2, 0, 8, 11, 4, 9, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 5, 4, 0, 1, 5, 2, 3, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5, - 1, - 1, - 1, - 1,
	10, 3, 11, 10, 1, 3, 9, 5, 4, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10, - 1, - 1, - 1, - 1,
	5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3, - 1, - 1, - 1, - 1,
	5, 4, 8, 5, 8, 10, 10, 8, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 7, 8, 5, 7, 9, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 3, 0, 9, 5, 3, 5, 7, 3, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 7, 8, 0, 1, 7, 1, 5, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 5, 3, 3, 5, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 7, 8, 9, 5, 7, 10, 1, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3, - 1, - 1, - 1, - 1,
	8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2, - 1, - 1, - 1, - 1,
	2, 10, 5, 2, 5, 3, 3, 5, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	7, 9, 5, 7, 8, 9, 3, 11, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11, - 1, - 1, - 1, - 1,
	2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7, - 1, - 1, - 1, - 1,
	11, 2, 1, 11, 1, 7, 7, 1, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11, - 1, - 1, - 1, - 1,
	5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0, - 1,
	11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0, - 1,
	11, 10, 5, 7, 11, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	10, 6, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 8, 3, 5, 10, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 0, 1, 5, 10, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 8, 3, 1, 9, 8, 5, 10, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 6, 5, 2, 6, 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 6, 5, 1, 2, 6, 3, 0, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 6, 5, 9, 0, 6, 0, 2, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8, - 1, - 1, - 1, - 1,
	2, 3, 11, 10, 6, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	11, 0, 8, 11, 2, 0, 10, 6, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 1, 9, 2, 3, 11, 5, 10, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11, - 1, - 1, - 1, - 1,
	6, 3, 11, 6, 5, 3, 5, 1, 3, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6, - 1, - 1, - 1, - 1,
	3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9, - 1, - 1, - 1, - 1,
	6, 5, 9, 6, 9, 11, 11, 9, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	5, 10, 6, 4, 7, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 3, 0, 4, 7, 3, 6, 5, 10, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 9, 0, 5, 10, 6, 8, 4, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4, - 1, - 1, - 1, - 1,
	6, 1, 2, 6, 5, 1, 4, 7, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7, - 1, - 1, - 1, - 1,
	8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6, - 1, - 1, - 1, - 1,
	7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9, - 1,
	3, 11, 2, 7, 8, 4, 10, 6, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11, - 1, - 1, - 1, - 1,
	0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6, - 1, - 1, - 1, - 1,
	9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6, - 1,
	8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6, - 1, - 1, - 1, - 1,
	5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11, - 1,
	0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7, - 1,
	6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9, - 1, - 1, - 1, - 1,
	10, 4, 9, 6, 4, 10, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 10, 6, 4, 9, 10, 0, 8, 3, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	10, 0, 1, 10, 6, 0, 6, 4, 0, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10, - 1, - 1, - 1, - 1,
	1, 4, 9, 1, 2, 4, 2, 6, 4, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4, - 1, - 1, - 1, - 1,
	0, 2, 4, 4, 2, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	8, 3, 2, 8, 2, 4, 4, 2, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	10, 4, 9, 10, 6, 4, 11, 2, 3, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6, - 1, - 1, - 1, - 1,
	3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10, - 1, - 1, - 1, - 1,
	6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1, - 1,
	9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3, - 1, - 1, - 1, - 1,
	8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1, - 1,
	3, 11, 6, 3, 6, 0, 0, 6, 4, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	6, 4, 8, 11, 6, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	7, 10, 6, 7, 8, 10, 8, 9, 10, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10, - 1, - 1, - 1, - 1,
	10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0, - 1, - 1, - 1, - 1,
	10, 6, 7, 10, 7, 1, 1, 7, 3, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7, - 1, - 1, - 1, - 1,
	2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9, - 1,
	7, 8, 0, 7, 0, 6, 6, 0, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	7, 3, 2, 6, 7, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7, - 1, - 1, - 1, - 1,
	2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7, - 1,
	1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11, - 1,
	11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1, - 1, - 1, - 1, - 1,
	8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6, - 1,
	0, 9, 1, 11, 6, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0, - 1, - 1, - 1, - 1,
	7, 11, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	7, 6, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 0, 8, 11, 7, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 1, 9, 11, 7, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	8, 1, 9, 8, 3, 1, 11, 7, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	10, 1, 2, 6, 11, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 2, 10, 3, 0, 8, 6, 11, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	2, 9, 0, 2, 10, 9, 6, 11, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8, - 1, - 1, - 1, - 1,
	7, 2, 3, 6, 2, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	7, 0, 8, 7, 6, 0, 6, 2, 0, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	2, 7, 6, 2, 3, 7, 0, 1, 9, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6, - 1, - 1, - 1, - 1,
	10, 7, 6, 10, 1, 7, 1, 3, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8, - 1, - 1, - 1, - 1,
	0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7, - 1, - 1, - 1, - 1,
	7, 6, 10, 7, 10, 8, 8, 10, 9, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	6, 8, 4, 11, 8, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 6, 11, 3, 0, 6, 0, 4, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	8, 6, 11, 8, 4, 6, 9, 0, 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6, - 1, - 1, - 1, - 1,
	6, 8, 4, 6, 11, 8, 2, 10, 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6, - 1, - 1, - 1, - 1,
	4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9, - 1, - 1, - 1, - 1,
	10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3, - 1,
	8, 2, 3, 8, 4, 2, 4, 6, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 4, 2, 4, 6, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8, - 1, - 1, - 1, - 1,
	1, 9, 4, 1, 4, 2, 2, 4, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1, - 1, - 1, - 1, - 1,
	10, 1, 0, 10, 0, 6, 6, 0, 4, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3, - 1,
	10, 9, 4, 6, 10, 4, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 9, 5, 7, 6, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 8, 3, 4, 9, 5, 11, 7, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	5, 0, 1, 5, 4, 0, 7, 6, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5, - 1, - 1, - 1, - 1,
	9, 5, 4, 10, 1, 2, 7, 6, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5, - 1, - 1, - 1, - 1,
	7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2, - 1, - 1, - 1, - 1,
	3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6, - 1,
	7, 2, 3, 7, 6, 2, 5, 4, 9, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7, - 1, - 1, - 1, - 1,
	3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0, - 1, - 1, - 1, - 1,
	6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8, - 1,
	9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7, - 1, - 1, - 1, - 1,
	1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4, - 1,
	4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10, - 1,
	7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10, - 1, - 1, - 1, - 1,
	6, 9, 5, 6, 11, 9, 11, 8, 9, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5, - 1, - 1, - 1, - 1,
	0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11, - 1, - 1, - 1, - 1,
	6, 11, 3, 6, 3, 5, 5, 3, 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6, - 1, - 1, - 1, - 1,
	0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10, - 1,
	11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5, - 1,
	6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3, - 1, - 1, - 1, - 1,
	5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2, - 1, - 1, - 1, - 1,
	9, 5, 6, 9, 6, 0, 0, 6, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8, - 1,
	1, 5, 6, 2, 1, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6, - 1,
	10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0, - 1, - 1, - 1, - 1,
	0, 3, 8, 5, 6, 10, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	10, 5, 6, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	11, 5, 10, 7, 5, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	11, 5, 10, 11, 7, 5, 8, 3, 0, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	5, 11, 7, 5, 10, 11, 1, 9, 0, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1, - 1, - 1, - 1, - 1,
	11, 1, 2, 11, 7, 1, 7, 5, 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11, - 1, - 1, - 1, - 1,
	9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7, - 1, - 1, - 1, - 1,
	7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2, - 1,
	2, 5, 10, 2, 3, 5, 3, 7, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5, - 1, - 1, - 1, - 1,
	9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2, - 1, - 1, - 1, - 1,
	9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2, - 1,
	1, 3, 5, 3, 7, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 8, 7, 0, 7, 1, 1, 7, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 0, 3, 9, 3, 5, 5, 3, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 8, 7, 5, 9, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	5, 8, 4, 5, 10, 8, 10, 11, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0, - 1, - 1, - 1, - 1,
	0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5, - 1, - 1, - 1, - 1,
	10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4, - 1,
	2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8, - 1, - 1, - 1, - 1,
	0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11, - 1,
	0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5, - 1,
	9, 4, 5, 2, 11, 3, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4, - 1, - 1, - 1, - 1,
	5, 10, 2, 5, 2, 4, 4, 2, 0, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9, - 1,
	5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2, - 1, - 1, - 1, - 1,
	8, 4, 5, 8, 5, 3, 3, 5, 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 4, 5, 1, 0, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5, - 1, - 1, - 1, - 1,
	9, 4, 5, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 11, 7, 4, 9, 11, 9, 10, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11, - 1, - 1, - 1, - 1,
	1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11, - 1, - 1, - 1, - 1,
	3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4, - 1,
	4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2, - 1, - 1, - 1, - 1,
	9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3, - 1,
	11, 7, 4, 11, 4, 2, 2, 4, 0, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4, - 1, - 1, - 1, - 1,
	2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9, - 1, - 1, - 1, - 1,
	9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7, - 1,
	3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10, - 1,
	1, 10, 2, 8, 7, 4, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 9, 1, 4, 1, 7, 7, 1, 3, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1, - 1, - 1, - 1, - 1,
	4, 0, 3, 7, 4, 3, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	4, 8, 7, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 10, 8, 10, 11, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 0, 9, 3, 9, 11, 11, 9, 10, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 1, 10, 0, 10, 8, 8, 10, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 1, 10, 11, 3, 10, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 2, 11, 1, 11, 9, 9, 11, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9, - 1, - 1, - 1, - 1,
	0, 2, 11, 8, 0, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	3, 2, 11, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	2, 3, 8, 2, 8, 10, 10, 8, 9, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	9, 10, 2, 0, 9, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8, - 1, - 1, - 1, - 1,
	1, 10, 2, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	1, 3, 8, 9, 1, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 9, 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	0, 3, 8, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1,
	- 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1, - 1 ] );

