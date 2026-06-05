import 'package:three_js_core/three_js_core.dart';

/// A IES version of {@link SpotLight}. Can only be used with {@link WebGPURenderer}.
class IESSpotLight extends SpotLight {
  Texture? iesMap = null;

	IESSpotLight(super.color, super.intensity, super.distance, super.angle, super.penumbra, super.decay );

	IESSpotLight copy(Object3D source, [bool? recursive] ) {
    source as IESSpotLight;
		super.copy( source, recursive );
		this.iesMap = source.iesMap;
		return this;
	}
}
