part of three_webgl;

class WebGLShadowMap {
  bool _didDispose = false;
  Frustum _frustum = Frustum();
  final _shadowMapSize = Vector2.zero();
  final _viewportSize = Vector2.zero();
  final _viewport = Vector4.identity();

  final shadowSide = {0: BackSide, 1: FrontSide, 2: DoubleSide};

  // HashMap<int, Material> _depthMaterials = HashMap<int, Material>();
  // HashMap<int, Material> _distanceMaterials = HashMap<int, Material>();

  late MeshDepthMaterial _depthMaterial;
  late MeshDistanceMaterial _distanceMaterial;

  final _materialCache = {};

  late ShaderMaterial shadowMaterialVertical;
  late ShaderMaterial shadowMaterialHorizontal;

  BufferGeometry fullScreenTri = BufferGeometry();

  late Mesh fullScreenMesh;

  bool enabled = false;

  bool autoUpdate = true;
  bool needsUpdate = false;

  int type = PCFShadowMap;

  late WebGLShadowMap scope;

  final WebGLRenderer _renderer;
  final WebGLObjects _objects;
  final WebGLCapabilities _capabilities;
  late int _maxTextureSize;
  
  late int _previousType;

  WebGLShadowMap(this._renderer, this._objects, this._capabilities) {
    _previousType = type;
    _maxTextureSize = _capabilities.maxTextureSize;

    _depthMaterial = MeshDepthMaterial.fromMap({"depthPacking": RGBADepthPacking});
    _distanceMaterial = MeshDistanceMaterial(null);

    shadowMaterialVertical = ShaderMaterial.fromMap({
      "defines": {"VSM_SAMPLES": 8},
      "uniforms": {
        "shadow_pass": <String,dynamic>{"value": null},
        "resolution": {"value": Vector2.zero()},
        "radius": {"value": 4.0}
      },
      "vertexShader": vsmVert,
      "fragmentShader": vsmFrag
    });

    final float32List = Float32List.fromList([-1.0, -1.0, 0.5, 3.0, -1.0, 0.5, -1.0, 3.0, 0.5]);

    fullScreenTri.setAttributeFromString('position', Float32BufferAttribute.fromList(float32List, 3, false));

    fullScreenMesh = Mesh(fullScreenTri, shadowMaterialVertical);

    shadowMaterialHorizontal = shadowMaterialVertical.clone();
    shadowMaterialHorizontal.defines!["HORIZONTAL_PASS"] = 1;

    scope = this;
  }

  void dispose(){
    if(_didDispose) return;
    _didDispose = true;
    fullScreenMesh.dispose();
    fullScreenTri.dispose();

    _depthMaterial.dispose();
    _distanceMaterial.dispose();

    shadowMaterialVertical.dispose();
    shadowMaterialHorizontal.dispose();

    _frustum.dispose();
    shadowSide.clear();

    scope.dispose();
    _renderer.dispose();
    _objects.dispose();
    _capabilities.dispose();
  }

