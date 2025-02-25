import '../core/index.dart';
import 'light.dart';
import 'directional_light_shadow.dart';

/// A light that gets emitted in a specific direction. This light will behave
/// as though it is infinitely far away and the rays produced from it are all
/// parallel. The common use case for this is to simulate daylight; the sun is
/// far enough away that its position can be considered to be infinite, and
/// all light rays coming from it are parallel.
///
/// This light can cast shadows - see the [DirectionalLightShadow] page
/// for details.
/// 
/// A Note about Position, Target and rotation
/// 
/// A common point of confusion for directional lights is that setting the
/// rotation has no effect. This is because three.js's DirectionalLight is the
/// equivalent to what is often called a 'Target Direct Light' in other
/// applications.
///
/// This means that its direction is calculated as pointing from the light's
/// [position] to the [target]'s position
/// (as opposed to a 'Free Direct Light' that just has a rotation
/// component).
///
/// The reason for this is to allow the light to cast shadows - the
/// [shadow] camera needs a position to calculate shadows
/// from.
///
/// See the [target] property below for details on updating the
/// target.
/// 
/// ```
/// // White directional light at half intensity shining from the top.
/// final directionalLight = DirectionalLight(0xffffff, 0.5 );
/// scene.add( directionalLight );
/// ```
class DirectionalLight extends Light {
  bool isDirectionalLight = true;
  bool disposed = true;

  /// [color] - (optional) hexadecimal color of the light.
  /// Default is 0xffffff.
  /// 
  /// [intensity] - (optional) numeric value of the light's
  /// strength/intensity. Default is `1`.
  DirectionalLight([super.color, super.intensity]){
    type = "DirectionalLight";
    position.setFrom(Object3D.defaultUp);
    updateMatrix();
    target = Object3D();
    shadow = DirectionalLightShadow();
  }

  /// Copies value of all the properties from the [source]
  /// to this DirectionalLight.
  @override
  DirectionalLight copy(Object3D source, [bool? recursive]) {
    super.copy(source, false);

    if (source is DirectionalLight) {
      target = source.target!.clone(false);
      shadow = source.shadow!.clone();
    }
    return this;
  }

  /// Frees the GPU-related resources allocated by this instance. Call this
  /// method whenever this instance is no longer used in your app.
  @override
  void dispose() {
    shadow!.dispose();
    if(disposed) return;
    disposed = true;
    super.dispose();
  }
}
