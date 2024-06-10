part of three_renderers;

class WebGLRenderer {
  late Map<String, dynamic> parameters;

  bool alpha = false;
  bool depth = true;
  bool stencil = true;
  bool _antialias = false;
  bool premultipliedAlpha = true;
  bool preserveDrawingBuffer = false;
  String powerPreference = "default";
  bool failIfMajorPerformanceCaveat = false;

  late WebGLRenderList? currentRenderList;
  late WebGLRenderState? currentRenderState;

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

  // scene graph
  bool sortObjects = true;

  // user-defined clipping

  List<Plane> clippingPlanes = [];
  bool localClippingEnabled = false;

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

  RenderTarget? _transmissionRenderTarget;

  // camera matrices cache

  final projScreenMatrix = Matrix4.identity();

  final _vector2 = Vector2.zero();
  final _vector3 = Vector3.zero();

  final _emptyScene = Scene();

  double getTargetPixelRatio() => _currentRenderTarget == null ? _pixelRatio : 1.0;

  // initialize

  late RenderingContext _gl;

  RenderingContext get gl => _gl;

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

  late WebGLShadowMap shadowMap;

  WebGLRenderer(Map<String, dynamic>? parameters) {
    this.parameters = parameters ?? <String, dynamic>{};

    _width = this.parameters["width"].toDouble();
    _height = this.parameters["height"].toDouble();

    depth = this.parameters["depth"] ?? true;
    stencil = this.parameters["stencil"] ?? true;
    _antialias = this.parameters["antialias"] ?? false;
    premultipliedAlpha = this.parameters["premultipliedAlpha"] ?? true;
    preserveDrawingBuffer = this.parameters["preserveDrawingBuffer"] ?? false;
    powerPreference = this.parameters["powerPreference"] ?? "default";

    failIfMajorPerformanceCaveat = this.parameters["failIfMajorPerformanceCaveat"] ?? false;

    alpha = this.parameters["alpha"] ?? false;

    _viewport = Vector4(0, 0, width, height);
    _scissor = Vector4(0, 0, width, height);

    _gl = this.parameters["gl"];

    initGLContext();
  }

  void initGLContext() {
    extensions = WebGLExtensions(_gl);
    capabilities = WebGLCapabilities(_gl, extensions, parameters);

    extensions.init(capabilities);

    utils = WebGLUtils(extensions, capabilities);

    state = WebGLState(_gl, extensions, capabilities);

    info = WebGLInfo(_gl);
    properties = WebGLProperties();
    textures = WebGLTextures(_gl, extensions, state, properties, capabilities, utils, info);

    cubemaps = WebGLCubeMaps(this);
    cubeuvmaps = WebGLCubeUVMaps(this);
    attributes = WebGLAttributes(_gl, capabilities);
    bindingStates = WebGLBindingStates(_gl, extensions, attributes, capabilities);
    geometries = WebGLGeometries(_gl, attributes, info, bindingStates);
    objects = WebGLObjects(_gl, geometries, attributes, info);
    morphtargets = WebGLMorphtargets(_gl, capabilities, textures);
    clipping = WebGLClipping(properties);
    programCache = WebGLPrograms(this, cubemaps, cubeuvmaps, extensions, capabilities, bindingStates, clipping);
    materials = WebGLMaterials(this, properties);
    renderLists = WebGLRenderLists();
    renderStates = WebGLRenderStates(extensions, capabilities);
    background = WebGLBackground(this, cubemaps, state, objects, alpha, premultipliedAlpha);

    bufferRenderer = WebGLBufferRenderer(_gl, extensions, info, capabilities);
    indexedBufferRenderer = WebGLIndexedBufferRenderer(_gl, extensions, info, capabilities);

    info.programs = programCache.programs;

    // xr
    xr = WebXRManager(this, _gl);

    // shadow map

    shadowMap = WebGLShadowMap(this, objects, capabilities);

    // print("3 initGLContext ..... ");
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
    target.setValues(width.toDouble(), height.toDouble());
    return target;
  }

  void setSize(double width, double height, [bool updateStyle = false]) {
    _width = width;
    _height = height;
    setViewport(0, 0, width, height);
  }

  Vector2 getDrawingBufferSize(Vector2 target) {
    target.setValues(width * _pixelRatio, height * _pixelRatio);
    target.floor();
    return target;
  }

  void setDrawingBufferSize(double width, double height, double pixelRatio) {
    _width = width;
    _height = height;
    _pixelRatio = pixelRatio;
    console.info("WebGLRenderer setDrawingBufferSize ");
    setViewport(0, 0, width, height);
  }

  Vector4 getCurrentViewport(Vector4 target) {
    target.setFrom(_currentViewport);
    return target;
  }

  Vector4 getViewport(Vector4 target) {
    target.setFrom(_viewport);
    return target;
  }

  void setViewport(double x, double y, double width, double height) {
    _viewport.setValues(x, y, width, height);
    _currentViewport.setFrom(_viewport);
    _currentViewport.scale(_pixelRatio);
    _currentViewport.floor();
    state.viewport(_currentViewport);
  }

