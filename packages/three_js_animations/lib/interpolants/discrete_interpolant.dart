import 'interpolant.dart';

///
/// Interpolant that evaluates to the sample value at the position preceeding
/// the parameter.

class DiscreteInterpolant extends Interpolant {
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
