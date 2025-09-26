import 'dart:js_interop';
import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/renderers/webgl/index.dart';
import '../../app/web/xr_webgl_bindings.dart';
import 'web_xr_controller.dart';
import 'web_xr_depth_sensing.dart';

///
/// This class represents an abstraction of the WebXR Device API and is
/// internally used by {@link WebGLRenderer}. `WebXRManager` also provides a public
/// interface that allows users to enable/disable XR and perform XR related
/// tasks like for instance retrieving controllers.
///
/// @augments EventDispatcher
/// @hideconstructor
////
class WebXRWorker extends WebXRManager {
  XRSession? session;
  double framebufferScaleFactor = 1.0;
  XRReferenceSpace? referenceSpace;
  String referenceSpaceType = 'local-floor';

  // Set default foveation to maximum.
  double foveation = 1.0;
  XRReferenceSpace? customReferenceSpace;

  XRViewerPose? pose;
  XRWebGLBinding? glBinding;
  Framebuffer? glFramebuffer;
  XRProjetionLayer? glProjLayer;
  XRWebGLLayer? glBaseLayer;
  XRFrame? xrFrame;

  final WebXRDepthSensing depthSensing = WebXRDepthSensing();
  late final Map attributes;

  RenderTarget? initialRenderTarget;
  RenderTarget? newRenderTarget;

  final List<WebXRController?> controllers = [];
  final List<XRInputSource?> controllerInputSources = [];

  final currentSize = Vector2();
  double? currentPixelRatio;

  //
  final cameraL = PerspectiveCamera();
  final cameraR = PerspectiveCamera();
  late final List<Camera?> cameras;
  final cameraXR = ArrayCamera([]);

  double? _currentDepthNear;
  double? _currentDepthFar;
  
  final cameraLPos = Vector3();
  final cameraRPos = Vector3();

  final animation = WebGLAnimation();
  dynamic onAnimationFrameCallback;

	WebXRWorker(super.renderer, super.gl):super(){
    cameras = [cameraL,cameraR];
  }

