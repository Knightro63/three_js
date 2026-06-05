import 'package:three_js_core/three_js_core.dart';

/// A projector light version of {@link SpotLight}. Can only be used with {@link WebGPURenderer}.
class ProjectorLight extends SpotLight {
  double? aspect;

	ProjectorLight(super.color, super.intensity, super.distance, super.angle, super.penumbra, super.decay );

	ProjectorLight copy(Object3D source, [bool? recursive] ) {
    source as ProjectorLight;
		super.copy( source, recursive );
		this.aspect = source.aspect;
		return this;
	}
}
