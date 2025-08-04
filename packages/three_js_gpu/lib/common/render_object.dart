import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/bind_group.dart';
import 'package:three_js_gpu/common/bundle_group.dart';
import 'package:three_js_gpu/common/clipping_context.dart';
import 'package:three_js_gpu/common/geometries.dart';
import 'package:three_js_gpu/common/nodes/node_builder_state.dart';
import 'package:three_js_gpu/common/render_context.dart';
import 'package:three_js_gpu/common/render_pipeline.dart';
import 'package:three_js_math/three_js_math.dart';

int _id = 0;

List<String> getKeys(Map<String,dynamic> obj ) {
	final keys = obj.keys.toList();
	dynamic proto = Object.getPrototypeOf( obj );

	while ( proto ) {
		final descriptors = Object.getOwnPropertyDescriptors( proto );

		for ( final key in descriptors ) {
			if ( descriptors[ key ] != null ) {
				final descriptor = descriptors[ key ];
				if ( descriptor != null && descriptor is Function) {
					keys.add( key );
				}
			}
		}

		proto = Object.getPrototypeOf( proto );
	}

	return keys;
}

/**
 * A render object is the renderer's representation of single entity that gets drawn
 * with a draw command. There is no unique mapping of render objects to 3D objects in the
 * scene since render objects also depend from the used material, the current render context
 * and the current scene's lighting.
 *
 * In general, the basic process of the renderer is:
 *
 * - Analyze the 3D objects in the scene and generate render lists containing render items.
 * - Process the render lists by calling one or more render commands for each render item.
 * - For each render command, request a render object and perform the draw.
 *
 * The module provides an interface to get data required for the draw command like the actual
 * draw parameters or vertex buffers. It also holds a series of caching related methods since
 * creating render objects should only be done when necessary.
 *
 * @private
 */
class RenderObject {
  late int id;
  late final Nodes _nodes;
  late final Geometries _geometries;
  final Renderer renderer;
  final Object3D object;
  final Material material;
  final Scene scene;
  final Camera camera;
  final LightsNode lightsNode;
  late RenderContext context;
  BufferGeometry? geometry;
  late int version;
  Map<String,dynamic>? drawRange;
  Map<String,dynamic>? drawParams;
  List<BufferAttribute>? attributes;
  Map<String,int>? attributesId;
  RenderPipeline? pipeline;
  BundleGroup? bundle;
  ClippingContext? clippingContext;
  String clippingContextCacheKey = '';
  int initialNodesCacheKey = 0;
  int initialCacheKey = 0;
  NodeBuilderState? _nodeBuilderState;
  List<BindGroup>? _bindings;
  NodeMaterialObserver? _monitor;
  void Function()? onDispose;
  bool isRenderObject = true;
  late void Function() onMaterialDispose;
  late void Function() onGeometryDispose;
  List? vertexBuffers;
  Map<String,dynamic>? group;

	RenderObject(Nodes nodes,Geometries geometries, this.renderer, this.object, this.material, this.scene, this.camera, this.lightsNode,RenderContext renderContext,this.clippingContext ) {
		this.id = _id ++;
		this.context = renderContext;
		this.geometry = object.geometry;
		this.version = material.version;

		this.clippingContextCacheKey = clippingContext != null ? clippingContext!.cacheKey : '';
		this.initialNodesCacheKey = this.getDynamicCacheKey();
		this.initialCacheKey = this.getCacheKey();

		this.onMaterialDispose = (){
			this.dispose();
		};

		this.onGeometryDispose = (){
			// clear geometry cache attributes
			this.attributes = null;
			this.attributesId = null;
		};

		this.material.addEventListener( 'dispose', this.onMaterialDispose );
		this.geometry?.addEventListener( 'dispose', this.onGeometryDispose );
	}

	/**
	 * Updates the clipping context.
	 *
	 * @param {ClippingContext} context - The clipping context to set.
	 */
	updateClipping( context ) {
		this.clippingContext = context;
	}

	/**
	 * Whether the clipping requires an update or not.
	 *
	 * @type {boolean}
	 * @readonly
	 */
	get clippingNeedsUpdate => _clippingNeedsUpdate();
  bool _clippingNeedsUpdate(){
		if ( this.clippingContext == null || this.clippingContext?.cacheKey == this.clippingContextCacheKey ) return false;
		this.clippingContextCacheKey = this.clippingContext!.cacheKey;
		return true;
	}

