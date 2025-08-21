import 'package:three_js_postprocessing/three_js_postprocessing.dart';

class FXAAPass extends ShaderPass {

	/**
	 * Constructs a new FXAA pass.
	 */
	FXAAPass():super.fromJson( fxaaShader );

	/**
	 * Sets the size of the pass.
	 *
	 * @param {number} width - The width to set.
	 * @param {number} height - The height to set.
	 */
	void setSize(int width, int height ) {
		this.material.uniforms['resolution']['value'].setValues( 1 / width, 1 / height );
	}
}