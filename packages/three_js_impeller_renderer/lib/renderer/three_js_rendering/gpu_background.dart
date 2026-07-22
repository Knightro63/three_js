import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_impeller_renderer/renderer/geometry/geometry_descriptor.dart';
import 'package:three_js_impeller_renderer/renderer/material/material_description_registry.dart';
import './gpu_render_list.dart';
import '../renderer.dart';
import 'package:three_js_math/three_js_math.dart';

final _e1 = Euler();
final _m1 = Matrix4();

class GpuBackground {
  bool _didDispose = false;

  ImpellerRenderer renderer;
  bool alpha;

  Color clearColor = Color(0x000000);
  double clearAlpha = 0;

  Mesh? planeMesh;
  Mesh? boxMesh;

  dynamic currentBackground;
  int currentBackgroundVersion = 0;
  late int currentTonemapping;

  GpuBackground(this.renderer, this.alpha) {
    clearAlpha = alpha == true ? 0.0 : 1.0;
  }
	
  dynamic getBackground(Object3D? scene ) {
		dynamic background = scene is Scene? scene.background : null;
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

    if (renderer.autoClear || forceClear) {
      renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
    }
  }

	void addToRenderList(GpuRenderList renderList, Object3D scene) {
		final background = getBackground( scene );

		if ( background != null && ( background is CubeTexture || (background is Texture && background.mapping == CubeUVReflectionMapping)) ) {
			if ( boxMesh == null ) {
				boxMesh = Mesh(
					BoxGeometry( 1, 1, 1 ),
					ShaderMaterial.fromMap( {
						'name': 'BackgroundCube',
            'uniforms': {
              'requiredAttributes': [GeometryAttribute.position,GeometryAttribute.uv0],
              'bindings': [TextureType.map],
            },
            'map': background,
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

			// boxMesh!.material!.uniforms['envMap']['value'] = background;
			// boxMesh!.material!.uniforms['flipEnvMap']['value'] = ( background is CubeTexture && !background.isRenderTargetTexture) ? - 1 : 1;
			// boxMesh!.material!.uniforms['backgroundBlurriness']['value'] = scene.backgroundBlurriness;
			// boxMesh!.material!.uniforms['backgroundIntensity']['value'] = scene.backgroundIntensity;
			// boxMesh!.material!.uniforms['backgroundRotation']['value'].setFromMatrix4( _m1.makeRotationFromEuler( _e1 ) );
			// boxMesh!.material!.toneMapped = ColorManagement.getTransfer( ColorSpace.fromString( background.colorSpace )) != SRGBTransfer;

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
						'name': 'Background',
            'uniforms': {
              'requiredAttributes': [GeometryAttribute.position,GeometryAttribute.uv0],
              'bindings': [TextureType.map],
              'uvTransform': Matrix4().setFromMatrix3(background.matrix)
            },
            'map': background,
						'side': FrontSide,
						'depthTest': false,
						'depthWrite': false,
						'fog': false
					} )
				);

				planeMesh!.geometry?.deleteAttributeFromString( 'normal' );
        //planeMesh!.material?.map = planeMesh!.material!.uniforms['t2D']['value'];
			}

			//planeMesh!.material?.uniforms['t2D']['value'] = background;
			//planeMesh!.material?.uniforms['backgroundIntensity']['value'] = (scene as Scene).backgroundIntensity;
			//planeMesh!.material?.toneMapped = ColorManagement.getTransfer( ColorSpace.fromString(background.colorSpace)) != SRGBTransfer;

			if ( background.matrixAutoUpdate) {
				background.updateMatrix();
			}

			//planeMesh!.material?.uniforms['uvTransform']['value'].setFrom( background.matrix );

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

  void setClear(Color color, double alpha) {}

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
    renderer.dispose();
    planeMesh?.dispose();
    boxMesh?.dispose();

    if(currentBackground is Texture){
      currentBackground.dispose();
    }
  }
}
