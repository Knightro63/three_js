part of three_renderers;

enum RenderType{after,before,custom}
enum PowerPreference{high,defaultp,low;

  String get name => _name();
  String _name(){
    if(index == 0){
      return 'high-performance';
    }
    else if(index == 2){
      return 'low-power';
    }
    else{
      return 'default';
    }
  }
}

enum Precision{highp,mediump,lowp}

class WebGLRendererParameters{
  double width;
  double height;
  RenderingContext gl;
  bool stencil;
  bool antialias;
  bool alpha;
  int clearColor;
  double clearAlpha;
  bool logarithmicDepthBuffer;
  bool premultipliedAlpha;
  bool preserveDrawingBuffer;
  PowerPreference powerPreference;
  bool reverseDepthBuffer;
  bool failIfMajorPerformanceCaveat;
  bool depth = true;
  Precision precision;
  WebXRManager Function(WebGLRenderer renderer, dynamic gl)? xr;

  WebGLRendererParameters({
    required this.width,
    required this.height,
    required this.gl,
    this.stencil = true,
    this.antialias = false,
    this.alpha = false,
    this.clearAlpha = 1.0,
    this.clearColor = 0x000000,
    this.logarithmicDepthBuffer = false,
    this.depth = true,
    this.premultipliedAlpha = true,
    this.preserveDrawingBuffer = false,
    this.powerPreference = PowerPreference.defaultp,
    this.failIfMajorPerformanceCaveat = false,
    this.reverseDepthBuffer = false,
    this.precision = Precision.highp,
    this.xr,
  });

  factory WebGLRendererParameters.fromMap(Map<String,dynamic> map){
    return WebGLRendererParameters(
      width: map["width"].toDouble(),
      height: map["height"].toDouble(),
      depth: map["depth"] ?? true,
      stencil: map["stencil"] ?? true,
      antialias: map["antialias"] ?? false,
      premultipliedAlpha: map["premultipliedAlpha"] ?? true,
      preserveDrawingBuffer: map["preserveDrawingBuffer"] ?? false,
      powerPreference: map["powerPreference"] ?? "default",
      failIfMajorPerformanceCaveat: map["failIfMajorPerformanceCaveat"] ?? false,
      alpha: map["alpha"] ?? false,
      gl: map["gl"],
      xr: map["xr"],
      precision: map['precision'],
      reverseDepthBuffer: map['reverseDepthBuffer']
    );
  }
}

class WebGLRenderer {
  late WebGLRendererParameters parameters;

  bool _didDispose = false;
  bool alpha = false;
  bool depth = true;
  bool stencil = true;
  bool antialias = false;

  final currentClearColor = Color.fromHex32( 0x000000 );
	double currentClearAlpha = 0;

  bool premultipliedAlpha = true;
  bool preserveDrawingBuffer = false;
  PowerPreference powerPreference = PowerPreference.defaultp;
  bool failIfMajorPerformanceCaveat = false;
  bool reverseDepthBuffer = false;

  bool renderBackground = false;
  WebGLRenderList? currentRenderList;
  WebGLRenderState? currentRenderState;

  // render() can be called from within a callback triggered by another render.

  // We track this so that the nested render call gets its list and state isolated from the parent render call.

  List<WebGLRenderList> renderListStack = [];
  List<WebGLRenderState> renderStateStack = [];

  // Debug configuration container
  Map<String, dynamic> debug = {
    /// Enables error checking and reporting when shader programs are being compiled
    /// @type {boolean}
    "checkShaderErrors": true
  };

  // clearing

  bool autoClear = true;
  bool autoClearColor = true;
  bool autoClearDepth = true;
  bool autoClearStencil = true;
  bool useLegacyLights = false;

  // scene graph
  bool sortObjects = true;

  // user-defined clipping

  List<Plane> clippingPlanes = [];
  bool localClippingEnabled = false;
  String _outputColorSpace = SRGBColorSpace;
  // physically based shading

  int outputEncoding = LinearEncoding;

  // physical lights

  bool physicallyCorrectLights = false;

  // tone mapping

  int toneMapping = NoToneMapping;
  double toneMappingExposure = 1.0;

  late double _width;
  late double _height;

  double get width => _width;
  double get height => _height;

  late Vector4 _viewport;
  late Vector4 _scissor;

  // internal properties

  bool _isContextLost = false;

  // internal state cache

  int _currentActiveCubeFace = 0;
  int _currentActiveMipmapLevel = 0;
  RenderTarget? _currentRenderTarget;

  int _currentMaterialId = -1;
  Camera? _currentCamera;

  final _currentProjectionMatrix = Matrix4();
  final _currentViewport = Vector4.identity();
  final _currentScissor = Vector4.identity();
  bool? _currentScissorTest;

  double _pixelRatio = 1;
  Function? _opaqueSort;
  Function? _transparentSort;

  bool _scissorTest = false;

  // frustum

  final _frustum = Frustum();

  // clipping

  bool _clippingEnabled = false;
  bool _localClippingEnabled = false;

  // transmission
  double transmissionResolutionScale = 1.0;

  // camera matrices cache

  final projScreenMatrix = Matrix4.identity();

  final _vector3 = Vector3();
  final _vector4 = Vector4();

  final _emptyScene = Scene();

  double getTargetPixelRatio() => _currentRenderTarget == null ? _pixelRatio : 1.0;

  // initialize

  late RenderingContext _gl;

  RenderingContext get gl => _gl;

  final animation = WebGLAnimation();
  late WebGLExtensions extensions;
  late WebGLCapabilities capabilities;
  late WebGLState state;
  late WebGLInfo info;
  late WebGLProperties properties;
  late WebGLTextures textures;
  late WebGLCubeMaps cubemaps;
  late WebGLCubeUVMaps cubeuvmaps;
  late WebGLAttributes attributes;
  late WebGLGeometries geometries;
  late WebGLObjects objects;
  late WebGLPrograms programCache;
  late WebGLMaterials materials;
  late WebGLRenderLists renderLists;
  late WebGLRenderStates renderStates;
  late WebGLClipping clipping;

  late WebGLBackground background;
  late WebGLMorphtargets morphtargets;
  late BaseWebGLBufferRenderer bufferRenderer;
  late WebGLIndexedBufferRenderer indexedBufferRenderer;

  late WebGLUtils utils;

  late WebGLBindingStates bindingStates;

  late WebXRManager xr;
  late WebXRManager Function(WebGLRenderer renderer, dynamic gl)? _setXR;
  late WebGLUniformsGroups uniformsGroups;
  late WebGLShadowMap shadowMap;

  late final Framebuffer _scratchFrameBuffer;
  late final Framebuffer _srcFramebuffer;
	late final Framebuffer _dstFramebuffer;
  WebGLRenderer(this.parameters) {
    _width = this.parameters.width;
    _height = this.parameters.height;

    depth = this.parameters.depth;
    stencil = this.parameters.stencil;
    antialias = this.parameters.antialias;
    premultipliedAlpha = this.parameters.premultipliedAlpha;
    preserveDrawingBuffer = this.parameters.preserveDrawingBuffer;
    powerPreference = this.parameters.powerPreference;

    failIfMajorPerformanceCaveat = this.parameters.failIfMajorPerformanceCaveat;

    alpha = this.parameters.alpha;

    _viewport = Vector4(0, 0, width, height);
    _scissor = Vector4(0, 0, width, height);

    _gl = this.parameters.gl;
    _setXR = this.parameters.xr;

    initGLContext();
  }
  factory WebGLRenderer.fromMap([Map<String, dynamic>? parameters]) {
    return WebGLRenderer(WebGLRendererParameters.fromMap(parameters ?? {}));
  }

  void initGLContext() {
    _scratchFrameBuffer = _gl.createFramebuffer();
    _srcFramebuffer = _gl.createFramebuffer();
	  _dstFramebuffer = _gl.createFramebuffer();

    extensions = WebGLExtensions(_gl);
    extensions.init();
    utils = WebGLUtils(extensions);

    capabilities = WebGLCapabilities(_gl, extensions, parameters, utils);
    state = WebGLState(_gl,extensions);

    if ( capabilities.reverseDepthBuffer && reverseDepthBuffer ) {
      state.buffers['depth'].setReversed( true );
    }

    info = WebGLInfo(_gl);
    properties = WebGLProperties();
    textures = WebGLTextures(_gl, extensions, state, properties, capabilities, utils, info);
    cubemaps = WebGLCubeMaps(this);
    cubeuvmaps = WebGLCubeUVMaps(this);
    attributes = WebGLAttributes(_gl);
    bindingStates = WebGLBindingStates(_gl, attributes);
    geometries = WebGLGeometries(_gl, attributes, info, bindingStates);
    objects = WebGLObjects(_gl, geometries, attributes, info);
    morphtargets = WebGLMorphtargets(_gl, capabilities, textures);
    clipping = WebGLClipping(properties);
    programCache = WebGLPrograms(this, cubemaps, cubeuvmaps, extensions, capabilities, bindingStates, clipping);
    materials = WebGLMaterials(this, properties);
    renderLists = WebGLRenderLists();
    renderStates = WebGLRenderStates(extensions);
    background = WebGLBackground(this, cubemaps, cubeuvmaps, state, objects, alpha, premultipliedAlpha);
    shadowMap = WebGLShadowMap(this, objects, capabilities);
    uniformsGroups = WebGLUniformsGroups( _gl, info, capabilities, state );

    bufferRenderer = WebGLBufferRenderer(_gl, extensions, info);
    indexedBufferRenderer = WebGLIndexedBufferRenderer(_gl, extensions, info);

    info.programs = programCache.programs;
  
    xr = _setXR?.call(this,gl) ?? WebXRManager(this, _gl);
    xr.init();
		xr.addEventListener( 'sessionstart', onXRSessionStart );
		xr.addEventListener( 'sessionend', onXRSessionEnd );
  }

  // API

  dynamic getContext() {
    return _gl;
  }

  dynamic getContextAttributes() {
    return _gl.getContextAttributes();
  }

  void forceContextLoss() {
    final extension = extensions.get('WEBGL_lose_context');
    if (extension) extension.loseContext();
  }

