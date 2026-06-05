import 'package:three_js_gpu/common/renderer.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

final _cameraLPos = Vector3();
final _cameraRPos = Vector3();

/**
 * The XR manager is built on top of the WebXR Device API to
 * manage XR sessions with `WebGPURenderer`.
 *
 * XR is currently only supported with a WebGL 2 backend.
 *
 * @augments EventDispatcher
 */
class XRManager extends EventDispatcher {
  bool enabled = false;
  bool isPresenting = false;
  bool cameraAutoUpdate = true;
  Renderer _renderer;
  PerspectiveCamera _cameraL = new PerspectiveCamera();
  PerspectiveCamera _cameraR = new PerspectiveCamera();
  late final List<PerspectiveCamera> _cameras = [ this._cameraL, this._cameraR ];
  late ArrayCamera _cameraXR = ArrayCamera(_cameras);
  double? _currentDepthNear;
  double? _currentDepthFar;
  RenderTarget? _xrRenderTarget;
  List _layers = [];
  List<XRInputSource> _controllerInputSources = [];
  List<WebXRController> _controllers = [];
  bool _supportsLayers = false;
  double _foveation = 1.0;
  double _framebufferScaleFactor = 1;
  XRReferenceSpace? _customReferenceSpace;
  String _referenceSpaceType = 'local-floor';
  final Vector2 _currentSize = Vector2();
  double? _currentPixelRatio;
  XRReferenceSpace? _referenceSpace;
  XRSession? _session;
  bool _useMultiview = false;
  late bool _useMultiviewIfPossible;
  XRFrame? _xrFrame;
  XRProjectionLayer? _glProjLayer;
  XRWebGLLayer? _glBaseLayer;
  XRWebGLBinding? _glBinding;

	/**
	 * Constructs a new XR manager.
	 *
	 * @param {Renderer} renderer - The renderer.
	 * @param {boolean} [multiview=false] - Enables multiview if the device supports it.
	 */
	XRManager(Renderer renderer, [multiview = false ]):super(){
		this._renderer = renderer;
		this._cameraL.viewport = new Vector4();
		this._cameraR.viewport = new Vector4();

		this._frameBufferTargets = null;

		/**
		 * Helper function to create native WebXR Layer.
		 *
		 * @private
		 * @type {Function}
		 */
		this._createXRLayer = createXRLayer.bind( this );

		/**
		* The current WebGL context.
		*
		* @private
		* @type {?WebGL2RenderingContext}
		* @default null
		*/
		this._gl = null;

		/**
		 * The current animation context.
		 *
		 * @private
		 * @type {?Window}
		 * @default null
		 */
		this._currentAnimationContext = null;

		/**
		 * The current animation loop.
		 *
		 * @private
		 * @type {?Function}
		 * @default null
		 */
		this._currentAnimationLoop = null;


		/**
		 * The default event listener for handling events inside a XR session.
		 *
		 * @private
		 * @type {Function}
		 */
		this._onSessionEvent = onSessionEvent.bind( this );

		/**
		 * The event listener for handling the end of a XR session.
		 *
		 * @private
		 * @type {Function}
		 */
		this._onSessionEnd = onSessionEnd.bind( this );

		/**
		 * The event listener for handling the `inputsourceschange` event.
		 *
		 * @private
		 * @type {Function}
		 */
		this._onInputSourcesChange = onInputSourcesChange.bind( this );

		/**
		 * The animation loop which is used as a replacement for the default
		 * animation loop of the application. It is only used when a XR session
		 * is active.
		 *
		 * @private
		 * @type {Function}
		 */
		this._onAnimationFrame = onAnimationFrame.bind( this );

		/**
		 * Whether to use the WebXR Layers API or not.
		 *
		 * @private
		 * @type {boolean}
		 * @readonly
		 */
		this._useLayers = ( typeof XRWebGLBinding != 'null' && 'createProjectionLayer' in XRWebGLBinding.prototype ); // eslint-disable-line compat/compat

		this._useMultiviewIfPossible = multiview;
	}

	/**
	 * Returns an instance of `THREE.Group` that represents the transformation
	 * of a XR controller in target ray space. The requested controller is defined
	 * by the given index.
	 *
	 * @param {number} index - The index of the XR controller.
	 * @return {Group} A group that represents the controller's transformation.
	 */
	getController(int index ) {
		final controller = this._getController( index );
		return controller.getTargetRaySpace();
	}

	/**
	 * Returns an instance of `THREE.Group` that represents the transformation
	 * of a XR controller in grip space. The requested controller is defined
	 * by the given index.
	 *
	 * @param {number} index - The index of the XR controller.
	 * @return {Group} A group that represents the controller's transformation.
	 */
	getControllerGrip(int index ) {
		final controller = this._getController( index );
		return controller.getGripSpace();
	}

