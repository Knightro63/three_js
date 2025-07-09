import 'dart:js_interop';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/renderers/webgl/index.dart';
import '../../app/web/xr_webgl_bindings.dart';
import 'web_xr_controller.dart';
import 'web_xr_depth_sensing.dart';

class WebXRWorker extends WebXRManager{
  late final WebGLState state;
  final WebXRDepthSensing depthSensing = WebXRDepthSensing();
  late final ArrayCamera cameraXR = ArrayCamera([]);
  
  XRSession? session;
  double framebufferScaleFactor = 1.0;

  XRReferenceSpace? referenceSpace;
  var onAnimationFrameCallback;
  String referenceSpaceType = 'local-floor';

  XRViewerPose? pose;
  XRWebGLBinding? glBinding;
  Framebuffer? glFramebuffer;
  XRProjetionLayer? glProjLayer;
  XRWebGLLayer? glBaseLayer;
  bool isMultisample = false;
  Framebuffer? glMultisampledFramebuffer;
  Renderbuffer? glColorRenderbuffer;
  Renderbuffer? glDepthRenderbuffer;
  XRFrame? xrFrame;
  int depthStyle = 0;
  int clearStyle = 0;

  final List<WebXRController> controllers = [];
  final Map<XRInputSource,WebXRController> inputSourcesMap = {};

  double? _currentDepthNear;
  double? _currentDepthFar;

  final WebGLAnimation animation = WebGLAnimation();
  late final ArrayCamera cameraVR;
  final PerspectiveCamera cameraL = PerspectiveCamera();
  final PerspectiveCamera cameraR = PerspectiveCamera();

  late final List<Camera> cameras;

  WebXRWorker(super.renderer, super.gl){
    cameras = [cameraL,cameraR];
  }

  @override
  void init(){
  // final scope = this;
    state = renderer.state;
    cameraL.layers.enable( 1 );
    cameraL.viewport = Vector4.zero();

    cameraR.layers.enable( 2 );
    cameraR.viewport = Vector4.zero();

    cameraVR = ArrayCamera([ cameraL, cameraR ]);
    
    cameraVR.layers.enable( 1 );
    cameraVR.layers.enable( 2 );

    animation.setAnimationLoop( onAnimationFrame );
  }

  ///
  /// Returns a group representing the `target ray` space of the XR controller.
  /// Use this space for visualizing 3D objects that support the user in pointing
  /// tasks like UI interaction.
  ///
  /// @param {number} index - The index of the controller.
  /// @return {Group} A group representing the `target ray` space.
  ////
  WebXRController? getController (int index ) {
    WebXRController? controller = _getController( index );
    return controller?.getTargetRaySpace();
  }

  ///
  /// Returns a group representing the `grip` space of the XR controller.
  /// Use this space for visualizing 3D objects that support the user in pointing
  /// tasks like UI interaction.
  ///
  /// Note: If you want to show something in the user's hand AND offer a
  /// pointing ray at the same time, you'll want to attached the handheld object
  /// to the group returned by `getControllerGrip()` and the ray to the
  /// group returned by `getController()`. The idea is to have two
  /// different groups in two different coordinate spaces for the same WebXR
  /// controller.
  ///
  /// @param {number} index - The index of the controller.
  /// @return {Group} A group representing the `grip` space.
  ////
  WebXRController? getControllerGrip(int index ) {
    WebXRController? controller = _getController( index );
    return controller?.getGripSpace();
  }

  ///
  /// Returns a group representing the `hand` space of the XR controller.
  /// Use this space for visualizing 3D objects that support the user in pointing
  /// tasks like UI interaction.
  ///
  /// @param {number} index - The index of the controller.
  /// @return {Group} A group representing the `hand` space.
  ////
  WebXRController? getHand(int index ) {
    WebXRController? controller = _getController( index );
    return controller?.getHandSpace();
  }

	///
	/// Returns a WebXR controller for the given controller index.
	///
	/// @private
	/// @param {number} index - The controller index.
	/// @return {WebXRController} The XR controller.
	///
	WebXRController? _getController(int index ) {
    late WebXRController? controller;

    if(controllers.isEmpty || controllers.length <= index) {
      controller = WebXRController();
      controllers.add(controller);
    }
    else{
      controller = controllers[index];
    }

		return controller;
	}

