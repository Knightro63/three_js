import 'package:three_js_core/three_js_core.dart';
import '../code/node_builder.dart';
import 'node.dart';

/**
 * Base class for representing data input nodes.
 *
 * @augments Node
 */
class InputNode extends Node {
  dynamic value;
  Precision? precision;

	String get type{
		return 'InputNode';
	}

	InputNode(this.value, [super.nodeType]);

	String? generateNodeType( /*builder*/ ) {
		if ( this.nodeType == null ) {
			return getValueType( this.value );
		}

		return this.nodeType;
	}

	/**
	 * Returns the input type of the node which is by default the node type. Derived modules
	 * might overwrite this method and use a fixed type or compute one analytically.
	 *
	 * A typical example for different input and node types are textures. The input type of a
	 * normal RGBA texture is `texture` whereas its node type is `vec4`.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {string} The input type.
	 */
	String? getInputType(NodeBuilder builder ) {
		return this.getNodeType( builder );
	}

	/**
	 * Sets the precision to the given value. The method can be
	 * overwritten in derived classes if the final precision must be computed
	 * analytically.
	 *
	 * @param {('low'|'medium'|'high')} precision - The precision of the input value in the shader.
	 * @return {InputNode} A reference to this node.
	 */
	InputNode setPrecision(Precision precision ) {
		this.precision = precision;
		return this;
	}

	void serialize( data ) {

		super.serialize( data );

		data.value = this.value;

		if ( this.value && this.value.toArray ) data.value = this.value.toArray();

		data.valueType = getValueType( this.value );
		data.nodeType = this.nodeType;

		if ( data.valueType == 'ArrayBuffer' ) data.value = arrayBufferToBase64( data.value );

		data.precision = this.precision;

	}

	void deserialize( data ) {
		super.deserialize( data );

		this.nodeType = data.nodeType;
		this.value = Array.isArray( data.value ) ? getValueFromType( data.valueType, ...data.value ) : data.value;

		this.precision = data.precision || null;

		if ( this.value && this.value.fromArray ) this.value = this.value.fromArray( data.value );
	}

	void generate( /*builder, output*/ ) {
		console.warning( 'Abstract function.' );
	}
}