	/**
	 * Returns an instance of `THREE.Group` that represents the transformation
	 * of a XR controller in hand space. The requested controller is defined
	 * by the given index.
	 *
	 * @param {number} index - The index of the XR controller.
	 * @return {Group} A group that represents the controller's transformation.
	 */
	getHand( index ) {

		final controller = this._getController( index );

		return controller.getHandSpace();

	}

	/**
	 * Returns the foveation value.
	 *
	 * @return {number|null} The foveation value. Returns `null` if no base or projection layer is defined.
	 */
	double? getFoveation() {
		if ( this._glProjLayer == null && this._glBaseLayer == null ) {
			return null;
		}

		return this._foveation;
	}

	/**
	 * Sets the foveation value.
	 *
	 * @param {number} foveation - A number in the range `[0,1]` where `0` means no foveation (full resolution)
	 * and `1` means maximum foveation (the edges render at lower resolution).
	 */
	void setFoveation(double foveation ) {
		this._foveation = foveation;

		if ( this._glProjLayer != null ) {
			this._glProjLayer.fixedFoveation = foveation;
		}

		if ( this._glBaseLayer != null && this._glBaseLayer.fixedFoveation != null ) {
			this._glBaseLayer.fixedFoveation = foveation;
		}
	}

	/**
	 * Returns the framebuffer scale factor.
	 *
	 * @return {number} The framebuffer scale factor.
	 */
	double getFramebufferScaleFactor() {
		return this._framebufferScaleFactor;
	}

	/**
	 * Sets the framebuffer scale factor.
	 *
	 * This method can not be used during a XR session.
	 *
	 * @param {number} factor - The framebuffer scale factor.
	 */
	void setFramebufferScaleFactor(double factor ) {
		this._framebufferScaleFactor = factor;

		if ( this.isPresenting == true ) {
			console.warning( 'THREE.XRManager: Cannot change framebuffer scale while presenting.' );
		}
	}

	/**
	 * Returns the reference space type.
	 *
	 * @return {XRReferenceSpaceType} The reference space type.
	 */
	XRReferenceSpaceType getReferenceSpaceType() {
		return this._referenceSpaceType;
	}

	/**
	 * Sets the reference space type.
	 *
	 * This method can not be used during a XR session.
	 *
	 * @param {XRReferenceSpaceType} type - The reference space type.
	 */
	void setReferenceSpaceType(XRReferenceSpaceType type ) {
		this._referenceSpaceType = type;
		if ( this.isPresenting == true ) {
			console.warning( 'THREE.XRManager: Cannot change reference space type while presenting.' );
		}
	}

	/**
	 * Returns the XR reference space.
	 *
	 * @return {XRReferenceSpace} The XR reference space.
	 */
	XRReferenceSpace getReferenceSpace() {
		return this._customReferenceSpace ?? this._referenceSpace;
	}

	/**
	 * Sets a custom XR reference space.
	 *
	 * @param {XRReferenceSpace} space - The XR reference space.
	 */
	setReferenceSpace(XRReferenceSpace space ) {
		this._customReferenceSpace = space;
	}

	/**
	 * Returns the XR camera.
	 *
	 * @return {ArrayCamera} The XR camera.
	 */
	ArrayCamera getCamera() {
		return this._cameraXR;
	}

	/**
	 * Returns the environment blend mode from the current XR session.
	 *
	 * @return {'opaque'|'additive'|'alpha-blend'|null} The environment blend mode. Returns `null` when used outside of a XR session.
	 */
	getEnvironmentBlendMode() {
		if ( this._session != null ) {
			return this._session.environmentBlendMode;
		}
	}

	/**
	 * Returns the current XR frame.
	 *
	 * @return {?XRFrame} The XR frame. Returns `null` when used outside a XR session.
	 */
	XRFrame? getFrame() {
		return this._xrFrame;
	}

	/**
	 * Returns `true` if the engine renders to a multiview target.
	 *
	 * @return {boolean} Whether the engine renders to a multiview render target or not.
	 */
	bool useMultiview() {
		return this._useMultiview;
	}

