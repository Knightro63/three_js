import 'package:three_js_core/three_js_core.dart';
import '../../common/nodes/node_builder_state.dart';
import '../../src/code/node_builder.dart';
import '../../src/core/constants.dart';
import 'package:three_js_math/three_js_math.dart';

const _parentBuildStage = {
	'analyze': 'setup',
	'generate': 'analyze'
};

int _nodeId = 0;

class Node extends EventDispatcher {
  String? nodeType;
	NodeUpdateType updateType = NodeUpdateType.none;
	NodeUpdateType updateBeforeType = NodeUpdateType.none;
	NodeUpdateType updateAfterType = NodeUpdateType.none;

	String uuid = MathUtils.generateUUID();
	int version = 0;
  bool global = false;
	bool parents = false;
	bool isNode = true;
	int? _cacheKey;
	int _cacheKeyVersion = 0;

	Node([this.nodeType]):super(){
		Object.defineProperty( this, 'id', { value: _nodeId ++ } );
	}

	/// Set this property to `true` when the node should be regenerated.
	set needsUpdate(bool value ) {
		if ( value == true ) {
			version ++;
		}
	}

  /// The type of the class. The value is usually the constructor name.
  /// @type {string}
  /// @readonly
	String get type{
		return runtimeType.toString();
	}

  /// Convenient method for defining {@link Node#update}.
	Node onUpdate(Function callback, NodeUpdateType updateType ) {
		this.updateType = updateType;
		update = callback.call( getSelf() );
		return this;
	}

  /// Convenient method for defining {@link Node#update}. Similar to {@link Node#onUpdate}, but
  /// this method automatically sets the update type to `FRAME`.
	Node onFrameUpdate(Function callback ) {
		return onUpdate( callback, NodeUpdateType.frame );
	}

  /// Convenient method for defining {@link Node#update}. Similar to {@link Node#onUpdate}, but
  /// this method automatically sets the update type to `RENDER`.
	Node onRenderUpdate(Function callback ) {
		return onUpdate( callback, NodeUpdateType.render );
	}

  /// Convenient method for defining {@link Node#update}. Similar to {@link Node#onUpdate}, but
  /// this method automatically sets the update type to `OBJECT`.
	Node onObjectUpdate(Function callback ) {
		return onUpdate( callback, NodeUpdateType.object );
	}

  /// Convenient method for defining {@link Node#updateReference}.
	Node onReference(Function callback ) {
		updateReference = callback.bind( getSelf() );
		return this;
	}

  /// The `this` reference might point to a Proxy so this method can be used
  /// to get the reference to the actual node instance.
	Node getSelf() {
		return this;
	}

  /// Nodes might refer to other objects like materials. This method allows to dynamically update the reference
  /// to such objects based on a given state (e.g. the current node frame or builder).
	Node updateReference( /*state*/ ) {
		return this;
	}

  /// By default this method returns the value of the {@link Node#global} flag. This method
  /// can be overwritten in derived classes if an analytical way is required to determine the
  /// global cache referring to the current shader-stage.
	bool isGlobal( /*builder*/ ) {
		return global;
	}

  /// Generator function that can be used to iterate over the child nodes.
  /// @generator
  /// @yields {Node} A child node.
	* getChildren() {

		for ( const { childNode } of getNodeChildren( this ) ) {

			yield childNode;

		}

	}

  /// Calling this method dispatches the `dispose` event. This event can be used
  /// to register event listeners for clean up tasks.
	dispose() {
		this.dispatchEvent( { type: 'dispose' } );
	}

  /// Callback for {@link Node#traverse}.
  /// @callback traverseCallback
  /// @param {Node} node - The current node.
  /// Can be used to traverse through the node's hierarchy.
  /// @param {traverseCallback} callback - A callback that is executed per node.
	traverse( callback ) {
		callback( this );

		for ( final childNode in getChildren() ) {
			childNode.traverse( callback );
		}
	}

  /// Returns the cache key for this node.
	int getCacheKey( [bool force = false] ) {
		force = force || version != _cacheKeyVersion;

		if ( force == true || _cacheKey == null ) {
			_cacheKey = hash( getCacheKey( this, force ), customCacheKey() );
			_cacheKeyVersion = version;
		}

		return _cacheKey;
	}