  void forceContextRestore() {
    final extension = extensions.get('WEBGL_lose_context');
    if (extension) extension.restoreContext();
  }

  double getPixelRatio() {
    return _pixelRatio;
  }

  void setPixelRatio(double value) {
    _pixelRatio = value;
    setSize(width, height, false);
  }

  Vector2 getSize(Vector2 target) {
    return target.setValues(width.toDouble(), height.toDouble());
  }

  void setSize(double width, double height, [bool updateStyle = false]) {
    if ( xr.isPresenting ) {
      console.warning( 'WebGLRenderer: Can\'t change size while VR device is presenting.' );
      return;
    }

    _width = width;
    _height = height;
    setViewport(0, 0, width, height);
  }

  Vector2 getDrawingBufferSize(Vector2 target) {
    return target.setValues(width * _pixelRatio, height * _pixelRatio).floor();
  }

  void setDrawingBufferSize(double width, double height, double pixelRatio) {
    _width = width;
    _height = height;
    console.info("WebGLRenderer setDrawingBufferSize ");
    setViewport(0, 0, width, height);
  }

  Vector4 getCurrentViewport(Vector4 target) {
    return target.setFrom(_currentViewport);
  }

  Vector4 getViewport(Vector4 target) {
    return target.setFrom(_viewport);
  }

  void setViewport(double x, double y, double width, double height) {
    _viewport.setValues(x, y, width, height);
    _currentViewport.setFrom(_viewport);
    _currentViewport.scale(_pixelRatio);
    _currentViewport.floor();
    state.viewport(_currentViewport);
  }

  Vector4 getScissor(Vector4 target) {
    return target.setFrom(_scissor);
  }

  void setScissor(double x, double y, double width, double height) {
    _scissor.setValues(x, y, width, height);
    _currentScissor.setFrom(_scissor);
    _currentScissor.scale(_pixelRatio);
    _currentScissor.floor();
    state.scissor(_currentScissor);
  }

  bool getScissorTest() {
    return _scissorTest;
  }

  void setScissorTest(bool boolean) {
    state.setScissorTest(_scissorTest = boolean);
  }

  void setOpaqueSort(Function? method) {
    _opaqueSort = method;
  }

  void setTransparentSort(Function? method) {
    _transparentSort = method;
  }

  // Clearing

  Color getClearColor(Color target) {
    target.setFrom(background.getClearColor());
    return target;
  }

  // color same as Color.set
  void setClearColor(Color color, [double alpha = 1.0]) {
    background.setClearColor(color, alpha);
  }

  double getClearAlpha() {
    return background.getClearAlpha();
  }

  void setClearAlpha(double alpha) {
    background.setClearAlpha(alpha);
  }

  final uintClearColor = Uint32List( 4 );
  final intClearColor = Uint32List( 4 );

  void clear([bool color = true, bool depth = true, bool stencil = true]) {
			int bits = 0;

			if ( color ) {
				// check if we're trying to clear an integer target
				bool isIntegerFormat = false;
				if ( _currentRenderTarget != null ) {
					final targetFormat = _currentRenderTarget!.texture.format;
					isIntegerFormat = targetFormat == RGBAIntegerFormat ||
						targetFormat == RGIntegerFormat ||
						targetFormat == RedIntegerFormat;
				}

				// use the appropriate clear functions to clear the target if it's a signed
				// or unsigned integer target
				if ( isIntegerFormat ) {
					final targetType = _currentRenderTarget!.texture.type;
					final isUnsignedType = targetType == UnsignedByteType ||
						targetType == UnsignedIntType ||
						targetType == UnsignedShortType ||
						targetType == UnsignedInt248Type ||
						targetType == UnsignedShort4444Type ||
						targetType == UnsignedShort5551Type;

					final clearColor = background.getClearColor();
					final a = background.getClearAlpha();
					final r = clearColor.red;
					final g = clearColor.green;
					final b = clearColor.blue;

					if ( isUnsignedType ) {
						uintClearColor[ 0 ] = (r*255).toInt();
						uintClearColor[ 1 ] = (g*255).toInt();
						uintClearColor[ 2 ] = (b*255).toInt();
						uintClearColor[ 3 ] = (a*255).toInt();
						_gl.clearBufferuiv( WebGL.COLOR, 0, uintClearColor.buffer.asByteData().getUint32(0) );
					} 
          else {
						intClearColor[ 0 ] = (r*255).toInt();
						intClearColor[ 1 ] = (g*255).toInt();
						intClearColor[ 2 ] = (b*255).toInt();
						intClearColor[ 3 ] = (a*255).toInt();
						_gl.clearBufferiv( WebGL.COLOR, 0, intClearColor.buffer.asByteData().getInt32(0) );
					}

				} 
        else {
					bits |= WebGL.COLOR_BUFFER_BIT;
				}
			}

			if ( depth ) bits |= WebGL.DEPTH_BUFFER_BIT;
			if ( stencil ) {
				bits |= WebGL.STENCIL_BUFFER_BIT;
				state.buffers['stencil'].setMask( 0xffffffff );
			}

			_gl.clear( bits );
  }

  void clearColor() {
    clear(true, false, false);
  }

  void clearDepth() {
    clear(false, true, false);
  }

  void clearStencil() {
    clear(false, false, true);
  }

  //
  void dispose() {
    if(_didDispose) return;
    _didDispose = true;
    state.reset();
    attributes.dispose();
    renderLists.dispose();
    renderStates.dispose();
    cubemaps.dispose();
    cubeuvmaps.dispose();
    bindingStates.dispose();
    programCache.dispose();
    
    currentRenderList?.dispose();
    for(final stack in renderListStack){
      stack.dispose();
    }
    renderListStack.clear();
    for(final stack in renderStateStack){
      stack.dispose();
    }
    
    renderStateStack.clear();
    debug.clear();
    
    _currentCamera?.clear();
    _frustum.dispose();
    _emptyScene.dispose();
    
    extensions.dispose();
    capabilities.dispose();
    clipping.dispose();
    utils.dispose();
    
    state.dispose();
    materials.dispose();
    objects.dispose();
    morphtargets.dispose();
    indexedBufferRenderer.dispose();
    background.dispose();
    textures.dispose();
    geometries.dispose();
    shadowMap.dispose();

    properties.dispose();

    _gl.deleteFramebuffer(_scratchFrameBuffer);
    _gl.deleteFramebuffer(_srcFramebuffer);
    _gl.deleteFramebuffer(_dstFramebuffer);
  }

  // Events
  void onContextLost( event ) {
    //event.preventDefault();
    console.info( 'THREE.WebGLRenderer: Context Lost.' );
    _isContextLost = true;
  }

  void onContextRestore() {
    console.info('WebGLRenderer: Context Restored.');

    _isContextLost = false;

    final infoAutoReset = info.autoReset;
    final shadowMapEnabled = shadowMap.enabled;
    final shadowMapAutoUpdate = shadowMap.autoUpdate;
    final shadowMapNeedsUpdate = shadowMap.needsUpdate;
    final shadowMapType = shadowMap.type;

    initGLContext();

    info.autoReset = infoAutoReset;
    shadowMap.enabled = shadowMapEnabled;
    shadowMap.autoUpdate = shadowMapAutoUpdate;
    shadowMap.needsUpdate = shadowMapNeedsUpdate;
    shadowMap.type = shadowMapType;
  }

  void onContextCreationError( event ) {
    console.error( 'THREE.WebGLRenderer: A WebGL context could not be created. Reason: ${event.statusMessage}');
  }

  void onMaterialDispose(Event event) {
    final material = event.target;
    material.removeEventListener('dispose', onMaterialDispose);
    deallocateMaterial(material);
  }

  // Buffer deallocation

  void deallocateMaterial(Material material) {
    releaseMaterialProgramReferences(material);
    properties.remove(material);
  }

  void releaseMaterialProgramReferences(Material material) {
    final programs = properties.get(material)["programs"];

    if (programs != null) {
      programs.forEach((key, program) {
        programCache.releaseProgram(program);
      });

      if (material is ShaderMaterial) {
        programCache.releaseShaderCache(material);
      }
    }
  }