	/**
	 * This method can be used in XR applications to create a quadratic layer that presents a separate
	 * rendered scene.
	 *
	 * @param {number} width - The width of the layer plane in world units.
	 * @param {number} height - The height of the layer plane in world units.
	 * @param {Vector3} translation - The position/translation of the layer plane in world units.
	 * @param {Quaternion} quaternion - The orientation of the layer plane expressed as a quaternion.
	 * @param {number} pixelwidth - The width of the layer's render target in pixels.
	 * @param {number} pixelheight - The height of the layer's render target in pixels.
	 * @param {Function} rendercall - A callback function that renders the layer. Similar to code in
	 * the default animation loop, this method can be used to update/transform 3D object in the layer's scene.
	 * @param {Object} [attributes={}] - Allows to configure the layer's render target.
	 * @return {Mesh} A mesh representing the quadratic XR layer. This mesh should be added to the XR scene.
	 */
	createQuadLayer( width, height, translation, quaternion, pixelwidth, pixelheight, rendercall, attributes = {} ) {

		final geometry = new PlaneGeometry( width, height );
		final renderTarget = new XRRenderTarget(
			pixelwidth,
			pixelheight,
			{
				format: RGBAFormat,
				type: UnsignedByteType,
				depthTexture: new DepthTexture(
					pixelwidth,
					pixelheight,
					attributes.stencil ? UnsignedInt248Type : UnsignedIntType,
					null,
					null,
					null,
					null,
					null,
					null,
					attributes.stencil ? DepthStencilFormat : DepthFormat
				),
				stencilBuffer: attributes.stencil,
				resolveDepthBuffer: false,
				resolveStencilBuffer: false
			} );

		renderTarget._autoAllocateDepthBuffer = true;

		final material = new MeshBasicMaterial( { color: 0xffffff, side: FrontSide } );
		material.map = renderTarget.texture;
		material.map.offset.y = 1;
		material.map.repeat.y = - 1;
		final plane = new Mesh( geometry, material );
		plane.position.copy( translation );
		plane.quaternion.copy( quaternion );

		final layer = {
			type: 'quad',
			width: width,
			height: height,
			translation: translation,
			quaternion: quaternion,
			pixelwidth: pixelwidth,
			pixelheight: pixelheight,
			plane: plane,
			material: material,
			rendercall: rendercall,
			renderTarget: renderTarget };

		this._layers.push( layer );

		if ( this._session != null ) {

			layer.plane.material = new MeshBasicMaterial( { color: 0xffffff, side: FrontSide } );
			layer.plane.material.blending = CustomBlending;
			layer.plane.material.blendEquation = AddEquation;
			layer.plane.material.blendSrc = ZeroFactor;
			layer.plane.material.blendDst = ZeroFactor;

			layer.xrlayer = this._createXRLayer( layer );

			final xrlayers = this._session.renderState.layers;
			xrlayers.unshift( layer.xrlayer );
			this._session.updateRenderState( { layers: xrlayers } );

		} else {

			renderTarget.isXRRenderTarget = false;

		}

		return plane;

	}

	/**
	 * This method can be used in XR applications to create a cylindrical layer that presents a separate
	 * rendered scene.
	 *
	 * @param {number} radius - The radius of the cylinder in world units.
	 * @param {number} centralAngle - The central angle of the cylinder in radians.
	 * @param {number} aspectratio - The aspect ratio.
	 * @param {Vector3} translation - The position/translation of the layer plane in world units.
	 * @param {Quaternion} quaternion - The orientation of the layer plane expressed as a quaternion.
	 * @param {number} pixelwidth - The width of the layer's render target in pixels.
	 * @param {number} pixelheight - The height of the layer's render target in pixels.
	 * @param {Function} rendercall - A callback function that renders the layer. Similar to code in
	 * the default animation loop, this method can be used to update/transform 3D object in the layer's scene.
	 * @param {Object} [attributes={}] - Allows to configure the layer's render target.
	 * @return {Mesh} A mesh representing the cylindrical XR layer. This mesh should be added to the XR scene.
	 */
	createCylinderLayer( radius, centralAngle, aspectratio, translation, quaternion, pixelwidth, pixelheight, rendercall, attributes = {} ) {

		final geometry = new CylinderGeometry( radius, radius, radius * centralAngle / aspectratio, 64, 64, true, Math.PI - centralAngle / 2, centralAngle );
		final renderTarget = new XRRenderTarget(
			pixelwidth,
			pixelheight,
			{
				format: RGBAFormat,
				type: UnsignedByteType,
				depthTexture: new DepthTexture(
					pixelwidth,
					pixelheight,
					attributes.stencil ? UnsignedInt248Type : UnsignedIntType,
					null,
					null,
					null,
					null,
					null,
					null,
					attributes.stencil ? DepthStencilFormat : DepthFormat
				),
				stencilBuffer: attributes.stencil,
				resolveDepthBuffer: false,
				resolveStencilBuffer: false
			} );

		renderTarget._autoAllocateDepthBuffer = true;

		final material = new MeshBasicMaterial( { color: 0xffffff, side: BackSide } );
		material.map = renderTarget.texture;
		material.map.offset.y = 1;
		material.map.repeat.y = - 1;
		final plane = new Mesh( geometry, material );
		plane.position.copy( translation );
		plane.quaternion.copy( quaternion );

		final layer = {
			type: 'cylinder',
			radius: radius,
			centralAngle: centralAngle,
			aspectratio: aspectratio,
			translation: translation,
			quaternion: quaternion,
			pixelwidth: pixelwidth,
			pixelheight: pixelheight,
			plane: plane,
			material: material,
			rendercall: rendercall,
			renderTarget: renderTarget };

		this._layers.push( layer );

		if ( this._session != null ) {

			layer.plane.material = new MeshBasicMaterial( { color: 0xffffff, side: BackSide } );
			layer.plane.material.blending = CustomBlending;
			layer.plane.material.blendEquation = AddEquation;
			layer.plane.material.blendSrc = ZeroFactor;
			layer.plane.material.blendDst = ZeroFactor;

			layer.xrlayer = this._createXRLayer( layer );

			final xrlayers = this._session.renderState.layers;
			xrlayers.unshift( layer.xrlayer );
			this._session.updateRenderState( { layers: xrlayers } );

		} else {

			renderTarget.isXRRenderTarget = false;

		}

		return plane;

	}

