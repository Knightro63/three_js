
import 'package:three_js_core/three_js_core.dart';
import 'clipping_context.dart';
import 'lighting.dart';
import 'package:three_js_math/three_js_math.dart';

/// Default sorting for opaque render items.
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

/// Default sorting for transparent render items.
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

/// Returns `true` if the given transparent material requires a double pass.
bool needsDoublePass(Material material ) {
	final hasTransmission = material.transmission > 0 || material.transmissionNode;
	return hasTransmission && material.side == DoubleSide && material.forceSinglePass == false;
}

/// When the renderer analyzes the scene at the beginning of a render call,
/// it stores 3D object for further processing in render lists. Depending on the
/// properties of a 3D objects (like their transformation or material state), the
/// objects are maintained in ordered lists for the actual rendering.
///
/// Render lists are unique per scene and camera combination.
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
		lightsNode = lighting.getNode( scene, camera );
	}

	/// This method is called right at the beginning of a render call
	/// before the scene is analyzed. It prepares the internal data
	/// structures for the upcoming render lists generation.
	RenderList begin() {
		renderItemsIndex = 0;

		opaque.length = 0;
		transparentDoublePass.length = 0;
		transparent.length = 0;
		bundles.length = 0;

		lightsArray.length = 0;
		occlusionQueryCount = 0;

		return this;
	}

	dynamic getNextRenderItem(Object3D object, BufferGeometry geometry, Material material, int groupOrder, int z, [int? group, ClippingContext? clippingContext ]) {
		dynamic renderItem = renderItems[ renderItemsIndex ];

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

			renderItems[ renderItemsIndex ] = renderItem;
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

		renderItemsIndex ++;

		return renderItem;
	}

	void push(Object3D object, BufferGeometry geometry, Material material, int groupOrder, int z, [int? group, ClippingContext? clippingContext ]) {
		final renderItem = getNextRenderItem( object, geometry, material, groupOrder, z, group, clippingContext );

		if ( object.occlusionTest == true ) occlusionQueryCount ++;
		if ( material.transparent == true || material.transmission > 0 ) {
			if ( needsDoublePass( material ) ) transparentDoublePass.add( renderItem );
			transparent.add( renderItem );
		} 
    else {
			opaque.add( renderItem );
		}
	}

	void unshift(Object3D object, BufferGeometry geometry, Material material, int groupOrder, int z, [int? group, ClippingContext? clippingContext] ) {
		final renderItem = getNextRenderItem( object, geometry, material, groupOrder, z, group, clippingContext );

		if ( material.transparent == true || material.transmission > 0 ) {
			if ( needsDoublePass( material ) ) transparentDoublePass.insert(0, renderItem );
			transparent.insert(0, renderItem );
		} 
    else {
			opaque.insert(0, renderItem );
		}
	}

	void pushBundle( group ) {
	  bundles.add( group );
	}

	void pushLight(Light light ) {
		lightsArray.add( light );
	}

	/// Sorts the internal render lists.
	void sort([int Function(dynamic,dynamic)? customOpaqueSort, int Function(dynamic,dynamic)? customTransparentSort] ) {
		if ( opaque.length > 1 ) opaque.sort( customOpaqueSort ?? painterSortStable );
		if ( transparentDoublePass.length > 1 ) transparentDoublePass.sort( customTransparentSort ?? reversePainterSortStable );
		if ( transparent.length > 1 ) transparent.sort( customTransparentSort ?? reversePainterSortStable );
	}

	/// This method performs finalizing tasks right after the render lists
	/// have been generated.
	void finish() {
		lightsNode.setLights( lightsArray );

		// Clear references from inactive renderItems in the list
		for (int i = renderItemsIndex, il = renderItems.length; i < il; i ++ ) {
			final renderItem = renderItems[ i ];

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
