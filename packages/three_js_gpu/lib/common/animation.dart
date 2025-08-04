
import 'package:three_js_gpu/common/info.dart';
import 'package:three_js_gpu/common/nodes/nodes.dart';

/**
 * This module manages the internal animation loop of the renderer.
 *
 * @private
 */
class Animation {
  Nodes nodes;
  Info info;
  Function? _animationLoop;
  int? _requestId;
  XRSession? _context;

	/**
	 * Constructs a new animation loop management component.
	 *
	 * @param {Nodes} nodes - Renderer component for managing nodes related logic.
	 * @param {Info} info - Renderer component for managing metrics and monitoring data.
	 */
	Animation(this.nodes, this.info );

	/**
	 * Starts the internal animation loop.
	 */
	void start() {
		update( time, xrFrame ) {
			_requestId = _context.requestAnimationFrame( update );
			if ( info.autoReset == true ) info.reset();
			nodes.nodeFrame.update();
			info.frame = nodes.nodeFrame.frameId;
			_animationLoop?.call( time, xrFrame );
		}

		update();
	}

	/**
	 * Stops the internal animation loop.
	 */
	void stop() {
		_context.cancelAnimationFrame( _requestId );
		_requestId = null;
	}

	/**
	 * Returns the user-level animation loop.
	 *
	 * @return {?Function} The animation loop.
	 */
	Function? getAnimationLoop() {
		return _animationLoop;
	}

	/**
	 * Defines the user-level animation loop.
	 *
	 * @param {?Function} callback - The animation loop.
	 */
	void setAnimationLoop( callback ) {
		_animationLoop = callback;
	}

	/**
	 * Returns the animation context.
	 *
	 * @return {Window|XRSession} The animation context.
	 */
	getContext() {
		return _context;
	}

	/**
	 * Defines the context in which `requestAnimationFrame()` is executed.
	 *
	 * @param {Window|XRSession} context - The context to set.
	 */
	void setContext( context ) {
		_context = context;
	}

	/**
	 * Frees all internal resources and stops the animation loop.
	 */
	void dispose() {
		stop();
	}

}