	/**
	 * Renders the XR layers that have been previously added to the scene.
	 *
	 * This method is usually called in your animation loop before rendering
	 * the actual scene via `renderer.render( scene, camera );`.
	 */
	renderLayers( ) {

		final translationObject = new Vector3();
		final quaternionObject = new Quaternion();
		final renderer = this._renderer;

		final wasPresenting = this.isPresenting;
		final rendererOutputTarget = renderer.getOutputRenderTarget();
		final rendererFramebufferTarget = renderer._frameBufferTarget;
		this.isPresenting = false;

		final rendererSize = new Vector2();
		renderer.getSize( rendererSize );
		final rendererQuad = renderer._quad;

		for ( final layer of this._layers ) {

			layer.renderTarget.isXRRenderTarget = this._session != null;
			layer.renderTarget._hasExternalTextures = layer.renderTarget.isXRRenderTarget;

			if ( layer.renderTarget.isXRRenderTarget && this._supportsLayers ) {

				layer.xrlayer.transform = new XRRigidTransform( layer.plane.getWorldPosition( translationObject ), layer.plane.getWorldQuaternion( quaternionObject ) );

				final glSubImage = this._glBinding.getSubImage( layer.xrlayer, this._xrFrame );
				renderer.backend.setXRRenderTargetTextures(
					layer.renderTarget,
					glSubImage.colorTexture,
					null );

				renderer._setXRLayerSize( layer.renderTarget.width, layer.renderTarget.height );
				renderer.setOutputRenderTarget( layer.renderTarget );
				renderer.setRenderTarget( null );
				renderer._frameBufferTarget = null;

				this._frameBufferTargets || ( this._frameBufferTargets = new WeakMap() );
				final { frameBufferTarget, quad } = this._frameBufferTargets.get( layer.renderTarget ) || { frameBufferTarget: null, quad: null };
				if ( ! frameBufferTarget ) {

					renderer._quad = new QuadMesh( new NodeMaterial() );
					this._frameBufferTargets.set( layer.renderTarget, { frameBufferTarget: renderer._getFrameBufferTarget(), quad: renderer._quad } );

				} else {

					renderer._frameBufferTarget = frameBufferTarget;
					renderer._quad = quad;

				}

				layer.rendercall();

				renderer._frameBufferTarget = null;

			} else {

				renderer.setRenderTarget( layer.renderTarget );
				layer.rendercall();

			}

		}

		renderer.setRenderTarget( null );
		renderer.setOutputRenderTarget( rendererOutputTarget );
		renderer._frameBufferTarget = rendererFramebufferTarget;
		renderer._setXRLayerSize( rendererSize.x, rendererSize.y );
		renderer._quad = rendererQuad;
		this.isPresenting = wasPresenting;

	}


	/**
	 * Returns the current XR session.
	 *
	 * @return {?XRSession} The XR session. Returns `null` when used outside a XR session.
	 */
	getSession() {

		return this._session;

	}

