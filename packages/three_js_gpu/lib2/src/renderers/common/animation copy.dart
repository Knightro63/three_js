
import 'info.dart';
import 'nodes/nodes.dart';

/// This module manages the internal animation loop of the renderer.
///
class Animation {
  Nodes nodes;
  Info info;
  Function? _animationLoop;
  int? _requestId;
  XRSession? _context;

	/// Constructs a new animation loop management component.
	///
	Animation(this.nodes, this.info );

	/// Starts the internal animation loop.
	///
	void start() {
		update();
	}

  void update([double? time, double? xrFrame]) {
    _requestId = _context.requestAnimationFrame( update );
    if ( info.autoReset == true ) info.reset();
    nodes.nodeFrame.update();
    info.frame = nodes.nodeFrame.frameId;
    _animationLoop?.call( time, xrFrame );
  }

	///
	/// Stops the internal animation loop.
	///
	void stop() {
		_context.cancelAnimationFrame( _requestId );
		_requestId = null;
	}

	/// Returns the user-level animation loop.
	///
	Function? getAnimationLoop() {
		return _animationLoop;
	}

	/// Defines the user-level animation loop.
	///
	void setAnimationLoop([Function? callback ]) {
		_animationLoop = callback;
	}

	/// Returns the animation context.
	///
	/// @return {Window|XRSession} The animation context.
	///
	getContext() {
		return _context;
	}

	/// Defines the context in which `requestAnimationFrame()` is executed.
	///
	/// @param {Window|XRSession} context - The context to set.
	///
	void setContext( context ) {
		_context = context;
	}

	/// Frees all internal resources and stops the animation loop.
	///
	void dispose() {
		stop();
	}

}
