import 'package:three_js_core/three_js_core.dart';
import 'function_node.dart';
import 'node_builder.dart';
import '../core/node.dart';
import '../core/temp_node.dart';
import '../tsl/tsl_core.dart';

/// This module represents the call of a {@link FunctionNode}. Developers are usually not confronted
/// with this module since they use the predefined TSL syntax `wgslFn` and `glslFn` which encapsulate
/// this logic.
class FunctionCallNode extends TempNode {
  FunctionNode? functionNode;
  late Map<String, Node> parameters;

	/// finalructs a new function call node.
	FunctionCallNode([ this.functionNode, Map<String, Node>? parameters]):super(){
    this.parameters = parameters ?? {};
  }

	/// Sets the parameters of the function call node.
	FunctionCallNode setParameters(Map<String,Node> parameters ) {
		this.parameters = parameters;
		return this;
	}

	/// Returns the parameters of the function call node.
	Map<String,Node> getParameters() {
		return parameters;
	}

  @override
	String? getNodeType(NodeBuilder builder, [String? output] ) {
		return functionNode?.getNodeType( builder );
	}

  @override
	String? generate( builder , [String? output]) {

		final params = [];

		final functionNode = this.functionNode;

		final inputs = functionNode?.getInputs( builder ) ?? [];
		final parameters = this.parameters;

		String? generateInput( node, inputNode ){
			final type = inputNode.type;
			final pointer = type == 'pointer';

			String? output;

			if ( pointer ){
        output = '&${node.build( builder )}' ;
      }
			else{
        output = node.build( builder, type );
      }

			return output;
		}

		if ( parameters is List ) {
			if ( parameters.length > inputs.length ) {
				console.error( 'THREE.TSL: The number of provided parameters exceeds the expected number of inputs in \'Fn()\'.' );
				parameters.length = inputs.length;
			} 
      else if ( parameters.length < inputs.length ) {
				console.error( 'THREE.TSL: The number of provided parameters is less than the expected number of inputs in \'Fn()\'.' );

				while ( parameters.length < inputs.length ) {
					parameters.add( float( 0 ) );
				}
			}

			for (int i = 0; i < parameters.length; i ++ ) {
				params.add( generateInput( parameters[ i ], inputs[ i ] ) );
			}
		} 
    else {
			for ( final inputNode in inputs ) {
				final node = parameters[ inputNode.name ];

				if ( node != null ) {
					params.add( generateInput( node, inputNode ) );
				}
        else {
					console.error( "THREE.TSL: Input '${ inputNode.name }' not found in \'Fn()\'." );
					params.add( generateInput( float( 0 ), inputNode ) );
				}
			}
		}

		final functionName = functionNode?.build( builder, 'property' );
		return '$functionName( ${ params.join( ', ' ) } )';
	}
}

// call( func, ...params ){
// 	params = params.length > 1 || ( params[ 0 ] && params[ 0 ] is Node) ? nodeArray( params ) : nodeObjects( params[ 0 ] );
// 	return nodeObject(FunctionCallNode( nodeObject( func ), params ) );
// }

// addMethodChaining( 'call', call );
