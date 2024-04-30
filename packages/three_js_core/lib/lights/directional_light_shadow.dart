import '../cameras/index.dart';
import 'light_shadow.dart';

class DirectionalLightShadow extends LightShadow {
  bool isDirectionalLightShadow = true;
  DirectionalLightShadow():super(OrthographicCamera(-5, 5, 5, -5, 0.5, 500));
}