	/**
	 * After a XR session has been requested usually with one of the `*Button` modules, it
	 * is injected into the renderer with this method. This method triggers the start of
	 * the actual XR rendering.
	 *
	 * @async
	 * @param {XRSession} session - The XR session to set.
	 * @return {Promise} A Promise that resolves when the session has been set.
	 */
	async setSession( session ) {

		final renderer = this._renderer;
		final backend = renderer.backend;

		this._gl = renderer.getContext();
		final gl = this._gl;
		final attributes = gl.getContextAttributes();

		this._session = session;

		if ( session != null ) {

			if ( backend.isWebGPUBackend == true ) throw new Error( 'THREE.XRManager: XR is currently not supported with a WebGPU backend. Use WebGL by passing "{ forceWebGL: true }" to the constructor of the renderer.' );

			session.addEventListener( 'select', this._onSessionEvent );
			session.addEventListener( 'selectstart', this._onSessionEvent );
			session.addEventListener( 'selectend', this._onSessionEvent );
			session.addEventListener( 'squeeze', this._onSessionEvent );
			session.addEventListener( 'squeezestart', this._onSessionEvent );
			session.addEventListener( 'squeezeend', this._onSessionEvent );
			session.addEventListener( 'end', this._onSessionEnd );
			session.addEventListener( 'inputsourceschange', this._onInputSourcesChange );

			await backend.makeXRCompatible();

			this._currentPixelRatio = renderer.getPixelRatio();
			renderer.getSize( this._currentSize );

			this._currentAnimationContext = renderer._animation.getContext();
			this._currentAnimationLoop = renderer._animation.getAnimationLoop();
			renderer._animation.stop();

			//

			if ( this._useLayers == true ) {

				// default path using XRWebGLBinding/XRProjectionLayer

				let depthFormat = null;
				let depthType = null;
				let glDepthFormat = null;

				if ( renderer.depth ) {

					glDepthFormat = renderer.stencil ? gl.DEPTH24_STENCIL8 : gl.DEPTH_COMPONENT24;
					depthFormat = renderer.stencil ? DepthStencilFormat : DepthFormat;
					depthType = renderer.stencil ? UnsignedInt248Type : UnsignedIntType;

				}

				final projectionlayerInit = {
					colorFormat: gl.RGBA8,
					depthFormat: glDepthFormat,
					scaleFactor: this._framebufferScaleFactor,
					clearOnAccess: false
				};

				if ( this._useMultiviewIfPossible && renderer.hasFeature( 'OVR_multiview2' ) ) {

					projectionlayerInit.textureType = 'texture-array';
					this._useMultiview = true;

				}

				final glBinding = new XRWebGLBinding( session, gl );
				final glProjLayer = glBinding.createProjectionLayer( projectionlayerInit );
				final layersArray = [ glProjLayer ];

				this._glBinding = glBinding;
				this._glProjLayer = glProjLayer;

				renderer.setPixelRatio( 1 );
				renderer._setXRLayerSize( glProjLayer.textureWidth, glProjLayer.textureHeight );

				final depth = this._useMultiview ? 2 : 1;
				final depthTexture = new DepthTexture( glProjLayer.textureWidth, glProjLayer.textureHeight, depthType, null, null, null, null, null, null, depthFormat, depth );

				this._xrRenderTarget = new XRRenderTarget(
					glProjLayer.textureWidth,
					glProjLayer.textureHeight,
					{
						format: RGBAFormat,
						type: UnsignedByteType,
						colorSpace: renderer.outputColorSpace,
						depthTexture: depthTexture,
						stencilBuffer: renderer.stencil,
						samples: attributes.antialias ? 4 : 0,
						resolveDepthBuffer: ( glProjLayer.ignoreDepthValues == false ),
						resolveStencilBuffer: ( glProjLayer.ignoreDepthValues == false ),
						depth: this._useMultiview ? 2 : 1,
						multiview: this._useMultiview
					} );

				this._xrRenderTarget._hasExternalTextures = true;
				this._xrRenderTarget.depth = this._useMultiview ? 2 : 1;

				this._supportsLayers = session.enabledFeatures.includes( 'layers' );

				this._referenceSpace = await session.requestReferenceSpace( this.getReferenceSpaceType() );

				if ( this._supportsLayers ) {

					// switch layers to native
					for ( final layer of this._layers ) {

						// change material so it "punches" out a hole to show the XR Layer.
						layer.plane.material = new MeshBasicMaterial( { color: 0xffffff, side: layer.type == 'cylinder' ? BackSide : FrontSide } );
						layer.plane.material.blending = CustomBlending;
						layer.plane.material.blendEquation = AddEquation;
						layer.plane.material.blendSrc = ZeroFactor;
						layer.plane.material.blendDst = ZeroFactor;

						layer.xrlayer = this._createXRLayer( layer );

						layersArray.unshift( layer.xrlayer );

					}

				}

				session.updateRenderState( { layers: layersArray } );

			} else {

				// fallback to XRWebGLLayer

				final layerInit = {
					antialias: renderer.samples > 0,
					alpha: true,
					depth: renderer.depth,
					stencil: renderer.stencil,
					framebufferScaleFactor: this.getFramebufferScaleFactor()
				};

				final glBaseLayer = new XRWebGLLayer( session, gl, layerInit );
				this._glBaseLayer = glBaseLayer;

				session.updateRenderState( { baseLayer: glBaseLayer } );

				renderer.setPixelRatio( 1 );
				renderer._setXRLayerSize( glBaseLayer.framebufferWidth, glBaseLayer.framebufferHeight );

				this._xrRenderTarget = new XRRenderTarget(
					glBaseLayer.framebufferWidth,
					glBaseLayer.framebufferHeight,
					{
						format: RGBAFormat,
						type: UnsignedByteType,
						colorSpace: renderer.outputColorSpace,
						stencilBuffer: renderer.stencil,
						resolveDepthBuffer: ( glBaseLayer.ignoreDepthValues == false ),
						resolveStencilBuffer: ( glBaseLayer.ignoreDepthValues == false ),
					}
				);

				this._xrRenderTarget._isOpaqueFramebuffer = true;
				this._referenceSpace = await session.requestReferenceSpace( this.getReferenceSpaceType() );

			}

			//

			this.setFoveation( this.getFoveation() );

			renderer._animation.setAnimationLoop( this._onAnimationFrame );
			renderer._animation.setContext( session );
			renderer._animation.start();

			this.isPresenting = true;

			this.dispatchEvent( { type: 'sessionstart' } );

		}

	}