  Vector4 getScissor(Vector4 target) {
    target.setFrom(_scissor);
    return target;
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

  void clear([bool color = true, bool depth = true, bool stencil = true]) {
    int bits = 0;

    if (color) bits |= WebGL.COLOR_BUFFER_BIT;
    if (depth) bits |= WebGL.DEPTH_BUFFER_BIT;
    if (stencil) bits |= WebGL.STENCIL_BUFFER_BIT;

    _gl.clear(bits);
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
    state.reset();
    attributes.dispose();
    renderLists.dispose();
    renderStates.dispose();
    properties.dispose();
    cubemaps.dispose();
    cubeuvmaps.dispose();
    objects.dispose();
    bindingStates.dispose();
    programCache.dispose();

    textures.dispose();
    geometries.dispose();
    //materials.renderer.dispose();
    
    if (_transmissionRenderTarget != null) {
      _transmissionRenderTarget!.dispose();
      _transmissionRenderTarget = null;
    }
  }

  // Events
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
    BufferAttribute? position = geometry.attributes["position"];

    // print(" WebGLRenderer.renderBufferDirect geometry.index ${index?.count} - ${index} position: - ${position}  ");
    if (index == null) {
      if (position == null || position.count == 0) return;
    } 
    else if (index.count == 0) {
      return;
    }
    //
    int rangeFactor = 1;
    if (material.wireframe == true) {
      index = geometries.getWireframeAttribute(geometry);
      if(kIsWeb){
        rangeFactor = 2;
      }
    }

    if (geometry.morphAttributes["position"] != null || geometry.morphAttributes["normal"] != null) {
      morphtargets.update(object, geometry, material, program);
    }

    bindingStates.setup(object, material, program, geometry, index);

    Map<String, dynamic> attribute;
    BaseWebGLBufferRenderer renderer = bufferRenderer;

    if (index != null) {
      attribute = attributes.get(index);
      renderer = indexedBufferRenderer;
      // print(index);
      // print("WebGLRenderer.renderBufferDirect index attribute: ${attribute}  ");
      renderer.setIndex(attribute);
    }

    int dataCount = (index != null) ? index.count : position!.count;

    final rangeStart = geometry.drawRange["start"]! * rangeFactor;
    final rangeCount = geometry.drawRange["count"]! * rangeFactor;

    final groupStart = group != null ? group["start"] * rangeFactor : 0;
    final groupCount = group != null ? group["count"] * rangeFactor : double.maxFinite.toInt();

    final drawStart = math.max<int>(rangeStart, groupStart);

    final drawEnd = math.min<int>(math.min(dataCount, rangeStart + rangeCount), groupStart + groupCount) - 1;

    final drawCount = math.max(0, drawEnd - drawStart + 1);

    if (drawCount == 0) return;

    if (object is Mesh) {
      if (material.wireframe == true) {
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

    if (object is InstancedMesh) {
      renderer.renderInstances(drawStart, drawCount, object.count!);
    } 
    else if (geometry is InstancedBufferGeometry) {
      final instanceCount = math.min(geometry.instanceCount!, geometry.maxInstanceCount!);
      renderer.renderInstances(drawStart, drawCount, instanceCount);
    } 
    else {
      renderer.render(drawStart, drawCount);
    }

    // print("renderBufferDirect - 1: ${DateTime.now().millisecondsSinceEpoch} - ${DateTime.now().microsecondsSinceEpoch}  ");
  }

  // Compile

  void compile(Object3D scene, Camera camera) {
    currentRenderState = renderStates.get(scene);
    currentRenderState!.init();
    renderStateStack.add(currentRenderState!);

    scene.traverseVisible((object) {
      if (object is Light && object.layers.test(camera.layers)) {
        currentRenderState!.pushLight(object);

        if (object.castShadow) {
          currentRenderState!.pushShadow(object);
        }
      }
    });

    currentRenderState!.setupLights(physicallyCorrectLights);

    scene.traverse((object) {
      final material = object.material;

      if (material != null) {
        if (material is GroupMaterial) {
          for (int i = 0; i < material.children.length; i++) {
            final material2 = material.children[i];
            getProgram(material2, scene, object);
          }
        } else {
          getProgram(material, scene, object);
        }
      }
    });

    renderStateStack.removeLast();
    currentRenderState = null;
  }

  // Animation Loop

  void Function(double)? onAnimationFrameCallback;

  void onAnimationFrame(double time) {
    if ( xr.isPresenting ) return;
    if (onAnimationFrameCallback != null) onAnimationFrameCallback!(time);
  }

  // Rendering

  void render(Object3D scene, Camera camera) {
    if (_isContextLost == true) return;

    // update scene graph
    if (scene.autoUpdate == true) scene.updateMatrixWorld();

    // update camera matrices and frustum

    if (camera.parent == null) camera.updateMatrixWorld();

    if ( xr.enabled == true && xr.isPresenting == true ) {
    	camera = xr.getCamera();
    }

    if (scene is Scene) {
      if (scene.onBeforeRender != null) {
        scene.onBeforeRender!(renderer: this, scene: scene, camera: camera, renderTarget: _currentRenderTarget);
      }
    }

    currentRenderState = renderStates.get(scene, renderCallDepth: renderStateStack.length);
    currentRenderState!.init();

    renderStateStack.add(currentRenderState!);

    projScreenMatrix.multiply2(camera.projectionMatrix, camera.matrixWorldInverse);

    _frustum.setFromMatrix(projScreenMatrix);

    _localClippingEnabled = localClippingEnabled;
    _clippingEnabled = clipping.init(clippingPlanes, _localClippingEnabled, camera);

    currentRenderList = renderLists.get(scene, renderListStack.length);
    currentRenderList!.init();

    renderListStack.add(currentRenderList!);

    projectObject(scene, camera, 0, sortObjects);

    currentRenderList!.finish();

    if (sortObjects == true) {
      currentRenderList!.sort(_opaqueSort, _transparentSort);
    }

    if (_clippingEnabled == true) clipping.beginShadows();

    final shadowsArray = currentRenderState!.state.shadowsArray;
    
    shadowMap.render(shadowsArray, scene, camera);

    currentRenderState!.setupLights(physicallyCorrectLights);
    currentRenderState!.setupLightsView(camera);

    if (_clippingEnabled == true) clipping.endShadows();

    if (info.autoReset == true) info.reset();
    background.render(currentRenderList!, scene);

    // render scene

    currentRenderState!.setupLights(physicallyCorrectLights);

    if (camera is ArrayCamera) {
      final cameras = (camera).cameras;

      for (int i = 0, l = cameras.length; i < l; i++) {
        final camera2 = cameras[i];

        renderScene(currentRenderList!, scene, camera2, camera2.viewport);
      }
    } else {
      renderScene(currentRenderList!, scene, camera);
    }

    if (_currentRenderTarget != null) {
      // resolve multisample renderbuffers to a single-sample texture if necessary
      textures.updateMultisampleRenderTarget(_currentRenderTarget!);

      // Generate mipmap if we're using any kind of mipmap filtering
      textures.updateRenderTargetMipmap(_currentRenderTarget!);
    }

    if (scene is Scene) {
      scene.onAfterRender(renderer: this, scene: scene, camera: camera);
    }

    _gl.finish();

    bindingStates.resetDefaultState();
    _currentMaterialId = -1;
    _currentCamera = null;

    renderStateStack.removeLast();
    if (renderStateStack.isNotEmpty) {
      currentRenderState = renderStateStack[renderStateStack.length - 1];
    } else {
      currentRenderState = null;
    }

    renderListStack.removeLast();

    if (renderListStack.isNotEmpty) {
      currentRenderList = renderListStack[renderListStack.length - 1];
    } else {
      currentRenderList = null;
    }
  }

  void projectObject(Object3D object, Camera camera, int groupOrder, bool sortObjects) {
    // print("projectObject object: ${object} name: ${object.name} tag: ${object.tag}  ${object.visible} ${object.scale.toJson()} ${object.children.length}  ");

    if (object.visible == false) return;

    bool visible = object.layers.test(camera.layers);

    // print("projectObject object: ${object.type} ${object.id} visible: ${visible} groupOrder: ${groupOrder} sortObjects: ${sortObjects} ");

    if (visible) {
      if (object is Group || object.type == "AnimationObject") {
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
            _vector3..setFromMatrixPosition(object.matrixWorld)..applyMatrix4(projScreenMatrix);
          }

          BufferGeometry geometry = objects.update(object);
          final material = object.material;

          if (material != null && material.visible) {
            currentRenderList!.push(object, geometry, material, groupOrder, _vector3.z, null);
          }
        }
      } 
      else if (object is Mesh || object is Line || object is Points) {
        if (object is SkinnedMesh) {
          // update skeleton only once in a frame
          if (object.skeleton!.frame != info.render["frame"]) {
            object.skeleton!.update();
            object.skeleton!.frame = info.render["frame"]!;
          }
        }

        // print("object: ${object.type} ${!object.frustumCulled} ${_frustum.intersectsObject(object)} ");

        if (!object.frustumCulled || _frustum.intersectsObject(object)) {
          if (sortObjects) {
            _vector3..setFromMatrixPosition(object.matrixWorld)..applyMatrix4(projScreenMatrix);
          }

          final geometry = objects.update(object);

          final material = object.material;

          if (material is GroupMaterial) {
            final groups = geometry.groups;

            if (groups.isNotEmpty) {
              for (int i = 0, l = groups.length; i < l; i++) {
                Map<String, dynamic> group = groups[i];
                if(group["materialIndex"] < material.children.length){
                  final groupMaterial = material.children[group["materialIndex"]];

                  if (groupMaterial.visible) {
                    currentRenderList!.push(object, geometry, groupMaterial, groupOrder, _vector3.z, group);
                  }
                }
              }
            } 
            else {
              //for (final element in material) {
                if (material.visible) {
                  currentRenderList!.push(object, geometry, material, groupOrder, _vector3.z, null);
                }
              //}
            }
          } else if (material != null && material.visible) {
            currentRenderList!.push(object, geometry, material, groupOrder, _vector3.z, null);
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

    if (transmissiveObjects.isNotEmpty) {
      renderTransmissionPass(opaqueObjects, scene, camera);
    }
    
    if (viewport != null){ 
      _currentViewport.setFrom(viewport);
      state.viewport(_currentViewport);
    }

    if (opaqueObjects.isNotEmpty) renderObjects(opaqueObjects, scene, camera);
    if (transmissiveObjects.isNotEmpty) {
      renderObjects(transmissiveObjects, scene, camera);
    }
    if (transparentObjects.isNotEmpty) {
      renderObjects(transparentObjects, scene, camera);
    }

    // Ensure depth buffer writing is enabled so it can be cleared on next render

    state.buffers["depth"].setTest(true);
    state.buffers["depth"].setMask(true);
    state.buffers["color"].setMask(true);

    state.setPolygonOffset(false, null, null);
  }

  void renderTransmissionPass(List<RenderItem> opaqueObjects, Object3D scene, Camera camera) {
    bool isWebGL2 = capabilities.isWebGL2;

    if (_transmissionRenderTarget == null) {
      final opts = WebGLRenderTargetOptions({
        "generateMipmaps": true,
        "type": utils.convert(HalfFloatType) != null ? HalfFloatType : UnsignedByteType,
        "minFilter": LinearMipmapLinearFilter,
        "samples": (isWebGL2 && _antialias == true) ? 4 : 0
      });

      _transmissionRenderTarget = WebGLRenderTarget(1, 1, opts);
    }

    // set size of transmission render target to half size of drawing buffer

    getDrawingBufferSize(_vector2);

    if (isWebGL2) {
      _transmissionRenderTarget!.setSize(
        _vector2.x.toInt(),
        _vector2.y.toInt(),
      );
    } else {
      _transmissionRenderTarget!.setSize(MathUtils.floorPowerOfTwo(_vector2.x).toInt(), MathUtils.floorPowerOfTwo(_vector2.y).toInt());
    }

    final currentRenderTarget = getRenderTarget();
    setRenderTarget(_transmissionRenderTarget);
    clear(true, true, true);

    // Turn off the features which can affect the frag color for opaque objects pass.
    // Otherwise they are applied twice in opaque objects pass and transmission objects pass.
    final currentToneMapping = toneMapping;
    toneMapping = NoToneMapping;

    renderObjects(opaqueObjects, scene, camera);

    toneMapping = currentToneMapping;

    textures.updateMultisampleRenderTarget(_transmissionRenderTarget!);
    textures.updateRenderTargetMipmap(_transmissionRenderTarget!);

    setRenderTarget(currentRenderTarget);
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
    // print(" render renderObject  type: ${object.type} material: ${material} name: ${object.name}  geometry: ${geometry}");
    // print("1 render renderObject type: ${object.type} name: ${object.name}  ${DateTime.now().millisecondsSinceEpoch}");

    if (object.onBeforeRender != null) {
      object.onBeforeRender!(
        renderer: this,
        mesh: object,
        scene: scene,
        camera: camera,
        geometry: geometry,
        material: material,
        group: group
      );
    }

    object.modelViewMatrix.multiply2(camera.matrixWorldInverse, object.matrixWorld);
    object.normalMatrix.getNormalMatrix(object.modelViewMatrix);

    if (material.onBeforeRender != null) {
      material.onBeforeRender!(this, scene, camera, geometry, object, group);
    }

    if (material.transparent == true && material.side == DoubleSide) {
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

    object.onAfterRender(renderer: this, scene: scene, camera: camera, geometry: geometry, material: material, group: group);

    // print("2 render renderObject type: ${object.type} name: ${object.name} ${DateTime.now().millisecondsSinceEpoch}");
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

    Texture? envMap;
    if (material is MeshStandardMaterial) {
      envMap = cubeuvmaps.get(material.envMap ?? materialProperties["environment"]);
    } else {
      envMap = cubemaps.get(material.envMap ?? materialProperties["environment"]);
    }

    materialProperties["envMap"] = envMap;

    if (programs == null) {
      // new material

      material.addEventListener('dispose', onMaterialDispose);

      programs = {};
      materialProperties["programs"] = programs;
    }

    WebGLProgram? program = programs[programCacheKey];

    if (program != null) {
      // early out if program and light state is identical
      if (materialProperties["currentProgram"] == program &&
          materialProperties["lightsStateVersion"] == lightsStateVersion) {
        updateCommonMaterialProperties(material, parameters);

        return program;
      }
    } else {
      parameters.uniforms = programCache.getUniforms(material);

      material.onBuild(parameters, this);

      if (material.onBeforeCompile != null) {
        material.onBeforeCompile!(parameters, this);
      }

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
      uniforms["spotShadowMatrix"]["value"] = lights.state.spotShadowMatrix;
      uniforms["pointShadowMap"]["value"] = lights.state.pointShadowMap;
      uniforms["pointShadowMatrix"]["value"] = lights.state.pointShadowMatrix;

      // TODO (abelnation): add area lights shadow info to uniforms
    }

    final progUniforms = program!.getUniforms();
    final uniformsList = WebGLUniforms.seqWithValue(progUniforms.seq, uniforms);

    materialProperties["currentProgram"] = program;
    materialProperties["uniformsList"] = uniformsList;

    return program;
  }

  void updateCommonMaterialProperties(Material material, parameters) {
    final materialProperties = properties.get(material);

    materialProperties["outputEncoding"] = parameters.outputEncoding;
    materialProperties["instancing"] = parameters.instancing;
    materialProperties["skinning"] = parameters.skinning;
    materialProperties["morphTargets"] = parameters.morphTargets;
    materialProperties["morphNormals"] = parameters.morphNormals;
    materialProperties["morphColors"] = parameters.morphColors;
    materialProperties["morphTargetsCount"] = parameters.morphTargetsCount;
    materialProperties["numClippingPlanes"] = parameters.numClippingPlanes;
    materialProperties["numIntersection"] = parameters.numClipIntersection;
    materialProperties["vertexAlphas"] = parameters.vertexAlphas;
    materialProperties["vertexTangents"] = parameters.vertexTangents;
    materialProperties["toneMapping"] = parameters.toneMapping;
  }

  WebGLProgram setProgram(Camera camera, Object3D? scene, BufferGeometry? geometry, Material material, Object3D object) {
    if (scene is! Scene) scene = _emptyScene;
    // scene could be a Mesh, Line, Points, ...
    textures.resetTextureUnits();

    final fog = scene.fog;
    final environment = material is MeshStandardMaterial ? scene.environment : null;
    final encoding = (_currentRenderTarget == null)
        ? outputEncoding
        : (_currentRenderTarget!.isXRRenderTarget == true ? _currentRenderTarget!.texture.encoding : LinearEncoding);

    Texture? envMap;
    if (material is MeshStandardMaterial) {
      envMap = cubeuvmaps.get(material.envMap ?? environment);
    } else {
      envMap = cubemaps.get(material.envMap ?? environment);
    }

    bool vertexAlphas = material.vertexColors == true &&
        geometry != null &&
        geometry.attributes["color"] != null &&
        geometry.attributes["color"].itemSize == 4;
    bool vertexTangents = material.normalMap != null && geometry != null && geometry.attributes["tangent"] != null;
    bool morphTargets = geometry != null && geometry.morphAttributes["position"] != null;
    bool morphNormals = geometry != null && geometry.morphAttributes["normal"] != null;
    bool morphColors = geometry != null && geometry.morphAttributes["color"] != null;

    int toneMapping = material.toneMapped ? this.toneMapping : NoToneMapping;

    List<BufferAttribute>? morphAttribute = geometry != null
        ? (geometry.morphAttributes["position"] ??
            geometry.morphAttributes["normal"] ??
            geometry.morphAttributes["color"])
        : null;
    int morphTargetsCount = (morphAttribute != null) ? morphAttribute.length : 0;

    Map<String, dynamic> materialProperties = properties.get(material);
    WebGLLights lights = currentRenderState!.state.lights;

    if (_clippingEnabled == true) {
      if (_localClippingEnabled == true || camera != _currentCamera) {
        final useCache = camera == _currentCamera && material.id == _currentMaterialId;

        // we might want to call this function with some ClippingGroup
        // object instead of the material, once it becomes feasible
        // (#8465, #8379)
        clipping.setState(material, camera, useCache);
      }
    }

    //

    bool needsProgramChange = false;

    if (material.version == materialProperties["__version"]) {
      if (materialProperties["needsLights"] != null &&
          (materialProperties["lightsStateVersion"] != lights.state.version)) {
        needsProgramChange = true;
      } else if (materialProperties["outputEncoding"] != encoding) {
        needsProgramChange = true;
      } else if (object is InstancedMesh && materialProperties["instancing"] == false) {
        needsProgramChange = true;
      } else if (object is! InstancedMesh && materialProperties["instancing"] == true) {
        needsProgramChange = true;
      } else if (object is SkinnedMesh && materialProperties["skinning"] == false) {
        needsProgramChange = true;
      } else if (object is! SkinnedMesh && materialProperties["skinning"] == true) {
        needsProgramChange = true;
      } else if (materialProperties["envMap"] != envMap) {
        needsProgramChange = true;
      } else if (material.fog && materialProperties["fog"] != fog) {
        needsProgramChange = true;
      } else if (materialProperties["numClippingPlanes"] != null &&
          (materialProperties["numClippingPlanes"] != clipping.numPlanes ||
              materialProperties["numIntersection"] != clipping.numIntersection)) {
        needsProgramChange = true;
      } else if (materialProperties["vertexAlphas"] != vertexAlphas) {
        needsProgramChange = true;
      } else if (materialProperties["vertexTangents"] != vertexTangents) {
        needsProgramChange = true;
      } else if (materialProperties["morphTargets"] != morphTargets) {
        needsProgramChange = true;
      } else if (materialProperties["morphNormals"] != morphNormals) {
        needsProgramChange = true;
      } else if (materialProperties["morphColors"] != morphColors) {
        needsProgramChange = true;
      } else if (materialProperties["toneMapping"] != toneMapping) {
        needsProgramChange = true;
      } else if (capabilities.isWebGL2 == true && materialProperties["morphTargetsCount"] != morphTargetsCount) {
        needsProgramChange = true;
      }
    } else {
      needsProgramChange = true;
      materialProperties["__version"] = material.version;
    }

    WebGLProgram? program = materialProperties["currentProgram"];

    if (needsProgramChange) {
      program = getProgram(material, scene, object);
    }

    bool refreshProgram = false;
    bool refreshMaterial = false;
    bool refreshLights = false;

    final pUniforms = program!.getUniforms();
    Map<String, dynamic> mUniforms = materialProperties["uniforms"];

    if (state.useProgram(program.program)) {
      refreshProgram = true;
      refreshMaterial = true;
      refreshLights = true;
    }

    if (material.id != _currentMaterialId) {
      _currentMaterialId = material.id;

      refreshMaterial = true;
    }

    if (refreshProgram || _currentCamera != camera) {
      pUniforms.setValue(_gl, 'projectionMatrix', camera.projectionMatrix, textures);

      if (capabilities.logarithmicDepthBuffer) {
        pUniforms.setValue(_gl, 'logDepthBufFC', 2.0 / (math.log(camera.far + 1.0) / math.ln2), textures);
      }

      if (_currentCamera != camera) {
        _currentCamera = camera;

        // lighting uniforms depend on the camera so enforce an update
        // now, in case this material supports lights - or later, when
        // the next material that does gets activated:

        refreshMaterial = true; // set to true on material change
        refreshLights = true; // remains set until update done

      }

      // load material specific uniforms
      // (shader material also gets them for the sake of genericity)

      if (material is ShaderMaterial ||
          material is MeshPhongMaterial ||
          material is MeshToonMaterial ||
          material is MeshStandardMaterial ||
          material.envMap != null) {
        final uCamPos = pUniforms.map["cameraPosition"];

        if (uCamPos != null) {
          uCamPos.setValue(_gl, _vector3.setFromMatrixPosition(camera.matrixWorld));
        }
      }

      if (material is MeshPhongMaterial ||
          material is MeshToonMaterial ||
          material is MeshLambertMaterial ||
          material is MeshBasicMaterial ||
          material is MeshStandardMaterial ||
          material is ShaderMaterial) {
        pUniforms.setValue(_gl, 'isOrthographic', camera is OrthographicCamera, textures);
      }

      if (material is MeshPhongMaterial ||
          material is MeshToonMaterial ||
          material is MeshLambertMaterial ||
          material is MeshBasicMaterial ||
          material is MeshStandardMaterial ||
          material is ShaderMaterial ||
          material is ShadowMaterial ||
          object is SkinnedMesh) {
        pUniforms.setValue(_gl, 'viewMatrix', camera.matrixWorldInverse, textures);
      }
    }

    // skinning uniforms must be set even if material didn't change
    // auto-setting of texture unit for bone texture must go before other textures
    // otherwise textures used for skinning can take over texture units reserved for other material textures

    if (object is SkinnedMesh) {
      pUniforms.setOptional(_gl, object, 'bindMatrix');
      pUniforms.setOptional(_gl, object, 'bindMatrixInverse');

      final skeleton = object.skeleton;

      if (skeleton != null) {
        if (capabilities.floatVertexTextures) {
          if (skeleton.boneTexture == null) skeleton.computeBoneTexture();

          pUniforms.setValue(_gl, 'boneTexture', skeleton.boneTexture, textures);
          pUniforms.setValue(_gl, 'boneTextureSize', skeleton.boneTextureSize, textures);
        } else {
          console.warning('WebGLRenderer: SkinnedMesh can only be used with WebGL 2. With WebGL 1 OES_texture_float and vertex textures support is required.');
        }
      }
    }

    final morphAttributes = geometry!.morphAttributes;

    if (morphAttributes["position"] != null ||
        morphAttributes["normal"] != null ||
        (morphAttributes["color"] != null && capabilities.isWebGL2 == true)) {
      morphtargets.update(object, geometry, material, program);
    }

    if (refreshMaterial || materialProperties["receiveShadow"] != object.receiveShadow) {
      materialProperties["receiveShadow"] = object.receiveShadow;
      pUniforms.setValue(_gl, 'receiveShadow', object.receiveShadow, textures);
    }

    // print(" setProgram .......... material: ${material.type} ");

    if (refreshMaterial) {
      pUniforms.setValue(_gl, 'toneMappingExposure', toneMappingExposure, textures);

      if (materialProperties["needsLights"]) {
        // the current material requires lighting info

        // note: all lighting uniforms are always set correctly
        // they simply reference the renderer's state for their
        // values
        //
        // use the current material's .needsUpdate flags to set
        // the GL state when required

        markUniformsLightsNeedsUpdate(mUniforms, refreshLights);
      }

      // refresh uniforms common to several materials

      if (fog != null && material.fog) {
        materials.refreshFogUniforms(mUniforms, fog);
      }

      materials.refreshMaterialUniforms(mUniforms, material, _pixelRatio, _height, _transmissionRenderTarget);
      WebGLUniforms.upload(_gl, materialProperties["uniformsList"], mUniforms, textures);
    }

    if (material is ShaderMaterial && material.uniformsNeedUpdate == true) {
      WebGLUniforms.upload(_gl, materialProperties["uniformsList"], mUniforms, textures);
      material.uniformsNeedUpdate = false;
    }

    if (material is SpriteMaterial) {
      dynamic c = object;
      pUniforms.setValue(_gl, 'center', c.center, textures);
    }

    // common matrices

    pUniforms.setValue(_gl, 'modelViewMatrix', object.modelViewMatrix, textures);
    pUniforms.setValue(_gl, 'normalMatrix', object.normalMatrix, textures);
    pUniforms.setValue(_gl, 'modelMatrix', object.matrixWorld, textures);

    return program;
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
    uniforms["directionalShadowMap"]["needsUpdate"] = value;
    uniforms["directionalShadowMatrix"]["needsUpdate"] = value;
    uniforms["spotShadowMap"]["needsUpdate"] = value;
    uniforms["spotShadowMatrix"]["needsUpdate"] = value;
    uniforms["pointShadowMap"]["needsUpdate"] = value;
    uniforms["pointShadowMatrix"]["needsUpdate"] = value;
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

    if (renderTargetProperties["__hasExternalTextures"] == true) {
      renderTargetProperties["__autoAllocateDepthBuffer"] = depthTexture == null;

      if (!(renderTargetProperties["__autoAllocateDepthBuffer"] == true)) {
        // The multisample_render_to_texture extension doesn't work properly if there
        // are midframe flushes and an external depth buffer. Disable use of the extension.
        if (extensions.has('WEBGL_multisampled_render_to_texture') == true) {
          console.warning('WebGLRenderer: extension was disabled because an external texture was provided');
          renderTarget.useRenderToTexture = false;
          renderTarget.useRenderbuffer = true;
        }
      }
    }
  }

  void setRenderTargetFramebuffer(RenderTarget renderTarget, defaultFramebuffer) {
    final renderTargetProperties = properties.get(renderTarget);
    renderTargetProperties["__webglFramebuffer"] = defaultFramebuffer;
    renderTargetProperties["__useDefaultFramebuffer"] = defaultFramebuffer == null;
  }

  void setRenderTarget(RenderTarget? renderTarget, [int activeCubeFace = 0, int activeMipmapLevel = 0]) {
    _currentRenderTarget = renderTarget;
    _currentActiveCubeFace = activeCubeFace;
    _currentActiveMipmapLevel = activeMipmapLevel;
    bool useDefaultFramebuffer = true;

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
      }
    }

    Framebuffer? framebuffer;
    bool isCube = false;
    bool isRenderTarget3D = false;

    if (renderTarget != null) {
      final texture = renderTarget.texture;

      if (texture is Data3DTexture || texture is DataArrayTexture) {
        isRenderTarget3D = true;
      }

      final webglFramebuffer = properties.get(renderTarget)["__webglFramebuffer"];

      if (renderTarget.isWebGLCubeRenderTarget) {
        framebuffer = webglFramebuffer[activeCubeFace];
        isCube = true;
      } 
      else if ((capabilities.isWebGL2 && renderTarget.samples > 0) && textures.useMultisampledRenderToTexture(renderTarget) == false) {
        framebuffer = properties.get(renderTarget)["__webglMultisampledFramebuffer"];
      } 
      else {
        framebuffer = webglFramebuffer;
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
      console.warning('framebufferTextureLayer not supported yet');
      // final textureProperties = properties.get(renderTarget!.texture);
      // final layer = activeCubeFace;
      // _gl.gl.glFramebufferTextureLayer( WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, textureProperties["__webglTexture"], activeMipmapLevel, layer);
    }

    _currentMaterialId = -1; // reset current material to ensure correct uniform bindings
  }

  void readRenderTargetPixels(WebGLRenderTarget renderTarget, int x, int y, int width, int height, NativeArray buffer, [activeCubeFaceIndex]) {
    dynamic framebuffer = properties.get(renderTarget)["__webglFramebuffer"]; //can be Map or int

    if (renderTarget.isWebGLCubeRenderTarget && activeCubeFaceIndex != null) {
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
            (extensions.get('EXT_color_buffer_half_float') ||
                (capabilities.isWebGL2 && extensions.get('EXT_color_buffer_float')));

        if (textureType != UnsignedByteType &&
            utils.convert(textureType) !=
                _gl.getParameter(WebGL.IMPLEMENTATION_COLOR_READ_TYPE) && // IE11, Edge and Chrome Mac < 52 (#9513)
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
          _gl.readPixels(x, y, width, height, utils.convert(textureFormat), utils.convert(textureType), buffer);
        }
      } finally {
        final framebuffer = (_currentRenderTarget != null) ? properties.get(_currentRenderTarget)["__webglFramebuffer"] : null;
        state.bindFramebuffer(WebGL.FRAMEBUFFER, framebuffer);
      }
    }
  }

  void copyFramebufferToTexture(position, Texture? texture, {int level = 0}) {
    //console.warning('copyFramebufferToTexture not supported');
    if (texture is! FramebufferTexture) {
      console.warning('WebGLRenderer: copyFramebufferToTexture() can only be used with FramebufferTexture.');
      return;
    }

    final levelScale = math.pow(2, -level);
    final width = (texture.image.width * levelScale).floor();
    final height = (texture.image.height * levelScale).floor();

    textures.setTexture2D(texture, 0);
    _gl.copyTexSubImage2D(WebGL.TEXTURE_2D, level, 0, 0, position.x.toInt(), position.y.toInt(), width, height);
    state.unbindTexture(WebGLTexture(WebGL.TEXTURE_2D));
  }

  void copyTextureToTexture(position, Texture srcTexture, dstTexture, {int level = 0}) {
    final width = srcTexture.image.width;
    final height = srcTexture.image.height;
    final glFormat = utils.convert(dstTexture.format);
    final glType = utils.convert(dstTexture.type);

    textures.setTexture2D(dstTexture, 0);

    // As another texture upload may have changed pixelStorei
    // parameters, make sure they are correct for the dstTexture
    _gl.pixelStorei(WebGL.UNPACK_FLIP_Y_WEBGL, dstTexture.flipY ? 1 : 0);
    _gl.pixelStorei(WebGL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, dstTexture.premultiplyAlpha);
    _gl.pixelStorei(WebGL.UNPACK_ALIGNMENT, dstTexture.unpackAlignment);

    if (srcTexture is DataTexture) {
      _gl.texSubImage2D(WebGL.TEXTURE_2D, level, position.x, position.y, width, height, glFormat, glType, srcTexture.image.data);
    } 
    else {
      if (srcTexture is CompressedTexture) {
        _gl.compressedTexSubImage2D(WebGL.TEXTURE_2D, level, position.x, position.y, srcTexture.mipmaps[0].width,srcTexture.mipmaps[0].height, glFormat, srcTexture.mipmaps[0].data);
      } 
      else {
        _gl.texSubImage2D(WebGL.TEXTURE_2D, level, position.x, position.y, 0, 0, glFormat, glType, srcTexture.image);
      }
    }

    // Generate mipmaps only when copying level 0
    if (level == 0 && dstTexture.generateMipmaps) {
      _gl.generateMipmap(WebGL.TEXTURE_2D);
    }

    state.unbindTexture();
  }

  void copyTextureToTexture3D(
    BoundingBox sourceBox,
    Vector3 position,
    Texture srcTexture,
    Texture dstTexture, {
    int level = 0,
  }) {
    final width = sourceBox.max.x - sourceBox.min.x + 1;
    final height = sourceBox.max.y - sourceBox.min.y + 1;
    final depth = sourceBox.max.z - sourceBox.min.z + 1;
    final glFormat = utils.convert(dstTexture.format);
    final glType = utils.convert(dstTexture.type);
    dynamic glTarget;

    if (dstTexture is Data3DTexture) {
      textures.setTexture3D(dstTexture, 0);
      glTarget = WebGL.TEXTURE_3D;
    } else if (dstTexture is DataArrayTexture) {
      textures.setTexture2DArray(dstTexture, 0);
      glTarget = WebGL.TEXTURE_2D_ARRAY;
    } else {
      console.warning('WebGLRenderer.copyTextureToTexture3D: only supports DataTexture3D and DataTexture2DArray.');
      return;
    }

    _gl.pixelStorei(WebGL.UNPACK_FLIP_Y_WEBGL, dstTexture.flipY ? 1 : 0);
    _gl.pixelStorei(WebGL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, dstTexture.premultiplyAlpha?1:0);
    _gl.pixelStorei(WebGL.UNPACK_ALIGNMENT, dstTexture.unpackAlignment);

    final unpackRowLen = _gl.getParameter(WebGL.UNPACK_ROW_LENGTH);
    final unpackImageHeight = _gl.getParameter(WebGL.UNPACK_IMAGE_HEIGHT);
    final unpackSkipPixels = _gl.getParameter(WebGL.UNPACK_SKIP_PIXELS);
    final unpackSkipRows = _gl.getParameter(WebGL.UNPACK_SKIP_ROWS);
    final unpackSkipImages = _gl.getParameter(WebGL.UNPACK_SKIP_IMAGES);
    
    final image = srcTexture.isCompressedTexture ? srcTexture.mipmaps[0] : srcTexture.image;

    _gl.pixelStorei(WebGL.UNPACK_ROW_LENGTH, image.width);
    _gl.pixelStorei(WebGL.UNPACK_IMAGE_HEIGHT, image.height);
    _gl.pixelStorei(WebGL.UNPACK_SKIP_PIXELS, sourceBox.min.x.toInt());
    _gl.pixelStorei(WebGL.UNPACK_SKIP_ROWS, sourceBox.min.y.toInt());
    _gl.pixelStorei(WebGL.UNPACK_SKIP_IMAGES, sourceBox.min.z.toInt());

    if (srcTexture is DataTexture || srcTexture is Data3DTexture) {
      _gl.texSubImage3D(glTarget, level, position.x.toInt(), position.y.toInt(), position.z.toInt(), width.toInt(), height.toInt(), depth.toInt(), glFormat, glType, image.data);
    } 
    else {
      if (srcTexture.isCompressedTexture) {
        console.warning('WebGLRenderer.copyTextureToTexture3D: untested support for compressed srcTexture.');
        //_gl.compressedTexSubImage3D(glTarget, level, position.x, position.y, position.z, width, height, depth, glFormat, image.data);
      } 
      else {
        _gl.texSubImage3D(glTarget, level, position.x.toInt(), position.y.toInt(), position.z.toInt(), width.toInt(), height.toInt(), depth.toInt(), glFormat, glType, image);
      }
    }

    _gl.pixelStorei(WebGL.UNPACK_ROW_LENGTH, unpackRowLen);
    _gl.pixelStorei(WebGL.UNPACK_IMAGE_HEIGHT, unpackImageHeight);
    _gl.pixelStorei(WebGL.UNPACK_SKIP_PIXELS, unpackSkipPixels);
    _gl.pixelStorei(WebGL.UNPACK_SKIP_ROWS, unpackSkipRows);
    _gl.pixelStorei(WebGL.UNPACK_SKIP_IMAGES, unpackSkipImages);

    // Generate mipmaps only when copying level 0
    if (level == 0 && dstTexture.generateMipmaps) _gl.generateMipmap(glTarget);

    state.unbindTexture();
  }

  void initTexture(Texture texture) {
    if ( texture is CubeTexture ) {
			textures.setTextureCube( texture, 0 );
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
}
