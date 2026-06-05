import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import '../nodes/core/node.dart';

/**
 * A loader for loading node objects in the three.js JSON Object/Scene format.
 *
 * @augments Loader
 */
class NodeLoader extends Loader {
  Map<String, Texture> textures = {};
  Map<String, Node> nodes = {};

	NodeLoader(super.manager );

	/**
	 * Loads the node definitions from the given URL.
	 *
	 * @param {string} url - The path/URL of the file to be loaded.
	 * @param {Function} onLoad - Will be called when load completes.
	 * @param {Function} onProgress - Will be called while load progresses.
	 * @param {Function} onError - Will be called when errors are thrown during the loading process.
	 */
	load( url, onLoad, onProgress, onError ) {

		final loader = new FileLoader( this.manager );
		loader.setPath( this.path );
		loader.setRequestHeader( this.requestHeader );
		loader.setWithCredentials( this.withCredentials );
		loader.load( url, ( text ) => {

			try {

				onLoad( this.parse( JSON.parse( text ) ) );

			} catch ( e ) {

				if ( onError ) {

					onError( e );

				} else {

					error( e );

				}

				this.manager.itemError( url );

			}

		}, onProgress, onError );

	}

	/**
	 * Parse the node dependencies for the loaded node.
	 *
	 * @param {Array<Object>} [json] - The JSON definition
	 * @return {Object<string,Node>} A dictionary with node dependencies.
	 */
	Map<String,dynamic> parseNodes(Map<String,dynamic>? json ) {
		final nodes = <String, Node>{};

		if ( json != null ) {
			for ( final nodeJSON in json ) {
				final uuid = nodeJSON['uuid'] as String;
				final type = nodeJSON['type'] as String;

				nodes[ uuid ] = createNodeFromType( type );
				nodes[ uuid ].uuid = uuid;
			}

			final meta = { 'nodes': nodes, 'textures': textures };

			for ( final nodeJSON in json ) {
				nodeJSON['meta'] = meta;

				final node = nodes[ nodeJSON['uuid'] as String ]!;
				node.deserialize( nodeJSON );

				nodeJSON.remove('meta');
			}
		}

		return nodes;
	}

	/**
	 * Parses the node from the given JSON.
	 *
	 * @param {Object} json - The JSON definition
	 * @param {string} json.type - The node type.
	 * @param {string} json.uuid - The node UUID.
	 * @param {Array<Object>} [json.nodes] - The node dependencies.
	 * @param {Object} [json.meta] - The meta data.
	 * @return {Node} The parsed node.
	 */
	Node parse(Map<String,dynamic> json ) {
		final node = createNodeFromType( json['type'] as String );
		node.uuid = json['uuid'] as String;

		final nodes = parseNodes( json['nodes'] as List<Map<String,dynamic>>? );
		final meta = { 'nodes': nodes, 'textures': textures };

		json['meta'] = meta;

		node.deserialize( json );

		json.remove('meta');

		return node;
	}

	/**
	 * Defines the dictionary of textures.
	 *
	 * @param {Object<string,Texture>} value - The texture library defines as `<uuid,texture>`.
	 * @return {NodeLoader} A reference to this loader.
	 */
	NodeLoader setTextures( Map<String, Texture> value ) {
		textures = value;
		return this;
	}

	NodeLoader setNodes(Map<String, dynamic> value ) {
		nodes = value;
		return this;
	}

	/**
	 * Creates a node object from the given type.
	 *
	 * @param {string} type - The node type.
	 * @return {Node} The created node instance.
	 */
	Node createNodeFromType(String type ) {
		if ( this.nodes[ type ] == null ) {
			console.error( 'NodeLoader: Node type not found: $type' );
			return float();
		}

		return this.nodes[ type ]();
	}
}