import 'package:three_js_core/three_js_core.dart';

/**
 * The purpose of a node library is to assign node implementations
 * to existing library features. In `WebGPURenderer` lights, materials
 * which are not based on `NodeMaterial` as well as tone mapping techniques
 * are implemented with node-based modules.
 *
 * @private
 */
class NodeLibrary {
  WeakMap lightNodes = new WeakMap();
  Map<String,Type> materialNodes = new Map();
  Map<int,Function> toneMappingNodes = new Map();

	NodeLibrary();

	/**
	 * Returns a matching node material instance for the given material object.
	 *
	 * This method also assigns/copies the properties of the given material object
	 * to the node material. This is done to make sure the current material
	 * configuration carries over to the node version.
	 *
	 * @param {Material} material - A material.
	 * @return {NodeMaterial} The corresponding node material.
	 */
	NodeMaterial fromMaterial(Material material ) {
		if ( material is NodeMaterial ) return material;

		dynamic nodeMaterial;
		final nodeMaterialClass = this.getMaterialNodeClass( material.type );
		
    if ( nodeMaterialClass != null ) {
			nodeMaterial = nodeMaterialClass();

			for ( final key in material ) {
				nodeMaterial[ key ] = material[ key ];
			}
		}

		return nodeMaterial;
	}

	/**
	 * Adds a tone mapping node function for a tone mapping technique (constant).
	 *
	 * @param {Function} toneMappingNode - The tone mapping node function.
	 * @param {number} toneMapping - The tone mapping.
	 */
	void addToneMapping(Function toneMappingNode, int toneMapping ) {
		this.addType( toneMappingNode, toneMapping, this.toneMappingNodes );
	}

	Function? getToneMappingFunction(int toneMapping ) {
		return this.toneMappingNodes[toneMapping];
	}

	/**
	 * Returns a node material class definition for a material type.
	 *
	 * @param {string} materialType - The material type.
	 * @return {?NodeMaterial.constructor} The node material class definition. Returns `null` if no node material is found.
	 */
	Type? getMaterialNodeClass(String materialType ) {
		return this.materialNodes[materialType];
	}

	/**
	 * Adds a node material class definition for a given material type.
	 *
	 * @param {NodeMaterial.constructor} materialNodeClass - The node material class definition.
	 * @param {string} materialClassType - The material type.
	 */
	void addMaterial(Type materialNodeClass,String materialClassType ) {
		this.addType( materialNodeClass, materialClassType, this.materialNodes );
	}

	/**
	 * Returns a light node class definition for a light class definition.
	 *
	 * @param {Light.constructor} light - The light class definition.
	 * @return {?AnalyticLightNode.constructor} The light node class definition. Returns `null` if no light node is found.
	 */
	Type? getLightNodeClass(Type light ) {
		return this.lightNodes[light];
	}

	/**
	 * Adds a light node class definition for a given light class definition.
	 *
	 * @param {AnalyticLightNode.constructor} lightNodeClass - The light node class definition.
	 * @param {Light.constructor} lightClass - The light class definition.
	 */
	void addLight(Type lightNodeClass, Type lightClass ) {
		this.addClass( lightNodeClass, lightClass, this.lightNodes );
	}

	/**
	 * Adds a node class definition for the given type to the provided type library.
	 *
	 * @param {any} nodeClass - The node class definition.
	 * @param {number|string} type - The object type.
	 * @param {Map} library - The type library.
	 */
	void addType(dynamic nodeClass, type, Map library ) {
		if ( library.containsKey( type ) ) {
			console.warning( 'Redefinition of node ${ type }' );
			return;
		}

		if (nodeClass is! Function ) throw( 'Node class ${ nodeClass.name } is not a class.' );
		if (type is Function || typeof type == 'object' ) throw( 'Base class ${ type } is not a class.' );

		library.set( type, nodeClass );
	}

	/**
	 * Adds a node class definition for the given class definition to the provided type library.
	 *
	 * @param {any} nodeClass - The node class definition.
	 * @param {any} baseClass - The class definition.
	 * @param {WeakMap} library - The type library.
	 */
	void addClass( nodeClass, baseClass, WeakMap library ) {
		if ( library.has( baseClass ) ) {
			console.warning( 'Redefinition of node ${ baseClass.name }' );
			return;
		}

		if (nodeClass is! Function ) throw( 'Node class ${ nodeClass.name } is not a class.' );
		if (baseClass is! Function ) throw ( 'Base class ${ baseClass.name } is not a class.' );

		library.set( baseClass, nodeClass );
	}
}