  void onSessionEvent(Event event ) {
    final WebXRController? controller = inputSourcesMap[event.inputSource];
    if(controller != null) {
      controller.dispatchEvent(Event(type: event.type, data: event.inputSource));
    }
  }

  void onSessionEnd() {
    inputSourcesMap.forEach((inputSource,controller) {
      controller.disconnect(controller);
    });

    inputSourcesMap.clear();

    _currentDepthNear = null;
    _currentDepthFar = null;

    // restore framebuffer/rendering state

    state.bindXRFramebuffer( null );
    renderer.setRenderTarget( renderer.getRenderTarget() );

    if ( glFramebuffer != null) gl.deleteFramebuffer( glFramebuffer );
    if ( glMultisampledFramebuffer != null) gl.deleteFramebuffer( glMultisampledFramebuffer );
    if ( glColorRenderbuffer != null) gl.deleteRenderbuffer( glColorRenderbuffer! );
    if ( glDepthRenderbuffer != null) gl.deleteRenderbuffer( glDepthRenderbuffer! );
    glFramebuffer = null;
    glMultisampledFramebuffer = null;
    glColorRenderbuffer = null;
    glDepthRenderbuffer = null;
    glBaseLayer = null;
    glProjLayer = null;
    glBinding = null;
    session = null;

    animation.stop();

    isPresenting = false;
    dispatchEvent(Event(type: 'sessionend'));
  }

  void setFramebufferScaleFactor(double value ) {
    framebufferScaleFactor = value;
    if (isPresenting == true ) {
      console.warning( 'WebXRManager: Cannot change framebuffer scale while presenting.' );
    }
  }

  void setReferenceSpaceType(String value ) {
    referenceSpaceType = value;
    if (isPresenting == true ) {
      console.warning( 'three.WebXRManager: Cannot change reference space type while presenting.' );
    }
  }

  XRReferenceSpace? getReferenceSpace () {
    return referenceSpace;
  }

  getBaseLayer () {
    return glProjLayer ?? glBaseLayer;
  }

  XRWebGLBinding? getBinding () {
    return glBinding;
  }

  XRFrame? getFrame () {
    return xrFrame;
  }

  XRSession? getSession () {
    return session;
  }

  Future<void> setSession (XRSession? value ) async{
    session = value;

    if ( session != null ) {
      session?.addEventListener( 'select', onSessionEvent.jsify() );
      session?.addEventListener( 'selectstart', onSessionEvent.jsify() );
      session?.addEventListener( 'selectend', onSessionEvent.jsify() );
      session?.addEventListener( 'squeeze', onSessionEvent.jsify() );
      session?.addEventListener( 'squeezestart', onSessionEvent.jsify() );
      session?.addEventListener( 'squeezeend', onSessionEvent.jsify() );
      session?.addEventListener( 'end', onSessionEnd.jsify() );
      session?.addEventListener( 'inputsourceschange', onInputSourcesChange.jsify() );

      final attributes = (gl.getContextAttributes() as JSAny).dartify() as Map;
      if ( attributes['xrCompatible'] != true ) {
        await gl.makeXRCompatible();
      }

      if ( session?.renderState.layers == null ) {
        final layerInit = {
          'antialias': attributes['antialias'],
          'alpha': attributes['alpha'],
          'depth': attributes['depth'],
          'stencil': attributes['stencil'],
          'framebufferScaleFactor': framebufferScaleFactor
        };

        glBaseLayer = XRWebGLLayer( session!, gl.gl.gl, layerInit.jsify() );

        session?.updateRenderState( {'baseLayer': glBaseLayer }.jsify() );

      }
      else {
        isMultisample = attributes['antialias'];
        dynamic depthFormat;

        if (attributes['depth'] != null) {
          clearStyle = WebGL.DEPTH_BUFFER_BIT;
          if ( attributes['stencil'] != null) clearStyle |= WebGL.STENCIL_BUFFER_BIT;
          depthStyle = attributes['stencil'] != null? WebGL.DEPTH_STENCIL_ATTACHMENT : WebGL.DEPTH_ATTACHMENT;
          depthFormat = attributes['stencil'] != null? WebGL.DEPTH24_STENCIL8 : WebGL.DEPTH_COMPONENT24;
        }

        final projectionlayerInit = {
          'colorFormat': attributes['alpha'] ? WebGL.RGBA8 : WebGL.RGB8,
          'depthFormat': depthFormat,
          'scaleFactor': framebufferScaleFactor
        };

        glBinding = XRWebGLBinding( session!, gl.gl.gl );
        glProjLayer = glBinding?.createProjectionLayer( projectionlayerInit.jsify() );
        glFramebuffer = gl.createFramebuffer();

        session?.updateRenderState( { 'layers': [ glProjLayer ] }.jsify() );

        if ( isMultisample ) {
          glMultisampledFramebuffer = gl.createFramebuffer();
          glColorRenderbuffer = gl.createRenderbuffer();
          gl.bindRenderbuffer( WebGL.RENDERBUFFER, glColorRenderbuffer );
          gl.renderbufferStorageMultisample(
            WebGL.RENDERBUFFER,
            4,
            WebGL.RGBA8,
            glProjLayer!.textureWidth,
            glProjLayer!.textureHeight 
          );
          state.bindFramebuffer( WebGL.FRAMEBUFFER, glMultisampledFramebuffer );
          gl.framebufferRenderbuffer( WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.RENDERBUFFER, glColorRenderbuffer );
          gl.bindRenderbuffer( WebGL.RENDERBUFFER, null );

          if ( depthFormat != null ) {
            glDepthRenderbuffer = gl.createRenderbuffer();
            gl.bindRenderbuffer( WebGL.RENDERBUFFER, glDepthRenderbuffer );
            gl.renderbufferStorageMultisample( WebGL.RENDERBUFFER, 4, depthFormat, glProjLayer!.textureWidth, glProjLayer!.textureHeight );
            gl.framebufferRenderbuffer( WebGL.FRAMEBUFFER, depthStyle, WebGL.RENDERBUFFER, glDepthRenderbuffer );
            gl.bindRenderbuffer( WebGL.RENDERBUFFER, null );
          }

          state.bindFramebuffer( WebGL.FRAMEBUFFER, null );
        }
      }

      referenceSpace = (await (session?.requestReferenceSpace( referenceSpaceType ).toDart)) as XRReferenceSpace;

      animation.setContext( session );
      animation.start();

      isPresenting = true;
      dispatchEvent( Event(type: 'sessionstart' ) );
    }
  }

