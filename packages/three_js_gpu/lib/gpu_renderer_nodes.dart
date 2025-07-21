import 'package:three_js_core/three_js_core.dart';

import './gpu_backend.dart';
import './gpu_renderer.dart';

/**
 * This alternative version of {@link WebGPURenderer} only supports node materials.
 * So classes like `MeshBasicMaterial` are not compatible.
 *
 * @private
 * @augments Renderer
 */
class WebGPURenderer extends Renderer {
  BasicNodeLibrary library = BasicNodeLibrary();
  bool isWebGPURenderer = true;

  WebGPURenderer(super.backend, super.parameters);

	/**
	 * Constructs a new WebGPU renderer.
	 *
	 * @param {WebGPURenderer~Options} [parameters] - The configuration parameter.
	 */
	factory WebGPURenderer.create( parameters = {} ) {
		let BackendClass;

		if ( parameters.forceWebGL ) {
			BackendClass = WebGLBackend;
		} else {
			BackendClass = WebGPUBackend;
			parameters.getFallback = (){
				console.warning( 'THREE.WebGPURenderer: WebGPU is not available, running under WebGL2 backend.' );
				return new WebGLBackend( parameters );
			};
		}

		final backend = BackendClass( parameters );
	}
}