	/**
	 * The number of clipping planes defined in context of hardware clipping.
	 *
	 * @type {number}
	 * @readonly
	 */
	int get hardwareClippingPlanes => material.hardwareClipping == true ? this.clippingContext?.unionClippingCount ?? 0 : 0;
	

	/**
	 * Returns the node builder state of this render object.
	 *
	 * @return {NodeBuilderState} The node builder state.
	 */
	NodeBuilderState getNodeBuilderState() {
		return this._nodeBuilderState ?? ( this._nodeBuilderState = this._nodes.getForRender( this ) );
	}

	/**
	 * Returns the node material observer of this render object.
	 *
	 * @return {NodeMaterialObserver} The node material observer.
	 */
	NodeMaterialObserver getMonitor() {
		return this._monitor ?? ( this._monitor = this.getNodeBuilderState().observer );
	}

	/**
	 * Returns an array of bind groups of this render object.
	 *
	 * @return {Array<BindGroup>} The bindings.
	 */
	List<BindGroup> getBindings() {
		return this._bindings ?? ( this._bindings = this.getNodeBuilderState().createBindings() );
	}

	/**
	 * Returns a binding group by group name of this render object.
	 *
	 * @param {string} name - The name of the binding group.
	 * @return {?BindGroup} The bindings.
	 */
	BindGroup? getBindingGroup(String name ) {
		for ( final bindingGroup in this.getBindings() ) {
			if ( bindingGroup.name == name ) {
				return bindingGroup;
			}
		}
	}

	/**
	 * Returns the index of the render object's geometry.
	 *
	 * @return {?BufferAttribute} The index. Returns `null` for non-indexed geometries.
	 */
	BufferAttribute? getIndex() {
		return this._geometries.getIndex( this );
	}

	/**
	 * Returns the indirect buffer attribute.
	 *
	 * @return {?BufferAttribute} The indirect attribute. `null` if no indirect drawing is used.
	 */
	BufferAttribute? getIndirect() {
		return this._geometries.getIndirect( this );
	}

	/**
	 * Returns an array that acts as a key for identifying the render object in a chain map.
	 *
	 * @return {Array<Object>} An array with object references.
	 */
	List<dynamic>getChainArray() {
		return [ this.object, this.material, this.context, this.lightsNode ];
	}

	/**
	 * This method is used when the geometry of a 3D object has been exchanged and the
	 * respective render object now requires an update.
	 *
	 * @param {BufferGeometry} geometry - The geometry to set.
	 */
	void setGeometry(BufferGeometry geometry ) {
		this.geometry = geometry;
		this.attributes = null;
		this.attributesId = null;
	}

	/**
	 * Returns the buffer attributes of the render object. The returned array holds
	 * attribute definitions on geometry and node level.
	 *
	 * @return {Array<BufferAttribute>} An array with buffer attributes.
	 */
	getAttributes() {
		if ( this.attributes != null ) return this.attributes;

		final nodeAttributes = this.getNodeBuilderState().nodeAttributes;
		final geometry = this.geometry;

		final List<BufferAttribute<NativeArray<num>>> attributes = [];
		final vertexBuffers = new Set();

		final attributesId = {};

		for ( final nodeAttribute in nodeAttributes ) {
			dynamic attribute;

			if ( nodeAttribute.node && nodeAttribute.node.attribute ) {
				// node attribute
				attribute = nodeAttribute.node.attribute;
			} 
      else {
				// geometry attribute
				attribute = geometry?.getAttribute( nodeAttribute.name );
				attributesId[ nodeAttribute.name ] = attribute.version;
			}

			if ( attribute == null ) continue;

			attributes.add( attribute );

			final bufferAttribute = attribute is InterleavedBufferAttribute ? attribute.data : attribute;
			vertexBuffers.add( bufferAttribute );
		}

		this.attributes = attributes;
		this.attributesId = attributesId;
		this.vertexBuffers = Array.from( vertexBuffers.values() );

		return attributes;
	}