  void onInputSourcesChange(Event event ) {
    final inputSources = session!.inputSources!.toDart;

    // Assign inputSources to available controllers
    for (int i = 0; i < controllers.length; i ++ ) {
      inputSourcesMap[inputSources[ i ]] =  controllers[ i ];
    }

    // Notify disconnected
    for (int i = 0; i < event.removed.length; i ++ ) {
      final inputSource = event.removed[ i ];
      final controller = inputSourcesMap[inputSource];
      if ( controller != null) {
        controller.dispatchEvent(Event(type: 'disconnected', data: inputSource));
        inputSourcesMap.remove( inputSource );
      }
    }

    // Notify connected
    for (int i = 0; i < event.added.length; i ++ ) {
      final inputSource = event.added[ i ];
      final controller = inputSourcesMap[inputSource];
      if ( controller != null) {
        controller.dispatchEvent( Event(type: 'connected', data: inputSource));
      }
    }
  }

  //

  final cameraLPos = Vector3.zero();
  final cameraRPos = Vector3.zero();

  /// Assumes 2 cameras that are parallel and share an X-axis, and that
  /// the cameras' projection and world matrices have already been set.
  /// And that near and far planes are identical for both cameras.
  /// Visualization of this technique: https://computergraphics.stackexchange.com/a/4765
  void setProjectionFromUnion(Camera camera, PerspectiveCamera cameraL, PerspectiveCamera cameraR ) {
    cameraLPos.setFromMatrixPosition( cameraL.matrixWorld );
    cameraRPos.setFromMatrixPosition( cameraR.matrixWorld );

    final ipd = cameraLPos.distanceTo( cameraRPos );

    final projL = cameraL.projectionMatrix.storage;
    final projR = cameraR.projectionMatrix.storage;

    // VR systems will have identical far and near planes, and
    // most likely identical top and bottom frustum extents.
    // Use the left camera for these values.
    final near = projL[ 14 ] / ( projL[ 10 ] - 1 );
    final far = projL[ 14 ] / ( projL[ 10 ] + 1 );
    final topFov = ( projL[ 9 ] + 1 ) / projL[ 5 ];
    final bottomFov = ( projL[ 9 ] - 1 ) / projL[ 5 ];

    final leftFov = ( projL[ 8 ] - 1 ) / projL[ 0 ];
    final rightFov = ( projR[ 8 ] + 1 ) / projR[ 0 ];
    final left = near * leftFov;
    final right = near * rightFov;

    // Calculate the camera's position offset from the
    // left camera. xOffset should be roughly half `ipd`.
    final zOffset = ipd / ( - leftFov + rightFov );
    final xOffset = zOffset * - leftFov;

    // TODO: Better way to apply this offset?
    cameraL.matrixWorld.decompose( camera.position, camera.quaternion, camera.scale );
    camera.translateX( xOffset );
    camera.translateZ( zOffset );
    camera.matrixWorld.compose( camera.position, camera.quaternion, camera.scale );
    camera.matrixWorldInverse.setFrom( camera.matrixWorld ).invert();

    // Find the union of the frustum values of the cameras and scale
    // the values so that the near plane's position does not change in world space,
    // although must now be relative to the union camera.
    final near2 = near + zOffset;
    final far2 = far + zOffset;
    final left2 = left - xOffset;
    final right2 = right + ( ipd - xOffset );
    final top2 = topFov * far / far2 * near2;
    final bottom2 = bottomFov * far / far2 * near2;

    camera.projectionMatrix.makePerspective( left2, right2, top2, bottom2, near2, far2 );
  }

