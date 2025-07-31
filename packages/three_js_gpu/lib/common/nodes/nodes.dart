import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/backend.dart';
import 'package:three_js_gpu/common/chain_map.dart';
import 'package:three_js_gpu/common/data_map.dart';
import 'package:three_js_gpu/common/nodes/node_builder_state.dart';
import 'package:three_js_gpu/common/nodes/node_uniforms_group.dart';
import 'package:three_js_math/three_js_math.dart';

final _outputNodeMap = new WeakMap();
final _chainKeys = [];
final _cacheKeyValues = [];

/**
 * This renderer module manages node-related objects and is the
 * primary interface between the renderer and the node system.
 *
 * @private
 * @augments DataMap
 */
class Nodes extends DataMap {
  Renderer renderer;
  Backend backend;
  NodeFrame nodeFrame = NodeFrame();
  Map<int,NodeBuilderState> nodeBuilderCache = new Map();
  ChainMap callHashCache = new ChainMap();
  ChainMap groupsData = new ChainMap();
  Map<String,WeakMap> cacheLib = {};

	/**
	 * Constructs a new nodes management component.
	 *
	 * @param {Renderer} renderer - The renderer.
	 * @param {Backend} backend - The renderer's backend.
	 */
	Nodes(this.renderer, this.backend ):super();

	/**
	 * Returns `true` if the given node uniforms group must be updated or not.
	 *
	 * @param {NodeUniformsGroup} nodeUniformsGroup - The node uniforms group.
	 * @return {boolean} Whether the node uniforms group requires an update or not.
	 */
	bool updateGroup(NodeUniformsGroup nodeUniformsGroup ) {

		final groupNode = nodeUniformsGroup.groupNode;
		final name = groupNode.name;

		// objectGroup is always updated

		if ( name == objectGroup.name ) return true;

		// renderGroup is updated once per render/compute call

		if ( name == renderGroup.name ) {
			final uniformsGroupData = this.get( nodeUniformsGroup );
			final renderId = this.nodeFrame.renderId;

			if ( uniformsGroupData.renderId != renderId ) {
				uniformsGroupData.renderId = renderId;
				return true;
			}

			return false;
		}

		// frameGroup is updated once per frame

		if ( name == frameGroup.name ) {
			final uniformsGroupData = this.get( nodeUniformsGroup );
			final frameId = this.nodeFrame.frameId;

			if ( uniformsGroupData.frameId != frameId ) {
				uniformsGroupData.frameId = frameId;
				return true;
			}

			return false;
		}

		// other groups are updated just when groupNode.needsUpdate is true

		_chainKeys[ 0 ] = groupNode;
		_chainKeys[ 1 ] = nodeUniformsGroup;

		var groupData = this.groupsData.get( _chainKeys );
		if ( groupData == null ) this.groupsData.set( _chainKeys, groupData = {} );

		_chainKeys.length = 0;

		if ( groupData.version != groupNode.version ) {
			groupData.version = groupNode.version;
			return true;
		}

		return false;
	}

	/**
	 * Returns the cache key for the given render object.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 * @return {number} The cache key.
	 */
	int getForRenderCacheKey(RenderObject renderObject ) {
		return renderObject.initialCacheKey;
	}

