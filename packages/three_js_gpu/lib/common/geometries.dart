import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/attributes.dart';
import 'package:three_js_gpu/common/constants.dart';
import 'package:three_js_gpu/common/data_map.dart';
import 'package:three_js_gpu/common/info.dart';
import 'package:three_js_gpu/common/render_object.dart';
import 'package:three_js_math/three_js_math.dart';

/**
 * Returns the wireframe version for the given geometry.
 *
 * @private
 * @function
 * @param {BufferGeometry} geometry - The geometry.
 * @return {number} The version.
 */
int getWireframeVersion(BufferGeometry geometry ) {
	return ( geometry.index != null ) ? geometry.index?.version : geometry.attributes['position']?.version;
}

/**
 * Returns a wireframe index attribute for the given geometry.
 *
 * @private
 * @function
 * @param {BufferGeometry} geometry - The geometry.
 * @return {BufferAttribute} The wireframe index attribute.
 */
BufferAttribute getWireframeIndex(BufferGeometry geometry ) {
	final List<int> indices = [];
	final geometryIndex = geometry.index;
	final geometryPosition = geometry.attributes['position'];

	if ( geometryIndex != null ) {

		final array = geometryIndex.array;

		for (int i = 0, l = array.length; i < l; i += 3 ) {
			final a = array[ i + 0 ].toInt();
			final b = array[ i + 1 ].toInt();
			final c = array[ i + 2 ].toInt();

			indices.addAll([ a, b, b, c, c, a ]);
		}
	} 
  else {
		final array = geometryPosition.array;

		for (int i = 0, l = ( array.length / 3 ) - 1; i < l; i += 3 ) {
			final a = i + 0;
			final b = i + 1;
			final c = i + 2;

			indices.addAll([ a, b, b, c, c, a ]);
		}
	}

	final attribute = arrayNeedsUint32( indices ) ? Uint32BufferAttribute.fromList( indices, 1 ) : Uint16BufferAttribute.fromList( indices, 1 );
	(attribute as BufferAttribute).version = getWireframeVersion( geometry );

	return attribute;
}

/**
 * This renderer module manages geometries.
 *
 * @private
 * @augments DataMap
 */
class Geometries extends DataMap {
  Attributes attributes;
  Info info;
  WeakMap wireframes = new WeakMap();
  WeakMap attributeCall = new WeakMap();

	/**
	 * Constructs a new geometry management component.
	 *
	 * @param {Attributes} attributes - Renderer component for managing attributes.
	 * @param {Info} info - Renderer component for managing metrics and monitoring data.
	 */
	Geometries(this.attributes, this.info ):super();

	/**
	 * Returns `true` if the given render object has an initialized geometry.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 * @return {boolean} Whether if the given render object has an initialized geometry or not.
	 */
	bool has(RenderObject renderObject ) {
		final geometry = renderObject.geometry;
		return super.has( geometry ) && this.get( geometry ).initialized == true;
	}

	/**
	 * Prepares the geometry of the given render object for rendering.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 */
	void updateForRender(RenderObject renderObject ) {
		if ( this.has( renderObject ) == false ) this.initGeometry( renderObject );
		this.updateAttributes( renderObject );
	}

	/**
	 * Initializes the geometry of the given render object.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 */
	initGeometry(RenderObject renderObject ) {

		final geometry = renderObject.geometry;
		final geometryData = this.get( geometry );

		geometryData.initialized = true;

		this.info.memory['geometries'] = this.info.memory['geometries']!+1;

		final onDispose = (){
			this.info.memory['geometries'] = this.info.memory['geometries']!-1;
			final index = geometry?.index;
			final geometryAttributes = renderObject.getAttributes();

			if ( index != null ) {
				this.attributes.delete( index );
			}

			for ( final geometryAttribute in geometryAttributes ) {
				this.attributes.delete( geometryAttribute );
			}

			final wireframeAttribute = this.wireframes.get( geometry );

			if ( wireframeAttribute != null ) {
				this.attributes.delete( wireframeAttribute );
			}

			geometry?.removeEventListener( 'dispose', onDispose );
		};

		geometry?.addEventListener( 'dispose', onDispose );
	}

	/**
	 * Updates the geometry attributes of the given render object.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 */
	updateAttributes(RenderObject renderObject ) {
		final attributes = renderObject.getAttributes();

		for ( final attribute in attributes ) {
			if ( attribute.isStorageBufferAttribute || attribute.isStorageInstancedBufferAttribute ) {
				this.updateAttribute( attribute, AttributeType.storage );
			} else {
				this.updateAttribute( attribute, AttributeType.vertex );
			}
		}

		// indexes

		final index = this.getIndex( renderObject );

		if ( index != null ) {
			this.updateAttribute( index, AttributeType.indx );
		}

		// indirect

		final indirect = renderObject.geometry?.indirect;

		if ( indirect != null ) {
			this.updateAttribute( indirect, AttributeType.indirect );
		}
	}

	/**
	 * Updates the given attribute.
	 *
	 * @param {BufferAttribute} attribute - The attribute to update.
	 * @param {number} type - The attribute type.
	 */
	void updateAttribute(BufferAttribute attribute, AttributeType type ) {
		final callId = this.info.render['calls'];

		if (attribute is! InterleavedBufferAttribute ) {
			if ( this.attributeCall.get( attribute ) != callId ) {
				this.attributes.update( attribute, type );
				this.attributeCall.set( attribute, callId );
			}
		} 
    else {
			if ( this.attributeCall.get( attribute ) == null ) {
				this.attributes.update( attribute, type );
				this.attributeCall.set( attribute, callId );
			} 
      else if ( this.attributeCall.get( attribute.data ) != callId ) {
				this.attributes.update( attribute, type );
				this.attributeCall.set( attribute.data, callId );
				this.attributeCall.set( attribute, callId );
			}
		}
	}

	/**
	 * Returns the indirect buffer attribute of the given render object.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 * @return {?BufferAttribute} The indirect attribute. `null` if no indirect drawing is used.
	 */
	getIndirect( renderObject ) {

		return renderObject.geometry.indirect;

	}

	/**
	 * Returns the index of the given render object's geometry. This is implemented
	 * in a method to return a wireframe index if necessary.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 * @return {?BufferAttribute} The index. Returns `null` for non-indexed geometries.
	 */
	BufferAttribute? getIndex(RenderObject renderObject ) {
		final geometry = renderObject.geometry;
    final material = renderObject.material;

		BufferAttribute? index = geometry?.index;

		if ( material.wireframe == true ) {
			final wireframes = this.wireframes;

			dynamic wireframeAttribute = wireframes.get( geometry );

			if ( wireframeAttribute == null && geometry != null) {
				wireframeAttribute = getWireframeIndex( geometry );
				wireframes.set( geometry, wireframeAttribute );
			} 
      else if (geometry != null && wireframeAttribute.version != getWireframeVersion( geometry ) ) {
				this.attributes.delete( wireframeAttribute );
				wireframeAttribute = getWireframeIndex( geometry );
				wireframes.set( geometry, wireframeAttribute );
			}

			index = wireframeAttribute;
		}

		return index;
	}
}
