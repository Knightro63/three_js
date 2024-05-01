import 'interpolant.dart';

///
/// Interpolant that evaluates to the sample value at the position preceeding
/// the parameter.
/// 
/// ```dart
/// final interpolant = DiscreteInterpolant(
///   [0,0],
///   [0,0],
///   1,
/// 	[0]
/// );
/// interpolant.evaluate( 0.5 );
/// ```
/// 
class DiscreteInterpolant extends Interpolant {
	/// [parameterPositions] -- array of positions
  /// 
	/// [sampleValues] -- array of samples
  /// 
	/// [sampleSize] -- number of samples
  /// 
	/// [resultBuffer] -- buffer to store the interpolation results.
  /// 
  DiscreteInterpolant(
    super.parameterPositions, 
    super.sampleValues, 
    super.sampleSize, 
    super.resultBuffer
  );

  @override
  List? interpolate(int i1, num t0, num t, num t1) {
    return copySampleValue(i1 - 1);
  }
}