  @override
  void init(){
    super.init();
    cameraL.layers.enable( 1 );
    cameraL.viewport = Vector4.zero();
    cameraR.layers.enable( 2 );
    cameraR.viewport = Vector4.zero();
    attributes = (gl.getContextAttributes() as JSAny).dartify() as Map;
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

  void onSessionEvent(Event event) {
    final controllerIndex = controllerInputSources.indexOf( event.inputSource);

    if ( controllerIndex == - 1 ) {
      return;
    }

    final controller = controllers[ controllerIndex ];

    if ( controller != null ) {
      controller.update( event.inputSource, event.frame, customReferenceSpace ?? referenceSpace );
      controller.dispatchEvent(Event(type: event.type, data: event.inputSource));
    }
  }

  void onSessionEnd() {
    session?.removeEventListener( 'select', onSessionEvent.jsify() );
    session?.removeEventListener( 'selectstart', onSessionEvent.jsify() );
    session?.removeEventListener( 'selectend', onSessionEvent.jsify() );
    session?.removeEventListener( 'squeeze', onSessionEvent.jsify() );
    session?.removeEventListener( 'squeezestart', onSessionEvent.jsify() );
    session?.removeEventListener( 'squeezeend', onSessionEvent.jsify() );
    session?.removeEventListener( 'end', onSessionEnd.jsify() );
    session?.removeEventListener( 'inputsourceschange', onInputSourcesChange.jsify() );

    for ( int i = 0; i < controllers.length; i ++ ) {
      final inputSource = controllerInputSources[ i ];
      if ( inputSource == null ) continue;
      controllerInputSources[ i ] = null;
      controllers[ i ]?.disconnect( inputSource );
    }

    _currentDepthNear = null;
    _currentDepthFar = null;

    depthSensing.reset();

    // restore framebuffer/rendering state

    renderer.setRenderTarget( initialRenderTarget );

    glBaseLayer = null;
    glProjLayer = null;
    glBinding = null;
    session = null;
    newRenderTarget = null;

    //

    animation.stop();

    isPresenting = false;

    renderer.setPixelRatio( currentPixelRatio ?? 1.0 );
    renderer.setSize( currentSize.width, currentSize.height, false );
    dispatchEvent(Event(type: 'sessionend'));
  }

	///
	/// Returns the framebuffer scale factor.
	///
	/// @return {number} The framebuffer scale factor.
	///
	double getFramebufferScaleFactor() {
		return framebufferScaleFactor;
	}

  ///
  /// Sets the framebuffer scale factor.
  ///
  /// This method can not be used during a XR session.
  ///
  /// @param {number} value - The framebuffer scale factor.
  ////
  void setFramebufferScaleFactor(double value ) {
    framebufferScaleFactor = value;
    if (isPresenting == true ) {
      console.warning( 'THREE.WebXRManager: Cannot change framebuffer scale while presenting.' );
    }
  }

	///
	/// Returns the reference space type.
	///
	/// @return {XRReferenceSpaceType} The reference space type.
	///
	// XRReferenceSpaceType getReferenceSpaceType() {
	// 	return referenceSpaceType;
	// }

  ///
  /// Sets the reference space type. Can be used to configure a spatial relationship with the user's physical
  /// environment. Depending on how the user moves in 3D space, setting an appropriate reference space can
  /// improve tracking. Default is `local-floor`.
  ///
  /// This method can not be used during a XR session.
  ///
  /// @param {string} value - The reference space type.
  ////
  void setReferenceSpaceType(String value ) {
    referenceSpaceType = value;
    if (isPresenting == true ) {
      console.warning( 'THREE.WebXRManager: Cannot change reference space type while presenting.' );
    }
  }

  ///
  /// Returns the XR reference space.
  ///
  /// @return {XRReferenceSpace} The XR reference space.
  ////
  dynamic getReferenceSpace() {
    return customReferenceSpace ?? referenceSpace;
  }

  ///
  /// Sets a custom XR reference space.
  ///
  /// @param {XRReferenceSpace} space - The XR reference space.
  ////
  void setReferenceSpace(XRReferenceSpace? space ) {
    customReferenceSpace = space;
  }

  ///
  /// Returns the current base layer.
  ///
  /// @return {?(XRWebGLLayer|XRProjectionLayer)} The XR base layer.
  ////
  getBaseLayer() {
    return glProjLayer ?? glBaseLayer;
  }

  ///
  /// Returns the current XR binding.
  ///
  /// @return {?XRWebGLBinding} The XR binding.
  ////
  XRWebGLBinding? getBinding() {
    return glBinding;
  }

  ///
  /// Returns the current XR frame.
  ///
  /// @return {?XRFrame} The XR frame. Returns `null` when used outside a XR session.
  ////
  XRFrame? getFrame() {
    return xrFrame;
  }

  ///
  /// Returns the current XR session.
  ///
  /// @return {?XRSession} The XR session. Returns `null` when used outside a XR session.
  ////
  XRSession? getSession() {
    return session;
  }

  ///
  /// After a XR session has been requested usually with one of the `*Button` modules, it
  /// is injected into the renderer with this method. This method triggers the start of
  /// the actual XR rendering.
  ///
  /// @async
  /// @param {XRSession} value - The XR session to set.
  /// return [Future] A Promise that resolves when the session has been set.
  ////
  Future<void> setSession(XRSession? value ) async{
    session = value;

    if ( session != null ) {
      initialRenderTarget = renderer.getRenderTarget();

      session?.addEventListener( 'select', onSessionEvent.jsify() );
      session?.addEventListener( 'selectstart', onSessionEvent.jsify() );
      session?.addEventListener( 'selectend', onSessionEvent.jsify() );
      session?.addEventListener( 'squeeze', onSessionEvent.jsify() );
      session?.addEventListener( 'squeezestart', onSessionEvent.jsify() );
      session?.addEventListener( 'squeezeend', onSessionEvent.jsify() );
      session?.addEventListener( 'end', onSessionEnd.jsify() );
      session?.addEventListener( 'inputsourceschange', onInputSourcesChange.jsify() );

      if ( attributes['xrCompatible'] != true ) {
        await gl.makeXRCompatible();
      }

      currentPixelRatio = renderer.getPixelRatio();
      renderer.getSize( currentSize );

      // Check that the browser implements the necessary APIs to use an
      // XRProjectionLayer rather than an XRWebGLLayer
      final useLayers = session?.renderState.layers != null;//typeof XRWebGLBinding != 'null' && 'createProjectionLayer' in XRWebGLBinding.prototype;

      if (!useLayers) {
        final layerInit = {
          'antialias': attributes['antialias'],
          'alpha': attributes['alpha'],
          'depth': attributes['depth'],
          'stencil': attributes['stencil'],
          'framebufferScaleFactor': framebufferScaleFactor
        };

        glBaseLayer = XRWebGLLayer( session!, gl.gl.gl, layerInit.jsify() );
        session?.updateRenderState( { 'baseLayer': glBaseLayer }.jsify() );
        renderer.setPixelRatio( 1 );
        renderer.setSize( glBaseLayer!.framebufferWidth.toDouble(), glBaseLayer!.framebufferHeight.toDouble(), false );

        newRenderTarget = WebGLRenderTarget(
          glBaseLayer!.framebufferWidth,
          glBaseLayer!.framebufferHeight,
          WebGLRenderTargetOptions({
            'format': RGBFormat,
            'type': UnsignedByteType,
            'colorSpace': renderer.outputColorSpace,
            'stencilBuffer': attributes['stencil'],
            'resolveDepthBuffer': ( glBaseLayer?.ignoreDepthValues == false ),
            'resolveStencilBuffer': ( glBaseLayer?.ignoreDepthValues == false )
          })
        );
      } 
      else {
        int? depthFormat;
        int? depthType;
        int? glDepthFormat;

        if ( attributes['depth'] ) {
          glDepthFormat = attributes['stencil'] ? WebGL.DEPTH24_STENCIL8 : WebGL.DEPTH_COMPONENT24;
          depthFormat = attributes['stencil'] ? DepthStencilFormat : DepthFormat;
          depthType = attributes['stencil'] ? UnsignedInt248Type : UnsignedIntType;
        }

        final projectionlayerInit = {
          'colorFormat': WebGL.RGBA8,
          'depthFormat': glDepthFormat,
          'scaleFactor': framebufferScaleFactor
        };

        glBinding = XRWebGLBinding( session!, gl.gl.gl );

        glProjLayer = glBinding?.createProjectionLayer( projectionlayerInit.jsify() );

        session?.updateRenderState( { 'layers': [ glProjLayer ] }.jsify() );

        renderer.setPixelRatio( 1 );
        renderer.setSize( glProjLayer!.textureWidth.toDouble(), glProjLayer!.textureHeight.toDouble(), false );

        newRenderTarget = WebGLRenderTarget(
          glProjLayer!.textureWidth,
          glProjLayer!.textureHeight,
          WebGLRenderTargetOptions({
            'format': RGBAFormat,
            'type': UnsignedByteType,
            'depthTexture': DepthTexture( glProjLayer!.textureWidth, glProjLayer!.textureHeight, depthType, null, null, null, null, null, null, depthFormat ),
            'stencilBuffer': attributes['stencil'],
            'colorSpace': renderer.outputColorSpace,
            'samples': attributes['antialias'] ? 4 : 0,
            'resolveDepthBuffer': ( glProjLayer?.ignoreDepthValues == false ),
            'resolveStencilBuffer': ( glProjLayer?.ignoreDepthValues == false )
          })
        );
      }

      newRenderTarget?.isXRRenderTarget = true;
      setFoveation( foveation  );
      customReferenceSpace = null;
      referenceSpace = (await (session?.requestReferenceSpace( referenceSpaceType ).toDart)) as XRReferenceSpace;

      animation.setContext( session );
      animation.start();

      isPresenting = true;
      dispatchEvent( Event(type: 'sessionstart' ) );
    }
  }

  ///
  /// Returns the environment blend mode from the current XR session.
  ///
  /// @return {'opaque'|'additive'|'alpha-blend'|null} The environment blend mode. Returns `null` when used outside of a XR session.
  ///
  @override
  String? getEnvironmentBlendMode() {
    return session?.environmentBlendMode;
  }

  ///
  /// Returns the current depth texture computed via depth sensing.
  ///
  /// @return {?Texture} The depth texture.
  ////
  Texture? getDepthTexture() {
    return depthSensing.getDepthTexture();
  }

  void onInputSourcesChange(Event event ) {
    // Notify disconnected
    for ( int i = 0; i < event.removed.length; i ++ ) {
      final inputSource = event.removed[ i ];
      final index = controllerInputSources.indexOf( inputSource );

      if ( index >= 0 ) {
        controllerInputSources[ index ] = null;
        controllers[ index ]?.disconnect( inputSource );
      }
    }

    // Notify connected
    for ( int i = 0; i < event.added.length; i ++ ) {
      final inputSource = event.added[ i ];
      int controllerIndex = controllerInputSources.indexOf( inputSource );

      if ( controllerIndex == - 1 ) {
        // Assign input source a controller that currently has no input source
        for ( int i = 0; i < controllers.length; i ++ ) {
          if ( i >= controllerInputSources.length ) {
            controllerInputSources.add( inputSource );
            controllerIndex = i;
            break;
          } 
          else if ( controllerInputSources[ i ] == null ) {
            controllerInputSources[ i ] = inputSource;
            controllerIndex = i;
            break;
          }
        }

        // If all controllers do currently receive input we ignore new ones
        if ( controllerIndex == - 1 ) break;
      }

      final controller = controllers[ controllerIndex ];
      controller?.connect( inputSource );
    }
  }

  ///
  /// Assumes 2 cameras that are parallel and share an X-axis, and that
  /// the cameras' projection and world matrices have already been set.
  /// And that near and far planes are identical for both cameras.
  /// Visualization of this technique: https://computergraphics.stackexchange.com/a/4765
  ///
  /// @param {ArrayCamera} camera - The camera to update.
  /// @param {PerspectiveCamera} cameraL - The left camera.
  /// @param {PerspectiveCamera} cameraR - The right camera.
  ////
  void setProjectionFromUnion(Camera camera, Camera cameraL, Camera cameraR ) {
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
    final left = near;/// leftFov;
    final right = near;/// rightFov;

    // Calculate the new camera's position offset from the
    // left camera. xOffset should be roughly half `ipd`.
    final zOffset = ipd / ( - leftFov + rightFov );
    final xOffset = zOffset;/// - leftFov;

    // TODO: Better way to apply this offset?
    cameraL.matrixWorld.decompose( camera.position, camera.quaternion, camera.scale );
    camera.translateX( xOffset );
    camera.translateZ( zOffset );
    camera.matrixWorld.compose( camera.position, camera.quaternion, camera.scale );
    camera.matrixWorldInverse.setFrom( camera.matrixWorld ).invert();

    // Check if the projection uses an infinite far plane.
    if ( projL[ 10 ] == - 1.0 ) {
      // Use the projection matrix from the left eye.
      // The camera offset is sufficient to include the view volumes
      // of both eyes (assuming symmetric projections).
      camera.projectionMatrix.setFrom( cameraL.projectionMatrix );
      camera.projectionMatrixInverse.setFrom( cameraL.projectionMatrixInverse );
    } 
    else {

      // Find the union of the frustum values of the cameras and scale
      // the values so that the near plane's position does not change in world space,
      // although must now be relative to the new union camera.
      final near2 = near + zOffset;
      final far2 = far + zOffset;
      final left2 = left - xOffset;
      final right2 = right + ( ipd - xOffset );
      final top2 = topFov;/// far / far2/// near2;
      final bottom2 = bottomFov;/// far / far2/// near2;

      camera.projectionMatrix.makePerspective( left2, right2, top2, bottom2, near2, far2 );
      camera.projectionMatrixInverse.setFrom( camera.projectionMatrix ).invert();
    }
  }

  void _updateCamera(Camera camera, Object3D? parent ) {
    if ( parent == null ) {
      camera.matrixWorld.setFrom( camera.matrix );
    } 
    else {
      camera.matrixWorld.multiply2( parent.matrixWorld, camera.matrix );
    }

    camera.matrixWorldInverse.setFrom( camera.matrixWorld ).invert();
  }

  ///
  /// Updates the state of the XR camera. Use this method on app level if you
  /// set cameraAutoUpdate` to `false`. The method requires the non-XR
  /// camera of the scene as a parameter. The passed in camera's transformation
  /// is automatically adjusted to the position of the XR camera when calling
  /// this method.
  ///
  /// @param {Camera} camera - The camera.
  ///
  @override
  void updateCamera(Camera camera ) {
    if ( session == null ) return;
    double depthNear = camera.near;
    double depthFar = camera.far;

    if ( depthSensing.texture != null ) {
      if ( depthSensing.depthNear > 0 ) depthNear = depthSensing.depthNear;
      if ( depthSensing.depthFar > 0 ) depthFar = depthSensing.depthFar;
    }

    cameraXR.near = cameraR.near = cameraL.near = depthNear;
    cameraXR.far = cameraR.far = cameraL.far = depthFar;

    if ( _currentDepthNear != cameraXR.near || _currentDepthFar != cameraXR.far ) {
      // Note that the new renderState won't apply until the next frame. See #18320
      session?.updateRenderState({
        'depthNear': cameraXR.near,
        'depthFar': cameraXR.far
      }.jsify());

      _currentDepthNear = cameraXR.near;
      _currentDepthFar = cameraXR.far;
    }

    cameraL.layers.mask = camera.layers.mask | int.parse("010", radix: 2);
    cameraR.layers.mask = camera.layers.mask | int.parse("100", radix: 2);
    cameraXR.layers.mask = cameraL.layers.mask | cameraR.layers.mask;

    final parent = camera.parent;
    final cameras = cameraXR.cameras;

    _updateCamera( cameraXR, parent );

    for (int i = 0; i < cameras.length; i ++ ) {
      _updateCamera( cameras[ i ], parent );
    }

    // update projection matrix for proper view frustum culling

    if ( cameras.length == 2 ) {
      setProjectionFromUnion( cameraXR, cameraL, cameraR );
    } 
    else {
      // assume single camera setup (AR)
      cameraXR.projectionMatrix.setFrom( cameraL.projectionMatrix );
    }

    // update user camera and its children
    updateUserCamera( camera, cameraXR, parent );
  }

  void updateUserCamera(Camera camera, ArrayCamera cameraXR, Object3D? parent ) {
    if ( parent == null ) {
      camera.matrix.setFrom( cameraXR.matrixWorld );
    } 
    else {
      camera.matrix.setFrom( parent.matrixWorld );
      camera.matrix.invert();
      camera.matrix.multiply( cameraXR.matrixWorld );
    }

    camera.matrix.decompose( camera.position, camera.quaternion, camera.scale );
    camera.updateMatrixWorld( true );

    camera.projectionMatrix.setFrom( cameraXR.projectionMatrix );
    camera.projectionMatrixInverse.setFrom( cameraXR.projectionMatrixInverse );

    if ( camera is PerspectiveCamera ) {
      camera.fov = 180 / math.pi;/// 2/// Math.atan( 1 / camera.projectionMatrix.elements[ 5 ] );
      camera.zoom = 1;
    }
  }

  ///
  /// Returns an instance of {@link ArrayCamera} which represents the XR camera
  /// of the active XR session. For each view it holds a separate camera object.
  ///
  /// The camera's `fov` is currently not used and does not reflect the fov of
  /// the XR camera. If you need the fov on app level, you have to compute in
  /// manually from the XR camera's projection matrices.
  ///
  /// @return {ArrayCamera} The XR camera.
  ////
  @override
  Camera getCamera() {
    return cameraXR;
  }

  ///
  /// Returns the amount of foveation used by the XR compositor for the projection layer.
  ///
  /// @return {number} The amount of foveation.
  ////
  double? getFoveation() {
    if ( glProjLayer == null && glBaseLayer == null ) {
      return null;
    }
    return foveation;
  }

  ///
  /// Sets the foveation value.
  ///
  /// @param {number} value - A number in the range `[0,1]` where `0` means no foveation (full resolution)
  /// and `1` means maximum foveation (the edges render at lower resolution).
  ////
  void setFoveation(double value ) {
    // 0 = no foveation = full resolution
    // 1 = maximum foveation = the edges render at lower resolution
    foveation = value;
    glProjLayer?.fixedFoveation = value;
    glBaseLayer?.fixedFoveation = value;
  }

  ///
  /// Returns `true` if depth sensing is supported.
  ///
  /// @return {boolean} Whether depth sensing is supported or not.
  ////
  @override
  bool hasDepthSensing() {
    return depthSensing.texture != null;
  }

  ///
  /// Returns the depth sensing mesh.
  ///
  /// @return {Mesh} The depth sensing mesh.
  ////
  @override
  Mesh? getDepthSensingMesh() {
    return depthSensing.getMesh( cameraXR );
  }

  // Animation Loop
  void onAnimationFrame(double time, XRFrame frame ) {
    pose = frame.getViewerPose( customReferenceSpace ?? referenceSpace );
    xrFrame = frame;

    if ( pose != null ) {
      final views = pose?.views.toDart;

      if ( glBaseLayer != null) {
        renderer.setRenderTargetFramebuffer( newRenderTarget!, Framebuffer(glBaseLayer!.framebuffer));
        renderer.setRenderTarget( newRenderTarget );
      }

      bool cameraXRNeedsUpdate = false;

      // check if it's necessary to rebuild cameraXR's camera list
      if ( views?.length != cameraXR.cameras.length ) {
        cameraXR.cameras.length = 0;
        cameraXRNeedsUpdate = true;
      }

      for (int i = 0; i < (views?.length ?? 0); i ++ ) {
        final view = views![ i ];
        XRViewport? viewport;

        if ( glBaseLayer != null ) {
          viewport = glBaseLayer!.getViewport( view );
        } 
        else {
          final glSubImage = glBinding?.getViewSubImage( glProjLayer!, view );
          viewport = glSubImage?.viewport;

          // For side-by-side projection, we only produce a single texture for both eyes.
          if ( i == 0 ) {
            renderer.setRenderTargetTextures(
              newRenderTarget!,
              glSubImage!.colorTexture,
              glSubImage.depthStencilTexture 
            );

            renderer.setRenderTarget( newRenderTarget );
          }
        }

        Camera? camera = cameras[ i ];

        if ( camera == null ) {
          camera = PerspectiveCamera();
          camera.layers.enable( i );
          camera.viewport = Vector4();
          cameras[ i ] = camera;
        }

        camera.matrix.copyFromUnknown( view.transform.matrix );
        camera.matrix.decompose( camera.position, camera.quaternion, camera.scale );
        camera.projectionMatrix.copyFromUnknown( view.projectionMatrix );
        camera.projectionMatrixInverse.setFrom( camera.projectionMatrix ).invert();
        camera.viewport?.setValues( viewport!.x, viewport.y, viewport.width, viewport.height );

        if ( i == 0 ) {
          cameraXR.matrix.setFrom( camera.matrix );
          cameraXR.matrix.decompose( cameraXR.position, cameraXR.quaternion, cameraXR.scale );
        }

        if ( cameraXRNeedsUpdate == true ) {
          cameraXR.cameras.add( camera );
        }
      }

      final enabledFeatures = session?.enabledFeatures?.toDart;
      final gpuDepthSensingEnabled = enabledFeatures != null && 
        enabledFeatures.isNotEmpty &&
        enabledFeatures.contains( 'depth-sensing' ) &&
        session?.depthUsage == 'gpu-optimized';

      if ( gpuDepthSensingEnabled && glBinding != null) {
        final depthData = glBinding?.getDepthInformation( views![ 0 ] );

        if ( depthData != null && depthData.isValid) {
          depthSensing.init( renderer, depthData, session!.renderState );
        }
      }
    }

    for (int i = 0; i < controllers.length; i ++ ) {
      final inputSource = controllerInputSources.isNotEmpty?controllerInputSources[ i ]:null;
      final controller = controllers[ i ];
      if ( inputSource != null && controller != null ) {
        controller.update( inputSource, frame, customReferenceSpace ?? referenceSpace );
      }
    }

    if ( onAnimationFrameCallback != null) onAnimationFrameCallback( time, frame );
    if ( frame.detectedPlanes != null) {
      dispatchEvent(Event( type: 'planesdetected', data: frame ));
    }

    xrFrame = null;
  }

  @override
  void setAnimationLoop( callback ) {
    onAnimationFrameCallback = callback;
  }
}