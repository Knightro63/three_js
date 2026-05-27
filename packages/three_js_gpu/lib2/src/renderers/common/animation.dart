import 'package:web/web.dart' as web;

/// This module manages the internal animation loop of the renderer.
class Animation {
  /// A reference to the main renderer.
  final dynamic renderer;

  /// Renderer component for managing nodes related logic.
  final dynamic nodes;

  /// Renderer component for managing metrics and monitoring data.
  final dynamic info;

  /// A reference to the context from which frame updates are requested (usually window).
  dynamic _context;

  /// The user-defined animation loop callback.
  Function(double time, dynamic xrFrame)? _animationLoop;

  /// The requestId which is returned from the animation frame system.
  int? _requestId;

  /// Constructs a new animation loop management component.
  Animation(this.renderer, this.nodes, this.info) {
    this._animationLoop = null;
    this._requestId = null;
    
    try {
      // Modern package:web global window context hook alignment
      this._context = web.window;
    } catch (_) {
      this._context = null;
    }
  }

  /// Starts the internal animation loop.
  void start() {
    // Prevent starting overlapping duplicate scheduler threads if already cycling
    if (this._requestId != null) return;

    void update(num highResTime) {
      if (this._context == null) return;

      final double time = highResTime.toDouble();
      
      // Extract active WebXR frame tokens from your underlying XR state manager layout
      final dynamic xrFrame = this.renderer.xr?.getFrame();

      // Recurse frame loop notifications on next paint boundary refresh cycle
      this._requestId = (this._context as dynamic).requestAnimationFrame(
        web.FrameRequestCallback(update)
      );

      if (this.info.autoReset == true) {
        this.info.reset();
      }

      this.nodes.nodeFrame.update();
      this.info.frame = this.nodes.nodeFrame.frameId;

      this.renderer.inspector?.begin();
      
      if (this._animationLoop != null) {
        this._animationLoop!(time, xrFrame);
      }
      
      this.renderer.inspector?.finish();
    }

    // Initiate the first procedural animation tick step execution
    if (this._context != null) {
      this._requestId = (this._context as dynamic).requestAnimationFrame(
        web.FrameRequestCallback(update)
      );
    }
  }

  /// Stops the internal animation loop framework tickers.
  void stop() {
    if (this._context != null && this._requestId != null) {
      (this._context as dynamic).cancelAnimationFrame(this._requestId!);
    }
    this._requestId = null;
  }

  /// Returns the user-level animation loop callback structure.
  Function(double time, dynamic xrFrame)? getAnimationLoop() {
    return this._animationLoop;
  }

  /// Defines the user-level animation loop.
  /// 
  /// [callback] - The animation loop callback.
  void setAnimationLoop(Function(double time, dynamic xrFrame)? callback) {
    this._animationLoop = callback;
  }

  /// Returns the current execution tracking context animation container layer.
  dynamic getContext() {
    return this._context;
  }

  /// Defines the context in which frame updates are executed.
  /// 
  /// [context] - The execution window or XRSession environment target block.
  void setContext(dynamic context) {
    this._context = context;
  }

  /// Frees all internal updates scheduler loops resources and stops execution threads.
  void dispose() {
    this.stop();
  }
}
