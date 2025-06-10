//import Easing from 'easing-functions';
import 'package:three_js/three_js.dart';

import './types.dart';

enum CurveFunctionId {
  bezier,
  linear,
  quadratic_in,
  quadratic_out,
  quadratic_in_out,
  cubic_in,
  cubic_out,
  cubic_in_out,
  quartic_in,
  quartic_out,
  quartic_in_out,
  quintic_in,
  quintic_out,
  quintic_in_out,
  sinusoidal_in,
  sinusoidal_out,
  sinusoidal_in_out,
  exponential_in,
  exponential_out,
  exponential_in_out,
  circular_in,
  circular_out,
  circular_in_out,
  elastic_in,
  elastic_out,
  elastic_in_out,
  back_in,
  back_out,
  back_in_out,
  bounce_in,
  bounce_out,
  bounce_in_out,
}

final Map<CurveFunctionId, CurveFunction?> CurveFunctionIdMap = {
  CurveFunctionId.linear: Easing.Linear[ETTypes.None],
  CurveFunctionId.quadratic_in: Easing.Quadratic[ETTypes.In],
  CurveFunctionId.quadratic_out: Easing.Quadratic[ETTypes.Out],
  CurveFunctionId.quadratic_in_out: Easing.Quadratic[ETTypes.InOut],
  CurveFunctionId.cubic_in: Easing.Cubic[ETTypes.In],
  CurveFunctionId.cubic_out: Easing.Cubic[ETTypes.Out],
  CurveFunctionId.cubic_in_out: Easing.Cubic[ETTypes.InOut],
  CurveFunctionId.quartic_in: Easing.Quartic[ETTypes.In],
  CurveFunctionId.quartic_out: Easing.Quartic[ETTypes.Out],
  CurveFunctionId.quartic_in_out: Easing.Quartic[ETTypes.InOut],
  CurveFunctionId.quintic_in: Easing.Quintic[ETTypes.In],
  CurveFunctionId.quintic_out: Easing.Quintic[ETTypes.Out],
  CurveFunctionId.quintic_in_out: Easing.Quintic[ETTypes.InOut],
  CurveFunctionId.sinusoidal_in: Easing.Sinusoidal[ETTypes.In],
  CurveFunctionId.sinusoidal_out: Easing.Sinusoidal[ETTypes.Out],
  CurveFunctionId.sinusoidal_in_out: Easing.Sinusoidal[ETTypes.InOut],
  CurveFunctionId.exponential_in: Easing.Exponential[ETTypes.In],
  CurveFunctionId.exponential_out: Easing.Exponential[ETTypes.Out],
  CurveFunctionId.exponential_in_out: Easing.Exponential[ETTypes.InOut],
  CurveFunctionId.circular_in: Easing.Circular[ETTypes.In],
  CurveFunctionId.circular_out: Easing.Circular[ETTypes.Out],
  CurveFunctionId.circular_in_out: Easing.Circular[ETTypes.InOut],
  CurveFunctionId.elastic_in: Easing.Elastic[ETTypes.In],
  CurveFunctionId.elastic_out: Easing.Elastic[ETTypes.Out],
  CurveFunctionId.elastic_in_out: Easing.Elastic[ETTypes.InOut],
  CurveFunctionId.back_in: Easing.Back[ETTypes.In],
  CurveFunctionId.back_out: Easing.Back[ETTypes.Out],
  CurveFunctionId.back_in_out: Easing.Back[ETTypes.InOut],
  CurveFunctionId.bounce_in: Easing.Bounce[ETTypes.In],
  CurveFunctionId.bounce_out: Easing.Bounce[ETTypes.Out],
  CurveFunctionId.bounce_in_out: Easing.Bounce[ETTypes.InOut],
};

CurveFunction getCurveFunction(
  curveFunctionId//: CurveFunctionId | CurveFunction
) =>
  curveFunctionId is CurveFunction
    ? curveFunctionId
    : CurveFunctionIdMap[curveFunctionId]!;