  /// Generate a custom cache key for this node.
	int customCacheKey() {
		return 0;
	}

  /// Returns the references to this node which is by default `this`.
  /// @return {Node} A reference to this node.
	getScope() {
		return this;
	}

  /// Returns the hash of the node which is used to identify the node. By default it's
  /// the {@link Node#uuid} however derived node classes might have to overwrite this method
  /// depending on their implementation.
	String getHash( /*builder*/ ) {
		return uuid;
	}

  /// Returns the update type of {@link Node#update}.
	NodeUpdateType getUpdateType() {
		return updateType;
	}

  /// Returns the update type of {@link Node#updateBefore}.
	NodeUpdateType getUpdateBeforeType() {
		return updateBeforeType;
	}

  /// Returns the update type of {@link Node#updateAfter}.
	NodeUpdateType getUpdateAfterType() {
		return updateAfterType;
	}

  /// Certain types are composed of multiple elements. For example a `vec3`
  /// is composed of three `float` values. This method returns the type of
  /// these elements.
  /// @param {NodeBuilder} builder - The current node builder.
  /// @return {string} The type of the node.
	String getElementType(NodeBuilderState builder ) {
		final type = getNodeType( builder );
		final elementType = builder.getElementType( type );

		return elementType;
	}

  /// Returns the node member type for the given name.
	String getMemberType( /*builder, name*/ ) {
		return 'void';
	}

  /// Returns the node's type.
	String? getNodeType(NodeBuilder builder,[String? output] ) {
		final nodeProperties = builder.getNodeProperties( this );

		if ( nodeProperties.outputNode ) {
			return nodeProperties.outputNode.getNodeType( builder );
		}

		return nodeType;
	}

  /// This method is used during the build process of a node and ensures
  /// equal nodes are not built multiple times but just once. For example if
  /// `attribute( 'uv' )` is used multiple times by the user, the build
  /// process makes sure to process just the first node.
	Node getShared(NodeBuilder builder ) {
		final hash = getHash( builder );
		final nodeFromHash = builder.getNodeFromHash( hash );

		return nodeFromHash ?? this;
	}

  /// Represents the setup stage which is the first step of the build process, see {@link Node#build} method.
  /// This method is often overwritten in derived modules to prepare the node which is used as the output/result.
  /// The output node must be returned in the `return` statement.
	Node? setup(NodeBuilder builder ) {
		final nodeProperties = builder.getNodeProperties( this );

		int index = 0;

		for ( final childNode in getChildren() ) {
			nodeProperties[ 'node${index ++}'] = childNode;
		}

		// return a outputNode if exists or null

		return nodeProperties.outputNode;
	}

  /// Represents the analyze stage which is the second step of the build process, see {@link Node#build} method.
  /// This stage analyzes the node hierarchy and ensures descendent nodes are built.
  /// @param {NodeBuilder} builder - The current node builder.
  /// @param {?Node} output - The target output node.
	Node? analyze(NodeBuilder builder, [output = null] ) {
		final usageCount = builder.increaseUsage( this );

		if ( parents == true ) {
			final nodeData = builder.getDataFromNode( this, 'any' );
			nodeData.stages = nodeData.stages ?? {};
			nodeData.stages[ builder.shaderStage ] = nodeData.stages[ builder.shaderStage ] ?? [];
			nodeData.stages[ builder.shaderStage ].push( output );
		}

		if ( usageCount == 1 ) {
			// node flow children
			final nodeProperties = builder.getNodeProperties( this );

			for ( final childNode in nodeProperties.values ) {
				if (childNode is Node) {
					childNode.build( builder, this );
				}
			}
		}
	}

  /// Represents the generate stage which is the third step of the build process, see {@link Node#build} method.
  /// This state builds the output node and returns the resulting shader string.
	String? generate(NodeBuilder builder, String? output ) {
		final outputNode = builder.getNodeProperties( this )['outputNode'];

		if (outputNode is Node) {
			return outputNode.build( builder, output );
		}
    return null;
	}