	/**
	 * Returns the vertex buffers of the render object.
	 *
	 * @return {Array<BufferAttribute|InterleavedBuffer>} An array with buffer attribute or interleaved buffers.
	 */
	List? getVertexBuffers() {
		if ( this.vertexBuffers == null ) this.getAttributes();
		return this.vertexBuffers;
	}

	/**
	 * Returns the draw parameters for the render object.
	 *
	 * @return {?{vertexCount: number, firstVertex: number, instanceCount: number, firstInstance: number}} The draw parameters.
	 */
	getDrawParameters() {

		final object = this.object;
    final material = this.material;
    final geometry = this.geometry;
    final group = this.group;
    final drawRange = this.drawRange;

		final drawParams = this.drawParams ?? ( this.drawParams = {
			'vertexCount': 0,
			'firstVertex': 0,
			'instanceCount': 0,
			'firstInstance': 0
		} );

		final index = this.getIndex();
		final hasIndex = ( index != null );

		int instanceCount = 1;

		if ( geometry is InstancedBufferGeometry) {
			instanceCount = geometry.instanceCount!;
		} 
    else if ( object.count != null ) {
			instanceCount = math.max( 0, object.count! );
		}

		if ( instanceCount == 0 ) return null;

		drawParams['instanceCount'] = instanceCount;

		if ( object is BatchedMesh == true ) return drawParams;

		int rangeFactor = 1;

		if ( material.wireframe == true && object is! Points && object is! LineSegments && object is! Line && object is! LineLoop ) {
			rangeFactor = 2;
		}

		int firstVertex = (drawRange?['start'] ?? 0)* rangeFactor;
		int lastVertex = ( (drawRange?['start'] ?? 0) + (drawRange?['count'] ?? 0) ) * rangeFactor;

		if ( group != null ) {
			firstVertex = math.max( firstVertex, group['start'] * rangeFactor );
			lastVertex = math.min( lastVertex, ( group['start'] + group['count'] ) * rangeFactor );
		}

		final position = geometry?.attributes['position'];
		int itemCount = double.infinity.toInt();

		if ( hasIndex ) {
			itemCount = index.count;
		} 
    else if ( position != null) {
			itemCount = position.count;
		}

		firstVertex = math.max( firstVertex, 0 );
		lastVertex = math.min( lastVertex, itemCount );

		final count = lastVertex - firstVertex;

		if ( count < 0 || count == double.infinity.toInt() ) return null;

		drawParams['vertexCount'] = count;
		drawParams['firstVertex'] = firstVertex;

		return drawParams;
	}

	/**
	 * Returns the render object's geometry cache key.
	 *
	 * The geometry cache key is part of the material cache key.
	 *
	 * @return {string} The geometry cache key.
	 */
	getGeometryCacheKey() {
		final geometry = this.geometry;
		String cacheKey = '';

		for ( final name in geometry!.attributes.keys.toList()..sort() ) {
			final attribute = geometry.attributes[ name ];

			cacheKey += name + ',';

			if ( attribute.data ) cacheKey += attribute.data.stride + ',';
			if ( attribute.offset ) cacheKey += attribute.offset + ',';
			if ( attribute.itemSize ) cacheKey += attribute.itemSize + ',';
			if ( attribute.normalized ) cacheKey += 'n,';
		}

		// structural equality isn't sufficient for morph targets since the
		// data are maintained in textures. only if the targets are all equal
		// the texture and thus the instance of `MorphNode` can be shared.

		for ( final name in geometry.morphAttributes.keys.toList()..sort() ) {
			final targets = geometry.morphAttributes[ name ];
			cacheKey += 'morph-' + name + ',';

			for (int i = 0, l = targets!.length; i < l; i ++ ) {
				final attribute = targets[ i ];
				cacheKey += attribute.id + ',';
			}
		}

		if ( geometry.index != null) {
			cacheKey += 'index,';
		}

		return cacheKey;
	}