  void renderBufferDirect(
    Camera camera,
    Object3D? scene,
    BufferGeometry geometry,
    Material material,
    Object3D object,
    Map<String, dynamic>? group,
  ) {
    // print("renderBufferDirect .............material: ${material.runtimeType}  ");
    // renderBufferDirect second parameter used to be fog (could be null)
    scene ??= _emptyScene;
    final frontFaceCW = (object is Mesh && object.matrixWorld.determinant() < 0);

    WebGLProgram program = setProgram(camera, scene, geometry, material, object);

    state.setMaterial(material, frontFaceCW);

    BufferAttribute? index = geometry.index;
    int rangeFactor = 1;

    if (material.wireframe) {
      index = geometries.getWireframeAttribute(geometry);
      if (index == null) return;
      if(kIsWeb && !kIsWasm){
        rangeFactor = 2;
      }
    }

    if (geometry.morphAttributes["position"] != null || geometry.morphAttributes["normal"] != null) {
      morphtargets.update(object, geometry, program);
    }

    final drawRange = geometry.drawRange;
    BufferAttribute? position = geometry.attributes["position"];
    int drawStart = drawRange['start']! * rangeFactor;
    int drawEnd = ( drawRange['start']! + drawRange['count']! ) * rangeFactor;

    if ( group != null ) {
      drawStart = math.max( drawStart, group['start'] * rangeFactor );
      drawEnd = math.min( drawEnd, ( group['start'] + group['count'] ) * rangeFactor );
    }

    if ( index != null ) {
      drawStart = math.max( drawStart, 0 );
      drawEnd = math.min( drawEnd, index.count );
    } else if (position != null) {
      drawStart = math.max( drawStart, 0 );
      drawEnd = math.min( drawEnd, position.count );
    }

    final drawCount = drawEnd - drawStart;
    if ( drawCount < 0 || drawCount == double.maxFinite.toInt() ) return;

    bindingStates.setup(object, material, program, geometry, index);

    Map<String, dynamic> attribute;
    BaseWebGLBufferRenderer renderer = bufferRenderer;

    if (index != null) {
      attribute = attributes.get(index);
      renderer = indexedBufferRenderer;
      renderer.setIndex(attribute);
    }

    if (object is Mesh) {
      if (material.wireframe) {
        state.setLineWidth(material.wireframeLinewidth! * getTargetPixelRatio());
        renderer.setMode(WebGL.LINES);
      } 
      else {
        renderer.setMode(WebGL.TRIANGLES);
      }
    } 
    else if (object is Line) {
      double? lineWidth = material.linewidth;

      lineWidth ??= 1; // Not using Line*Material

      state.setLineWidth(lineWidth * getTargetPixelRatio());

      if (object is LineSegments) {
        renderer.setMode(WebGL.LINES);
      } 
      else if (object is LineLoop) {
        renderer.setMode(WebGL.LINE_LOOP);
      } 
      else {
        renderer.setMode(WebGL.LINE_STRIP);
      }
    } 
    else if (object is Points) {
      renderer.setMode(WebGL.POINTS);
    } 
    else if (object is Sprite) {
      renderer.setMode(WebGL.TRIANGLES);
    }

    if ( object is BatchedMesh ) {
      if (object.multiDrawInstances != null ) {
        renderer.renderMultiDrawInstances( object.multiDrawStarts, object.multiDrawCounts, object.multiDrawCount, object.multiDrawInstances! );
      }
      else {
        if ( ! extensions.get( 'WEBGL_multi_draw' ) ) {
          final starts = object.multiDrawStarts;
          final counts = object.multiDrawCounts;
          final drawCount = object.multiDrawCount;
          final bytesPerElement = index != null? attributes.get( index ).bytesPerElement : 1;
          final uniforms = properties.get( material )['currentProgram'].getUniforms();
          
          for ( int i = 0; i < drawCount; i ++ ) {
            uniforms.setValue( _gl, '_gl_DrawID', i );
            renderer.render( starts[ i ] ~/ bytesPerElement, counts[ i ] );
          }
        } 
        else {
          renderer.renderMultiDraw( object.multiDrawStarts, object.multiDrawCounts, object.multiDrawCount );
        }      
      }
    }
    if (object is InstancedMesh) {
      renderer.renderInstances(drawStart, drawCount, object.count!);
    } 
    else if (geometry is InstancedBufferGeometry) {
      final instanceCount = math.min(geometry.instanceCount!, geometry.maxInstanceCount ?? 0);
      renderer.renderInstances(drawStart, drawCount, instanceCount);
    } 
    else {
      renderer.render(drawStart, drawCount);
    }
  }

  // Compile
  void prepareMaterial(Material material, Object3D? scene, Object3D object ) {

    if ( material.transparent == true && material.side == DoubleSide && material.forceSinglePass == false ) {

      material.side = BackSide;
      material.needsUpdate = true;
      getProgram( material, scene, object );

      material.side = FrontSide;
      material.needsUpdate = true;
      getProgram( material, scene, object );

      material.side = DoubleSide;

    } else {

      getProgram( material, scene, object );

    }

  }
  Set compile(Object3D scene, Camera camera, [Object3D? targetScene]) {
    targetScene ??= scene;

    currentRenderState = renderStates.get(targetScene);
    currentRenderState!.init(camera);
    renderStateStack.add(currentRenderState!);

    targetScene.traverseVisible((object) {
      if (object is Light && object.layers.test(camera.layers)) {
        currentRenderState!.pushLight(object);

        if (object.castShadow) {
          currentRenderState!.pushShadow(object);
        }
      }
    });

    if ( scene != targetScene ) {
      scene.traverseVisible((object){
        if (object is Light && object.layers.test( camera.layers ) ) {
          currentRenderState!.pushLight( object );
          if ( object.castShadow ) {
            currentRenderState!.pushShadow( object );
          }
        }
      });
    }
    currentRenderState!.setupLights();

    final materials = Set();

    scene.traverse((object) {
      if( ! ( object is Mesh || object is Points || object is Line || object is Sprite ) ) {
        return;
      }

      final material = object.material;

      if (material != null) {
        if (material is GroupMaterial) {
          for (int i = 0; i < material.children.length; i++) {
            final material2 = material.children[i];
            prepareMaterial(material2, targetScene, object);//getProgram(material2, scene, object);
            materials.add( material2 );
          }
        } else {
          prepareMaterial(material, targetScene, object);//getProgram(material, scene, object);
          materials.add( material );
        }
      }
    });

    currentRenderState = renderStateStack.removeLast();
    return materials;
  }

  // Animation Loop

  void Function(double)? onAnimationFrameCallback;

  void onAnimationFrame(double time) {
    if (onAnimationFrameCallback != null) onAnimationFrameCallback!(time);
  }

  void onXRSessionStart(event) {
    animation.stop();
  }

  void onXRSessionEnd(event) {
    animation.start();
  }

  void setAnimationLoop( callback ) {
    onAnimationFrameCallback = callback;
    xr.setAnimationLoop( callback );
    ( callback == null ) ? animation.stop() : animation.start();
  }
  // Rendering

  void render(Object3D scene, Camera camera) {
    if (_isContextLost) return;

    // update scene graph
    if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();

    // update camera matrices and frustum

    if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

    if ( xr.enabled && xr.isPresenting ) {
      if (xr.cameraAutoUpdate) xr.updateCamera( camera );
    	camera = xr.getCamera();
    }

    if (scene is Scene) {
      scene.onBeforeRender?.call(renderer: this, scene: scene, camera: camera, renderTarget: _currentRenderTarget);
    }

    currentRenderState = renderStates.get(scene, renderCallDepth: renderStateStack.length);
    currentRenderState!.init(camera);

    renderStateStack.add(currentRenderState!);

    projScreenMatrix.multiply2(camera.projectionMatrix, camera.matrixWorldInverse);

    _frustum.setFromMatrix(projScreenMatrix);

    _localClippingEnabled = localClippingEnabled;
    _clippingEnabled = clipping.init(clippingPlanes, _localClippingEnabled);

    currentRenderList = renderLists.get(scene, renderListStack.length);
    currentRenderList!.init();

    renderListStack.add(currentRenderList!);

    if ( xr.enabled && xr.isPresenting) {
      final depthSensingMesh = xr.getDepthSensingMesh();
      if ( depthSensingMesh != null ) {
        projectObject( depthSensingMesh, camera, - double.maxFinite.toInt(), this.sortObjects );
      }
    }

    projectObject(scene, camera, 0, sortObjects);

    currentRenderList!.finish();

    if (sortObjects) {
      currentRenderList!.sort(_opaqueSort, _transparentSort);
    }

		renderBackground = !xr.enabled || !xr.isPresenting || !xr.hasDepthSensing();
		if ( renderBackground ) {
      background.addToRenderList( currentRenderList!, scene );
    }

    info.render['frame'] = info.render['frame']!+1;

    if (_clippingEnabled) clipping.beginShadows();
    final shadowsArray = currentRenderState!.state.shadowsArray;
    if(kIsWeb){
      shadowMap.render(shadowsArray, scene, camera);
    }
    if (_clippingEnabled) clipping.endShadows();

    if (info.autoReset) info.reset();

    // render scene
    final opaqueObjects = currentRenderList?.opaque;
		final transmissiveObjects = currentRenderList?.transmissive;

    currentRenderState!.setupLights(physicallyCorrectLights);

    if (camera is ArrayCamera) {
      
      final cameras = camera.cameras;
      if (transmissiveObjects != null && transmissiveObjects.isNotEmpty) {
        for (int i = 0, l = cameras.length; i < l; i ++ ) {
          final camera2 = cameras[ i ];
          renderTransmissionPass( opaqueObjects!, transmissiveObjects, scene, camera2);
        }
      }
			if (renderBackground) background.render(scene);
      for (int i = 0, l = cameras.length; i < l; i++) {
        final camera2 = cameras[i];
        renderScene(currentRenderList!, scene, camera2, camera2.viewport);
      }
    } 
    else {
			if ( renderBackground ) background.render( scene );
      renderScene(currentRenderList!, scene, camera);
      if(transmissiveObjects != null && transmissiveObjects.isNotEmpty) renderTransmissionPass( opaqueObjects!, transmissiveObjects, scene, camera );
    }

    if(!kIsWeb){
      shadowMap.render(shadowsArray, scene, camera);
    }

    if (_currentRenderTarget != null) {
      // resolve multisample renderbuffers to a single-sample texture if necessary
      textures.updateMultisampleRenderTarget(_currentRenderTarget!);
      // Generate mipmap if we're using any kind of mipmap filtering
      textures.updateRenderTargetMipmap(_currentRenderTarget!);
    }

    if (scene is Scene) {
      scene.onAfterRender?.call(renderer: this, scene: scene, camera: camera);
    }

    _gl.flush();

    bindingStates.resetDefaultState();
    _currentMaterialId = -1;
    _currentCamera = null;

    renderStateStack.removeLast();
    if (renderStateStack.isNotEmpty) {
      currentRenderState = renderStateStack[renderStateStack.length - 1];
      if (_clippingEnabled) clipping.setGlobalState(clippingPlanes, currentRenderState!.state.camera! );
    } 
    else {
      currentRenderState = null;
    }

    renderListStack.removeLast();

    if (renderListStack.isNotEmpty) {
      currentRenderList = renderListStack[renderListStack.length - 1];
    } 
    else {
      currentRenderList = null;
    }
  }