  /// The method can be implemented to update the node's internal state before it is used to render an object.
  /// The {@link Node#updateBeforeType} property defines how often the update is executed.
  /// @abstract
  /// @param {NodeFrame} frame - A reference to the current node frame.
  /// @return {?boolean} An optional bool that indicates whether the implementation actually performed an update or not (e.g. due to caching).
	updateBefore( /*frame*/ ) {
		console.warning( 'Abstract function.' );
	}

  /// The method can be implemented to update the node's internal state after it was used to render an object.
  /// The {@link Node#updateAfterType} property defines how often the update is executed.
  /// @abstract
  /// @param {NodeFrame} frame - A reference to the current node frame.
  /// @return {?boolean} An optional bool that indicates whether the implementation actually performed an update or not (e.g. due to caching).
	updateAfter( /*frame*/ ) {
		console.warning( 'Abstract function.' );
	}

  /// The method can be implemented to update the node's internal state when it is used to render an object.
  /// The {@link Node#updateType} property defines how often the update is executed.
  /// @abstract
  /// @param {NodeFrame} frame - A reference to the current node frame.
  /// @return {?boolean} An optional bool that indicates whether the implementation actually performed an update or not (e.g. due to caching).
	update( /*frame*/ ) {
		console.warning( 'Abstract function.' );
	}

  /// This method performs the build of a node. The behavior and return value depend on the current build stage:
  /// - **setup**: Prepares the node and its children for the build process. This process can also create new nodes. Returns the node itself or a variant.
  /// - **analyze**: Analyzes the node hierarchy for optimizations in the code generation stage. Returns `null`.
  /// - **generate**: Generates the shader code for the node. Returns the generated shader string.
  /// @param {NodeBuilder} builder - The current node builder.
  /// @param {string|Node|null} [output=null] - Can be used to define the output type.
  /// @return {Node|string|null} The result of the build process, depending on the build stage.
	dynamic build(NodeBuilder builder, [String? output]) {
		final refNode = getShared( builder );

		if ( this != refNode ) {
			return refNode.build( builder, output );
		}

		final nodeData = builder.getDataFromNode( this );
		nodeData.buildStages = nodeData.buildStages ?? {};
		nodeData.buildStages[ builder.buildStage ] = true;

		final parentBuildStage = _parentBuildStage[ builder.buildStage ];

		if ( parentBuildStage != null && nodeData.buildStages[ parentBuildStage ] != true ) {
			// force parent build stage (setup or analyze)
			final previousBuildStage = builder.getBuildStage();
			builder.setBuildStage( parentBuildStage );
			build( builder );
			builder.setBuildStage( previousBuildStage );
		}

		//

		builder.addNode( this );
		builder.addChain( this );

		/* Build stages expected results:
			- "setup"		-> Node
			- "analyze"		-> null
			- "generate"	-> String
		*/
		let result = null;

		final buildStage = builder.getBuildStage();

		if ( buildStage == 'setup' ) {

			updateReference( builder );

			final properties = builder.getNodeProperties( this );

			if ( properties.initialized != true ) {

				//const stackNodesBeforeSetup = builder.stack.nodes.length;

				properties.initialized = true;
				properties.outputNode = setup( builder ) ?? properties.outputNode;

				/*if ( isNodeOutput && builder.stack.nodes.length !== stackNodesBeforeSetup ) {

					// !! no outputNode !!
					//outputNode = builder.stack;

				}*/

				for ( final childNode in properties.values) {
					if (childNode is Node ) {
						if ( childNode.parents == true ) {
							final childProperties = builder.getNodeProperties( childNode );
							childProperties.parents = childProperties.parents ?? [];
							childProperties.parents.push( this );
						}
						childNode.build( builder );
					}
				}
			}

			result = properties.outputNode;

		} 
    else if ( buildStage == 'analyze' ) {
			analyze( builder, output );
		} 
    else if ( buildStage == 'generate' ) {

			final isGenerateOnce = generate.length == 1;

			if ( isGenerateOnce ) {

				const type = this.getNodeType( builder );
				const nodeData = builder.getDataFromNode( this );

				result = nodeData.snippet;

				if ( result === undefined ) {

					if ( nodeData.generated === undefined ) {

						nodeData.generated = true;

						result = this.generate( builder ) || '';

						nodeData.snippet = result;

					} else {

						console.warn( 'THREE.Node: Recursion detected.', this );

						result = '/* Recursion detected. */';

					}

				} else if ( nodeData.flowCodes !== undefined && builder.context.nodeBlock !== undefined ) {

					builder.addFlowCodeHierarchy( this, builder.context.nodeBlock );

				}

				result = builder.format( result, type, output );

			} else {

				result = this.generate( builder, output ) || '';

			}

		}

		builder.removeChain( this );
		builder.addSequentialNode( this );

		return result;

	}