  void render(List<Light> lights, Object3D scene, Camera camera) {
    if (!scope.enabled) return;
    if (!scope.autoUpdate && !scope.needsUpdate) return;

    if (lights.isEmpty) return;

    final currentRenderTarget = _renderer.getRenderTarget();
    final activeCubeFace = _renderer.getActiveCubeFace();
    final activeMipmapLevel = _renderer.getActiveMipmapLevel();
    
    final state = _renderer.state;

    // Set GL state for depth map.
    state.setBlending(NoBlending);
    state.buffers["color"].setClear(1.0, 1.0, 1.0, 1.0, false);
    state.buffers["depth"].setTest(true);
    state.setScissorTest(false);

		final toVSM = ( _previousType != VSMShadowMap && type == VSMShadowMap );
		final fromVSM = ( _previousType == VSMShadowMap && type != VSMShadowMap );

    // render depth map

    for (int i = 0, il = lights.length; i < il; i++) {
      final light = lights[i];
      final shadow = light.shadow;

      if (shadow == null) {
        continue;
      }

      if (!shadow.autoUpdate && !shadow.needsUpdate) continue;

      _shadowMapSize.setFrom(shadow.mapSize);

      final shadowFrameExtents = shadow.getFrameExtents();
      _shadowMapSize.multiply(shadowFrameExtents);
      _viewportSize.setFrom(shadow.mapSize);

      if (_shadowMapSize.x > _maxTextureSize || _shadowMapSize.y > _maxTextureSize) {
        if (_shadowMapSize.x > _maxTextureSize) {
          _viewportSize.x = (_maxTextureSize / shadowFrameExtents.x).floorToDouble();
          _shadowMapSize.x = _viewportSize.x * shadowFrameExtents.x;
          shadow.mapSize.x = _viewportSize.x;
        }

        if (_shadowMapSize.y > _maxTextureSize) {
          _viewportSize.y = (_maxTextureSize / shadowFrameExtents.y).floorToDouble();
          _shadowMapSize.y = _viewportSize.y * shadowFrameExtents.y;
          shadow.mapSize.y = _viewportSize.y;
        }
      }

      if (shadow.map == null || toVSM || fromVSM && shadow is! PointLightShadow && type == VSMShadowMap) {
				final Map<String,dynamic> pars = (type != VSMShadowMap ) ? { 'minFilter': NearestFilter, 'magFilter': NearestFilter } : {};

				if ( shadow.map != null ) {
					shadow.map?.dispose();
				}

        shadow.map = WebGLRenderTarget(_shadowMapSize.x.toInt(), _shadowMapSize.y.toInt(), WebGLRenderTargetOptions(pars));
        shadow.map!.texture.name = '${light.name}.shadowMap';

        shadow.camera!.updateProjectionMatrix();
      }
      
      _renderer.setRenderTarget(shadow.map);
      _renderer.clear();

      final viewportCount = shadow.getViewportCount();

      for (int vp = 0; vp < viewportCount; vp++) {
        final viewport = shadow.getViewport(vp);
        _viewport.setValues(_viewportSize.x * viewport.x, _viewportSize.y * viewport.y, _viewportSize.x * viewport.z, _viewportSize.y * viewport.w);
        state.viewport(_viewport);
        shadow.updateMatrices(light, viewportIndex: vp);
        _frustum = shadow.getFrustum();
        renderObject(scene, camera, shadow.camera!, light, type);
      }

      // do blur pass for VSM

      if (shadow is! PointLightShadow && type == VSMShadowMap) {
        vSMPass(shadow, camera);
      }

      shadow.needsUpdate = false;
    }
    _previousType = type;

    scope.needsUpdate = false;
    _renderer.setRenderTarget(currentRenderTarget, activeCubeFace, activeMipmapLevel);
  }

  void vSMPass(LightShadow shadow, Camera camera) {
    final geometry = _objects.update(fullScreenMesh);

    if (shadowMaterialVertical.defines!["VSM_SAMPLES"] != shadow.blurSamples) {
      shadowMaterialVertical.defines!["VSM_SAMPLES"] = shadow.blurSamples;
      shadowMaterialHorizontal.defines!["VSM_SAMPLES"] = shadow.blurSamples;

      shadowMaterialVertical.needsUpdate = true;
      shadowMaterialHorizontal.needsUpdate = true;
    }

		shadow.mapPass ??= WebGLRenderTarget( _shadowMapSize.x.toInt(), _shadowMapSize.y.toInt() );

    // vertical pass

    shadowMaterialVertical.uniforms["shadow_pass"]['value'] = shadow.map!.texture;
    shadowMaterialVertical.uniforms["resolution"]['value'] = shadow.mapSize;
    shadowMaterialVertical.uniforms["radius"]['value'] = shadow.radius;

    _renderer.setRenderTarget(shadow.mapPass);
    _renderer.clear();
    _renderer.renderBufferDirect(camera, null, geometry, shadowMaterialVertical, fullScreenMesh, null);

    // horizontal pass

    shadowMaterialHorizontal.uniforms["shadow_pass"]['value'] = shadow.mapPass!.texture;
    shadowMaterialHorizontal.uniforms["resolution"]['value'] = shadow.mapSize;
    shadowMaterialHorizontal.uniforms["radius"]['value'] = shadow.radius;

    _renderer.setRenderTarget(shadow.map);
    _renderer.clear();
    _renderer.renderBufferDirect(camera, null, geometry, shadowMaterialHorizontal, fullScreenMesh, null);
  }