  void projectObject(Object3D object, Camera camera, int groupOrder, bool sortObjects) {
    if (!object.visible) return;
    final visible = object.layers.test(camera.layers);
    
    if (visible) {
      if (object is Group) {
        groupOrder = object.renderOrder;
      } 
      else if (object is LOD) {
        dynamic u = object;
        if (object.autoUpdate == true) u.update(camera);
      } 
      else if (object is Light) {
        currentRenderState!.pushLight(object);

        if (object.castShadow) {
          currentRenderState!.pushShadow(object);
        }
      } 
      else if (object is Sprite) {
        if (!object.frustumCulled || _frustum.intersectsSprite(object)) {
          if (sortObjects) {
            _vector4.setFromMatrixPosition(object.matrixWorld).applyMatrix4(projScreenMatrix);
          }

          BufferGeometry geometry = objects.update(object);
          final material = object.material;

          if (material != null && material.visible) {
            currentRenderList!.push(object, geometry, material, groupOrder, _vector4.z, null);
          }
        }
      } 
      else if (object is Mesh || object is Line || object is Points) {
        // if (object is SkinnedMesh) {
        //   // update skeleton only once in a frame
        //   if (object.skeleton!.frame != info.render["frame"]) {
        //     object.skeleton!.update();
        //     object.skeleton!.frame = info.render["frame"]!;
        //   }
        // }

        // print("object: ${object.type} ${!object.frustumCulled} ${_frustum.intersectsObject(object)} ");

        if (!object.frustumCulled || _frustum.intersectsObject(object)) {
          final geometry = objects.update(object);
          final material = object.material;

          if (sortObjects) {
            if (object.boundingSphere != null ) {
              if (object.boundingSphere == null ) object.computeBoundingSphere();
              _vector4.setFrom(object.boundingSphere!.center );
            } 
            else {
              if ( geometry.boundingSphere == null ) geometry.computeBoundingSphere();
              _vector4.setFrom( geometry.boundingSphere!.center );
            }
            _vector4..applyMatrix4(object.matrixWorld)..applyMatrix4(projScreenMatrix);
          }

          if (material is GroupMaterial) {
            final groups = geometry.groups;

            if (groups.isNotEmpty) {
              for (int i = 0, l = groups.length; i < l; i++) {
                Map<String, dynamic> group = groups[i];
                final groupMaterial = material.children[group["materialIndex"]];

                if (groupMaterial.visible) {
                  currentRenderList!.push(object, geometry, groupMaterial, groupOrder, _vector4.z, group);
                }
              }
            } 
            else {
              if (material.visible && material.children.isNotEmpty) {
                currentRenderList!.push(object, geometry, material.children[0], groupOrder, _vector4.z, null);
              }
            }
          } 
          else if (material != null && material.visible) {
            currentRenderList!.push(object, geometry, material, groupOrder, _vector4.z, null);
          }
        }
      }
    }

    final children = object.children;

    for (int i = 0, l = children.length; i < l; i++) {
      projectObject(children[i], camera, groupOrder, sortObjects);
    }
  }

  void renderScene(WebGLRenderList currentRenderList, Object3D scene, Camera camera, [Vector4? viewport]) {
    List<RenderItem> opaqueObjects = currentRenderList.opaque;
    final transmissiveObjects = currentRenderList.transmissive;
    final transparentObjects = currentRenderList.transparent;

    currentRenderState!.setupLightsView(camera);

    if (_clippingEnabled) clipping.setGlobalState(clippingPlanes, camera );
    
    if (viewport != null){ 
      _currentViewport.setFrom(viewport);
      state.viewport(_currentViewport);
    }

    if (opaqueObjects.isNotEmpty) renderObjects(opaqueObjects, scene, camera);
    if (transmissiveObjects.isNotEmpty) renderObjects(transmissiveObjects, scene, camera);
    if (transparentObjects.isNotEmpty) renderObjects(transparentObjects, scene, camera);

    // Ensure depth buffer writing is enabled so it can be cleared on next render

    state.buffers["depth"].setTest(true);
    state.buffers["depth"].setMask(true);
    state.buffers["color"].setMask(true);

    state.setPolygonOffset(false);
  }

  void renderTransmissionPass(List<RenderItem> opaqueObjects, List<RenderItem> transmissiveObjects, Object3D scene, Camera camera) {
			final overrideMaterial = scene is Scene? scene.overrideMaterial : null;

			if ( overrideMaterial != null ) {
				return;
			}

      RenderTarget? transmissionRenderTarget = currentRenderState?.state.transmissionRenderTarget[ camera.id ];
      final activeViewport = camera.viewport ?? _currentViewport;

			if ( currentRenderState?.state.transmissionRenderTarget[ camera.id ] == null ||
        (activeViewport.w.toInt() != transmissionRenderTarget?.height || activeViewport.z.toInt() != transmissionRenderTarget?.width)
      ) {
        transmissionRenderTarget?.dispose();
        currentRenderState?.state.transmissionRenderTarget[ camera.id ] = WebGLRenderTarget( 1, 1, WebGLRenderTargetOptions({
          'generateMipmaps': true,
          'type': ( extensions.has( 'EXT_color_buffer_half_float' ) || extensions.has( 'EXT_color_buffer_float' ) ) ? HalfFloatType : UnsignedByteType,
          'minFilter': LinearMipmapLinearFilter,
          'samples': 4,
          'stencilBuffer': stencil,
          'resolveDepthBuffer': false,
          'resolveStencilBuffer': false,
          'colorSpace': ColorManagement.workingColorSpace.toString(),
        }));

        transmissionRenderTarget = currentRenderState?.state.transmissionRenderTarget[ camera.id ];
			}

			transmissionRenderTarget!.setSize( (activeViewport.z * transmissionResolutionScale).toInt(), (activeViewport.w * transmissionResolutionScale).toInt());

			final currentRenderTarget = getRenderTarget();
			setRenderTarget( transmissionRenderTarget );

			getClearColor( currentClearColor );
			currentClearAlpha = getClearAlpha();
			if ( currentClearAlpha < 1 ) setClearColor( Color.fromHex32(0xffffff), 0.5 );
			clear();

      if ( renderBackground ) background.render( scene );

			// Turn off the features which can affect the frag color for opaque objects pass.
			// Otherwise they are applied twice in opaque objects pass and transmission objects pass.
			final currentToneMapping = toneMapping;
			toneMapping = NoToneMapping;

			// Remove viewport from camera to avoid nested render calls resetting viewport to it (e.g Reflector).
			// Transmission render pass requires viewport to match the transmissionRenderTarget.
			final currentCameraViewport = camera.viewport;
			if ( camera.viewport != null ) camera.viewport = null;

			currentRenderState?.setupLightsView( camera );

			if ( _clippingEnabled == true ) clipping.setGlobalState( clippingPlanes, camera );

			renderObjects( opaqueObjects, scene, camera );

			textures.updateMultisampleRenderTarget( transmissionRenderTarget );
			textures.updateRenderTargetMipmap( transmissionRenderTarget );

			if (!extensions.has( 'WEBGL_multisampled_render_to_texture' ) ) { // see #28131
				bool renderTargetNeedsUpdate = false;
        
				for ( int i = 0, l = transmissiveObjects.length; i < l; i ++ ) {
					final renderItem = transmissiveObjects[ i ];

					final object = renderItem.object;
					final geometry = renderItem.geometry;
					final material = renderItem.material;
					final group = renderItem.group;

					if ( material!.side == DoubleSide && object!.layers.test( camera.layers ) ) {
						final currentSide = material.side;

						material.side = BackSide;
						material.needsUpdate = true;

						renderObject( object, scene, camera, geometry!, material, group );

						material.side = currentSide;
						material.needsUpdate = true;

						renderTargetNeedsUpdate = true;
					}
				}

				if ( renderTargetNeedsUpdate == true ) {
					textures.updateMultisampleRenderTarget( transmissionRenderTarget );
					textures.updateRenderTargetMipmap( transmissionRenderTarget );
				}
			}

			setRenderTarget( currentRenderTarget );
			setClearColor( currentClearColor, currentClearAlpha );

			if (currentCameraViewport != null) camera.viewport = currentCameraViewport;

			toneMapping = currentToneMapping;
  }

  void renderObjects(List<RenderItem> renderList, Object3D scene, Camera camera) {
    final overrideMaterial = scene is Scene ? scene.overrideMaterial : null;
    for (int i = 0, l = renderList.length; i < l; i++) {
      final renderItem = renderList[i];

      final object = renderItem.object!;
      final geometry = renderItem.geometry!;
      final material = overrideMaterial ?? renderItem.material!;
      final group = renderItem.group;

      if (object.layers.test(camera.layers)) {
        renderObject(object, scene, camera, geometry, material, group);
      }
    }
  }

  void renderObject(Object3D object, scene, Camera camera, BufferGeometry geometry, Material material, Map<String, dynamic>? group) {
    object.onBeforeRender?.call(
      renderer: this,
      mesh: object,
      scene: scene,
      camera: camera,
      geometry: geometry,
      material: material,
      group: group
    );

    object.modelViewMatrix.multiply2(camera.matrixWorldInverse, object.matrixWorld);
    object.normalMatrix.getNormalMatrix(object.modelViewMatrix);

    material.onBeforeRender?.call(
      this, 
      scene, 
      camera, 
      geometry, 
      object, 
      group
    );

    if (material.transparent && material.side == DoubleSide && !material.forceSinglePass) {
      material.side = BackSide;
      material.needsUpdate = true;
      renderBufferDirect(camera, scene, geometry, material, object, group);

      material.side = FrontSide;
      material.needsUpdate = true;
      renderBufferDirect(camera, scene, geometry, material, object, group);

      material.side = DoubleSide;
    } 
    else {
      renderBufferDirect(camera, scene, geometry, material, object, group);
    }

    object.onAfterRender?.call(renderer: this, scene: scene, camera: camera, geometry: geometry, material: material, group: group);
  }

