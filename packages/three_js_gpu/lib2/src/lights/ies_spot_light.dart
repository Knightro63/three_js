import 'package:three_js_core/three_js_core.dart';

/**
 * A IES version of {@link SpotLight}. Can only be used with {@link WebGPURenderer}.
 *
 * @augments SpotLight
 */
class IESSpotLight extends SpotLight {
  Texture? iesMap = null;
	/**
	 * Constructs a new IES spot light.
	 *
	 * @param {(number|Color|string)} [color=0xffffff] - The light's color.
	 * @param {number} [intensity=1] - The light's strength/intensity measured in candela (cd).
	 * @param {number} [distance=0] - Maximum range of the light. `0` means no limit.
	 * @param {number} [angle=Math.PI/3] - Maximum angle of light dispersion from its direction whose upper bound is `Math.PI/2`.
	 * @param {number} [penumbra=0] - Percent of the spotlight cone that is attenuated due to penumbra. Value range is `[0,1]`.
	 * @param {number} [decay=2] - The amount the light dims along the distance of the light.
	 */
	IESSpotLight(super.color, super.intensity, super.distance, super.angle, super.penumbra, super.decay );

	IESSpotLight copy(Object3D source, [bool? recursive] ) {
    source as IESSpotLight;
		super.copy( source, recursive );
		this.iesMap = source.iesMap;
		return this;
	}
}