	/**
	 * This method is called by the renderer per frame and updates the XR camera
	 * and it sub cameras based on the given camera. The given camera is the "user"
	 * camera created on application level and used for non-XR rendering.
	 *
	 * @param {PerspectiveCamera} camera - The camera.
	 */
	updateCamera( camera ) {

		final session = this._session;

		if ( session == null ) return;

		final depthNear = camera.near;
		final depthFar = camera.far;

		final cameraXR = this._cameraXR;
		final cameraL = this._cameraL;
		final cameraR = this._cameraR;

		cameraXR.near = cameraR.near = cameraL.near = depthNear;
		cameraXR.far = cameraR.far = cameraL.far = depthFar;
		cameraXR.isMultiViewCamera = this._useMultiview;

		if ( this._currentDepthNear != cameraXR.near || this._currentDepthFar != cameraXR.far ) {

			// Note that the new renderState won't apply until the next frame. See #18320

			session.updateRenderState( {
				depthNear: cameraXR.near,
				depthFar: cameraXR.far
			} );

			this._currentDepthNear = cameraXR.near;
			this._currentDepthFar = cameraXR.far;

		}

		cameraL.layers.mask = camera.layers.mask | 0b010;
		cameraR.layers.mask = camera.layers.mask | 0b100;
		cameraXR.layers.mask = cameraL.layers.mask | cameraR.layers.mask;

		final parent = camera.parent;
		final cameras = cameraXR.cameras;

		updateCamera( cameraXR, parent );

		for ( let i = 0; i < cameras.length; i ++ ) {

			updateCamera( cameras[ i ], parent );

		}

		// update projection matrix for proper view frustum culling

		if ( cameras.length == 2 ) {

			setProjectionFromUnion( cameraXR, cameraL, cameraR );

		} else {

			// assume single camera setup (AR)

			cameraXR.projectionMatrix.copy( cameraL.projectionMatrix );

		}

		// update user camera and its children

		updateUserCamera( camera, cameraXR, parent );


	}

	/**
	 * Returns a WebXR controller for the given controller index.
	 *
	 * @private
	 * @param {number} index - The controller index.
	 * @return {WebXRController} The XR controller.
	 */
	_getController( index ) {

		let controller = this._controllers[ index ];

		if ( controller == null ) {

			controller = new WebXRController();
			this._controllers[ index ] = controller;

		}

		return controller;

	}

}

/**
 * Assumes 2 cameras that are parallel and share an X-axis, and that
 * the cameras' projection and world matrices have already been set.
 * And that near and far planes are identical for both cameras.
 * Visualization of this technique: https://computergraphics.stackexchange.com/a/4765
 *
 * @param {ArrayCamera} camera - The camera to update.
 * @param {PerspectiveCamera} cameraL - The left camera.
 * @param {PerspectiveCamera} cameraR - The right camera.
 */
function setProjectionFromUnion( camera, cameraL, cameraR ) {

	_cameraLPos.setFromMatrixPosition( cameraL.matrixWorld );
	_cameraRPos.setFromMatrixPosition( cameraR.matrixWorld );

	final ipd = _cameraLPos.distanceTo( _cameraRPos );

	final projL = cameraL.projectionMatrix.elements;
	final projR = cameraR.projectionMatrix.elements;

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

	// Calculate the new camera's position offset from the
	// left camera. xOffset should be roughly half `ipd`.
	final zOffset = ipd / ( - leftFov + rightFov );
	final xOffset = zOffset * - leftFov;

	// TODO: Better way to apply this offset?
	cameraL.matrixWorld.decompose( camera.position, camera.quaternion, camera.scale );
	camera.translateX( xOffset );
	camera.translateZ( zOffset );
	camera.matrixWorld.compose( camera.position, camera.quaternion, camera.scale );
	camera.matrixWorldInverse.copy( camera.matrixWorld ).invert();

	// Check if the projection uses an infinite far plane.
	if ( projL[ 10 ] == - 1.0 ) {

		// Use the projection matrix from the left eye.
		// The camera offset is sufficient to include the view volumes
		// of both eyes (assuming symmetric projections).
		camera.projectionMatrix.copy( cameraL.projectionMatrix );
		camera.projectionMatrixInverse.copy( cameraL.projectionMatrixInverse );

	} else {

		// Find the union of the frustum values of the cameras and scale
		// the values so that the near plane's position does not change in world space,
		// although must now be relative to the new union camera.
		final near2 = near + zOffset;
		final far2 = far + zOffset;
		final left2 = left - xOffset;
		final right2 = right + ( ipd - xOffset );
		final top2 = topFov * far / far2 * near2;
		final bottom2 = bottomFov * far / far2 * near2;

		camera.projectionMatrix.makePerspective( left2, right2, top2, bottom2, near2, far2 );
		camera.projectionMatrixInverse.copy( camera.projectionMatrix ).invert();

	}

}

/**
 * Updates the world matrices for the given camera based on the parent 3D object.
 *
 * @inner
 * @param {Camera} camera - The camera to update.
 * @param {Object3D} parent - The parent 3D object.
 */