  WebGLProgram? getProgram(Material material, Object3D? scene, Object3D object) {
    if (scene is! Scene) scene = _emptyScene;
    // scene could be a Mesh, Line, Points, ...

    final materialProperties = properties.get(material);

    final lights = currentRenderState!.state.lights;
    final shadowsArray = currentRenderState!.state.shadowsArray;

    final lightsStateVersion = lights.state.version;

    final parameters = programCache.getParameters(material, lights.state, shadowsArray, scene, object);
    final programCacheKey = programCache.getProgramCacheKey(parameters);

    Map? programs = materialProperties["programs"];

    // always update environment and fog - changing these trigger an getProgram call, but it's possible that the program doesn't change
    materialProperties["environment"] = material is MeshStandardMaterial ? scene.environment : null;
    materialProperties["fog"] = scene.fog;
		materialProperties['envMap'] = ( material is MeshStandardMaterial ? cubeuvmaps.get( material.envMap ?? materialProperties['environment'] ) : cubemaps.get( material.envMap ?? materialProperties['environment'] ) );
		materialProperties['envMapRotation'] = ( materialProperties['environment'] != null && material.envMap == null ) ? scene.environmentRotation : material.envMapRotation;

    if (programs == null) {
      material.addEventListener('dispose', onMaterialDispose);
      programs = {};
      materialProperties["programs"] = programs;
    }

    WebGLProgram? program = programs[programCacheKey];

    if (program != null) {
      // early out if program and light state is identical
      if (materialProperties["currentProgram"] == program && materialProperties["lightsStateVersion"] == lightsStateVersion) {
        updateCommonMaterialProperties(material, parameters);
        return program;
      }
    } 
    else {
      parameters.uniforms = programCache.getUniforms(material);

      //material.onBuild(parameters, this);
      material.onBeforeCompile?.call(parameters, this);
      program = programCache.acquireProgram(parameters, programCacheKey);
      programs[programCacheKey] = program;

      materialProperties["uniforms"] = parameters.uniforms;
    }

    Map<String, dynamic> uniforms = materialProperties["uniforms"];

    if ((material is! ShaderMaterial && material is! RawShaderMaterial) || material.clipping == true) {
      uniforms["clippingPlanes"] = clipping.uniform;
    }

    updateCommonMaterialProperties(material, parameters);

    // store the light setup it was created for

    materialProperties["needsLights"] = materialNeedsLights(material);
    materialProperties["lightsStateVersion"] = lightsStateVersion;

    if (materialProperties["needsLights"] == true) {
      // wire up the material to this renderer's lighting state

      uniforms["ambientLightColor"]["value"] = lights.state.ambient;
      uniforms["lightProbe"]["value"] = lights.state.probe;
      uniforms["directionalLights"]["value"] = lights.state.directional;
      uniforms["directionalLightShadows"]["value"] = lights.state.directionalShadow;
      uniforms["spotLights"]["value"] = lights.state.spot;
      uniforms["spotLightShadows"]["value"] = lights.state.spotShadow;
      uniforms["rectAreaLights"]["value"] = lights.state.rectArea;
      uniforms["ltc_1"]["value"] = lights.state.rectAreaLTC1;
      uniforms["ltc_2"]["value"] = lights.state.rectAreaLTC2;
      uniforms["pointLights"]["value"] = lights.state.point;
      uniforms["pointLightShadows"]["value"] = lights.state.pointShadow;
      uniforms["hemisphereLights"]["value"] = lights.state.hemi;
      
      uniforms["directionalShadowMap"]["value"] = lights.state.directionalShadowMap;
      uniforms["directionalShadowMatrix"]["value"] = lights.state.directionalShadowMatrix;
      uniforms["spotShadowMap"]["value"] = lights.state.spotShadowMap;
      uniforms["spotLightMatrix"]["value"] = lights.state.spotLightMatrix;
      uniforms["spotLightMap"]["value"] = lights.state.spotLightMap;
      uniforms["pointShadowMap"]["value"] = lights.state.pointShadowMap;
      uniforms["pointShadowMatrix"]["value"] = lights.state.pointShadowMatrix;
    }

    materialProperties["currentProgram"] = program;
    materialProperties["uniformsList"] = null;

    return program;
  }

   List getUniformList(Map materialProperties ) {
    if ( materialProperties['uniformsList'] == null ) {
      final progUniforms = (materialProperties['currentProgram'] as WebGLProgram).getUniforms();
      materialProperties['uniformsList'] = WebGLUniforms.seqWithValue( progUniforms.seq, materialProperties['uniforms'] );
    }

    return materialProperties['uniformsList'];
  }
  void updateCommonMaterialProperties(Material material, WebGLParameters parameters) {
    final materialProperties = properties.get(material);

    materialProperties['outputColorSpace'] = parameters.outputColorSpace;
    materialProperties['batching'] = parameters.batching;
    materialProperties['batchingColor'] = parameters.batchingColor;
    materialProperties['instancing'] = parameters.instancing;
    materialProperties['instancingColor'] = parameters.instancingColor;
    materialProperties['instancingMorph'] = parameters.instancingMorph;
    materialProperties['skinning'] = parameters.skinning;
    materialProperties['morphTargets'] = parameters.morphTargets;
    materialProperties['morphNormals'] = parameters.morphNormals;
    materialProperties['morphColors'] = parameters.morphColors;
    materialProperties['morphTargetsCount'] = parameters.morphTargetsCount;
    materialProperties['numClippingPlanes'] = parameters.numClippingPlanes;
    materialProperties['numIntersection'] = parameters.numClipIntersection;
    materialProperties['vertexAlphas'] = parameters.vertexAlphas;
    materialProperties['vertexTangents'] = parameters.vertexTangents;
    materialProperties['toneMapping'] = parameters.toneMapping;
  }

