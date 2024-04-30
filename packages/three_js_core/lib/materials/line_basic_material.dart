import './material.dart';
import 'package:three_js_math/three_js_math.dart';

class LineBasicMaterial extends Material {
  LineBasicMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    type = 'LineBasicMaterial';

    color = Color(1, 1, 1);
    linewidth = 1;
    linecap = 'round'; // 'butt', 'round' and 'square'.
    linejoin = 'round'; // 'round', 'bevel' and 'miter'.

    fog = true;

    setValues(parameters);
  }

  LineBasicMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    type = 'LineBasicMaterial';

    color = Color(1, 1, 1);
    linewidth = 1;
    linecap = 'round'; // 'butt', 'round' and 'square'.
    linejoin = 'round'; // 'round', 'bevel' and 'miter'.

    fog = true;

    setValuesFromString(parameters);
  }

  @override
  LineBasicMaterial copy(Material source) {
    super.copy(source);

    color.setFrom(source.color);

    linewidth = source.linewidth;
    linecap = source.linecap;
    linejoin = source.linejoin;

    fog = source.fog;

    return this;
  }

  @override
  LineBasicMaterial clone() {
    return LineBasicMaterial({}).copy(this);
  }
}

