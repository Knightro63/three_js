import 'package:three_js_core/materials/shadow_material.dart';
import 'node_material.dart';

final _defaultValues = /*@__PURE__*/ ShadowMaterial();

/**
 * Node material version of {@link ShadowMaterial}.
 *
 * @augments NodeMaterial
 */
class ShadowNodeMaterial extends NodeMaterial {
	String get type => 'ShadowNodeMaterial';
  /**
   * Set to `true` because so it's possible to implement
   * the shadow mask effect.
   *
   * @type {boolean}
   * @default true
   */
  bool lights = true;

  /**
   * Overwritten since shadow materials are transparent
   * by default.
   *
   * @type {boolean}
   * @default true
   */
  bool transparent = true;

	/**
	 * Constructs a new shadow node material.
	 *
	 * @param {Object} [parameters] - The configuration parameter.
	 */
	ShadowNodeMaterial( parameters ):super() {

		this.setDefaultValues( _defaultValues );
		this.setValues( parameters );
	}

	/**
	 * Setups the lighting model.
	 *
	 * @return {ShadowMaskModel} The lighting model.
	 */
	ShadowMaskModel setupLightingModel( /*builder*/ ) {
		return ShadowMaskModel();
	}
}


