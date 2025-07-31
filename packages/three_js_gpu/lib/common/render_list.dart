
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/clipping_context.dart';
import 'package:three_js_gpu/common/lighting.dart';
import 'package:three_js_math/three_js_math.dart';

/**
 * Default sorting for opaque render items.
 *
 * @private
 * @function
 * @param {Object} a - The first render item.
 * @param {Object} b - The second render item.
 * @return {number} A numeric value which defines the sort order.
 */
int painterSortStable( a, b ) {
	if ( a.groupOrder != b.groupOrder ) {
		return a.groupOrder - b.groupOrder;
	} else if ( a.renderOrder != b.renderOrder ) {
		return a.renderOrder - b.renderOrder;
	} else if ( a.z != b.z ) {
		return a.z - b.z;
	} else {
		return a.id - b.id;
	}
}

/**
 * Default sorting for transparent render items.
 *
 * @private
 * @function
 * @param {Object} a - The first render item.
 * @param {Object} b - The second render item.
 * @return {number} A numeric value which defines the sort order.
 */
int reversePainterSortStable( a, b ) {
	if ( a.groupOrder != b.groupOrder ) {
		return a.groupOrder - b.groupOrder;
	} else if ( a.renderOrder != b.renderOrder ) {
		return a.renderOrder - b.renderOrder;
	} else if ( a.z != b.z ) {
		return b.z - a.z;
	} else {
		return a.id - b.id;
	}
}

/**
 * Returns `true` if the given transparent material requires a double pass.
 *
 * @private
 * @function
 * @param {Material} material - The transparent material.
 * @return {boolean} Whether the given material requires a double pass or not.
 */
needsDoublePass(Material material ) {
	final hasTransmission = material.transmission > 0 || material.transmissionNode;
	return hasTransmission && material.side == DoubleSide && material.forceSinglePass == false;

}

/**
 * When the renderer analyzes the scene at the beginning of a render call,
 * it stores 3D object for further processing in render lists. Depending on the
 * properties of a 3D objects (like their transformation or material state), the
 * objects are maintained in ordered lists for the actual rendering.
 *
 * Render lists are unique per scene and camera combination.
 *
 * @private
 * @augments Pipeline
 */
class RenderList {
  Lighting lighting;
  Scene scene;
  Camera camera;
  int occlusionQueryCount = 0;
  int renderItemsIndex = 0;
  List renderItems = [];
  List opaque = [];
  List transparentDoublePass = [];
  List transparent = [];
  List bundles = [];
  List<Light> lightsArray = [];
  LightsNode lightsNode;

	RenderList(this.lighting, this.scene, this.camera ) {
		this.lightsNode = lighting.getNode( scene, camera );
	}

	/**
	 * This method is called right at the beginning of a render call
	 * before the scene is analyzed. It prepares the internal data
	 * structures for the upcoming render lists generation.
	 *
	 * @return {RenderList} A reference to this render list.
	 */
	RenderList begin() {
		this.renderItemsIndex = 0;

		this.opaque.length = 0;
		this.transparentDoublePass.length = 0;
		this.transparent.length = 0;
		this.bundles.length = 0;

		this.lightsArray.length = 0;

		this.occlusionQueryCount = 0;

		return this;
	}

	dynamic getNextRenderItem(Object3D object, BufferGeometry geometry, Material material, int groupOrder, int z, [int? group, ClippingContext? clippingContext ]) {
		dynamic renderItem = this.renderItems[ this.renderItemsIndex ];

		if ( renderItem == null ) {
			renderItem = {
				'id': object.id,
				'object': object,
				'geometry': geometry,
				'material': material,
				'groupOrder': groupOrder,
				'renderOrder': object.renderOrder,
				'z': z,
				'group': group,
				'clippingContext': clippingContext
			};

			this.renderItems[ this.renderItemsIndex ] = renderItem;
		}
    else {
			renderItem.id = object.id;
			renderItem.object = object;
			renderItem.geometry = geometry;
			renderItem.material = material;
			renderItem.groupOrder = groupOrder;
			renderItem.renderOrder = object.renderOrder;
			renderItem.z = z;
			renderItem.group = group;
			renderItem.clippingContext = clippingContext;
		}

		this.renderItemsIndex ++;

		return renderItem;
	}

	void push(Object3D object, BufferGeometry geometry, Material material, int groupOrder, int z, [int? group, ClippingContext? clippingContext ]) {
		final renderItem = this.getNextRenderItem( object, geometry, material, groupOrder, z, group, clippingContext );

		if ( object.occlusionTest == true ) this.occlusionQueryCount ++;
		if ( material.transparent == true || material.transmission > 0 ) {
			if ( needsDoublePass( material ) ) this.transparentDoublePass.add( renderItem );
			this.transparent.add( renderItem );
		} 
    else {
			this.opaque.add( renderItem );
		}
	}

	void unshift(Object3D object, BufferGeometry geometry, Material material, int groupOrder, int z, [int? group, ClippingContext? clippingContext] ) {
		final renderItem = this.getNextRenderItem( object, geometry, material, groupOrder, z, group, clippingContext );

		if ( material.transparent == true || material.transmission > 0 ) {
			if ( needsDoublePass( material ) ) this.transparentDoublePass.insert(0, renderItem );
			this.transparent.insert(0, renderItem );
		} 
    else {
			this.opaque.insert(0, renderItem );
		}
	}

	void pushBundle( group ) {
		this.bundles.add( group );
	}

	void pushLight(Light light ) {
		this.lightsArray.add( light );
	}

	/**
	 * Sorts the internal render lists.
	 *
	 * @param {?function(any, any): number} customOpaqueSort - A custom sort for opaque objects.
	 * @param {?function(any, any): number} customTransparentSort -  A custom sort for transparent objects.
	 */
	void sort( customOpaqueSort, customTransparentSort ) {
		if ( this.opaque.length > 1 ) this.opaque.sort( customOpaqueSort ?? painterSortStable );
		if ( this.transparentDoublePass.length > 1 ) this.transparentDoublePass.sort( customTransparentSort ?? reversePainterSortStable );
		if ( this.transparent.length > 1 ) this.transparent.sort( customTransparentSort ?? reversePainterSortStable );
	}

	/**
	 * This method performs finalizing tasks right after the render lists
	 * have been generated.
	 */
	void finish() {
		this.lightsNode.setLights( this.lightsArray );

		// Clear references from inactive renderItems in the list
		for (int i = this.renderItemsIndex, il = this.renderItems.length; i < il; i ++ ) {
			final renderItem = this.renderItems[ i ];

			if ( renderItem.id == null ) break;
			renderItem.id = null;
			renderItem.object = null;
			renderItem.geometry = null;
			renderItem.material = null;
			renderItem.groupOrder = null;
			renderItem.renderOrder = null;
			renderItem.z = null;
			renderItem.group = null;
			renderItem.clippingContext = null;
		}
	}
}