  WebGLProgram setProgram(Camera camera, Object3D? scene, BufferGeometry? geometry, Material material, Object3D object) {
    if (scene is! Scene) scene = _emptyScene; // scene could be a Mesh, Line, Points, ...
    textures.resetTextureUnits();

    final fog = scene.fog;
    final environment = material is MeshStandardMaterial ? scene.environment : null;
    final colorSpace = ( _currentRenderTarget == null ) ? outputColorSpace : ( _currentRenderTarget?.isXRRenderTarget == true ? _currentRenderTarget?.texture.colorSpace : LinearSRGBColorSpace );
    final envMap = ( material is MeshStandardMaterial ? cubeuvmaps.get( material.envMap ?? environment ) : cubemaps.get( material.envMap ?? environment ) );
    final vertexAlphas = material.vertexColors && 
      geometry?.attributes['color'] != null && 
      geometry?.attributes['color'].itemSize == 4;
    final vertexTangents = geometry?.attributes['tangent'] != null && (material.normalMap != null || (material is MeshPhysicalMaterial && material.anisotropy > 0));
    final morphTargets = geometry?.morphAttributes['position'] != null;
    final morphNormals = geometry?.morphAttributes['normal'] != null;
    final morphColors = geometry?.morphAttributes['color'] != null;

    int toneMapping = NoToneMapping;

    if ( material.toneMapped ) {
      if ( _currentRenderTarget == null || _currentRenderTarget?.isXRRenderTarget == true ) {
        toneMapping = toneMapping;
      }
    }

    final morphAttribute = geometry?.morphAttributes['position'] ?? geometry?.morphAttributes['normal'] ?? geometry?.morphAttributes['color'];
    final morphTargetsCount = ( morphAttribute != null ) ? morphAttribute.length : 0;

    final materialProperties = properties.get( material );
    final lights = currentRenderState?.state.lights;

    if (_clippingEnabled) {
      if (_localClippingEnabled || camera != _currentCamera ) {
        final useCache = camera == _currentCamera && material.id == _currentMaterialId;

        // we might want to call this function with some ClippingGroup
        // object instead of the material, once it becomes feasible
        // (#8465, #8379)
        clipping.setState( material, camera, useCache );
      }
    }

    bool needsProgramChange = false;

    if ( material.version == materialProperties['__version'] ) {
      if ( materialProperties['needsLights'] != null && ( materialProperties['lightsStateVersion'] != lights?.state.version ) ) {
        needsProgramChange = true;
      } else if ( materialProperties['outputColorSpace'] != colorSpace ) {
        needsProgramChange = true;
      } else if ( object is BatchedMesh && materialProperties['batching'] == false ) {
        needsProgramChange = true;
      } else if (object is! BatchedMesh && materialProperties['batching'] == true ) {
        needsProgramChange = true;
      }else if ( object is BatchedMesh && materialProperties['batchingColor'] == true && object.colorsTexture == null ) {
				needsProgramChange = true;
			} else if ( object is BatchedMesh && materialProperties['batchingColor'] == false && object.colorsTexture != null ) {
				needsProgramChange = true;
			}else if ( object is InstancedMesh && materialProperties['instancing'] == false ) {
        needsProgramChange = true;
      } else if (object is! InstancedMesh && materialProperties['instancing'] == true ) {
        needsProgramChange = true;
      } else if ( object is SkinnedMesh && materialProperties['skinning'] == false ) {
        needsProgramChange = true;
      } else if (object is! SkinnedMesh && materialProperties['skinning'] == true ) {
        needsProgramChange = true;
      } else if ( object is InstancedMesh && materialProperties['instancingColor'] == true && object.instanceColor == null ) {
        needsProgramChange = true;
      } else if ( object is InstancedMesh && materialProperties['instancingColor'] == false && object.instanceColor != null ) {
        needsProgramChange = true;
      } else if ( object is InstancedMesh && materialProperties['instancingMorph'] == true && object.morphTexture == null ) {
        needsProgramChange = true;
      } else if ( object is InstancedMesh && materialProperties['instancingMorph'] == false && object.morphTexture != null ) {
        needsProgramChange = true;
      } else if ( materialProperties['envMap'] != envMap ) {
        needsProgramChange = true;
      } else if ( material.fog == true && materialProperties['fog'] != fog ) {
        needsProgramChange = true;
      } else if ( materialProperties['numClippingPlanes'] != null &&
        ( materialProperties['numClippingPlanes'] != clipping.numPlanes ||
        materialProperties['numIntersection'] != clipping.numIntersection ) ) {
        needsProgramChange = true;
      } else if ( materialProperties['vertexAlphas'] != vertexAlphas ) {
        needsProgramChange = true;
      } else if ( materialProperties['vertexTangents'] != vertexTangents ) {
        needsProgramChange = true;
      } else if ( materialProperties['morphTargets'] != morphTargets ) {
        needsProgramChange = true;
      } else if ( materialProperties['morphNormals'] != morphNormals ) {
        needsProgramChange = true;
      } else if ( materialProperties['morphColors'] != morphColors ) {
        needsProgramChange = true;
      } else if ( materialProperties['toneMapping'] != toneMapping ) {
        needsProgramChange = true;
      } else if ( materialProperties['morphTargetsCount'] != morphTargetsCount ) {
        needsProgramChange = true;
      }
    } else {
      needsProgramChange = true;
      materialProperties['__version'] = material.version;
    }

    WebGLProgram? program = materialProperties['currentProgram'];

    if (needsProgramChange) {
      program = getProgram( material, scene, object );
    }

    bool refreshProgram = false;
    bool refreshMaterial = false;
    bool refreshLights = false;

    final WebGLUniforms? pUniformS = program?.getUniforms();
    final Map<String, dynamic> mUniformS = materialProperties['uniforms'];

    if (state.useProgram( program?.program ) ) {
      refreshProgram = true;
      refreshMaterial = true;
      refreshLights = true;
    }

    if ( material.id != _currentMaterialId ) {
      _currentMaterialId = material.id;
      refreshMaterial = true;
    }

    if ( refreshProgram || _currentCamera != camera ) {

      // common camera uniforms
      final reverseDepthBuffer = (state.buffers['depth'] as DepthBuffer).getReversed();

      if ( reverseDepthBuffer ) {
        _currentProjectionMatrix.setFrom( camera.projectionMatrix );
        toNormalizedProjectionMatrix( _currentProjectionMatrix );
        toReversedProjectionMatrix( _currentProjectionMatrix );
        pUniformS?.setValue( _gl, 'projectionMatrix', _currentProjectionMatrix );
      } 
      else {
        pUniformS?.setValue( _gl, 'projectionMatrix', camera.projectionMatrix );
      }

      pUniformS?.setValue( _gl, 'viewMatrix', camera.matrixWorldInverse );

      final uCamPos = pUniformS?.map['cameraPosition'];

      if ( uCamPos != null ) {
        uCamPos.setValue( _gl, _vector3.setFromMatrixPosition( camera.matrixWorld ) );
      }

      if ( capabilities.logarithmicDepthBuffer ) {
        pUniformS?.setValue( _gl, 'logDepthBufFC', 2.0 / ( math.log( camera.far + 1.0 ) / math.ln2 ) );
      }

      // consider moving isOrthographic to UniformLib and WebGLMaterials, see https://github.com/mrdoob/three.js/pull/26467#issuecomment-1645185067

      if ( material is MeshPhongMaterial ||
        material is MeshToonMaterial ||
        material is MeshLambertMaterial ||
        material is MeshBasicMaterial ||
        material is MeshStandardMaterial ||
        material is ShaderMaterial ) {
        pUniformS?.setValue( _gl, 'isOrthographic', camera is OrthographicCamera);
      }

      if ( _currentCamera != camera ) {
        _currentCamera = camera;

        // lighting uniforms depend on the camera so enforce an update
        // now, in case this material supports lights - or later, when
        // the next material that does gets activated:

        refreshMaterial = true;		// set to true on material change
        refreshLights = true;		// remains set until update done
      }
    }

    // skinning and morph target uniforms must be set even if material didn't change
    // auto-setting of texture unit for bone and morph texture must go before other textures
    // otherwise textures used for skinning and morphing can take over texture units reserved for other material textures

    if ( object is SkinnedMesh ) {
      pUniformS?.setOptional( _gl, object, 'bindMatrix' );
      pUniformS?.setOptional( _gl, object, 'bindMatrixInverse' );

      final skeleton = object.skeleton;
      if ( skeleton != null) {
        if ( skeleton.boneTexture == null ) skeleton.computeBoneTexture();
        pUniformS?.setValue( _gl, 'boneTexture', skeleton.boneTexture, textures );
      }
    }

    if ( object is BatchedMesh ) {
      pUniformS?.setOptional( _gl, object, 'batchingTexture' );
      pUniformS?.setValue( _gl, 'batchingTexture', object.matricesTexture, textures );

      pUniformS?.setOptional( _gl, object, 'batchingIdTexture' );
      pUniformS?.setValue( _gl, 'batchingIdTexture', object.indirectTexture, textures );

      pUniformS?.setOptional( _gl, object, 'batchingColorTexture' );
      if ( object.colorsTexture != null ) {
        pUniformS?.setValue( _gl, 'batchingColorTexture', object.colorsTexture, textures );
      }
    }

    final morphAttributes = geometry?.morphAttributes;

    if ( morphAttributes?['position'] != null || morphAttributes?['normal'] != null || ( morphAttributes?['color'] != null ) ) {
      morphtargets.update( object, geometry!, program! );
    }

    if ( refreshMaterial || materialProperties['receiveShadow'] != object.receiveShadow ) {
      materialProperties['receiveShadow'] = object.receiveShadow;
      pUniformS?.setValue( _gl, 'receiveShadow', object.receiveShadow );
    }

    // https://github.com/mrdoob/three.js/pull/24467#issuecomment-1209031512

    if ( material is MeshGouraudMaterial && material.envMap != null ) {
      mUniformS['envMap']['value'] = envMap;
      mUniformS['flipEnvMap']['value'] = ( envMap is CubeTexture && envMap.isRenderTargetTexture == false ) ? - 1 : 1;
    }

    if ( material is MeshStandardMaterial && material.envMap == null && scene.environment != null ) {
      mUniformS['envMapIntensity']['value'] = scene.environmentIntensity;
    }

    if ( refreshMaterial ) {
      pUniformS?.setValue( _gl, 'toneMappingExposure', toneMappingExposure );
      if ( materialProperties['needsLights'] == true) {
        markUniformsLightsNeedsUpdate( mUniformS, refreshLights );
      }

      // refresh uniforms common to several materials

      if (fog != null && material.fog == true ) {
        materials.refreshFogUniforms( mUniformS, fog );
      }

      materials.refreshMaterialUniforms( mUniformS, material, _pixelRatio, _height, currentRenderState?.state.transmissionRenderTarget[ camera.id ] );
      WebGLUniforms.upload( _gl, getUniformList( materialProperties ), mUniformS, textures );
    }

    if ( material is ShaderMaterial && material.uniformsNeedUpdate == true ) {
      WebGLUniforms.upload( _gl, getUniformList( materialProperties ), mUniformS, textures );
      material.uniformsNeedUpdate = false;
    }

    if ( material is SpriteMaterial ) {
      pUniformS?.setValue( _gl, 'center', (object as Sprite).center );
    }

    // common matrices

    pUniformS?.setValue( _gl, 'modelViewMatrix', object.modelViewMatrix );
    pUniformS?.setValue( _gl, 'normalMatrix', object.normalMatrix );
    pUniformS?.setValue( _gl, 'modelMatrix', object.matrixWorld );

    // UBOs

    if ( material is ShaderMaterial || material is RawShaderMaterial ) {
      late final List groups;
      if ( material is ShaderMaterial) {
        groups = material.uniformsGroups;
      }
      else if(material is RawShaderMaterial){
        groups = material.uniformsGroups;
      }

      for ( int i = 0, l = groups.length; i < l; i ++ ) {
        final group = groups[i];
        uniformsGroups.update( group, program );
        uniformsGroups.bind( group, program );
      }
    }

    return program!;
  }

  void markUniformsLightsNeedsUpdate(Map<String, dynamic> uniforms, dynamic value) {
    uniforms["ambientLightColor"]["needsUpdate"] = value;
    uniforms["lightProbe"]["needsUpdate"] = value;
    uniforms["directionalLights"]["needsUpdate"] = value;
    uniforms["directionalLightShadows"]["needsUpdate"] = value;
    uniforms["pointLights"]["needsUpdate"] = value;
    uniforms["pointLightShadows"]["needsUpdate"] = value;
    uniforms["spotLights"]["needsUpdate"] = value;
    uniforms["spotLightShadows"]["needsUpdate"] = value;
    uniforms["rectAreaLights"]["needsUpdate"] = value;
    uniforms["hemisphereLights"]["needsUpdate"] = value;
  }

  bool materialNeedsLights(Material material) {
    return material is MeshLambertMaterial ||
        material is MeshToonMaterial ||
        material is MeshPhongMaterial ||
        material is MeshStandardMaterial ||
        material is ShadowMaterial ||
        (material is ShaderMaterial && material.lights == true);
  }

  int getActiveCubeFace() {
    return _currentActiveCubeFace;
  }

  int getActiveMipmapLevel() {
    return _currentActiveMipmapLevel;
  }

  RenderTarget? getRenderTarget() {
    return _currentRenderTarget;
  }

  void setRenderTargetTextures(RenderTarget renderTarget, colorTexture, depthTexture) {
    properties.get(renderTarget.texture)["__webglTexture"] = colorTexture;
    properties.get(renderTarget.depthTexture)["__webglTexture"] = depthTexture;

    final renderTargetProperties = properties.get(renderTarget);
    renderTargetProperties["__hasExternalTextures"] = true;

    //if (renderTargetProperties["__hasExternalTextures"] == true) {
      renderTargetProperties["__autoAllocateDepthBuffer"] = depthTexture == null;

      if (!(renderTargetProperties["__autoAllocateDepthBuffer"] == true)) {
        if (extensions.has('WEBGL_multisampled_render_to_texture') == true) {
          console.warning('WebGLRenderer: extension was disabled because an external texture was provided');
          renderTargetProperties['__useRenderToTexture'] = false;
        }
      }
    //}
  }

  void setRenderTargetFramebuffer(RenderTarget renderTarget, Framebuffer? defaultFramebuffer) {
    final renderTargetProperties = properties.get(renderTarget);
    renderTargetProperties["__webglFramebuffer"] = defaultFramebuffer;
    renderTargetProperties["__useDefaultFramebuffer"] = defaultFramebuffer == null;
  }

