import '../core/index.dart';
import 'light.dart';
import 'directional_light_shadow.dart';

class DirectionalLight extends Light {
  bool isDirectionalLight = true;

  DirectionalLight(super.color, [super.intensity]){
    type = "DirectionalLight";
    position.setFrom(Object3D.defaultUp);
    updateMatrix();
    target = Object3D();
    shadow = DirectionalLightShadow();
  }

  @override
  DirectionalLight copy(Object3D source, [bool? recursive]) {
    super.copy(source, false);

    if (source is DirectionalLight) {
      target = source.target!.clone(false);
      shadow = source.shadow!.clone();
    }
    return this;
  }

  @override
  void dispose() {
    shadow!.dispose();
  }
}