  void _updateCamera(Camera camera, Object3D? parent ) {
    if ( parent == null ) {
      camera.matrixWorld.setFrom( camera.matrix );
    } else {
      camera.matrixWorld.multiply2( parent.matrixWorld, camera.matrix );
    }
    camera.matrixWorldInverse.setFrom( camera.matrixWorld ).invert();
  }

  @override
  void updateCamera(Camera camera ) {
    if ( session == null ) return;
    cameraVR.near = cameraR.near = cameraL.near = camera.near;
    cameraVR.far = cameraR.far = cameraL.far = camera.far;

    if ( _currentDepthNear != cameraVR.near || _currentDepthFar != cameraVR.far ) {
      // Note that the renderState won't apply until the next frame. See #18320
      session?.updateRenderState( {
        'depthNear': cameraVR.near,
        'depthFar': cameraVR.far
      }.jsify() );

      _currentDepthNear = cameraVR.near;
      _currentDepthFar = cameraVR.far;
    }

    final parent = camera.parent;
    final cameras = cameraVR.cameras;

    _updateCamera( cameraVR, parent );

    for (int i = 0; i < cameras.length; i ++ ) {
      _updateCamera( cameras[ i ], parent );
    }

    cameraVR.matrixWorld.decompose( cameraVR.position, cameraVR.quaternion, cameraVR.scale );

    // update user camera and its children

    camera.position.setFrom( cameraVR.position );
    camera.quaternion.setFrom( cameraVR.quaternion );
    camera.scale.setFrom( cameraVR.scale );
    camera.matrix.setFrom( cameraVR.matrix );
    camera.matrixWorld.setFrom( cameraVR.matrixWorld );

    final children = camera.children;

    for (int i = 0, l = children.length; i < l; i ++ ) {
      children[ i ].updateMatrixWorld( true );
    }

    // update projection matrix for proper view frustum culling
    if ( cameras.length == 2 ) {
      setProjectionFromUnion( cameraVR, cameraL, cameraR );
    } 
    else {
      cameraVR.projectionMatrix.setFrom( cameraL.projectionMatrix );
    }
  }

  @override
  ArrayCamera getCamera() {
    return cameraVR;
  }

  double? getFoveation () {
    if ( glProjLayer != null ) {
      return glProjLayer?.fixedFoveation;
    }

    if ( glBaseLayer != null ) {
      return glBaseLayer?.fixedFoveation;
    }

    return null;
  }

  void setFoveation(double foveation ) {
    // 0 = no foveation = full resolution
    // 1 = maximum foveation = the edges render at lower resolution

    if ( glProjLayer != null ) {
      glProjLayer?.fixedFoveation = foveation;
    }

    if ( glBaseLayer != null && glBaseLayer?.fixedFoveation != null ) {
      glBaseLayer?.fixedFoveation = foveation;
    }
  }

  @override
  String? getEnvironmentBlendMode () {
    if ( session != null ) {
      return session?.environmentBlendMode;
    }

    return null;
  }

  @override
  bool hasDepthSensing () {
    return depthSensing.texture != null;
  }

