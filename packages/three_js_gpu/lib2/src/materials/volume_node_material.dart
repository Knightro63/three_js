import 'node_material.dart';

class VolumeNodeMaterial extends NodeMaterial {
	String get type => 'VolumeNodeMaterial';
  /**
   * Number of steps used for raymarching.
   */
  int steps = 25;

  /**
   * Offsets the distance a ray has been traveled through a volume.
   * Can be used to implement dithering to reduce banding.
   */
  Node<float>? offsetNode = null;

  /**
   * Node used for scattering calculations.
   */
  Function? scatteringNode;

  bool lights = true;

  bool transparent = true;
  int side = BackSide;

  bool depthTest = false;
  bool depthWrite = false;

	/**
	 * Constructs a new volume node material.
	 *
	 * @param {Object} [parameters] - The configuration parameter.
	 */
	VolumeNodeMaterial( parameters ):super() {
    this.setValues( parameters );
	}

	VolumetricLightingModel setupLightingModel() {
		return VolumetricLightingModel();
	}
}