  Material getDepthMaterial(
    Object3D object, 
    Material material, 
    Light light, 
    double shadowCameraNear, 
    double shadowCameraFar, 
    int type
  ) {
    Material? result;

    final customMaterial = light is PointLight ? object.customDistanceMaterial : object.customDepthMaterial;

    if (customMaterial != null) {
      result = customMaterial;
    } else {
      result = light is PointLight ? _distanceMaterial : _depthMaterial;

      if ((
        _renderer.localClippingEnabled && 
        material.clipShadows == true && 
        material.clippingPlanes!.isNotEmpty
        ) || 
        (material.displacementMap != null && material.displacementScale != 0 ) ||
        ( material.alphaMap  != null && material.alphaTest > 0 ) ||
        (material.map != null && material.alphaTest > 0)
      ) {
        // in this case we need a unique material instance reflecting the
        // appropriate state

        final keyA = result.uuid;
        final keyB = material.uuid;

        Map? materialsForVariant = _materialCache[keyA];

        if (materialsForVariant == null) {
          materialsForVariant = {};
          _materialCache[keyA] = materialsForVariant;
        }

        Material? cachedMaterial = materialsForVariant[keyB];

        if (cachedMaterial == null) {
          cachedMaterial = result.clone();
          materialsForVariant[keyB] = cachedMaterial;
        }

        result = cachedMaterial;
      }
    }

    result.visible = material.visible;
    result.wireframe = material.wireframe;

    if (type == VSMShadowMap) {
      result.side = (material.shadowSide != null) ? material.shadowSide! : material.side;
    } 
    else {
      result.side = (material.shadowSide != null) ? material.shadowSide! : shadowSide[material.side]!;
    }

		result.alphaMap = material.alphaMap;
		result.alphaTest = material.alphaTest;
		result.map = material.map;

    result.clipShadows = material.clipShadows;
    result.clippingPlanes = material.clippingPlanes;
    result.clipIntersection = material.clipIntersection;

    result.wireframeLinewidth = material.wireframeLinewidth;
    result.linewidth = material.linewidth;

    if (light is PointLight == true && result is MeshDistanceMaterial) {
      // result.referencePosition.setFromMatrixPosition(light.matrixWorld);
      // result.nearDistance = shadowCameraNear;
      // result.farDistance = shadowCameraFar;

			final materialProperties = _renderer.properties.get( result );
			materialProperties['light'] = light;
    }

    return result;
  }

  void renderObject(Object3D object, Camera camera, Camera shadowCamera, Light light, int type) {
    if (object.visible == false) return;

    final visible = object.layers.test(camera.layers);

    if (visible && (object is Mesh || object is Line || object is Points)) {
      if ((object.castShadow || (object.receiveShadow && type == VSMShadowMap)) &&
          (!object.frustumCulled || _frustum.intersectsObject(object))) {
        object.modelViewMatrix.multiply2(shadowCamera.matrixWorldInverse, object.matrixWorld);

        final geometry = _objects.update(object);
        final material = object.material;

        if (material is GroupMaterial) {
          final groups = geometry.groups;

          for (int k = 0, kl = groups.length; k < kl; k++) {
            final group = groups[k];
            final groupMaterial = material.children[group["materialIndex"]];

            if (groupMaterial.visible) {//groupMaterial != null && 
              final depthMaterial = getDepthMaterial(object, groupMaterial, light, shadowCamera.near, shadowCamera.far, type);
              object.onBeforeShadow(renderer: _renderer, scene: object, camera: camera, shadowCamera: shadowCamera, geometry: geometry, material: depthMaterial, group: group);
              _renderer.renderBufferDirect(shadowCamera, null, geometry, depthMaterial, object, group);
              object.onAfterShadow(renderer: _renderer, scene: object, camera: camera, shadowCamera: shadowCamera, geometry: geometry, material: depthMaterial, group: group);
            }
          }
        } 
        else if (material != null && material.visible) {
          final depthMaterial = getDepthMaterial(object, material, light, shadowCamera.near, shadowCamera.far, type);
          object.onBeforeShadow(renderer: _renderer, scene: object, camera: camera, shadowCamera: shadowCamera, geometry: geometry, material: depthMaterial);
          _renderer.renderBufferDirect(shadowCamera, null, geometry, depthMaterial, object, null);
          object.onAfterShadow(renderer: _renderer, scene: object, camera: camera, shadowCamera: shadowCamera, geometry: geometry, material: depthMaterial);
        }
      }
    }

    final children = object.children;

    for (int i = 0, l = children.length; i < l; i++) {
      renderObject(children[i], camera, shadowCamera, light, type);
    }
  }
}