  void setRenderTarget(RenderTarget? renderTarget, [int activeCubeFace = 0, int activeMipmapLevel = 0]) {
    _currentRenderTarget = renderTarget;
    _currentActiveCubeFace = activeCubeFace;
    _currentActiveMipmapLevel = activeMipmapLevel;

    bool useDefaultFramebuffer = true;
    Framebuffer? framebuffer;
    bool isCube = false;
    bool isRenderTarget3D = false;

    if (renderTarget != null) {
      final renderTargetProperties = properties.get(renderTarget);

      if (renderTargetProperties["__useDefaultFramebuffer"] != null) {
        // We need to make sure to rebind the framebuffer.
        state.bindFramebuffer(WebGL.FRAMEBUFFER, null);
        useDefaultFramebuffer = false;
      } 
      else if (renderTargetProperties["__webglFramebuffer"] == null) {
        textures.setupRenderTarget(renderTarget);
      } 
      else if (renderTargetProperties["__hasExternalTextures"] == true) {
        // Color and depth texture must be rebound in order for the swapchain to update.
        textures.rebindTextures(renderTarget, properties.get(renderTarget.texture)["__webglTexture"],properties.get(renderTarget.depthTexture)["__webglTexture"]);
      }else if ( renderTarget.depthBuffer ) {
        // check if the depth texture is already bound to the frame buffer and that it's been initialized
        final depthTexture = renderTarget.depthTexture;
        if ( renderTargetProperties['__boundDepthTexture'] != depthTexture ) {

          // check if the depth texture is compatible
          if (
            depthTexture != null &&
            properties.has( depthTexture ) &&
            ( renderTarget.width != depthTexture.image.width || renderTarget.height != depthTexture.image.height )
          ) {
            throw( 'WebGLRenderTarget: Attached DepthTexture is initialized to the incorrect size.' );
          }

          // Swap the depth buffer to the currently attached one
          textures.setupDepthRenderbuffer( renderTarget );
        }
      }

      final texture = renderTarget.texture;

      if (texture is Data3DTexture || texture is DataArrayTexture || texture is CompressedArrayTexture) {
        isRenderTarget3D = true;
      }

      final webglFramebuffer = properties.get(renderTarget)["__webglFramebuffer"];

      if (renderTarget is WebGLCubeRenderTarget) {
        if (webglFramebuffer[ activeCubeFace ] is List) {
          framebuffer = webglFramebuffer[ activeCubeFace ][ activeMipmapLevel ];
        } 
        else {
          framebuffer = webglFramebuffer[ activeCubeFace ];
        }
        isCube = true;
      } 
      else if ((renderTarget.samples > 0) && textures.useMultisampledRTT(renderTarget) == false) {
        framebuffer = properties.get(renderTarget)["__webglMultisampledFramebuffer"];
      } 
      else {
        if (webglFramebuffer is List) {
          framebuffer = webglFramebuffer[ activeMipmapLevel ];
        } else {
          framebuffer = webglFramebuffer;
        }
      }

      _currentViewport.setFrom(renderTarget.viewport);
      _currentScissor.setFrom(renderTarget.scissor);
      _currentScissorTest = renderTarget.scissorTest;
    } 
    else {
      _currentViewport.setFrom(_viewport).scale(_pixelRatio).floor();
      _currentScissor.setFrom(_scissor).scale(_pixelRatio).floor();
      _currentScissorTest = _scissorTest;
    }
    
    // Use a scratch frame buffer if rendering to a mip level to avoid depth buffers
    // being bound that are different sizes.
    if ( activeMipmapLevel != 0 ) {
      framebuffer = _scratchFrameBuffer;
    }

    final framebufferBound = state.bindFramebuffer(WebGL.FRAMEBUFFER, framebuffer);
    
    if (framebufferBound && capabilities.drawBuffers && useDefaultFramebuffer) {
      state.drawBuffers(renderTarget, framebuffer);
    }

    state.viewport(_currentViewport);
    state.scissor(_currentScissor);
    state.setScissorTest(_currentScissorTest!);

    if (isCube) {
      final textureProperties = properties.get(renderTarget!.texture);
      _gl.framebufferTexture2D(WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_CUBE_MAP_POSITIVE_X + activeCubeFace, textureProperties["__webglTexture"], activeMipmapLevel);
    } 
    else if (isRenderTarget3D) {
      final textureProperties = properties.get(renderTarget!.texture);
      final layer = activeCubeFace;
      _gl.framebufferTextureLayer( WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, textureProperties["__webglTexture"], activeMipmapLevel, layer);
    }
    else if ( renderTarget != null && activeMipmapLevel != 0 ) {
      // Only bind the frame buffer if we are using a scratch frame buffer to render to a mipmap.
      // If we rebind the texture when using a multi sample buffer then an error about inconsistent samples will be thrown.
      final textureProperties = properties.get( renderTarget.texture );
      _gl.framebufferTexture2D( WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D, textureProperties['__webglTexture'], activeMipmapLevel );
    }

    _currentMaterialId = -1; // reset current material to ensure correct uniform bindings
  }

  void readRenderTargetPixels(WebGLRenderTarget renderTarget, int x, int y, int width, int height, NativeArray buffer, [activeCubeFaceIndex]) {
    dynamic framebuffer = properties.get(renderTarget)["__webglFramebuffer"]; //can be Map or int

    if (renderTarget is WebGLCubeRenderTarget && activeCubeFaceIndex != null) {
      framebuffer = framebuffer?[activeCubeFaceIndex];
    }

    if (framebuffer != null) {
      state.bindFramebuffer(WebGL.FRAMEBUFFER, framebuffer);

      try {
        final texture = renderTarget.texture;
        final textureFormat = texture.format;
        final textureType = texture.type;

        if (textureFormat != RGBAFormat &&
            utils.convert(textureFormat) != _gl.getParameter(WebGL.IMPLEMENTATION_COLOR_READ_FORMAT)) {
          console.warning('WebGLRenderer.readRenderTargetPixels: renderTarget is not in RGBA or implementation defined format.');
          return;
        }

        final halfFloatSupportedByExt = textureType == HalfFloatType &&
            (extensions.has('EXT_color_buffer_half_float') ||
                (capabilities.isWebGL2 && extensions.has('EXT_color_buffer_float')));

        if (textureType != UnsignedByteType &&
            (kIsWeb && utils.convert(textureType) != _gl.getParameter(WebGL.IMPLEMENTATION_COLOR_READ_TYPE)) && // IE11, Edge and Chrome Mac < 52 (#9513)
            !(textureType == FloatType &&
                (capabilities.isWebGL2 ||
                    extensions.get('OES_texture_float') ||
                    extensions.get('WEBGL_color_buffer_float'))) && // Chrome Mac >= 52 and Firefox
            !halfFloatSupportedByExt) {
          console.warning('WebGLRenderer.readRenderTargetPixels: renderTarget is not in UnsignedByteType or implementation defined type.');
          return;
        }
        // the following if statement ensures valid read requests (no out-of-bounds pixels, see #8604)

        if ((x >= 0 && x <= (renderTarget.width - width)) && (y >= 0 && y <= (renderTarget.height - height))) {
          _gl.readPixels(x, y, width, height, utils.convert(textureFormat), utils.convert(textureType), kIsWeb?buffer.data:buffer);
        }
      } finally {
        final framebuffer = (_currentRenderTarget != null) ? properties.get(_currentRenderTarget)["__webglFramebuffer"] : null;
        state.bindFramebuffer(WebGL.FRAMEBUFFER, framebuffer);
      }
    }
  }

  void copyFramebufferToTexture(Vector? position, Texture? texture, {int level = 0}) {
    //console.warning('copyFramebufferToTexture not supported');
    if (texture is! FramebufferTexture) {
      console.warning('WebGLRenderer: copyFramebufferToTexture() can only be used with FramebufferTexture.');
      return;
    }

    final levelScale = math.pow(2, -level);
    final width = (texture.image.width * levelScale).floor();
    final height = (texture.image.height * levelScale).floor();

    final x = position != null ? position.x.toInt() : 0;
    final y = position != null ? position.y.toInt() : 0;

    textures.setTexture2D(texture, 0);
    _gl.copyTexSubImage2D(WebGL.TEXTURE_2D, level, 0, 0, x, y, width, height);
    state.unbindTexture(WebGLTexture(WebGL.TEXTURE_2D));
  }

