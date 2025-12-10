import '../core/temp_node.dart';
import '../tsl/tsl_core.dart';

/**
 * This module represents the call of a {@link FunctionNode}. Developers are usually not confronted
 * with this module since they use the predefined TSL syntax `wgslFn` and `glslFn` which encapsulate
 * this logic.
 *
 * @augments TempNode
 */
class FunctionCallNode extends TempNode {
  FunctionNode? functionNode;
  late Map<String, Node> parameters;

	/**
	 * finalructs a new function call node.
	 *
	 * @param {?FunctionNode} functionNode - The function node.
	 * @param {Object<string, Node>} [parameters={}] - The parameters for the function call.
	 */
	FunctionCallNode([ this.functionNode, Map<String, Node>? parameters]):super(){
    this.parameters = parameters ?? {};
  }

	/**
	 * Sets the parameters of the function call node.
	 *
	 * @param {Object<string, Node>} parameters - The parameters to set.
	 * @return {FunctionCallNode} A reference to this node.
	 */
	FunctionCallNode setParameters( parameters ) {
		this.parameters = parameters;
		return this;
	}

	/**
	 * Returns the parameters of the function call node.
	 *
	 * @return {Object<string, Node>} The parameters of this node.
	 */
	getParameters() {
		return this.parameters;
	}

	getNodeType(NodeBuilder builder ) {
		return this.functionNode.getNodeType( builder );
	}

	generate( builder ) {

		final params = [];

		final functionNode = this.functionNode;

		final inputs = functionNode.getInputs( builder );
		final parameters = this.parameters;

		final generateInput = ( node, inputNode ) => {

			final type = inputNode.type;
			final pointer = type === 'pointer';

			let output;

			if ( pointer ) output = '&' + node.build( builder );
			else output = node.build( builder, type );

			return output;

		};

		if ( Array.isArray( parameters ) ) {

			if ( parameters.length > inputs.length ) {

				console.error( 'THREE.TSL: The number of provided parameters exceeds the expected number of inputs in \'Fn()\'.' );

				parameters.length = inputs.length;

			} else if ( parameters.length < inputs.length ) {

				console.error( 'THREE.TSL: The number of provided parameters is less than the expected number of inputs in \'Fn()\'.' );

				while ( parameters.length < inputs.length ) {

					parameters.push( float( 0 ) );

				}

			}

			for ( let i = 0; i < parameters.length; i ++ ) {

				params.push( generateInput( parameters[ i ], inputs[ i ] ) );

			}

		} else {

			for ( final inputNode of inputs ) {

				final node = parameters[ inputNode.name ];

				if ( node !== undefined ) {

					params.push( generateInput( node, inputNode ) );

				} else {

					console.error( `THREE.TSL: Input '${ inputNode.name }' not found in \'Fn()\'.` );

					params.push( generateInput( float( 0 ), inputNode ) );

				}

			}

		}

		final functionName = functionNode.build( builder, 'property' );

		return `${ functionName }( ${ params.join( ', ' ) } )`;

	}

}

export final call = ( func, ...params ) => {

	params = params.length > 1 || ( params[ 0 ] && params[ 0 ].isNode === true ) ? nodeArray( params ) : nodeObjects( params[ 0 ] );

	return nodeObject( new FunctionCallNode( nodeObject( func ), params ) );

};

addMethodChaining( 'call', call );
