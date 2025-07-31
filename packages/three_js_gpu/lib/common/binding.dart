
/**
 * A binding represents the connection between a resource (like a texture, sampler
 * or uniform buffer) and the resource definition in a shader stage.
 *
 * This module is an abstract base class for all concrete bindings types.
 *
 * @abstract
 * @private
 */
class Binding {
  String name;
  int visibility = 0;

	Binding([ this.name = '' ]);

	void setVisibility(int visibility ) {
		this.visibility |= visibility;
	}

	Binding clone() {
    throw("Not implimented.");
		//return Object.assign( new this.constructor(), this );
	}
}
