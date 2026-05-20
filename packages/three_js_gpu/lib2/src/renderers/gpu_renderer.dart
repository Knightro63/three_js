import 'package:three_js_core/three_js_core.dart';
import './nodes/standard_node_library.dart';
import './gpu_backend.dart';

/*
const debugHandler = {

	get: function ( target, name ) {

		// Add |update
		if ( /^(create|destroy)/.test( name ) ) log( 'WebGPUBackend.' + name );

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
class WebGPURenderer extends Renderer {
  late final Map<String, dynamic> parameters;
  final library = StandardNodeLibrary();

	WebGPURenderer([Map<String, dynamic>? parameters]) {
    this.parameters = parameters ?? {};
    WebGPUBackend( this.parameters );
  }
}