	/**
	 * Returns a node builder state for the given render object.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 * @return {NodeBuilderState} The node builder state.
	 */
	NodeBuilderState getForRender(RenderObject renderObject ) {
		final renderObjectData = this.get( renderObject );
		var nodeBuilderState = renderObjectData.nodeBuilderState;

		if ( nodeBuilderState == null ) {
			final nodeBuilderCache = this.nodeBuilderCache;

			final cacheKey = this.getForRenderCacheKey( renderObject );

			nodeBuilderState = nodeBuilderCache.get( cacheKey );

			if ( nodeBuilderState == null ) {
				final nodeBuilder = this.backend.createNodeBuilder( renderObject.object, this.renderer );
				nodeBuilder.scene = renderObject.scene;
				nodeBuilder.material = renderObject.material;
				nodeBuilder.camera = renderObject.camera;
				nodeBuilder.context.material = renderObject.material;
				nodeBuilder.lightsNode = renderObject.lightsNode;
				nodeBuilder.environmentNode = this.getEnvironmentNode( renderObject.scene );
				nodeBuilder.fogNode = this.getFogNode( renderObject.scene );
				nodeBuilder.clippingContext = renderObject.clippingContext;
				if ( this.renderer.getOutputRenderTarget() ? this.renderer.getOutputRenderTarget().multiview : false ) {
					nodeBuilder.enableMultiview();
				}

				nodeBuilder.build();
				nodeBuilderState = this._createNodeBuilderState( nodeBuilder );
				nodeBuilderCache.set( cacheKey, nodeBuilderState );
			}

			nodeBuilderState.usedTimes ++;
			renderObjectData.nodeBuilderState = nodeBuilderState;
		}

		return nodeBuilderState;
	}

	/**
	 * Deletes the given object from the internal data map
	 *
	 * @param {any} object - The object to delete.
	 * @return {?Object} The deleted dictionary.
	 */
	delete( object ) {
		if ( object.isRenderObject ) {
			final nodeBuilderState = this.get( object ).nodeBuilderState;
			nodeBuilderState.usedTimes --;

			if ( nodeBuilderState.usedTimes == 0 ) {
				this.nodeBuilderCache.delete( this.getForRenderCacheKey( object ) );
			}
		}

		return super.delete( object );
	}

	/**
	 * Returns a node builder state for the given compute node.
	 *
	 * @param {Node} computeNode - The compute node.
	 * @return {NodeBuilderState} The node builder state.
	 */
	NodeBuilderState getForCompute(Node computeNode ) {
		final computeData = this.get( computeNode );
		var nodeBuilderState = computeData.nodeBuilderState;

		if ( nodeBuilderState == null ) {
			final nodeBuilder = this.backend.createNodeBuilder( computeNode, this.renderer );
			nodeBuilder.build();

			nodeBuilderState = this._createNodeBuilderState( nodeBuilder );
			computeData.nodeBuilderState = nodeBuilderState;
		}

		return nodeBuilderState;
	}

	/**
	 * Creates a node builder state for the given node builder.
	 *
	 * @private
	 * @param {NodeBuilder} nodeBuilder - The node builder.
	 * @return {NodeBuilderState} The node builder state.
	 */
	NodeBuilderState _createNodeBuilderState(NodeBuilder nodeBuilder ) {
		return new NodeBuilderState(
			nodeBuilder.vertexShader,
			nodeBuilder.fragmentShader,
			nodeBuilder.computeShader,
			nodeBuilder.getAttributesArray(),
			nodeBuilder.getBindings(),
			nodeBuilder.updateNodes,
			nodeBuilder.updateBeforeNodes,
			nodeBuilder.updateAfterNodes,
			nodeBuilder.observer,
			nodeBuilder.transforms
		);
	}

	/**
	 * Returns an environment node for the current configured
	 * scene environment.
	 *
	 * @param {Scene} scene - The scene.
	 * @return {Node} A node representing the current scene environment.
	 */
	getEnvironmentNode( scene ) {

		this.updateEnvironment( scene );

		var environmentNode = null;

		if ( scene.environmentNode && scene.environmentNode.isNode ) {

			environmentNode = scene.environmentNode;

		} else {

			final sceneData = this.get( scene );

			if ( sceneData.environmentNode ) {

				environmentNode = sceneData.environmentNode;

			}

		}

		return environmentNode;

	}

