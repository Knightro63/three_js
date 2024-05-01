import 'package:three_js_math/three_js_math.dart';
import 'interpolant.dart';

/// Spherical linear unit quaternion interpolant.
/// ```dart
/// final interpolant = LinearInterpolant(
///   [0,0],
///   [0,0],
///   1,
/// 	[0]
/// );
/// interpolant.evaluate( 0.5 );
/// ```
/// 
class QuaternionLinearInterpolant extends Interpolant {
	/// [parameterPositions] -- array of positions
  /// 
	/// [sampleValues] -- array of samples
  /// 
	/// [sampleSize] -- number of samples
  /// 
	/// [resultBuffer] -- buffer to store the interpolation results.
  /// 
  QuaternionLinearInterpolant(
    super.parameterPositions, 
    super.sampleValues, 
    super.sampleSize, 
    super.resultBuffer
  );

  @override
  List? interpolate(int i1, num t0, num t, num t1) {
    var result = resultBuffer;
    var values = sampleValues;
    var stride = valueSize;

    double v0 = t + (t0 * -1);
    double v1 = t1 + (t0 * -1);

    double alpha = v0 / v1;

    int offset = i1 * stride;

    for (int end = offset + stride; offset < end; offset += 4) {
      Quaternion.slerpFlat(result, 0, values, offset - stride, values, offset, alpha);
    }

    return result;
  }
}
