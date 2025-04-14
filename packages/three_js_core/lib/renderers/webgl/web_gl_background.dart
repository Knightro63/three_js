part of three_webgl;

final _e1 = Euler();
final _m1 = Matrix4();

class WebGLBackground {
  bool _didDispose = false;
  WebGLCubeMaps cubemaps;
  WebGLCubeUVMaps cubeuvmaps;
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

  WebGLBackground(this.renderer, this.cubemaps, this.cubeuvmaps, this.state, this.objects, this.alpha, this.premultipliedAlpha) {
    clearAlpha = alpha == true ? 0.0 : 1.0;
  }
	
  dynamic getBackground(Object3D? scene ) {
		dynamic background = scene is Scene? scene.background : null;

		if ( background != null && background is Texture ) {
			final usePMREM = (scene as Scene).backgroundBlurriness > 0; // use PMREM if the user wants to blur the background
			background = usePMREM ? cubeuvmaps.get(background) : cubemaps.get(background);
		}

		return background;
	}

  void render(Object3D scene) {
    bool forceClear = false;
    dynamic background = getBackground(scene);//scene is Scene ? scene.background : null;

    if (background == null) {
      setClear(clearColor, clearAlpha);
    } 
    else if (background != null && background is Color) {
      setClear(background, 1);
      forceClear = true;
    }

    final environmentBlendMode = renderer.xr.getEnvironmentBlendMode();

		if (environmentBlendMode == 'additive' ) {
			state.buffers['color'].setClear( 0, 0, 0, 1, premultipliedAlpha );
		} 
    else if (environmentBlendMode == 'alpha-blend' ) {
			state.buffers['color'].setClear( 0, 0, 0, 0, premultipliedAlpha );
		}

    if (renderer.autoClear || forceClear) {
			state.buffers['depth'].setTest( true );
			state.buffers['depth'].setMask( true );
			state.buffers['color'].setMask( true );

      renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
    }
  }

	void addToRenderList(WebGLRenderList renderList, Object3D scene) {
		final background = getBackground( scene );

		if ( background != null && ( background is CubeTexture || (background is Texture && background.mapping == CubeUVReflectionMapping)) ) {
			if ( boxMesh == null ) {
				boxMesh = Mesh(
					BoxGeometry( 1, 1, 1 ),
					ShaderMaterial.fromMap( {
						'name': 'BackgroundCubeMaterial',
						'uniforms': cloneUniforms( shaderLib['backgroundCube']['uniforms'] ),
						'vertexShader': shaderLib['backgroundCube']['vertexShader'],
						'fragmentShader': shaderLib['backgroundCube']['fragmentShader'],
						'side': BackSide,
						'depthTest': false,
						'depthWrite': false,
						'fog': false
					})
				);

				boxMesh!.geometry?.deleteAttributeFromString( 'normal' );
				boxMesh!.geometry?.deleteAttributeFromString( 'uv' );

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

        planeMesh?.material?.envMap = planeMesh?.material?.uniforms['envMap']['value'];
				objects.update(boxMesh!);
			}

      (scene as Scene);
			_e1.copy(scene.backgroundRotation);

			// accommodate left-handed frame
			_e1.x *= - 1; _e1.y *= - 1; _e1.z *= - 1;

			if ( background is CubeTexture && !background.isRenderTargetTexture) {
				// environment maps which are not cube render targets or PMREMs follow a different convention
				_e1.y *= - 1;
				_e1.z *= - 1;
			}

			boxMesh!.material!.uniforms['envMap']['value'] = background;
			boxMesh!.material!.uniforms['flipEnvMap']['value'] = ( background is CubeTexture && !background.isRenderTargetTexture) ? - 1 : 1;
			boxMesh!.material!.uniforms['backgroundBlurriness']['value'] = scene.backgroundBlurriness;
			boxMesh!.material!.uniforms['backgroundIntensity']['value'] = scene.backgroundIntensity;
			boxMesh!.material!.uniforms['backgroundRotation']['value'].setFromMatrix4( _m1.makeRotationFromEuler( _e1 ) );
			boxMesh!.material!.toneMapped = ColorManagement.getTransfer( ColorSpace.fromString( background.colorSpace )) != SRGBTransfer;

			if ( currentBackground != background ||
				currentBackgroundVersion != background.version ||
				currentTonemapping != renderer.toneMapping ) {
				boxMesh!.material?.needsUpdate = true;

				currentBackground = background;
				currentBackgroundVersion = background.version;
				currentTonemapping = renderer.toneMapping;
			}

			boxMesh!.layers.enableAll();

			// push to the pre-sorted opaque render list
			renderList.unshift(boxMesh!, boxMesh!.geometry, boxMesh!.material, 0, 0, null );

		} 
    else if ( background != null && background is Texture ) {
			if (planeMesh == null ) {

				planeMesh = Mesh(
					PlaneGeometry( 2, 2 ),
					ShaderMaterial.fromMap( {
						'name': 'BackgroundMaterial',
						'uniforms': cloneUniforms( shaderLib['background']['uniforms'] ),
						'vertexShader': shaderLib['background']['vertexShader'],
						'fragmentShader': shaderLib['background']['fragmentShader'],
						'side': FrontSide,
						'depthTest': false,
						'depthWrite': false,
						'fog': false
					} )
				);

				planeMesh!.geometry?.deleteAttributeFromString( 'normal' );
        planeMesh!.material?.map = planeMesh!.material!.uniforms['t2D']['value'];

				objects.update(planeMesh!);
			}

			planeMesh!.material?.uniforms['t2D']['value'] = background;
			planeMesh!.material?.uniforms['backgroundIntensity']['value'] = (scene as Scene).backgroundIntensity;
			planeMesh!.material?.toneMapped = ColorManagement.getTransfer( ColorSpace.fromString(background.colorSpace)) != SRGBTransfer;

			if ( background.matrixAutoUpdate) {
				background.updateMatrix();
			}

			planeMesh!.material?.uniforms['uvTransform']['value'].setFrom( background.matrix );

			if ( currentBackground != background ||
				currentBackgroundVersion != background.version ||
				currentTonemapping != renderer.toneMapping ) {

				planeMesh!.material?.needsUpdate = true;

				currentBackground = background;
				currentBackgroundVersion = background.version;
				currentTonemapping = renderer.toneMapping;
			}

			planeMesh!.layers.enableAll();

			// push to the pre-sorted opaque render list
			renderList.unshift( planeMesh!, planeMesh!.geometry, planeMesh!.material, 0, 0, null );
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

  void dispose(){
    if(_didDispose) return;
    _didDispose = true;
    cubemaps.dispose();
    state.dispose();
    renderer.dispose();
    planeMesh?.dispose();
    boxMesh?.dispose();
    objects.dispose();

    if(currentBackground is Texture){
      currentBackground.dispose();
    }
  }
}