	/**
	 * Returns a background node for the current configured
	 * scene background.
	 *
	 * @param {Scene} scene - The scene.
	 * @return {Node} A node representing the current scene background.
	 */
	getBackgroundNode( scene ) {

		this.updateBackground( scene );

		var backgroundNode = null;

		if ( scene.backgroundNode && scene.backgroundNode.isNode ) {

			backgroundNode = scene.backgroundNode;

		} else {

			final sceneData = this.get( scene );

			if ( sceneData.backgroundNode ) {

				backgroundNode = sceneData.backgroundNode;

			}

		}

		return backgroundNode;

	}

	/**
	 * Returns a fog node for the current configured scene fog.
	 *
	 * @param {Scene} scene - The scene.
	 * @return {Node} A node representing the current scene fog.
	 */
	Node? getFogNode(Scene scene ) {
		this.updateFog( scene );
		return scene.fogNode ?? this.get( scene ).fogNode ?? null;
	}

	/**
	 * Returns a cache key for the given scene and lights node.
	 * This key is used by `RenderObject` as a part of the dynamic
	 * cache key (a key that must be checked every time the render
	 * objects is drawn).
	 *
	 * @param {Scene} scene - The scene.
	 * @param {LightsNode} lightsNode - The lights node.
	 * @return {number} The cache key.
	 */
	int getCacheKey(Scene scene, LightsNode lightsNode ) {
		_chainKeys[ 0 ] = scene;
		_chainKeys[ 1 ] = lightsNode;

		final callId = this.renderer.info.calls;
		final cacheKeyData = this.callHashCache.get( _chainKeys ) || {};

		if ( cacheKeyData.callId != callId ) {

			final environmentNode = this.getEnvironmentNode( scene );
			final fogNode = this.getFogNode( scene );

			if ( lightsNode ) _cacheKeyValues.add( lightsNode.getCacheKey( true ) );
			if ( environmentNode ) _cacheKeyValues.add( environmentNode.getCacheKey() );
			if ( fogNode ) _cacheKeyValues.add( fogNode.getCacheKey() );

			_cacheKeyValues.add( this.renderer.getOutputRenderTarget() && this.renderer.getOutputRenderTarget().multiview ? 1 : 0 );
			_cacheKeyValues.add( this.renderer.shadowMap.enabled ? 1 : 0 );

			cacheKeyData.callId = callId;
			cacheKeyData.cacheKey = hashArray( _cacheKeyValues );

			this.callHashCache.set( _chainKeys, cacheKeyData );

			_cacheKeyValues.length = 0;
		}

		_chainKeys.length = 0;
		return cacheKeyData.cacheKey;
	}

	/**
	 * A boolean that indicates whether tone mapping should be enabled
	 * or not.
	 *
	 * @type {boolean}
	 */
	get isToneMappingState() {

		return this.renderer.getRenderTarget() ? false : true;

	}

	/**
	 * If a scene background is configured, this method makes sure to
	 * represent the background with a corresponding node-based implementation.
	 *
	 * @param {Scene} scene - The scene.
	 */
	void updateBackground(Scene scene ) {
		final sceneData = this.get( scene );
		final background = scene.background;

		if ( background != null) {
			final forceUpdate = ( scene.backgroundBlurriness == 0 && sceneData.backgroundBlurriness > 0 ) || ( scene.backgroundBlurriness > 0 && sceneData.backgroundBlurriness == 0 );

			if ( sceneData.background != background || forceUpdate ) {
				final backgroundNode = this.getCacheNode( 'background', background, (){

					if ( background.isCubeTexture == true || ( background.mapping == EquirectangularReflectionMapping || background.mapping == EquirectangularRefractionMapping || background.mapping == CubeUVReflectionMapping ) ) {
						if ( scene.backgroundBlurriness > 0 || background.mapping == CubeUVReflectionMapping ) {
							return pmremTexture( background );
						} 
            else {

							var envMap;

							if ( background.isCubeTexture == true ) {
								envMap = cubeTexture( background );
							} else {
								envMap = texture( background );
							}

							return cubeMapNode( envMap );
						}
					} else if ( background.isTexture == true ) {
						return texture( background, screenUV.flipY() ).setUpdateMatrix( true );
					} else if ( background.isColor != true ) {
						console.error( 'WebGPUNodes: Unsupported background configuration.', background );
					}

				}, forceUpdate );

				sceneData.backgroundNode = backgroundNode;
				sceneData.background = background;
				sceneData.backgroundBlurriness = scene.backgroundBlurriness;
			}
		} else if ( sceneData.backgroundNode ) {
			delete sceneData.backgroundNode;
			delete sceneData.background;
		}
	}

