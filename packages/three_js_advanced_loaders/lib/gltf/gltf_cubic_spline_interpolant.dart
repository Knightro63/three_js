import 'package:three_js_animations/three_js_animations.dart';

/*********************************/
/********** INTERPOLATION ********/

/*********************************/

// Spline Interpolation
// Specification: https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#appendix-c-spline-interpolation
class GLTFCubicSplineInterpolant extends Interpolant {
  GLTFCubicSplineInterpolant(super.parameterPositions, super.sampleValues, super.sampleSize, super.resultBuffer);
  @override
  List? copySampleValue(int index) {
    // Copies a sample value to the result buffer. See description of glTF
    // CUBICSPLINE values layout in interpolate() function below.

    final result = resultBuffer,
        values = sampleValues,
        valueSize = this.valueSize,
        offset = index * valueSize * 3 + valueSize;

    for (int i = 0; i < valueSize; i++) {
      result?[i] = values[offset + i];
    }

    return result;
  }
  @override
  List? beforeStart(int v1, v2, v3) {
    return copySampleValue(v1);
  }
  @override
  List? afterEnd(int v1, v2, v3) {
    return copySampleValue(v1);
  }
  @override
  List? interpolate(int i1, num t0, num t, num t1) {
    final result = resultBuffer;
    final values = sampleValues;
    final stride = valueSize;

    final stride2 = stride * 2;
    final stride3 = stride * 3;

    final td = t1 - t0;

    final p = (t - t0) / td;
    final pp = p * p;
    final ppp = pp * p;

    final offset1 = i1 * stride3;
    final offset0 = offset1 - stride3;

    final s2 = -2 * ppp + 3 * pp;
    final s3 = ppp - pp;
    final s0 = 1 - s2;
    final s1 = s3 - pp + p;

    // Layout of keyframe output values for CUBICSPLINE animations:
    //   [ inTangent_1, splineVertex_1, outTangent_1, inTangent_2, splineVertex_2, ... ]
    for (int i = 0; i < stride; i++) {
      final p0 = values[offset0 + i + stride]; // splineVertex_k
      final m0 =
          values[offset0 + i + stride2] * td; // outTangent_k * (t_k+1 - t_k)
      final p1 = values[offset1 + i + stride]; // splineVertex_k+1
      final m1 = values[offset1 + i] * td; // inTangent_k+1 * (t_k+1 - t_k)

      result?[i] = s0 * p0 + s1 * m0 + s2 * p1 + s3 * m1;
    }

    return result;
  }
}
