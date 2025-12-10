import '../core/node.dart';
import '../tsl/tsl_base.dart';

/**
 * This class represents native code sections. It is the base
 * class for modules like {@link FunctionNode} which allows to implement
 * functions with native shader languages.
 *
 * @augments Node
 */
class CodeNode extends Node {
  String code;
  List<Node> includes;
  String language;
  bool global = true;
	/**
	 * finalructs a new code node.
	 *
	 * @param {string} [code=''] - The native code.
	 * @param {Array<Node>} [includes=[]] - An array of includes.
	 * @param {('js'|'wgsl'|'glsl')} [language=''] - The used language.
	 */
	CodeNode([ this.code = '', this.includes = [], this.language = '' ]):super( 'code' );

	/**
	 * Sets the includes of this code node.
	 *
	 * @param {Array<Node>} includes - The includes to set.
	 * @return {CodeNode} A reference to this node.
	 */
	CodeNode setIncludes(List<Node> includes ) {
		this.includes = includes;

		return this;
	}

	/**
	 * Returns the includes of this code node.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {Array<Node>} The includes.
	 */
	List<Node> getIncludes([NodeBuilder? builder]) {
		return this.includes;
	}

	generate(NodeBuilder builder ) {
		final includes = this.getIncludes( builder );

		for ( final include in includes ) {
			include.build( builder );
		}

		final nodeCode = builder.getCodeFromNode( this, this.getNodeType( builder ) );
		nodeCode.code = this.code;

		return nodeCode.code;
	}

	serialize( data ) {
		super.serialize( data );

		data.code = this.code;
		data.language = this.language;
	}

	deserialize( data ) {
		super.deserialize( data );

		this.code = data.code;
		this.language = data.language;
	}
}

/**
 * TSL function for creating a code node.
 *
 * @tsl
 * @function
 * @param {string} [code] - The native code.
 * @param {?Array<Node>} [includes=[]] - An array of includes.
 * @param {?('js'|'wgsl'|'glsl')} [language=''] - The used language.
 * @returns {CodeNode}
 */
export final code = /*@__PURE__*/ nodeProxy( CodeNode ).setParameterLength( 1, 3 );

/**
 * TSL function for creating a JS code node.
 *
 * @tsl
 * @function
 * @param {string} src - The native code.
 * @param {Array<Node>} includes - An array of includes.
 * @returns {CodeNode}
 */
export final js = ( src, includes ) => code( src, includes, 'js' );

/**
 * TSL function for creating a WGSL code node.
 *
 * @tsl
 * @function
 * @param {string} src - The native code.
 * @param {Array<Node>} includes - An array of includes.
 * @returns {CodeNode}
 */
export final wgsl = ( src, includes ) => code( src, includes, 'wgsl' );

/**
 * TSL function for creating a GLSL code node.
 *
 * @tsl
 * @function
 * @param {string} src - The native code.
 * @param {Array<Node>} includes - An array of includes.
 * @returns {CodeNode}
 */
export final glsl = ( src, includes ) => code( src, includes, 'glsl' );