function updateCamera( camera, parent ) {

	if ( parent == null ) {

		camera.matrixWorld.copy( camera.matrix );

	} else {

		camera.matrixWorld.multiplyMatrices( parent.matrixWorld, camera.matrix );

	}

	camera.matrixWorldInverse.copy( camera.matrixWorld ).invert();

}

/**
 * Updates the given camera with the transformation of the XR camera and parent object.
 *
 * @inner
 * @param {Camera} camera - The camera to update.
 * @param {ArrayCamera} cameraXR - The XR camera.
 * @param {Object3D} parent - The parent 3D object.
 */
function updateUserCamera( camera, cameraXR, parent ) {

	if ( parent == null ) {

		camera.matrix.copy( cameraXR.matrixWorld );

	} else {

		camera.matrix.copy( parent.matrixWorld );
		camera.matrix.invert();
		camera.matrix.multiply( cameraXR.matrixWorld );

	}

	camera.matrix.decompose( camera.position, camera.quaternion, camera.scale );
	camera.updateMatrixWorld( true );

	camera.projectionMatrix.copy( cameraXR.projectionMatrix );
	camera.projectionMatrixInverse.copy( cameraXR.projectionMatrixInverse );

	if ( camera.isPerspectiveCamera ) {

		camera.fov = RAD2DEG * 2 * Math.atan( 1 / camera.projectionMatrix.elements[ 5 ] );
		camera.zoom = 1;

	}

}

function onSessionEvent( event ) {

	final controllerIndex = this._controllerInputSources.indexOf( event.inputSource );

	if ( controllerIndex == - 1 ) {

		return;

	}

	final controller = this._controllers[ controllerIndex ];

	if ( controller != null ) {

		final referenceSpace = this.getReferenceSpace();

		controller.update( event.inputSource, event.frame, referenceSpace );
		controller.dispatchEvent( { type: event.type, data: event.inputSource } );

	}

}

function onSessionEnd() {

	final session = this._session;
	final renderer = this._renderer;

	session.removeEventListener( 'select', this._onSessionEvent );
	session.removeEventListener( 'selectstart', this._onSessionEvent );
	session.removeEventListener( 'selectend', this._onSessionEvent );
	session.removeEventListener( 'squeeze', this._onSessionEvent );
	session.removeEventListener( 'squeezestart', this._onSessionEvent );
	session.removeEventListener( 'squeezeend', this._onSessionEvent );
	session.removeEventListener( 'end', this._onSessionEnd );
	session.removeEventListener( 'inputsourceschange', this._onInputSourcesChange );

	for ( let i = 0; i < this._controllers.length; i ++ ) {

		final inputSource = this._controllerInputSources[ i ];

		if ( inputSource == null ) continue;

		this._controllerInputSources[ i ] = null;

		this._controllers[ i ].disconnect( inputSource );

	}

	this._currentDepthNear = null;
	this._currentDepthFar = null;

	// restore framebuffer/rendering state

	renderer._resetXRState();

	this._session = null;
	this._xrRenderTarget = null;

	// switch layers back to emulated
	if ( this._supportsLayers == true ) {

		for ( final layer of this._layers ) {

			// Recreate layer render target to reset state
			layer.renderTarget = new XRRenderTarget(
				layer.pixelwidth,
				layer.pixelheight,
				{
					format: RGBAFormat,
					type: UnsignedByteType,
					depthTexture: new DepthTexture(
						layer.pixelwidth,
						layer.pixelheight,
						layer.stencilBuffer ? UnsignedInt248Type : UnsignedIntType,
						null,
						null,
						null,
						null,
						null,
						null,
						layer.stencilBuffer ? DepthStencilFormat : DepthFormat
					),
					stencilBuffer: layer.stencilBuffer,
					resolveDepthBuffer: false,
					resolveStencilBuffer: false
				} );

			layer.renderTarget.isXRRenderTarget = false;

			layer.plane.material = layer.material;
			layer.material.map = layer.renderTarget.texture;
			layer.material.map.offset.y = 1;
			layer.material.map.repeat.y = - 1;
			delete layer.xrlayer;

		}

	}

	//

	this.isPresenting = false;
	this._useMultiview = false;

	renderer._animation.stop();
	renderer._animation.setAnimationLoop( this._currentAnimationLoop );
	renderer._animation.setContext( this._currentAnimationContext );
	renderer._animation.start();

	renderer.setPixelRatio( this._currentPixelRatio );
	renderer.setSize( this._currentSize.width, this._currentSize.height, false );

	this.dispatchEvent( { type: 'sessionend' } );

}