	/**
	 * This method is part of the caching of nodes which are used to represents the
	 * scene's background, fog or environment.
	 *
	 * @param {string} type - The type of object to cache.
	 * @param {Object} object - The object.
	 * @param {Function} callback - A callback that produces a node representation for the given object.
	 * @param {boolean} [forceUpdate=false] - Whether an update should be enforced or not.
	 * @return {Node} The node representation.
	 */
	Node getCacheNode(String type, object, Function callback, [bool forceUpdate = false] ) {
		final nodeCache = this.cacheLib[ type ] ?? ( this.cacheLib[ type ] = new WeakMap() );

		var node = nodeCache.get( object );

		if ( node == null || forceUpdate ) {
			node = callback();
			nodeCache.set( object, node );
		}

		return node;
	}

	/**
	 * If a scene fog is configured, this method makes sure to
	 * represent the fog with a corresponding node-based implementation.
	 *
	 * @param {Scene} scene - The scene.
	 */
	void updateFog(Scene scene ) {
		final sceneData = this.get( scene );
		final sceneFog = scene.fog;

		if ( sceneFog != null) {
			if ( sceneData.fog != sceneFog ) {

				final fogNode = this.getCacheNode( 'fog', sceneFog, (){

					if ( sceneFog.isFogExp2 ) {
						final color = reference( 'color', 'color', sceneFog ).setGroup( renderGroup );
						final density = reference( 'density', 'float', sceneFog ).setGroup( renderGroup );

						return fog( color, densityFogFactor( density ) );
					} else if ( sceneFog.isFog ) {
						final color = reference( 'color', 'color', sceneFog ).setGroup( renderGroup );
						final near = reference( 'near', 'float', sceneFog ).setGroup( renderGroup );
						final far = reference( 'far', 'float', sceneFog ).setGroup( renderGroup );

						return fog( color, rangeFogFactor( near, far ) );
					} else {
						console.error( 'THREE.Renderer: Unsupported fog configuration.', sceneFog );
					}
				} );

				sceneData.fogNode = fogNode;
				sceneData.fog = sceneFog;
			}
		} else {
			delete sceneData.fogNode;
			delete sceneData.fog;
		}
	}

	/**
	 * If a scene environment is configured, this method makes sure to
	 * represent the environment with a corresponding node-based implementation.
	 *
	 * @param {Scene} scene - The scene.
	 */
	void updateEnvironment(Scene scene ) {
		final sceneData = this.get( scene );
		final environment = scene.environment;

		if ( environment != null) {
			if ( sceneData.environment != environment ) {

				final environmentNode = this.getCacheNode( 'environment', environment, (){

					if ( environment is CubeTexture == true ) {
						return cubeTexture( environment );
					} else if ( environment.isTexture == true ) {
						return texture( environment );
					} else {
						console.error( 'Nodes: Unsupported environment configuration. $environment');
					}
				} );

				sceneData.environmentNode = environmentNode;
				sceneData.environment = environment;
			}
		} else if ( sceneData.environmentNode ) {
			delete sceneData.environmentNode;
			delete sceneData.environment;
		}
	}

	Node getNodeFrame([Renderer? renderer, Scene? scene, Object3D? object, Camera? camera, Material? material]) {
    renderer ??= this.renderer;
		final nodeFrame = this.nodeFrame;
		nodeFrame.renderer = renderer;
		nodeFrame.scene = scene;
		nodeFrame.object = object;
		nodeFrame.camera = camera;
		nodeFrame.material = material;

		return nodeFrame;
	}

