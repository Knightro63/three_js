

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/chain_map.dart';
import './render_context.dart';

final _chainKeys = [];
final _defaultScene = Scene();
final _defaultCamera = Camera();

/**
 * This module manages the render contexts of the renderer.
 *
 * @private
 */
class RenderContexts {
  Map chainMaps = {};


	RenderContexts();

	/**
	 * Returns a render context for the given scene, camera and render target.
	 *
	 * @param {Scene} scene - The scene.
	 * @param {Camera} camera - The camera that is used to render the scene.
	 * @param {?RenderTarget} [renderTarget=null] - The active render target.
	 * @return {RenderContext} The render context.
	 */
	RenderContext get(Scene scene, Camera camera, [RenderTarget? renderTarget]) {
		_chainKeys[ 0 ] = scene;
		_chainKeys[ 1 ] = camera;

		String attachmentState;

		if ( renderTarget == null ) {
			attachmentState = 'default';
		} else {
			final format = renderTarget.texture.format;
			final count = renderTarget.textures.length;

			attachmentState = '${ count }:${ format }:${ renderTarget.samples }:${ renderTarget.depthBuffer }:${ renderTarget.stencilBuffer }';
		}

		final chainMap = this._getChainMap( attachmentState );

		dynamic renderState = chainMap.get( _chainKeys );

		if ( renderState == null ) {
			renderState = new RenderContext();
			chainMap.set( _chainKeys, renderState );
		}

		_chainKeys.length = 0;

		if ( renderTarget != null ) renderState.sampleCount = renderTarget.samples == 0 ? 1 : renderTarget.samples;

		return renderState;
	}

	RenderContext? getForClear(RenderTarget? renderTarget) {
		return this.get( _defaultScene, _defaultCamera, renderTarget );
	}

	/**
	 * Returns a chain map for the given attachment state.
	 *
	 * @private
	 * @param {string} attachmentState - The attachment state.
	 * @return {ChainMap} The chain map.
	 */
	ChainMap _getChainMap(String attachmentState ) {
		return this.chainMaps[ attachmentState ] ?? ( this.chainMaps[ attachmentState ] = ChainMap() );
	}

	void dispose() {
		this.chainMaps = {};
	}
}