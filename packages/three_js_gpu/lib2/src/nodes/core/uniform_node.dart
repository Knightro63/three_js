import 'input_node.dart';
import 'uniform_group_node.dart';

/**
 * Class for representing a uniform.
 *
 * @augments InputNode
 */
class UniformNode extends InputNode {
  UniformGroupNode groupNode = objectGroup;
  String name = '';

	String get type{
		return 'UniformNode';
	}

	UniformNode(super.value, [super.nodeType ]);

	/**
	 * Sets the {@link UniformNode#name} property.
	 *
	 * @param {string} name - The name of the uniform.
	 * @return {UniformNode} A reference to this node.
	 */
	setName( name ) {

		this.name = name;

		return this;

	}

	/**
	 * Sets the {@link UniformNode#name} property.
	 *
	 * @deprecated
	 * @param {string} name - The name of the uniform.
	 * @return {UniformNode} A reference to this node.
	 */
	label( name ) {

		warn( 'TSL: "label()" has been deprecated. Use "setName()" instead.', new StackTrace() ); // @deprecated r179

		return this.setName( name );

	}

	/**
	 * Sets the {@link UniformNode#groupNode} property.
	 *
	 * @param {UniformGroupNode} group - The uniform group.
	 * @return {UniformNode} A reference to this node.
	 */
	setGroup( group ) {

		this.groupNode = group;

		return this;

	}

	/**
	 * Returns the {@link UniformNode#groupNode}.
	 *
	 * @return {UniformGroupNode} The uniform group.
	 */
	getGroup() {

		return this.groupNode;

	}

	/**
	 * By default, this method returns the result of {@link Node#getHash} but derived
	 * classes might overwrite this method with a different implementation.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {string} The uniform hash.
	 */
	getUniformHash( builder ) {

		return this.getHash( builder );

	}

	onUpdate( callback, updateType ) {

		callback = callback.bind( this );

		return super.onUpdate( ( frame ) => {

			const value = callback( frame, this );

			if ( value !== undefined ) {

				this.value = value;

			}

	 	}, updateType );

	}

	getInputType( builder ) {

		let type = super.getInputType( builder );

		if ( type === 'bool' ) {

			type = 'uint';

		}

		return type;

	}

	generate( builder, output ) {

		const type = this.getNodeType( builder );

		const hash = this.getUniformHash( builder );

		let sharedNode = builder.getNodeFromHash( hash );

		if ( sharedNode === undefined ) {

			builder.setHashNode( this, hash );

			sharedNode = this;

		}

		const sharedNodeType = sharedNode.getInputType( builder );

		const nodeUniform = builder.getUniformFromNode( sharedNode, sharedNodeType, builder.shaderStage, this.name || builder.context.nodeName );
		const uniformName = builder.getPropertyName( nodeUniform );

		if ( builder.context.nodeName !== undefined ) delete builder.context.nodeName;

		//

		let snippet = uniformName;

		if ( type === 'bool' ) {

			// cache to variable

			const nodeData = builder.getDataFromNode( this );

			let propertyName = nodeData.propertyName;

			if ( propertyName === undefined ) {

				const nodeVar = builder.getVarFromNode( this, null, 'bool' );
				propertyName = builder.getPropertyName( nodeVar );

				nodeData.propertyName = propertyName;

				snippet = builder.format( uniformName, sharedNodeType, type );

				builder.addLineFlowCode( `${ propertyName } = ${ snippet }`, this );

			}

			snippet = propertyName;

		}

		return builder.format( snippet, type, output );

	}

}

/**
 * TSL function for creating a uniform node.
 *
 * @tsl
 * @function
 * @param {any|string} value - The value of this uniform or your type. Usually a JS primitive or three.js object (vector, matrix, color, texture).
 * @param {string} [type] - The node type. If no explicit type is defined, the node tries to derive the type from its value.
 * @returns {UniformNode}
 */
 uniform( value, type ) => {

	const nodeType = getConstNodeType( type || value );

	if ( nodeType === value ) {

		// if the value is a type but no having a value

		value = getValueFromType( nodeType );

	}

	if ( value && value.isNode === true ) {

		let v = value.value;

		value.traverse( n => {

			if ( n.isConstNode === true ) {

				v = n.value;

			}

		} );

		value = v;

	}

	return new UniformNode( value, nodeType );

};
