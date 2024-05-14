// https://cs.nyu.edu/~perlin/noise/

final _p = [ 151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10,
	 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87,
	 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211,
	 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208,
	 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5,
	 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119,
	 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232,
	 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249,
	 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205,
	 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180 ];

class ImprovedNoise {
  ImprovedNoise(){
    for(int i = 0; i < 256; i++){
      if(_p.length <= 256+i){
        _p.add(_p[i]);
      }
      else{
        _p[256+i] = _p[i];
      }
    }
  }

  double _fade(double t) {
    return t * t * t * ( t * ( t * 6 - 15 ) + 10 );
  }

  double _lerp(double t,double a,double b ) {
    return a + t * ( b - a );
  }

  double _grad(int hash, double x, double y, double z ) {
    final h = hash & 15;
    final u = h < 8 ? x : y, v = h < 4 ? y : h == 12 || h == 14 ? x : z;
    return ( ( h & 1 ) == 0 ? u : - u ) + ( ( h & 2 ) == 0 ? v : - v );
  }

	double noise(double x, double y, double z ) {
		final floorX = x.floor(), floorY = y.floor(), floorZ = z.floor();

		final X = floorX & 255, Y = floorY & 255, Z = floorZ & 255;

		x -= floorX;
		y -= floorY;
		z -= floorZ;

		final xMinus1 = x - 1, 
      yMinus1 = y - 1, 
      zMinus1 = z - 1;

		final u = _fade(x), 
      v = _fade(y), 
      w = _fade(z);

		final a = _p[ X ] + Y, 
      aa = _p[ a ] + Z, 
      ab = _p[ a + 1 ] + Z, 
      b = _p[ X + 1 ] + Y, 
      ba = _p[ b ] + Z, 
      bb = _p[ b + 1 ] + Z;

		return _lerp( w, _lerp( v, _lerp( u, _grad( _p[ aa ], x, y, z ),
			_grad( _p[ ba ], xMinus1, y, z ) ),
		_lerp( u, _grad( _p[ ab ], x, yMinus1, z ),
			_grad( _p[ bb ], xMinus1, yMinus1, z ) ) ),
		_lerp( v, _lerp( u, _grad( _p[ aa + 1 ], x, y, zMinus1 ),
			_grad( _p[ ba + 1 ], xMinus1, y, zMinus1 ) ),
		_lerp( u, _grad( _p[ ab + 1 ], x, yMinus1, zMinus1 ),
			_grad( _p[ bb + 1 ], xMinus1, yMinus1, zMinus1 ) ) ) );
	}
}