  @override
  Mesh? getDepthSensingMesh() {
    return depthSensing.getMesh( cameraXR );
  }

  // Animation Loop
  void onAnimationFrame(double time, XRFrame frame ) {
    pose = frame.getViewerPose( referenceSpace! );
    xrFrame = frame;

    if ( pose != null ) {
      final views = pose!.views;
      if ( glBaseLayer != null ) {
        state.bindXRFramebuffer( Framebuffer(glBaseLayer!.framebuffer) );
      }

      bool cameraVRNeedsUpdate = false;

      // check if it's necessary to rebuild cameraVR's camera list
      if ( views.length != cameraVR.cameras.length ) {
        cameraVR.cameras.length = 0;
        cameraVRNeedsUpdate = true;
      }

      for (int i = 0; i < views.length; i ++ ) {
        final view = views[ i ];
        XRViewport? viewport;

        if ( glBaseLayer != null ) {
          viewport = glBaseLayer?.getViewport( view );
        } 
        else {
          final glSubImage = glBinding?.getViewSubImage( glProjLayer!, view );
          state.bindXRFramebuffer( glFramebuffer );

          if ( glSubImage?.depthStencilTexture != null ) {
            gl.framebufferTexture2D( 
              WebGL.FRAMEBUFFER, 
              depthStyle, 
              WebGL.TEXTURE_2D, 
              WebGLTexture(glSubImage!.depthStencilTexture), 
              0 
            );
          }

          gl.framebufferTexture2D( 
            WebGL.FRAMEBUFFER, 
            WebGL.COLOR_ATTACHMENT0, 
            WebGL.TEXTURE_2D, 
            WebGLTexture(glSubImage!.colorTexture), 
            0 
          );
          viewport = glSubImage.viewport;
        }
        
        final camera = cameras[ i ];
        camera.matrix.copyFromUnknown( view.transform.matrix.dartify());
        camera.projectionMatrix.copyFromUnknown( view.projectionMatrix.dartify()  );
        camera.viewport?.setValues( viewport!.x, viewport.y, viewport.width, viewport.height);

        if ( i == 0 ) {
          cameraVR.matrix.setFrom( camera.matrix );
        }

        if ( cameraVRNeedsUpdate == true ) {
          cameraVR.cameras.add( camera );
        }
      }

      if ( isMultisample ) {
        state.bindXRFramebuffer( glMultisampledFramebuffer );
        if ( clearStyle != 0) gl.clear( clearStyle );
      }
    }

    //
    final inputSources = session!.inputSources!.toDart;

    for (int i = 0; i < controllers.length; i ++ ) {
      final controller = controllers[ i ];
      final inputSource = inputSources.isNotEmpty?inputSources[ i ]:null;
      if ( inputSource != null) {
        controller.update( inputSource, frame, referenceSpace! );
      }
    }

    if ( onAnimationFrameCallback != null) onAnimationFrameCallback( time, frame );

    if ( isMultisample ) {
      final width = glProjLayer!.textureWidth;
      final height = glProjLayer!.textureHeight;

      state.bindFramebuffer( WebGL.READ_FRAMEBUFFER, glMultisampledFramebuffer );
      state.bindFramebuffer( WebGL.DRAW_FRAMEBUFFER, glFramebuffer );
      // Invalidate the depth here to avoid flush of the depth data to main memory.
      gl.invalidateFramebuffer( WebGL.READ_FRAMEBUFFER, [ depthStyle ] );
      gl.invalidateFramebuffer( WebGL.DRAW_FRAMEBUFFER, [ depthStyle ] );
      gl.blitFramebuffer( 0, 0, width, height, 0, 0, width, height, WebGL.COLOR_BUFFER_BIT, WebGL.NEAREST );
      // Invalidate the MSAA buffer because it's not needed anymore.
      gl.invalidateFramebuffer( WebGL.READ_FRAMEBUFFER, [ WebGL.COLOR_ATTACHMENT0 ] );
      state.bindFramebuffer( WebGL.READ_FRAMEBUFFER, null );
      state.bindFramebuffer( WebGL.DRAW_FRAMEBUFFER, null );

      state.bindFramebuffer( WebGL.FRAMEBUFFER, glMultisampledFramebuffer );
    }

    xrFrame = null;
  }

  @override
  void setAnimationLoop ( callback ) {
    onAnimationFrameCallback = callback;
  }

  @override
  void dispose(){}
}
