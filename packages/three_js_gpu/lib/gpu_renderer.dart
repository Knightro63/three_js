import 'package:three_js_core/three_js_core.dart';
import './gpu_backend.dart';

/*
const debugHandler = {

	get: function ( target, name ) {

		// Add |update
		if ( /^(create|destroy)/.test( name ) ) console.log( 'WebGPUBackend.' + name );

		return target[ name ];

	}

};
*/

/**
 * This renderer is the new alternative of `WebGLRenderer`. `WebGPURenderer` has the ability
 * to target different backends. By default, the renderer tries to use a WebGPU backend if the
 * browser supports WebGPU. If not, `WebGPURenderer` falls backs to a WebGL 2 backend.
 *
 * @augments Renderer
 */
class WebGPURenderer extends Renderer{
  bool isWebGPURenderer = true;
  StandardNodeLibrary library = StandardNodeLibrary();

  WebGPURenderer(super.backend, super.parameters);

	/**
	 * Constructs a new WebGPU renderer.
	 *
	 * @param {WebGPURenderer~Options} [parameters] - The configuration parameter.
	 */
	factory WebGPURenderer.create( parameters) {
		Type BackendClass;

		if ( parameters.forceWebGL ) {
			BackendClass = WebGLBackend;
		} 
    else {
			BackendClass = WebGPUBackend;
			parameters.getFallback = () => {
				console.warning( 'THREE.WebGPURenderer: WebGPU is not available, running under WebGL2 backend.' );
				return new WebGLBackend( parameters );
			};
		}

		final backend = new BackendClass( parameters );

		if ( typeof __THREE_DEVTOOLS__ !== 'undefined' ) {
			__THREE_DEVTOOLS__.dispatchEvent( new CustomEvent( 'observe', { detail: this } ) );
		}

    return WebGPURenderer(backend,parameters);
	}
}
