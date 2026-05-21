import 'package:three_js_gpu/src/code/node_builder.dart';
import '../core/node.dart';
import '../tsl/tsl_base.dart';

/// This class represents native code sections. It is the base
/// class for modules like {@link FunctionNode} which allows to implement
/// functions with native shader languages.
class CodeNode extends Node {
  String code;
  late List<Node> includes;
  String language;

	CodeNode([ this.code = '', List<Node>? includes, this.language = '' ]):super( 'code' ){
    this.includes = includes ?? [];
    global = true;
  }

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

	/// Returns the includes of this code node.
	List<Node> getIncludes([NodeBuilder? builder]) {
		return includes;
	}

  @override
	String? generate(NodeBuilder builder, [String? output] ) {
		final includes = getIncludes( builder );

		for ( final include in includes ) {
			include.build( builder );
		}

		final nodeCode = builder.getCodeFromNode( this, getNodeType( builder ) );
		nodeCode.code = code;

		return nodeCode.code;
	}

  @override
	serialize( data ) {
		super.serialize( data );
		data.code = code;
		data.language = language;
	}

  @override
	deserialize( data ) {
		super.deserialize( data );
		code = data.code;
		language = data.language;
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
final code = /*@__PURE__*/ nodeProxy( CodeNode ).setParameterLength( 1, 3 );

/**
 * TSL function for creating a JS code node.
 *
 * @tsl
 * @function
 * @param {string} src - The native code.
 * @param {Array<Node>} includes - An array of includes.
 * @returns {CodeNode}
 */
final js = ( src, includes ) => code( src, includes, 'js' );

/**
 * TSL function for creating a WGSL code node.
 *
 * @tsl
 * @function
 * @param {string} src - The native code.
 * @param {Array<Node>} includes - An array of includes.
 * @returns {CodeNode}
 */
final wgsl = ( src, includes ) => code( src, includes, 'wgsl' );

/**
 * TSL function for creating a GLSL code node.
 *
 * @tsl
 * @function
 * @param {string} src - The native code.
 * @param {Array<Node>} includes - An array of includes.
 * @returns {CodeNode}
 */
final glsl = ( src, includes ) => code( src, includes, 'glsl' );
