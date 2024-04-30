part of three_renderers;

class XRWebGLLayer{
  XRWebGLLayer( session, gl, layerInit );
}
class WebGLRenderingContext{
  WebGLRenderingContext();
}
class XRWebGLBinding{
  XRWebGLBinding( session, gl );
}

class WebXRManager with EventDispatcher {
  bool enabled = false;
  bool cameraAutoUpdate = true;
  late final state;
  final WebGLRenderer renderer;
  bool isPresenting = false;
  dynamic gl;
  
  var session = null;
  double framebufferScaleFactor = 1.0;

  var referenceSpace = null;
  var onAnimationFrameCallback = null;
  String referenceSpaceType = 'local-floor';

  var pose = null;
  var glBinding = null;
  var glFramebuffer = null;
  var glProjLayer = null;
  var glBaseLayer = null;
  bool isMultisample = false;
  var glMultisampledFramebuffer = null;
  var glColorRenderbuffer = null;
  var glDepthRenderbuffer = null;
  var xrFrame = null;
  var depthStyle = null;
  var clearStyle = null;

  final controllers = [];
  final Map inputSourcesMap = {};

  var _currentDepthNear = null;
  var _currentDepthFar = null;

  final WebGLAnimation animation = WebGLAnimation();
  late final ArrayCamera cameraVR;
  final PerspectiveCamera cameraL = PerspectiveCamera();
  final PerspectiveCamera cameraR = PerspectiveCamera();

  final cameras = [];