	/**
	 * Returns the render object's material cache key.
	 *
	 * The material cache key is part of the render object cache key.
	 *
	 * @return {number} The material cache key.
	 */
	getMaterialCacheKey() {
		final object = this.object;
    final material = this.material;

		String cacheKey = material.customProgramCacheKey();

		for ( final property in getKeys( material ) ) {

			if ( /^(is[A-Z]|_)|^(visible|version|uuid|name|opacity|userData)$/.test( property ) ) continue;

			final value = material[ property ];

			String valueKey;

			if ( value != null ) {
				// some material values require a formatting
				final type = value;

				if ( type is num ) {
					valueKey = value != 0 ? '1' : '0'; // Convert to on/off, important for clearcoat, transmission, etc
				} 
        else if ( type is Map) {
					valueKey = '{';
					if ( value is Texture ) {
						valueKey += value.mapping.toString();
					}
					valueKey += '}';
				} 
        else {
					valueKey = value.toString();
				}
			} 
      else {
				valueKey = value.toString();
			}

			cacheKey += /*property + ':' +*/ valueKey + ',';

		}

		cacheKey += this.clippingContextCacheKey + ',';

		if ( object.geometry != null) {
			cacheKey += this.getGeometryCacheKey();
		}

		if ( object.skeleton != null) {
			cacheKey +=  '${object.skeleton!.bones.length},';
		}

		if ( object is BatchedMesh ) {
			cacheKey += object.matricesTexture!.uuid + ',';

			if ( object.colorsTexture != null ) {
				cacheKey += object.colorsTexture!.uuid + ',';
			}
		}

		if ( (object.count ?? 0) > 1 ) {
			// TODO: https://github.com/mrdoob/three.js/pull/29066#issuecomment-2269400850
			cacheKey += object.uuid + ',';
		}

		cacheKey +=  '${object.receiveShadow},';

		return hashString( cacheKey );
	}

	/**
	 * Whether the geometry requires an update or not.
	 *
	 * @type {boolean}
	 * @readonly
	 */
	bool get needsGeometryUpdate => _needsGeometryUpdate();
  bool _needsGeometryUpdate() {
		if ( this.geometry?.id != this.object.geometry?.id ) return true;

		if ( this.attributes != null ) {
			final attributesId = this.attributesId;

			for ( final name in attributesId!.keys ) {
				final attribute = this.geometry?.getAttributeFromString( name );

				if ( attribute == null || attributesId[ name ] != attribute.id ) {
					return true;
				}
			}
		}

		return false;
	}

	/**
	 * Whether the render object requires an update or not.
	 *
	 * Note: There are two distinct places where render objects are checked for an update.
	 *
	 * 1. In `RenderObjects.get()` which is executed when the render object is request. This
	 * method checks the `needsUpdate` flag and recreates the render object if necessary.
	 * 2. In `Renderer._renderObjectDirect()` right after getting the render object via
	 * `RenderObjects.get()`. The render object's NodeMaterialObserver is then used to detect
	 * a need for a refresh due to material, geometry or object related value changes.
	 *
	 * TODO: Investigate if it's possible to merge both steps so there is only a single place
	 * that performs the 'needsUpdate' check.
	 *
	 * @type {boolean}
	 * @readonly
	 */
	bool get needsUpdate => ( this.initialNodesCacheKey != this.getDynamicCacheKey() || this.clippingNeedsUpdate );
	

	/**
	 * Returns the dynamic cache key which represents a key that is computed per draw command.
	 *
	 * @return {number} The cache key.
	 */
	int getDynamicCacheKey() {
		int cacheKey = 0;

		// `Nodes.getCacheKey()` returns an environment cache key which is not relevant when
		// the renderer is inside a shadow pass.

		if ( this.material.isShadowPassMaterial != true ) {
			cacheKey = this._nodes.getCacheKey( this.scene, this.lightsNode );
		}

		if ( this.camera is ArrayCamera ) {
			cacheKey = hash( cacheKey, (camera as ArrayCamera).cameras.length );
		}

		if ( this.object.receiveShadow ) {
			cacheKey = hash( cacheKey, 1 );
		}

		return cacheKey;
	}

	/**
	 * Returns the render object's cache key.
	 *
	 * @return {number} The cache key.
	 */
	int getCacheKey() {
		return this.getMaterialCacheKey() + this.getDynamicCacheKey();
	}

	/**
	 * Frees internal resources.
	 */
	void dispose() {
		this.material.removeEventListener( 'dispose', this.onMaterialDispose );
		this.geometry?.removeEventListener( 'dispose', this.onGeometryDispose );
		this.onDispose?.call();
	}
}