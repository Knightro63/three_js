

import 'package:three_js_gpu/common/quad_mesh.dart';
import 'package:three_js_math/three_js_math.dart';

/**
 * This module is responsible to manage the post processing setups in apps.
 * You usually create a single instance of this class and use it to define
 * the output of your post processing effect chain.
 * ```js
 * final postProcessing = new PostProcessing( renderer );
 *
 * final scenePass = pass( scene, camera );
 *
 * postProcessing.outputNode = scenePass;
 * ```
 *
 * Note: This module can only be used with `WebGPURenderer`.
 */
class PostProcessing {
  late final QuadMesh _quadMesh;
  Renderer renderer;
  bool outputColorTransform = true;
  bool needsUpdate = true;
  NodeMaterial material = NodeMaterial();
  Map? _context;

	/**
	 * Constructs a new post processing management module.
	 *
	 * @param {Renderer} renderer - A reference to the renderer.
	 * @param {Node<vec4>} outputNode - An optional output node.
	 */
	PostProcessing(this.renderer, outputNode = vec4( 0, 0, 1, 1 ) ) {

		/**
		 * A node which defines the final output of the post
		 * processing. This is usually the last node in a chain
		 * of effect nodes.
		 *
		 * @type {Node<vec4>}
		 */
		this.outputNode = outputNode;
		material.name = 'PostProcessing';
		this._quadMesh = new QuadMesh( material );
	}

	/**
	 * When `PostProcessing` is used to apply post processing effects,
	 * the application must use this version of `render()` inside
	 * its animation loop (not the one from the renderer).
	 */
	void render() {
		final renderer = this.renderer;
		this._update();

		this._context?['onBeforePostProcessing']?.call();

		final toneMapping = renderer.toneMapping;
		final outputColorSpace = renderer.outputColorSpace;

		renderer.toneMapping = NoToneMapping;
		renderer.outputColorSpace = LinearSRGBColorSpace;

		//

		final currentXR = renderer.xr.enabled;
		renderer.xr.enabled = false;

		this._quadMesh.render( renderer );

		renderer.xr.enabled = currentXR;

		//

		renderer.toneMapping = toneMapping;
		renderer.outputColorSpace = outputColorSpace;

		this._context?['onAfterPostProcessing']?.call();
	}

	get context => this._context;


	void dispose() {
		this._quadMesh.material?.dispose();
	}

	/**
	 * Updates the state of the module.
	 *
	 * @private
	 */
	void _update() {
		if ( this.needsUpdate == true ) {

			final renderer = this.renderer;

			final toneMapping = renderer.toneMapping;
			final outputColorSpace = renderer.outputColorSpace;

			final context = {
				'postProcessing': this,
				'onBeforePostProcessing': null,
				'onAfterPostProcessing': null
			};

			let outputNode = this.outputNode;

			if ( this.outputColorTransform == true ) {
				outputNode = outputNode.context( context );
				outputNode = renderOutput( outputNode, toneMapping, outputColorSpace );
			} 
      else {
				context['toneMapping'] = toneMapping;
				context['outputColorSpace'] = outputColorSpace;
				outputNode = outputNode.context( context );
			}

			this._context = context;

			this._quadMesh.material.fragmentNode = outputNode;
			this._quadMesh.material?.needsUpdate = true;

			this.needsUpdate = false;
		}
	}

	/**
	 * When `PostProcessing` is used to apply post processing effects,
	 * the application must use this version of `renderAsync()` inside
	 * its animation loop (not the one from the renderer).
	 *
	 * @async
	 * @return {Promise} A Promise that resolves when the render has been finished.
	 */
	Future<void> renderAsync() async{
		this._update();

		this._context?['onBeforePostProcessing']?.call();

		final renderer = this.renderer;

		final toneMapping = renderer.toneMapping;
		final outputColorSpace = renderer.outputColorSpace;

		renderer.toneMapping = NoToneMapping;
		renderer.outputColorSpace = LinearSRGBColorSpace;

		//

		final currentXR = renderer.xr.enabled;
		renderer.xr.enabled = false;

		await this._quadMesh.renderAsync( renderer );

		renderer.xr.enabled = currentXR;

		//

		renderer.toneMapping = toneMapping;
		renderer.outputColorSpace = outputColorSpace;

		this._context?['onAfterPostProcessing']?.call();
	}
}