	Node getNodeFrameForRender(RenderObject renderObject ) {
		return this.getNodeFrame( renderObject.renderer, renderObject.scene, renderObject.object, renderObject.camera, renderObject.material );
	}

	/**
	 * Returns the current output cache key.
	 *
	 * @return {string} The output cache key.
	 */
	String getOutputCacheKey() {
		final renderer = this.renderer;
		return renderer.toneMapping + ',' + renderer.currentColorSpace + ',' + renderer.xr.isPresenting;
	}

	/**
	 * Checks if the output configuration (tone mapping and color space) for
	 * the given target has changed.
	 *
	 * @param {Texture} outputTarget - The output target.
	 * @return {boolean} Whether the output configuration has changed or not.
	 */
	bool hasOutputChange(Texture outputTarget ) {
		final cacheKey = _outputNodeMap.get( outputTarget );
		return cacheKey != this.getOutputCacheKey();
	}

	/**
	 * Returns a node that represents the output configuration (tone mapping and
	 * color space) for the current target.
	 *
	 * @param {Texture} outputTarget - The output target.
	 * @return {Node} The output node.
	 */
	Node getOutputNode(Texture outputTarget ) {
		final renderer = this.renderer;
		final cacheKey = this.getOutputCacheKey();

		final output = outputTarget is ArrayTexture ?
			texture3D( outputTarget, vec3( screenUV, builtin( 'gl_ViewID_OVR' ) ) ).renderOutput( renderer.toneMapping, renderer.currentColorSpace ) :
			texture( outputTarget, screenUV ).renderOutput( renderer.toneMapping, renderer.currentColorSpace );

		_outputNodeMap.set( outputTarget, cacheKey );

		return output;
	}

	/**
	 * Triggers the call of `updateBefore()` methods
	 * for all nodes of the given render object.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 */
	void updateBefore(RenderObject renderObject ) {
		final nodeBuilder = renderObject.getNodeBuilderState();

		for ( final node in nodeBuilder.updateBeforeNodes ) {
			this.getNodeFrameForRender( renderObject ).updateBeforeNode( node );
		}
	}

	/**
	 * Triggers the call of `updateAfter()` methods
	 * for all nodes of the given render object.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 */
	void updateAfter(RenderObject renderObject ) {
		final nodeBuilder = renderObject.getNodeBuilderState();

		for ( final node in nodeBuilder.updateAfterNodes ) {
			this.getNodeFrameForRender( renderObject ).updateAfterNode( node );
		}
	}

	/**
	 * Triggers the call of `update()` methods
	 * for all nodes of the given compute node.
	 *
	 * @param {Node} computeNode - The compute node.
	 */
	void updateForCompute(Node computeNode ) {
		final nodeFrame = this.getNodeFrame();
		final nodeBuilder = this.getForCompute( computeNode );

		for ( final node in nodeBuilder.updateNodes ) {
			nodeFrame.updateNode( node );
		}
	}

	/**
	 * Triggers the call of `update()` methods
	 * for all nodes of the given compute node.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 */
	void updateForRender(RenderObject renderObject ) {
		final nodeFrame = this.getNodeFrameForRender( renderObject );
		final nodeBuilder = renderObject.getNodeBuilderState();

		for ( final node in nodeBuilder.updateNodes ) {
			nodeFrame.updateNode( node );
		}
	}

	bool needsRefresh(RenderObject renderObject ) {
		final nodeFrame = this.getNodeFrameForRender( renderObject );
		final monitor = renderObject.getMonitor();
		return monitor.needsRefresh( renderObject, nodeFrame );
	}

	void dispose() {
		super.dispose();
		this.nodeFrame = new NodeFrame();
		this.nodeBuilderCache = new Map();
		this.cacheLib = {};
	}

}


