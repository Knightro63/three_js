import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/data_map.dart';
import 'package:three_js_gpu/common/nodes/nodes.dart';
import 'package:three_js_gpu/common/render_context.dart';
import 'package:three_js_gpu/common/render_list.dart';
import 'package:three_js_gpu/common/renderer.dart';
import 'package:three_js_math/three_js_math.dart';

final _clearColor = Color();


class Background extends DataMap {
  Renderer renderer;
  Nodes nodes;

	Background(this.renderer, this.nodes ):super();

	/**
	 * Updates the background for the given scene. Depending on how `Scene.background`
	 * or `Scene.backgroundNode` are configured, this method might configure a simple clear
	 * or add a mesh to the render list for rendering the background as a textured plane
	 * or skybox.
	 *
	 * @param {Scene} scene - The scene.
	 * @param {RenderList} renderList - The current render list.
	 * @param {RenderContext} renderContext - The current render context.
	 */
	void update(Scene scene, RenderList renderList, RenderContext renderContext ) {
		final renderer = this.renderer;
		final background = this.nodes.getBackgroundNode( scene ) ?? scene.background;

		bool forceClear = false;

		if ( background == null ) {
			// no background settings, use clear color configuration from the renderer

			renderer._clearColor.getRGB( _clearColor );
			_clearColor.alpha = renderer._clearColor.a;
		} 
    else if ( background is Color) {
			// background is an opaque color

			background.getRGB( _clearColor );
			_clearColor.alpha = 1;
			forceClear = true;
		} 
    else if ( background is Node ) {

			final sceneData = this.get( scene );
			final backgroundNode = background;

			_clearColor.setFrom( renderer._clearColor );

			let backgroundMesh = sceneData.backgroundMesh;

			if ( backgroundMesh == null ) {

				final backgroundMeshNode = context( vec4( backgroundNode ).mul( backgroundIntensity ), {
					// @TODO: Add Texture2D support using node context
					getUV: () => backgroundRotation.mul( normalWorldGeometry ),
					getTextureLevel: () => backgroundBlurriness
				} );

				let viewProj = modelViewProjection;
				viewProj = viewProj.setZ( viewProj.w );

				final nodeMaterial = new NodeMaterial();
				nodeMaterial.name = 'Background.material';
				nodeMaterial.side = BackSide;
				nodeMaterial.depthTest = false;
				nodeMaterial.depthWrite = false;
				nodeMaterial.allowOverride = false;
				nodeMaterial.fog = false;
				nodeMaterial.lights = false;
				nodeMaterial.vertexNode = viewProj;
				nodeMaterial.colorNode = backgroundMeshNode;

				sceneData.backgroundMeshNode = backgroundMeshNode;
				sceneData.backgroundMesh = backgroundMesh = new Mesh( new SphereGeometry( 1, 32, 32 ), nodeMaterial );
				backgroundMesh.frustumCulled = false;
				backgroundMesh.name = 'Background.mesh';

				backgroundMesh.onBeforeRender = ( renderer, scene, camera ) {
					this.matrixWorld.copyPosition( camera.matrixWorld );
				};

				void onBackgroundDispose() {
					background.removeEventListener( 'dispose', onBackgroundDispose );

					backgroundMesh.material.dispose();
					backgroundMesh.geometry.dispose();
				}

				background.addEventListener( 'dispose', onBackgroundDispose );
			}

			final backgroundCacheKey = backgroundNode.getCacheKey();

			if ( sceneData.backgroundCacheKey != backgroundCacheKey ) {
				sceneData.backgroundMeshNode.node = vec4( backgroundNode ).mul( backgroundIntensity );
				sceneData.backgroundMeshNode.needsUpdate = true;

				backgroundMesh.material.needsUpdate = true;

				sceneData.backgroundCacheKey = backgroundCacheKey;
			}

			renderList.unshift( backgroundMesh, backgroundMesh.geometry, backgroundMesh.material, 0, 0, null, null );
		}
     else {
			console.error( 'THREE.Renderer: Unsupported background configuration. $background');
		}

		//

		final environmentBlendMode = renderer.xr.getEnvironmentBlendMode();

		if ( environmentBlendMode == 'additive' ) {
			_clearColor.setValues( 0, 0, 0, 1 );
		} 
    else if ( environmentBlendMode == 'alpha-blend' ) {
			_clearColor.setValues( 0, 0, 0, 0 );
		}

		//

		if ( renderer.autoClear == true || forceClear == true ) {
			final clearColorValue = renderContext.clearColorValue;

			clearColorValue.r = _clearColor.r;
			clearColorValue.g = _clearColor.g;
			clearColorValue.b = _clearColor.b;
			clearColorValue.a = _clearColor.a;

			// premultiply alpha

			if ( renderer.backend is WebGLBackend || renderer.alpha == true ) {
				clearColorValue.r *= clearColorValue.a;
				clearColorValue.g *= clearColorValue.a;
				clearColorValue.b *= clearColorValue.a;
			}

			//
			renderContext.depthClearValue = renderer._clearDepth;
			renderContext.stencilClearValue = renderer._clearStencil;

			renderContext.clearColor = renderer.autoClearColor == true;
			renderContext.clearDepth = renderer.autoClearDepth == true;
			renderContext.clearStencil = renderer.autoClearStencil == true;
		} 
    else {
			renderContext.clearColor = false;
			renderContext.clearDepth = false;
			renderContext.clearStencil = false;
		}
	}
}
