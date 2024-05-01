import 'interpolant.dart';

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
class LinearInterpolant extends Interpolant {
	/// [parameterPositions] -- array of positions
  /// 
	/// [sampleValues] -- array of samples
  /// 
	/// [sampleSize] -- number of samples
  /// 
	/// [resultBuffer] -- buffer to store the interpolation results.
  /// 
  LinearInterpolant(
    super.parameterPositions, 
    super.sampleValues, 
    super.sampleSize, 
    super.resultBuffer
  );

  @override
  List? interpolate(int i1, num t0, num t, num t1) {
    final result = resultBuffer,
        values = sampleValues,
        stride = valueSize,
        offset1 = i1 * stride,
        offset0 = offset1 - stride,
        weight1 = (t - t0) / (t1 - t0),
        weight0 = 1 - weight1;

    for (int i = 0; i != stride; ++i) {
      result?[i] = values[offset0 + i] * weight0 + values[offset1 + i] * weight1;
    }

    return result;
  }
}
