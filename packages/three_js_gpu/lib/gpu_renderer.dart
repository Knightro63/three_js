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

  WebGPURenderer(super.backend, super.parameters);

	/**
	 * Constructs a new WebGPU renderer.
	 *
	 * @param {WebGPURenderer~Options} [parameters] - The configuration parameter.
	 */
	factory WebGPURenderer.create( parameters) {
		let BackendClass;

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

		const backend = new BackendClass( parameters );

		/**
		 * The generic default value is overwritten with the
		 * standard node library for type mapping.
		 *
		 * @type {StandardNodeLibrary}
		 */
		this.library = new StandardNodeLibrary();

		/**
		 * This flag can be used for type testing.
		 *
		 * @type {boolean}
		 * @readonly
		 * @default true
		 */
		this.isWebGPURenderer = true;

		if ( typeof __THREE_DEVTOOLS__ !== 'undefined' ) {
			__THREE_DEVTOOLS__.dispatchEvent( new CustomEvent( 'observe', { detail: this } ) );
		}

    return WebGPURenderer(backend,parameters);

	}

}
