import 'package:three_js_gpu/common/bindings.dart';
import 'package:three_js_gpu/common/chain_map.dart';
import 'package:three_js_gpu/common/geometries.dart';
import 'package:three_js_gpu/common/info.dart';
import 'package:three_js_gpu/common/nodes/nodes.dart';
import 'package:three_js_gpu/common/pipelines.dart';
import 'package:three_js_gpu/common/render_object.dart';
import 'package:three_js_gpu/common/renderer.dart';

final _chainKeys = [];

/**
 * This module manages the render objects of the renderer.
 *
 * @private
 */
class RenderObjects {
  Renderer renderer;
  Nodes nodes;
  Geometries geometries;
  Pipelines pipelines;
  Bindings bindings;
  Info info;
  Map<String,dynamic> chainMaps = {};

	/**
	 * Constructs a new render object management component.
	 *
	 * @param {Renderer} renderer - The renderer.
	 * @param {Nodes} nodes - Renderer component for managing nodes related logic.
	 * @param {Geometries} geometries - Renderer component for managing geometries.
	 * @param {Pipelines} pipelines - Renderer component for managing pipelines.
	 * @param {Bindings} bindings - Renderer component for managing bindings.
	 * @param {Info} info - Renderer component for managing metrics and monitoring data.
	 */
	RenderObjects(this.renderer,this.nodes,this.geometries,this.pipelines,this.bindings,this.info );

	/**
	 * Returns a render object for the given object and state data.
	 *
	 * @param {Object3D} object - The 3D object.
	 * @param {Material} material - The 3D object's material.
	 * @param {Scene} scene - The scene the 3D object belongs to.
	 * @param {Camera} camera - The camera the 3D object should be rendered with.
	 * @param {LightsNode} lightsNode - The lights node.
	 * @param {RenderContext} renderContext - The render context.
	 * @param {ClippingContext} clippingContext - The clipping context.
	 * @param {string} [passId] - An optional ID for identifying the pass.
	 * @return {RenderObject} The render object.
	 */
	get( object, material, scene, camera, lightsNode, renderContext, clippingContext, passId ) {
		final chainMap = this.getChainMap( passId );

		// reuse chainArray
		_chainKeys[ 0 ] = object;
		_chainKeys[ 1 ] = material;
		_chainKeys[ 2 ] = renderContext;
		_chainKeys[ 3 ] = lightsNode;

		var renderObject = chainMap.get( _chainKeys );

		if ( renderObject == null ) {
			renderObject = this.createRenderObject( this.nodes, this.geometries, this.renderer, object, material, scene, camera, lightsNode, renderContext, clippingContext, passId );
			chainMap.set( _chainKeys, renderObject );
		} 
    else {
			renderObject.updateClipping( clippingContext );

			if ( renderObject.needsGeometryUpdate ) {
				renderObject.setGeometry( object.geometry );
			}

			if ( renderObject.version != material.version || renderObject.needsUpdate ) {
				if ( renderObject.initialCacheKey != renderObject.getCacheKey() ) {
					renderObject.dispose();
					renderObject = this.get( object, material, scene, camera, lightsNode, renderContext, clippingContext, passId );
				} 
        else {
					renderObject.version = material.version;
				}
			}
		}

		_chainKeys.length = 0;

		return renderObject;
	}

	/**
	 * Returns a chain map for the given pass ID.
	 *
	 * @param {string} [passId='default'] - The pass ID.
	 * @return {ChainMap} The chain map.
	 */
	getChainMap( [String passId = 'default'] ) {
		return this.chainMaps[ passId ] ?? ( this.chainMaps[ passId ] = new ChainMap() );
	}

	/**
	 * Frees internal resources.
	 */
	dispose() {
		this.chainMaps = {};
	}

	/**
	 * Factory method for creating render objects with the given list of parameters.
	 *
	 * @param {Nodes} nodes - Renderer component for managing nodes related logic.
	 * @param {Geometries} geometries - Renderer component for managing geometries.
	 * @param {Renderer} renderer - The renderer.
	 * @param {Object3D} object - The 3D object.
	 * @param {Material} material - The object's material.
	 * @param {Scene} scene - The scene the 3D object belongs to.
	 * @param {Camera} camera - The camera the object should be rendered with.
	 * @param {LightsNode} lightsNode - The lights node.
	 * @param {RenderContext} renderContext - The render context.
	 * @param {ClippingContext} clippingContext - The clipping context.
	 * @param {string} [passId] - An optional ID for identifying the pass.
	 * @return {RenderObject} The render object.
	 */
	createRenderObject( nodes, geometries, renderer, object, material, scene, camera, lightsNode, renderContext, clippingContext, passId ) {
		final chainMap = this.getChainMap( passId );
		final renderObject = new RenderObject( nodes, geometries, renderer, object, material, scene, camera, lightsNode, renderContext, clippingContext );

		renderObject.onDispose = (){
			this.pipelines.delete( renderObject );
			this.bindings.delete( renderObject );
			this.nodes.delete( renderObject );

			chainMap.delete( renderObject.getChainArray() );
		};

		return renderObject;
	}
}