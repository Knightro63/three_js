part of three_webgl;

class WebGLBackground {
  WebGLCubeMaps cubemaps;
  WebGLState state;

  WebGLRenderer renderer;
  WebGLObjects objects;
  bool alpha;
  bool premultipliedAlpha;

  Color clearColor = Color(0x000000);
  double clearAlpha = 0;

  Mesh? planeMesh;
  Mesh? boxMesh;

  dynamic currentBackground;
  int currentBackgroundVersion = 0;
  late int currentTonemapping;

  WebGLBackground(this.renderer, this.cubemaps, this.state, this.objects, this.alpha, this.premultipliedAlpha) {
    clearAlpha = alpha == true ? 0.0 : 1.0;
  }

  void render(WebGLRenderList renderList, Object3D scene) {
    bool forceClear = false;
    dynamic background = scene is Scene ? scene.background : null;

    if (background != null && background is Texture) {
      background = cubemaps.get(background);
    }

    // Ignore background in AR

    final xr = renderer.xr;
    final session = xr.getSession();

    if ( session != null && session.environmentBlendMode == 'additive' ) {
    	background = null;
    }

    if (background == null) {
      setClear(clearColor, clearAlpha);
    } 
    else if (background != null && background is Color) {
      setClear(background, 1);
      forceClear = true;
    }

    if (renderer.autoClear || forceClear) {
      renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
    }

    if (background != null && (background is CubeTexture || (background is Texture && background.mapping == CubeUVReflectionMapping))) {
      if (boxMesh == null) {
        boxMesh = Mesh(
          BoxGeometry(),
          ShaderMaterial.fromMap({
            "name": 'BackgroundCubeMaterial',
            "uniforms": cloneUniforms(shaderLib["cube"]["uniforms"]),
            "vertexShader": shaderLib["cube"]["vertexShader"],
            "fragmentShader": shaderLib["cube"]["fragmentShader"],
            "side": BackSide,
            "depthTest": false,
            "depthWrite": false,
            "fog": false
          })
        );

        boxMesh!.geometry?.deleteAttributeFromString('normal');
        boxMesh!.geometry?.deleteAttributeFromString('uv');

        boxMesh!.onBeforeRender = ({
          renderer, 
          scene, 
          camera, 
          renderTarget, 
          mesh, 
          geometry, 
          material,
          group
        }) {
          boxMesh!.matrixWorld.copyPosition(camera!.matrixWorld);
        };

        objects.update(boxMesh!);
      }

      boxMesh!.material?.uniforms["envMap"]["value"] = background;
      boxMesh!.material?.uniforms["flipEnvMap"]["value"] = (background is CubeTexture && background is WebGL3DRenderTarget) ? -1 : 1;
      
      if (background.matrixAutoUpdate == true) {
        background.updateMatrix();
      }

      if (currentBackground != background ||
        currentBackgroundVersion != background.version ||
        currentTonemapping != renderer.toneMapping
      ) {
        boxMesh!.material?.needsUpdate = true;

        currentBackground = background;
        currentBackgroundVersion = background.version;
        currentTonemapping = renderer.toneMapping;
      }

      boxMesh!.layers.enableAll();

      // push to the pre-sorted opaque render list
      renderList.unshift(boxMesh!, boxMesh!.geometry, boxMesh!.material, 0, 0, null);
    } 
    else if (background != null && background is Texture) {
      if (planeMesh == null) {
        planeMesh = Mesh(
          PlaneGeometry(2, 2),
          ShaderMaterial.fromMap({
            "name": 'BackgroundMaterial',
            "uniforms": cloneUniforms(shaderLib["background"]["uniforms"]),
            "vertexShader": shaderLib["background"]["vertexShader"],
            "fragmentShader": shaderLib["background"]["fragmentShader"],
            "side": FrontSide,
            "depthTest": false,
            "depthWrite": false,
            "fog": false
          })
        );

        planeMesh!.geometry?.deleteAttributeFromString('normal');

        objects.update(planeMesh!);
      }

      planeMesh!.material?.uniforms["t2D"]["value"] = background;

      if (background.matrixAutoUpdate == true) {
        background.updateMatrix();
      }

      planeMesh!.material?.uniforms["uvTransform"]["value"].setFrom(background.matrix);

      if (currentBackground != background ||
          currentBackgroundVersion != background.version ||
          currentTonemapping != renderer.toneMapping) {
        planeMesh!.material?.needsUpdate = true;

        currentBackground = background;
        currentBackgroundVersion = background.version;
        currentTonemapping = renderer.toneMapping;
      }

      planeMesh!.layers.enableAll();

      // push to the pre-sorted opaque render list
      renderList.unshift(planeMesh!, planeMesh!.geometry, planeMesh!.material, 0, 0, null);
    }
  }

  void setClear(Color color, double alpha) {
    state.buffers["color"].setClear(color.red, color.green, color.blue, alpha, premultipliedAlpha);
  }

  Color getClearColor() {
    return clearColor;
  }

  void setClearColor(Color color, [double alpha = 1.0]) {
    clearColor.setFrom(color);
    clearAlpha = alpha;
    setClear(clearColor, clearAlpha);
  }

  double getClearAlpha() {
    return clearAlpha;
  }

  void setClearAlpha(double alpha) {
    clearAlpha = alpha;
    setClear(clearColor, clearAlpha);
  }
}
