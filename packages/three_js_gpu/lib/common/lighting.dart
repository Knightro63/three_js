

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/quad_mesh.dart';

import './chain_map.dart';

const _defaultLights = /*@__PURE__*/ new LightsNode();
const _chainKeys = [];

/**
 * This renderer module manages the lights nodes which are unique
 * per scene and camera combination.
 *
 * The lights node itself is later configured in the render list
 * with the actual lights from the scene.
 *
 * @private
 * @augments ChainMap
 */
class Lighting extends ChainMap {
	Lighting():super();

	LightsNode createNode([List<Light>? lights]) {
    lights ??= [];
		return LightsNode().setLights( lights );
	}

	LightsNode getNode(Scene scene, Camera camera ) {
		if ( scene is QuadMesh ) return _defaultLights;

		_chainKeys[ 0 ] = scene;
		_chainKeys[ 1 ] = camera;

		dynamic node = get( _chainKeys );

		if ( node == null ) {
			node = createNode();
			set( _chainKeys, node );
		}

		_chainKeys.length = 0;

		return node;
	}
}