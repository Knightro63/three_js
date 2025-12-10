import './code_node.dart';
import '../tsl/tsl_base.dart';

/**
 * This class represents a native shader function. It can be used to implement
 * certain aspects of a node material with native shader code. There are two predefined
 * TSL functions for easier usage.
 *
 * - `wgslFn`: Creates a WGSL function node.
 * - `glslFn`: Creates a GLSL function node.
 *
 * A basic example with one include looks like so:
 *
 * ```js
 * final desaturateWGSLFn = wgslFn( `
 *	fn desaturate( color:vec3<f32> ) -> vec3<f32> {
 *		let lum = vec3<f32>( 0.299, 0.587, 0.114 );
 *		return vec3<f32>( dot( lum, color ) );
 *	}`
 *);
 * final someWGSLFn = wgslFn( `
 *	fn someFn( color:vec3<f32> ) -> vec3<f32> {
 * 		return desaturate( color );
 * 	}
 * `, [ desaturateWGSLFn ] );
 * material.colorNode = someWGSLFn( { color: texture( map ) } );
 *```
 * @augments CodeNode
 */
class FunctionNode extends CodeNode {
  String code;
  List<Node> includes;
  String language;
	/**
	 * finalructs a new function node.
	 *
	 * @param {string} [code=''] - The native code.
	 * @param {Array<Node>} [includes=[]] - An array of includes.
	 * @param {('js'|'wgsl'|'glsl')} [language=''] - The used language.
	 */
	FunctionNode([this.code = '', List<Node>? includes, this.language = '' ]):super( code, includes, language ){
    this.includes = includes ?? [];
  }

	NodeFunction getNodeType(NodeBuilder builder ) {
		return this.getNodeFunction( builder ).type;
	}

	/**
	 * Returns the inputs of this function node.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {Array<NodeFunctionInput>} The inputs.
	 */
	List<NodeFunctionInput> getInputs(NodeBuilder builder ) {
		return this.getNodeFunction( builder ).inputs;
	}

	/**
	 * Returns the node function for this function node.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {NodeFunction} The node function.
	 */
	NodeFunction getNodeFunction(NodeBuilder builder ) {
		final nodeData = builder.getDataFromNode( this );

		let nodeFunction = nodeData.nodeFunction;

		if ( nodeFunction == null ) {
			nodeFunction = builder.parser.parseFunction( this.code );
			nodeData.nodeFunction = nodeFunction;
		}

		return nodeFunction;
	}

	generate(NodeBuilder builder, String output ) {
		super.generate( builder );

		final nodeFunction = this.getNodeFunction( builder );

		final name = nodeFunction.name;
		final type = nodeFunction.type;

		final nodeCode = builder.getCodeFromNode( this, type );

		if ( name != '' ) {
			// use a custom property name
			nodeCode.name = name;
		}

		final propertyName = builder.getPropertyName( nodeCode );
		final code = this.getNodeFunction( builder ).getCode( propertyName );

		nodeCode.code = code + '\n';

		if ( output == 'property' ) {
			return propertyName;
		} 
    else {
			return builder.format( `${ propertyName }()`, type, output );
		}
	}
}

final nativeFn = ( code, includes = [], language = '' ) => {

	for ( let i = 0; i < includes.length; i ++ ) {

		final include = includes[ i ];

		// TSL Function: glslFn, wgslFn

		if ( typeof include === 'function' ) {

			includes[ i ] = include.functionNode;

		}

	}

	final functionNode = nodeObject( new FunctionNode( code, includes, language ) );

	final fn = ( ...params ) => functionNode.call( ...params );
	fn.functionNode = functionNode;

	return fn;

};

export final glslFn = ( code, includes ) => nativeFn( code, includes, 'glsl' );
export final wgslFn = ( code, includes ) => nativeFn( code, includes, 'wgsl' );
