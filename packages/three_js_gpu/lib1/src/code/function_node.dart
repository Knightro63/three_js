import 'package:three_js_gpu/src/code/node_builder.dart';
import 'package:three_js_gpu/src/code/node_function.dart';
import 'package:three_js_gpu/src/code/node_function_input.dart';
import 'package:three_js_gpu/src/core/node.dart';

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

	FunctionNode([super.code = '', super.includes, super.language = '' ]);

  @override
	String? getNodeType(NodeBuilder builder, [String? output ]) {
		return getNodeFunction( builder ).type;
	}

	List<NodeFunctionInput> getInputs(NodeBuilder builder ) {
		return getNodeFunction( builder ).inputs;
	}

	NodeFunction getNodeFunction(NodeBuilder builder ) {
		final nodeData = builder.getDataFromNode( this );

		var nodeFunction = nodeData.nodeFunction;

		if ( nodeFunction == null ) {
			nodeFunction = builder.parser.parseFunction( code );
			nodeData.nodeFunction = nodeFunction;
		}

		return nodeFunction;
	}

  @override
	String? generate(NodeBuilder builder, [String? output ]) {
		super.generate( builder );

		final nodeFunction = getNodeFunction( builder );

		final name = nodeFunction.name;
		final type = nodeFunction.type;

		final nodeCode = builder.getCodeFromNode( this, type );

		if ( name != '' ) {
			// use a custom property name
			nodeCode.name = name;
		}

		final propertyName = builder.getPropertyName( nodeCode );
		final code = getNodeFunction( builder ).getCode( propertyName );

		nodeCode.code = code + '\n';

		if ( output == 'property' ) {
			return propertyName;
		} 
    else {
			return builder.format( '$propertyName()', type, output );
		}
	}
}

nativeFn( code, [List<Node>? includes, language = '' ]){
  includes ??= [];

	for ( int i = 0; i < includes.length; i ++ ) {
		final include = includes[ i ];

		// TSL Function: glslFn, wgslFn

		if ( include is Function ) {
			includes[ i ] = include.functionNode;
		}
	}

	final functionNode = nodeObject(FunctionNode( code, includes, language ) );

	final fn = ( ...params ) => functionNode.call( ...params );
	fn.functionNode = functionNode;

	return fn;
}

glslFn( code, includes ) => nativeFn( code, includes, 'glsl' );
wgslFn( code, includes ) => nativeFn( code, includes, 'wgsl' );