  /// Returns the child nodes as a JSON object.
  /// @return {Array<Object>} An iterable list of serialized child objects as JSON.
	getSerializeChildren() {
		return getNodeChildren( this );
	}

  /// Serializes the node to JSON.
  /// @param {Object} json - The output JSON object.
	serialize( json ) {

		const nodeChildren = this.getSerializeChildren();

		const inputNodes = {};

		for ( const { property, index, childNode } of nodeChildren ) {

			if ( index !== undefined ) {

				if ( inputNodes[ property ] === undefined ) {

					inputNodes[ property ] = Number.isInteger( index ) ? [] : {};

				}

				inputNodes[ property ][ index ] = childNode.toJSON( json.meta ).uuid;

			} else {

				inputNodes[ property ] = childNode.toJSON( json.meta ).uuid;

			}

		}

		if ( Object.keys( inputNodes ).length > 0 ) {

			json.inputNodes = inputNodes;

		}

	}

  /// Deserializes the node from the given JSON.
  /// @param {Object} json - The JSON object.
	deserialize( json ) {

		if ( json.inputNodes !== undefined ) {

			const nodes = json.meta.nodes;

			for ( const property in json.inputNodes ) {

				if ( Array.isArray( json.inputNodes[ property ] ) ) {

					const inputArray = [];

					for ( const uuid of json.inputNodes[ property ] ) {

						inputArray.push( nodes[ uuid ] );

					}

					this[ property ] = inputArray;

				} else if ( typeof json.inputNodes[ property ] === 'object' ) {

					const inputObject = {};

					for ( const subProperty in json.inputNodes[ property ] ) {

						const uuid = json.inputNodes[ property ][ subProperty ];

						inputObject[ subProperty ] = nodes[ uuid ];

					}

					this[ property ] = inputObject;

				} else {

					const uuid = json.inputNodes[ property ];

					this[ property ] = nodes[ uuid ];

				}

			}

		}

	}

  /// Serializes the node into the three.js JSON Object/Scene format.
  /// @param {?Object} meta - An optional JSON object that already holds serialized data from other scene objects.
  /// @return {Object} The serialized node.
	toJSON( meta ) {

		const { uuid, type } = this;
		const isRoot = ( meta === undefined || typeof meta === 'string' );

		if ( isRoot ) {

			meta = {
				textures: {},
				images: {},
				nodes: {}
			};

		}

		// serialize

		let data = meta.nodes[ uuid ];

		if ( data === undefined ) {

			data = {
				uuid,
				type,
				meta,
				metadata: {
					version: 4.7,
					type: 'Node',
					generator: 'Node.toJSON'
				}
			};

			if ( isRoot !== true ) meta.nodes[ data.uuid ] = data;

			this.serialize( data );

			delete data.meta;

		}

		// TODO: Copied from Object3D.toJSON

		function extractFromCache( cache ) {

			const values = [];

			for ( const key in cache ) {

				const data = cache[ key ];
				delete data.metadata;
				values.push( data );

			}

			return values;

		}

		if ( isRoot ) {
			const textures = extractFromCache( meta.textures );
			const images = extractFromCache( meta.images );
			const nodes = extractFromCache( meta.nodes );

			if ( textures.length > 0 ) data.textures = textures;
			if ( images.length > 0 ) data.images = images;
			if ( nodes.length > 0 ) data.nodes = nodes;
		}

		return data;
	}
}