  void copyTextureToTexture(Texture srcTexture, Texture dstTexture, {srcRegion, dstPosition, int srcLevel = 0, dstLevel}) {
    if ( dstLevel == null ) {
      if ( srcLevel != 0 ) {
        dstLevel = srcLevel;
        srcLevel = 0;
      } 
      else {
        dstLevel = 0;
      }
    }
    
    // gather the necessary dimensions to copy
    int width, height, depth, minX, minY, minZ;
    int dstX, dstY, dstZ;
    final image = srcTexture is CompressedTexture ? srcTexture.mipmaps[ dstLevel ] : srcTexture.image;
    if ( srcRegion != null ) {
      width = srcRegion.max.x - srcRegion.min.x;
      height = srcRegion.max.y - srcRegion.min.y;
      depth = srcRegion is BoundingBox ? (srcRegion.max.z - srcRegion.min.z).toInt() : 1;
      minX = srcRegion.min.x;
      minY = srcRegion.min.y;
      minZ = srcRegion is BoundingBox ? srcRegion.min.z.toInt() : 0;
    } 
    else {
      final levelScale = math.pow( 2, - srcLevel );
      width = ( image.width * levelScale ).floor();
      height = ( image.height * levelScale ).floor();
      if ( srcTexture is DataArrayTexture ) {
        depth = image.depth;
      } 
      else if ( srcTexture is Data3DTexture ) {
        depth = ( image.depth * levelScale ).floor();
      } 
      else {
        depth = 1;
      }

      minX = 0;
      minY = 0;
      minZ = 0;
    }

    if ( dstPosition != null ) {
      dstX = dstPosition.x;
      dstY = dstPosition.y;
      dstZ = dstPosition.z;
    } 
    else {
      dstX = 0;
      dstY = 0;
      dstZ = 0;
    }

    // Set up the destination target
    final glFormat = utils.convert( dstTexture.format );
    final glType = utils.convert( dstTexture.type );
    int glTarget = 0;

    if ( dstTexture is Data3DTexture ) {
      textures.setTexture3D( dstTexture, 0 );
      glTarget = WebGL.TEXTURE_3D;
    } 
    else if ( dstTexture is DataArrayTexture || dstTexture is CompressedArrayTexture ) {
      textures.setTexture2DArray( dstTexture, 0 );
      glTarget = WebGL.TEXTURE_2D_ARRAY;
    } 
    else {
      textures.setTexture2D( dstTexture, 0 );
      glTarget = WebGL.TEXTURE_2D;
    }
    // if(kIsWeb){
    //   _gl.pixelStorei( WebGL.UNPACK_FLIP_Y_WEBGL, dstTexture.flipY?1:0 );
    //   _gl.pixelStorei( WebGL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, dstTexture.premultiplyAlpha?1:0 );
    //   _gl.pixelStorei( WebGL.UNPACK_ALIGNMENT, dstTexture.unpackAlignment );
    // }

    // used for copying data from cpu
    final currentUnpackRowLen = _gl.getParameter( WebGL.UNPACK_ROW_LENGTH );
    final currentUnpackImageHeight = _gl.getParameter( WebGL.UNPACK_IMAGE_HEIGHT );
    final currentUnpackSkipPixels = _gl.getParameter( WebGL.UNPACK_SKIP_PIXELS );
    final currentUnpackSkipRows = _gl.getParameter( WebGL.UNPACK_SKIP_ROWS );
    final currentUnpackSkipImages = _gl.getParameter( WebGL.UNPACK_SKIP_IMAGES );

    _gl.pixelStorei( WebGL.UNPACK_ROW_LENGTH, image.width );
    _gl.pixelStorei( WebGL.UNPACK_IMAGE_HEIGHT, image.height );
    _gl.pixelStorei( WebGL.UNPACK_SKIP_PIXELS, minX );
    _gl.pixelStorei( WebGL.UNPACK_SKIP_ROWS, minY );
    _gl.pixelStorei( WebGL.UNPACK_SKIP_IMAGES, minZ );

    // set up the src texture
    final isSrc3D = srcTexture is DataArrayTexture || srcTexture is Data3DTexture;
    final isDst3D = dstTexture is DataArrayTexture || dstTexture is Data3DTexture;
    if ( srcTexture.isDepthTexture ) {

      final srcTextureProperties = properties.get( srcTexture );
      final dstTextureProperties = properties.get( dstTexture );
      final srcRenderTargetProperties = properties.get( srcTextureProperties['__renderTarget'] );
      final dstRenderTargetProperties = properties.get( dstTextureProperties['__renderTarget'] );
      state.bindFramebuffer( WebGL.READ_FRAMEBUFFER, srcRenderTargetProperties['__webglFramebuffer'] );
      state.bindFramebuffer( WebGL.DRAW_FRAMEBUFFER, dstRenderTargetProperties['__webglFramebuffer'] );

      for (int i = 0; i < depth; i ++ ) {
        // if the source or destination are a 3d target then a layer needs to be bound
        if ( isSrc3D ) {
          _gl.framebufferTextureLayer( WebGL.READ_FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, properties.get( srcTexture )['__webglTexture'], srcLevel, minZ + i );
          _gl.framebufferTextureLayer( WebGL.DRAW_FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, properties.get( dstTexture )['__webglTexture'], dstLevel, dstZ + i );
        }

        _gl.blitFramebuffer( minX, minY, width, height, dstX, dstY, width, height, WebGL.DEPTH_BUFFER_BIT, WebGL.NEAREST );
      }

      state.bindFramebuffer( WebGL.READ_FRAMEBUFFER, null );
      state.bindFramebuffer( WebGL.DRAW_FRAMEBUFFER, null );

    } 
    else if ( srcLevel != 0 || srcTexture.isRenderTargetTexture || properties.has( srcTexture ) ) {
      // get the appropriate frame buffers
      final srcTextureProperties = properties.get( srcTexture );
      final dstTextureProperties = properties.get( dstTexture );

      // bind the frame buffer targets
      state.bindFramebuffer( WebGL.READ_FRAMEBUFFER, _srcFramebuffer );
      state.bindFramebuffer( WebGL.DRAW_FRAMEBUFFER, _dstFramebuffer );

      for (int i = 0; i < depth; i ++ ) {

        // assign the correct layers and mip maps to the frame buffers
        if ( isSrc3D ) {
          _gl.framebufferTextureLayer( WebGL.READ_FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, srcTextureProperties['__webglTexture'], srcLevel, minZ + i );
        } 
        else {
          _gl.framebufferTexture2D( WebGL.READ_FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D, srcTextureProperties['__webglTexture'], srcLevel );
        }

        if ( isDst3D ) {
          _gl.framebufferTextureLayer( WebGL.DRAW_FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, dstTextureProperties['__webglTexture'], dstLevel, dstZ + i );
        } 
        else {
          _gl.framebufferTexture2D( WebGL.DRAW_FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D, dstTextureProperties['__webglTexture'], dstLevel );
        }

        // copy the data using the fastest function that can achieve the copy
        if ( srcLevel != 0 ) {
          _gl.blitFramebuffer( minX, minY, width, height, dstX, dstY, width, height, WebGL.COLOR_BUFFER_BIT, WebGL.NEAREST );
        } else if ( isDst3D ) {
          _gl.copyTexSubImage3D( glTarget, dstLevel, dstX, dstY, dstZ + i, minX, minY, width, height );
        } else {
          _gl.copyTexSubImage2D( glTarget, dstLevel, dstX, dstY, minX, minY, width, height );
        }
      }

      // unbind read, draw buffers
      state.bindFramebuffer( WebGL.READ_FRAMEBUFFER, null );
      state.bindFramebuffer( WebGL.DRAW_FRAMEBUFFER, null );
    } 
    else {

      if ( isDst3D ) {
        // copy data into the 3d texture
        if ( srcTexture is DataTexture || srcTexture is Data3DTexture ) {
          _gl.texSubImage3D( glTarget, dstLevel, dstX, dstY, dstZ, width, height, depth, glFormat, glType, image.data );
        } 
        else if ( dstTexture is CompressedArrayTexture ) {
          _gl.compressedTexSubImage3D( glTarget, dstLevel, dstX, dstY, dstZ, width, height, depth, glFormat, image.data );
        } 
        else {
          _gl.texSubImage3D( glTarget, dstLevel, dstX, dstY, dstZ, width, height, depth, glFormat, glType, image );
        }
      } 
      else {
        // copy data into the 2d texture
        if ( srcTexture is DataTexture ) {
          _gl.texSubImage2D( WebGL.TEXTURE_2D, dstLevel, dstX, dstY, width, height, glFormat, glType, image.data );
        } 
        else if ( srcTexture.isCompressedTexture ) {
          _gl.compressedTexSubImage2D( WebGL.TEXTURE_2D, dstLevel, dstX, dstY, image.width, image.height, glFormat, image.data );
        } 
        else {
          _gl.texSubImage2D( WebGL.TEXTURE_2D, dstLevel, dstX, dstY, width, height, glFormat, glType, image );
        }
      }
    }

    // reset values
    _gl.pixelStorei( WebGL.UNPACK_ROW_LENGTH, currentUnpackRowLen );
    _gl.pixelStorei( WebGL.UNPACK_IMAGE_HEIGHT, currentUnpackImageHeight );
    _gl.pixelStorei( WebGL.UNPACK_SKIP_PIXELS, currentUnpackSkipPixels );
    _gl.pixelStorei( WebGL.UNPACK_SKIP_ROWS, currentUnpackSkipRows );
    _gl.pixelStorei( WebGL.UNPACK_SKIP_IMAGES, currentUnpackSkipImages );

    // Generate mipmaps only when copying level 0
    if ( dstLevel == 0 && dstTexture.generateMipmaps ) {
      _gl.generateMipmap( glTarget );
    }

    state.unbindTexture();
  }

  void copyTextureToTexture3D(
    Texture srcTexture,
    Texture dstTexture, {
    srcRegion, 
    dstPosition,
    int level = 0,
  }) {
    return copyTextureToTexture( srcTexture, dstTexture, srcRegion: srcRegion, dstPosition: dstPosition, srcLevel: level);
  }

  void initRenderTarget( target ) {
    if ( properties.get( target )['__webglFramebuffer'] == null ) {
      textures.setupRenderTarget( target );
    }
  }

  void initTexture(Texture texture) {
    if (texture is CubeTexture) {
			textures.setTextureCube( texture, 0 );
		}
    else if (texture is Data3DTexture ) {
      textures.setTexture3D( texture, 0 );
    } 
    else if ( texture is DataArrayTexture || texture is CompressedArrayTexture ) {
      textures.setTexture2DArray( texture, 0 );
    }
    else{
      textures.setTexture2D(texture, 0);
    }

    state.unbindTexture();
  }

  WebGLTexture getRenderTargetGLTexture(RenderTarget renderTarget) {
    final textureProperties = properties.get(renderTarget.texture);
    return textureProperties["__webglTexture"];
  }

  void resetState() {
    _currentActiveCubeFace = 0;
    _currentActiveMipmapLevel = 0;
    _currentRenderTarget = null;

    state.reset();
    bindingStates.reset();
  }

	int get coordinateSystem => WebGLCoordinateSystem;
	String get outputColorSpace => _outputColorSpace;
	set outputColorSpace(String colorSpace ) {
		_outputColorSpace = colorSpace;

		final gl = this.getContext();
		gl.drawingBufferColorSpace = colorSpace == DisplayP3ColorSpace ? 'display-p3' : 'srgb';
		gl.unpackColorSpace = ColorManagement.workingColorSpace == LinearDisplayP3ColorSpace ? 'display-p3' : 'srgb';
	}

  void toNormalizedProjectionMatrix(Matrix4 projectionMatrix ) {
    final m = projectionMatrix.storage;

    // Convert [-1, 1] to [0, 1] projection matrix
    m[ 2 ] = 0.5 * m[ 2 ] + 0.5 * m[ 3 ];
    m[ 6 ] = 0.5 * m[ 6 ] + 0.5 * m[ 7 ];
    m[ 10 ] = 0.5 * m[ 10 ] + 0.5 * m[ 11 ];
    m[ 14 ] = 0.5 * m[ 14 ] + 0.5 * m[ 15 ];
  }

  void toReversedProjectionMatrix(Matrix4 projectionMatrix ) {
    final m = projectionMatrix.storage;
    final isPerspectiveMatrix = m[ 11 ] == - 1;

    // Reverse [0, 1] projection matrix
    if ( isPerspectiveMatrix ) {
      m[ 10 ] = - m[ 10 ] - 1;
      m[ 14 ] = - m[ 14 ];
    } 
    else {
      m[ 10 ] = - m[ 10 ];
      m[ 14 ] = - m[ 14 ] + 1;
    }
  }
}