function onInputSourcesChange( event ) {

	final controllers = this._controllers;
	final controllerInputSources = this._controllerInputSources;

	// Notify disconnected

	for ( let i = 0; i < event.removed.length; i ++ ) {

		final inputSource = event.removed[ i ];
		final index = controllerInputSources.indexOf( inputSource );

		if ( index >= 0 ) {

			controllerInputSources[ index ] = null;
			controllers[ index ].disconnect( inputSource );

		}

	}

	// Notify connected

	for ( let i = 0; i < event.added.length; i ++ ) {

		final inputSource = event.added[ i ];

		let controllerIndex = controllerInputSources.indexOf( inputSource );

		if ( controllerIndex == - 1 ) {

			// Assign input source a controller that currently has no input source

			for ( let i = 0; i < controllers.length; i ++ ) {

				if ( i >= controllerInputSources.length ) {

					controllerInputSources.push( inputSource );
					controllerIndex = i;
					break;

				} else if ( controllerInputSources[ i ] == null ) {

					controllerInputSources[ i ] = inputSource;
					controllerIndex = i;
					break;

				}

			}

			// If all controllers do currently receive input we ignore new ones

			if ( controllerIndex == - 1 ) break;

		}

		final controller = controllers[ controllerIndex ];

		if ( controller ) {

			controller.connect( inputSource );

		}

	}

}

// Creation method for native WebXR layers
createXRLayer( layer ) {

	if ( layer.type == 'quad' ) {

		return this._glBinding.createQuadLayer( {
			transform: new XRRigidTransform( layer.translation, layer.quaternion ),
			width: layer.width / 2,
			height: layer.height / 2,
			space: this._referenceSpace,
			viewPixelWidth: layer.pixelwidth,
			viewPixelHeight: layer.pixelheight,
			clearOnAccess: false
		} );

	} else {

		return this._glBinding.createCylinderLayer( {
			transform: new XRRigidTransform( layer.translation, layer.quaternion ),
			radius: layer.radius,
			centralAngle: layer.centralAngle,
			aspectRatio: layer.aspectRatio,
			space: this._referenceSpace,
			viewPixelWidth: layer.pixelwidth,
			viewPixelHeight: layer.pixelheight,
			clearOnAccess: false
		} );

	}

}

// Animation Loop

onAnimationFrame( time, frame ) {

	if ( frame == null ) return;

	final cameraXR = this._cameraXR;
	final renderer = this._renderer;
	final backend = renderer.backend;

	final glBaseLayer = this._glBaseLayer;

	final referenceSpace = this.getReferenceSpace();
	final pose = frame.getViewerPose( referenceSpace );

	this._xrFrame = frame;

	if ( pose != null ) {

		final views = pose.views;

		if ( this._glBaseLayer != null ) {

			backend.setXRTarget( glBaseLayer.framebuffer );

		}

		let cameraXRNeedsUpdate = false;

		// check if it's necessary to rebuild cameraXR's camera list

		if ( views.length != cameraXR.cameras.length ) {

			cameraXR.cameras.length = 0;
			cameraXRNeedsUpdate = true;

		}

		for ( let i = 0; i < views.length; i ++ ) {

			final view = views[ i ];

			let viewport;

			if ( this._useLayers == true ) {

				final glSubImage = this._glBinding.getViewSubImage( this._glProjLayer, view );
				viewport = glSubImage.viewport;

				// For side-by-side projection, we only produce a single texture for both eyes.
				if ( i == 0 ) {

					backend.setXRRenderTargetTextures(
						this._xrRenderTarget,
						glSubImage.colorTexture,
						( this._glProjLayer.ignoreDepthValues && ! this._useMultiview ) ? null : glSubImage.depthStencilTexture
					);

				}

			} else {

				viewport = glBaseLayer.getViewport( view );

			}

			let camera = this._cameras[ i ];

			if ( camera == null ) {

				camera = new PerspectiveCamera();
				camera.layers.enable( i );
				camera.viewport = new Vector4();
				this._cameras[ i ] = camera;

			}

			camera.matrix.fromArray( view.transform.matrix );
			camera.matrix.decompose( camera.position, camera.quaternion, camera.scale );
			camera.projectionMatrix.fromArray( view.projectionMatrix );
			camera.projectionMatrixInverse.copy( camera.projectionMatrix ).invert();
			camera.viewport.set( viewport.x, viewport.y, viewport.width, viewport.height );

			if ( i == 0 ) {

				cameraXR.matrix.copy( camera.matrix );
				cameraXR.matrix.decompose( cameraXR.position, cameraXR.quaternion, cameraXR.scale );

			}

			if ( cameraXRNeedsUpdate == true ) {

				cameraXR.cameras.push( camera );

			}

		}

		renderer.setOutputRenderTarget( this._xrRenderTarget );

	}

	//

	for ( let i = 0; i < this._controllers.length; i ++ ) {

		final inputSource = this._controllerInputSources[ i ];
		final controller = this._controllers[ i ];

		if ( inputSource != null && controller != null ) {

			controller.update( inputSource, frame, referenceSpace );

		}

	}

	if ( this._currentAnimationLoop ) this._currentAnimationLoop( time, frame );

	if ( frame.detectedPlanes ) {

		this.dispatchEvent( { type: 'planesdetected', data: frame } );

	}

	this._xrFrame = null;

}
