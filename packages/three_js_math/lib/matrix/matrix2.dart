import 'dart:typed_data';

import 'package:three_js_math/three_js_math.dart';

/**
 * Represents a 2x2 matrix.
 *
 * A Note on Row-Major and Column-Major Ordering:
 *
 * The constructor and {@link Matrix2#set} method take arguments in
 * [row-major]{@link https://en.wikipedia.org/wiki/Row-_and_column-major_order#Column-major_order}
 * order, while internally they are stored in the {@link Matrix2#elements} array in column-major order.
 * This means that calling:
 * ```js
 * const m = new THREE.Matrix2();
 * m.set( 11, 12,
 *        21, 22 );
 * ```
 * will result in the elements array containing:
 * ```js
 * m.elements = [ 11, 21,
 *                12, 22 ];
 * ```
 * and internally all calculations are performed using column-major ordering.
 * However, as the actual ordering makes no difference mathematically and
 * most people are used to thinking about matrices in row-major order, the
 * three.js documentation shows matrices in row-major order. Just bear in
 * mind that if you are reading the source code, you'll have to take the
 * transpose of any matrices outlined here to make sense of the calculations.
 */
class Matrix2 {
  String type = "Matrix2";
  late Float32List storage;

	// Matrix2() {
  //   storage = Float32List.fromList(
	// 		[0, 0,
	// 		0, 0]
	// 	);
	// }

  /// Set the current 3x3 matrix as an identity matrix.
  Matrix2 identity() {
    setValues(1, 0, 0, 1);
    return this;
  }

	/**
	 * Sets this matrix to the 2x2 identity matrix.
	 *
	 * @return {Matrix2} A reference to this matrix.
	 */
	Matrix2.identity() {
		storage = Float32List.fromList(
			[1, 0,
			0, 1]
		);
	}

	Matrix2 fromArray(List<double> array, [int offset = 0 ]) {
		for (int i = 0; i < 4; i ++ ) {
			this.storage[ i ] = array[ i + offset ];
		}
		return this;
	}

	Matrix2 fromNativeArray(NativeArray array, [int offset = 0 ]) {
		for (int i = 0; i < 4; i ++ ) {
			this.storage[ i ] = array[ i + offset ].toDouble();
		}
		return this;
	}

  Matrix2 unknown(array, [int offset = 0 ]) {
		for (int i = 0; i < 4; i ++ ) {
			this.storage[ i ] = array[ i + offset ];
		}
		return this;
	}

	Matrix2 setValues(double n11, double n12, double n21, double n22 ) {
		final te = storage;

		te[ 0 ] = n11; te[ 2 ] = n12;
		te[ 1 ] = n21; te[ 3 ] = n22;
		return this;
	}
}