  WebXRManager(this.renderer, this.gl) : super() {
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

  getController (int index ) {
    var controller = controllers[ index ];

    if ( controller == null ) {
      controller = WebXRController();
      controllers[ index ] = controller;
    }

    return controller.getTargetRaySpace();
  }

  getControllerGrip(int index ) {
    var controller = controllers[ index ];

    if ( controller == null ) {
      controller = WebXRController();
      controllers[ index ] = controller;
    }

    return controller.getGripSpace();
  }

  getHand(int index ) {
    var controller = controllers[ index ];

    if ( controller == null ) {
      controller = WebXRController();
      controllers[ index ] = controller;
    }

    return controller.getHandSpace();
  }

  void onSessionEvent( event ) {
    final controller = inputSourcesMap[event.inputSource];
    if ( controller ) {
      controller.dispatchEvent({'type': event.type, 'data': event.inputSource } );
    }
  }

  void onSessionEnd() {
    inputSourcesMap.forEach(( controller, inputSource ) {
      controller.disconnect( inputSource );
    } );

    inputSourcesMap.clear();

    _currentDepthNear = null;
    _currentDepthFar = null;

    // restore framebuffer/rendering state

    state.bindXRFramebuffer( null );
    renderer.setRenderTarget( renderer.getRenderTarget() );

    if ( glFramebuffer ) gl.deleteFramebuffer( glFramebuffer );
    if ( glMultisampledFramebuffer ) gl.deleteFramebuffer( glMultisampledFramebuffer );
    if ( glColorRenderbuffer ) gl.deleteRenderbuffer( glColorRenderbuffer );
    if ( glDepthRenderbuffer ) gl.deleteRenderbuffer( glDepthRenderbuffer );
    glFramebuffer = null;
    glMultisampledFramebuffer = null;
    glColorRenderbuffer = null;
    glDepthRenderbuffer = null;
    glBaseLayer = null;
    glProjLayer = null;
    glBinding = null;
    session = null;

    //

    animation.stop();

    isPresenting = false;
    dispatchEvent(Event(type: 'sessionend'));
  }

  setFramebufferScaleFactor( value ) {
    framebufferScaleFactor = value;
    if (isPresenting == true ) {
      print( 'three.WebXRManager: Cannot change framebuffer scale while presenting.' );
    }
  }

  setReferenceSpaceType ( value ) {
    referenceSpaceType = value;
    if (isPresenting == true ) {
      print( 'three.WebXRManager: Cannot change reference space type while presenting.' );
    }
  }

  getReferenceSpace () {
    return referenceSpace;
  }

  getBaseLayer () {
    return glProjLayer != null ? glProjLayer : glBaseLayer;
  }

  getBinding () {
    return glBinding;
  }

  getFrame () {
    return xrFrame;
  }

  getSession () {
    return session;
  }

  Future<void> setSession ( value ) async{
    session = value;

    if ( session != null ) {
      session.addEventListener( 'select', onSessionEvent );
      session.addEventListener( 'selectstart', onSessionEvent );
      session.addEventListener( 'selectend', onSessionEvent );
      session.addEventListener( 'squeeze', onSessionEvent );
      session.addEventListener( 'squeezestart', onSessionEvent );
      session.addEventListener( 'squeezeend', onSessionEvent );
      session.addEventListener( 'end', onSessionEnd );
      session.addEventListener( 'inputsourceschange', onInputSourcesChange );

      final attributes = gl.getContextAttributes();

      if ( attributes.xrCompatible != true ) {
        await gl.makeXRCompatible();
      }

      if ( session.renderState.layers == null ) {
        final layerInit = {
          'antialias': attributes.antialias,
          'alpha': attributes.alpha,
          'depth': attributes.depth,
          'stencil': attributes.stencil,
          'framebufferScaleFactor': framebufferScaleFactor
        };

        glBaseLayer = XRWebGLLayer( session, gl, layerInit );

        session.updateRenderState( {'baseLayer': glBaseLayer } );

      } 
      else if ( gl is WebGLRenderingContext ) {
        // Use old style webgl layer because we can't use MSAA
        // WebGL2 support.

        final layerInit = {
          'antialias': true,
          'alpha': attributes.alpha,
          'depth': attributes.depth,
          'stencil': attributes.stencil,
          'framebufferScaleFactor': framebufferScaleFactor
        };

        glBaseLayer = XRWebGLLayer( session, gl, layerInit );

        session.updateRenderState( { 'layers': [ glBaseLayer ] } );

      } else {
        isMultisample = attributes.antialias;
        var depthFormat = null;

        if ( attributes.depth ) {

          clearStyle = gl.DEPTH_BUFFER_BIT;

          if ( attributes.stencil ) clearStyle |= gl.STENCIL_BUFFER_BIT;

          depthStyle = attributes.stencil ? gl.DEPTH_STENCIL_ATTACHMENT : gl.DEPTH_ATTACHMENT;
          depthFormat = attributes.stencil ? gl.DEPTH24_STENCIL8 : gl.DEPTH_COMPONENT24;

        }

        final projectionlayerInit = {
          'colorFormat': attributes.alpha ? gl.RGBA8 : gl.RGB8,
          'depthFormat': depthFormat,
          'scaleFactor': framebufferScaleFactor
        };

        glBinding = XRWebGLBinding( session, gl );

        glProjLayer = glBinding.createProjectionLayer( projectionlayerInit );

        glFramebuffer = gl.createFramebuffer();

        session.updateRenderState( { 'layers': [ glProjLayer ] } );

        if ( isMultisample ) {

          glMultisampledFramebuffer = gl.createFramebuffer();
          glColorRenderbuffer = gl.createRenderbuffer();
          gl.bindRenderbuffer( gl.RENDERBUFFER, glColorRenderbuffer );
          gl.renderbufferStorageMultisample(
            gl.RENDERBUFFER,
            4,
            gl.RGBA8,
            glProjLayer.textureWidth,
            glProjLayer.textureHeight );
          state.bindFramebuffer( gl.FRAMEBUFFER, glMultisampledFramebuffer );
          gl.framebufferRenderbuffer( gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.RENDERBUFFER, glColorRenderbuffer );
          gl.bindRenderbuffer( gl.RENDERBUFFER, null );

          if ( depthFormat != null ) {

            glDepthRenderbuffer = gl.createRenderbuffer();
            gl.bindRenderbuffer( gl.RENDERBUFFER, glDepthRenderbuffer );
            gl.renderbufferStorageMultisample( gl.RENDERBUFFER, 4, depthFormat, glProjLayer.textureWidth, glProjLayer.textureHeight );
            gl.framebufferRenderbuffer( gl.FRAMEBUFFER, depthStyle, gl.RENDERBUFFER, glDepthRenderbuffer );
            gl.bindRenderbuffer( gl.RENDERBUFFER, null );

          }

          state.bindFramebuffer( gl.FRAMEBUFFER, null );
        }
      }

      referenceSpace = await session.requestReferenceSpace( referenceSpaceType );

      animation.setContext( session );
      animation.start();

      isPresenting = true;
      dispatchEvent( Event(type: 'sessionstart' ) );
    }
  }

  void onInputSourcesChange( event ) {

    final inputSources = session.inputSources;

    // Assign inputSources to available controllers

    for (int i = 0; i < controllers.length; i ++ ) {
      inputSourcesMap[inputSources[ i ]] =  controllers[ i ];
    }

    // Notify disconnected

    for (int i = 0; i < event.removed.length; i ++ ) {
      final inputSource = event.removed[ i ];
      final controller = inputSourcesMap[inputSource];

      if ( controller ) {
        controller.dispatchEvent(Event(type: 'disconnected', data: inputSource));
        inputSourcesMap.remove( inputSource );
      }
    }

    // Notify connected

    for (int i = 0; i < event.added.length; i ++ ) {
      final inputSource = event.added[ i ];
      final controller = inputSourcesMap[inputSource];

      if ( controller ) {
        controller.dispatchEvent( Event(type: 'connected', data: inputSource));
      }
    }
  }

  //

  final cameraLPos = Vector3.zero();
  final cameraRPos = Vector3.zero();

  /**
   * Assumes 2 cameras that are parallel and share an X-axis, and that
   * the cameras' projection and world matrices have already been set.
   * And that near and far planes are identical for both cameras.
   * Visualization of this technique: https://computergraphics.stackexchange.com/a/4765
   */
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

  void updateCamera(Camera camera ) {
    if ( session == null ) return;

    cameraVR.near = cameraR.near = cameraL.near = camera.near;
    cameraVR.far = cameraR.far = cameraL.far = camera.far;

    if ( _currentDepthNear != cameraVR.near || _currentDepthFar != cameraVR.far ) {

      // Note that the renderState won't apply until the next frame. See #18320

      session.updateRenderState( {
        'depthNear': cameraVR.near,
        'depthFar': cameraVR.far
      } );

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
    } else {
      cameraVR.projectionMatrix.setFrom( cameraL.projectionMatrix );
    }
  }

  ArrayCamera getCamera() {
    return cameraVR;
  }

  getFoveation () {
    if ( glProjLayer != null ) {
      return glProjLayer.fixedFoveation;
    }

    if ( glBaseLayer != null ) {
      return glBaseLayer.fixedFoveation;
    }

    return null;
  }

  void setFoveation( foveation ) {
    // 0 = no foveation = full resolution
    // 1 = maximum foveation = the edges render at lower resolution

    if ( glProjLayer != null ) {
      glProjLayer.fixedFoveation = foveation;
    }

    if ( glBaseLayer != null && glBaseLayer.fixedFoveation != null ) {
      glBaseLayer.fixedFoveation = foveation;
    }
  }

  //   	// Animation Loop

  //   	

  void onAnimationFrame(double time, frame ) {
    pose = frame.getViewerPose( referenceSpace );
    xrFrame = frame;

    if ( pose != null ) {
      final views = pose.views;
      if ( glBaseLayer != null ) {
        state.bindXRFramebuffer( glBaseLayer.framebuffer );
      }

      var cameraVRNeedsUpdate = false;

      // check if it's necessary to rebuild cameraVR's camera list

      if ( views.length != cameraVR.cameras.length ) {
        cameraVR.cameras.length = 0;
        cameraVRNeedsUpdate = true;
      }

      for ( var i = 0; i < views.length; i ++ ) {
        final view = views[ i ];
        var viewport = null;

        if ( glBaseLayer != null ) {
          viewport = glBaseLayer.getViewport( view );
        } else {
          final glSubImage = glBinding.getViewSubImage( glProjLayer, view );
          state.bindXRFramebuffer( glFramebuffer );

          if ( glSubImage.depthStencilTexture != null ) {
            gl.framebufferTexture2D( gl.FRAMEBUFFER, depthStyle, gl.TEXTURE_2D, glSubImage.depthStencilTexture, 0 );
          }

          gl.framebufferTexture2D( gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, glSubImage.colorTexture, 0 );
          viewport = glSubImage.viewport;
        }

        final camera = cameras[ i ];

        camera.matrix.fromArray( view.transform.matrix );
        camera.projectionMatrix.fromArray( view.projectionMatrix );
        camera.viewport.set( viewport.x, viewport.y, viewport.width, viewport.height );

        if ( i == 0 ) {
          cameraVR.matrix.setFrom( camera.matrix );
        }

        if ( cameraVRNeedsUpdate == true ) {
          cameraVR.cameras.add( camera );
        }
      }

      if ( isMultisample ) {
        state.bindXRFramebuffer( glMultisampledFramebuffer );
        if ( clearStyle != null ) gl.clear( clearStyle );
      }
    }

    //

    final inputSources = session.inputSources;

    for (int i = 0; i < controllers.length; i ++ ) {
      final controller = controllers[ i ];
      final inputSource = inputSources[ i ];
      controller.update( inputSource, frame, referenceSpace );
    }

    if ( onAnimationFrameCallback ) onAnimationFrameCallback( time, frame );

    if ( isMultisample ) {
      final width = glProjLayer.textureWidth;
      final height = glProjLayer.textureHeight;

      state.bindFramebuffer( gl.READ_FRAMEBUFFER, glMultisampledFramebuffer );
      state.bindFramebuffer( gl.DRAW_FRAMEBUFFER, glFramebuffer );
      // Invalidate the depth here to avoid flush of the depth data to main memory.
      gl.invalidateFramebuffer( gl.READ_FRAMEBUFFER, [ depthStyle ] );
      gl.invalidateFramebuffer( gl.DRAW_FRAMEBUFFER, [ depthStyle ] );
      gl.blitFramebuffer( 0, 0, width, height, 0, 0, width, height, gl.COLOR_BUFFER_BIT, gl.NEAREST );
      // Invalidate the MSAA buffer because it's not needed anymore.
      gl.invalidateFramebuffer( gl.READ_FRAMEBUFFER, [ gl.COLOR_ATTACHMENT0 ] );
      state.bindFramebuffer( gl.READ_FRAMEBUFFER, null );
      state.bindFramebuffer( gl.DRAW_FRAMEBUFFER, null );

      state.bindFramebuffer( gl.FRAMEBUFFER, glMultisampledFramebuffer );
    }

    xrFrame = null;
  }

  void setAnimationLoop ( callback ) {
    onAnimationFrameCallback = callback;
  }

  void dispose(){}
}
