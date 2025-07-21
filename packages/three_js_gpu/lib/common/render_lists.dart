import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/lighting.dart';
import 'package:three_js_gpu/common/render_list.dart';
import './chain_map.dart';

const _chainKeys = [];

class RenderLists {
  ChainMap lists = ChainMap();
  Lighting lighting; 

	/**
	 * Constructs a render lists management component.
	 *
	 * @param {Lighting} lighting - The lighting management component.
	 */
	RenderLists(this.lighting );

	/**
	 * Returns a render list for the given scene and camera.
	 *
	 * @param {Scene} scene - The scene.
	 * @param {Camera} camera - The camera.
	 * @return {RenderList} The render list.
	 */
	RenderList get(Scene scene, Camera camera ) {
		final lists = this.lists;

		_chainKeys[ 0 ] = scene;
		_chainKeys[ 1 ] = camera;

		dynamic list = lists.get( _chainKeys );

		if ( list == null ) {
			list = new RenderList( this.lighting, scene, camera );
			lists.set( _chainKeys, list );
		}

		_chainKeys.length = 0;

		return list;
	}

	/**
	 * Frees all internal resources.
	 */
	void dispose() {
		lists = ChainMap();
	}

}