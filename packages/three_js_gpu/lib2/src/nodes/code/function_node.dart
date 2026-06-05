import 'node_builder.dart';
import 'node_function.dart';
import 'node_function_input.dart';
import '../core/node.dart';

import './code_node.dart';
import '../tsl/tsl_base.dart';

class NativeFunctionCallable {
  final FunctionNode functionNode;

  NativeFunctionCallable(this.functionNode);

  /// Allows the instance to be called directly like a function: fn(params)
  dynamic call([List<dynamic> params = const []]) {
    return functionNode.call(params);
  }
}

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

NativeFunctionCallable nativeFn(
  String code, [
  List<dynamic>? includes, 
  String language = '',
]) {
  // Use a modifiable list if provided, otherwise create a new empty list
  final List<Node> processedIncludes = includes != null ? List<Node>.from(includes) : [];

  for (int i = 0; i < processedIncludes.length; i++) {
    final include = processedIncludes[i];
    
    // Check if the item is a dynamic callable object or function variant
    if (include is NativeFunctionCallable) {
      processedIncludes[i] = include.functionNode;
    } else if (include is Function) {
      // Handle fallback if raw Dart closures are passed down
      try {
        processedIncludes[i] = (include as dynamic).functionNode;
      } catch (_) {
        // Handle gracefully if the closure doesn't have the property
      }
    }
  }

  final functionNode = nodeObject(FunctionNode(code, processedIncludes, language));
  return NativeFunctionCallable(functionNode);
}

glslFn( code, includes ) => nativeFn( code, includes, 'glsl' );
wgslFn( code, includes ) => nativeFn( code, includes, 'wgsl' );
