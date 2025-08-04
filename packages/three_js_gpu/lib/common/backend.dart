import 'dart:typed_data';
import 'package:three_js_core/others/weak_map.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/bind_group.dart';
import 'package:three_js_gpu/common/compute_pipeline.dart';
import 'package:three_js_gpu/common/programmable_stage.dart';
import 'package:three_js_gpu/common/render_context.dart';
import 'package:three_js_gpu/common/render_object.dart';
import 'package:three_js_gpu/common/renderer.dart';
import 'package:three_js_math/three_js_math.dart';

Vector2? _vector2;
Color? _color4;

/**
 * Most of the rendering related logic is implemented in the
 * {@link Renderer} module and related management components.
 * Sometimes it is required though to execute commands which are
 * specific to the current 3D backend (which is WebGPU or WebGL 2).
 * This abstract base class defines an interface that encapsulates
 * all backend-related logic. Derived classes for each backend must
 * implement the interface.
 *
 * @abstract
 * @private
 */
abstract class Backend {
  late final Map parameters;
  final data = WeakMap();
  Renderer? renderer;
  GlobalKey? domElement;

  final Map<String,dynamic> timestampQueryPool = {
    'render': null,
    'compute': null
  };

  bool trackTimestamp = false;

	/**
	 * Constructs a new backend.
	 *
	 * @param {Object} parameters - An object holding parameters for the backend.
	 */
	Backend(Map? parameters) {
		this.parameters = parameters ?? {};
		trackTimestamp = parameters?['trackTimestamp'] == true;
	}

	Future<void> init(Renderer renderer ) async{
		this.renderer = renderer;
	}

	/**
	 * The coordinate system of the backend.
	 *
	 * @abstract
	 * @type {number}
	 * @readonly
	 */
	get coordinateSystem;

	// render context

	/**
	 * This method is executed at the beginning of a render call and
	 * can be used by the backend to prepare the state for upcoming
	 * draw calls.
	 *
	 * @abstract
	 * @param {RenderContext} renderContext - The render context.
	 */
	void beginRender() {}

	/**
	 * This method is executed at the end of a render call and
	 * can be used by the backend to finalize work after draw
	 * calls.
	 *
	 * @abstract
	 * @param {RenderContext} renderContext - The render context.
	 */
	void finishRender() {}

	/**
	 * This method is executed at the beginning of a compute call and
	 * can be used by the backend to prepare the state for upcoming
	 * compute tasks.
	 *
	 * @abstract
	 * @param {Node|Array<Node>} computeGroup - The compute node(s).
	 */
	void beginCompute() {}

	/**
	 * This method is executed at the end of a compute call and
	 * can be used by the backend to finalize work after compute
	 * tasks.
	 *
	 * @abstract
	 * @param {Node|Array<Node>} computeGroup - The compute node(s).
	 */
	void finishCompute( /*computeGroup*/ ) {}

	// render object

	/**
	 * Executes a draw command for the given render object.
	 *
	 * @abstract
	 * @param {RenderObject} renderObject - The render object to draw.
	 * @param {Info} info - Holds a series of statistical information about the GPU memory and the rendering process.
	 */
	void draw( /*renderObject, info*/ ) { }

	// compute node

	/**
	 * Executes a compute command for the given compute node.
	 *
	 * @abstract
	 * @param {Node|Array<Node>} computeGroup - The group of compute nodes of a compute call. Can be a single compute node.
	 * @param {Node} computeNode - The compute node.
	 * @param {Array<BindGroup>} bindings - The bindings.
	 * @param {ComputePipeline} computePipeline - The compute pipeline.
	 */
	compute( /*computeGroup, computeNode, computeBindings, computePipeline*/ ) { }

	// program

	/**
	 * Creates a shader program from the given programmable stage.
	 *
	 * @abstract
	 * @param {ProgrammableStage} program - The programmable stage.
	 */
	void createProgram(ProgrammableStage program) { }

	/**
	 * Destroys the shader program of the given programmable stage.
	 *
	 * @abstract
	 * @param {ProgrammableStage} program - The programmable stage.
	 */
	void destroyProgram(ProgrammableStage program) { }

	// bindings

	/**
	 * Creates bindings from the given bind group definition.
	 *
	 * @abstract
	 * @param {BindGroup} bindGroup - The bind group.
	 * @param {Array<BindGroup>} bindings - Array of bind groups.
	 * @param {number} cacheIndex - The cache index.
	 * @param {number} version - The version.
	 */
	void createBindings(BindGroup bindGroup, List<BindGroup> bindings, int cacheIndex,[int? version ]) { }

	/**
	 * Updates the given bind group definition.
	 *
	 * @abstract
	 * @param {BindGroup} bindGroup - The bind group.
	 * @param {Array<BindGroup>} bindings - Array of bind groups.
	 * @param {number} cacheIndex - The cache index.
	 * @param {number} version - The version.
	 */
	updateBindings( BindGroup bindGroup, List<BindGroup> bindings, int cacheIndex, int version ) { }

	/**
	 * Updates a buffer binding.
	 *
	 * @abstract
	 * @param {Buffer} binding - The buffer binding to update.
	 */
	void updateBinding(Buffer binding ) { }

	// pipeline

	/**
	 * Creates a render pipeline for the given render object.
	 *
	 * @abstract
	 * @param {RenderObject} renderObject - The render object.
	 * @param {Array<Promise>} promises - An array of compilation promises which are used in `compileAsync()`.
	 */
	void createRenderPipeline(RenderObject renderObject, [List? promises]) { }

	/**
	 * Creates a compute pipeline for the given compute node.
	 *
	 * @abstract
	 * @param {ComputePipeline} computePipeline - The compute pipeline.
	 * @param {Array<BindGroup>} bindings - The bindings.
	 */
	void createComputePipeline(ComputePipeline computePipeline, List<BindGroup> bindings) { }

	// cache key

	/**
	 * Returns `true` if the render pipeline requires an update.
	 *
	 * @abstract
	 * @param {RenderObject} renderObject - The render object.
	 * @return {boolean} Whether the render pipeline requires an update or not.
	 */
	bool needsRenderUpdate(RenderObject renderObject);

	/**
	 * Returns a cache key that is used to identify render pipelines.
	 *
	 * @abstract
	 * @param {RenderObject} renderObject - The render object.
	 * @return {string} The cache key.
	 */
	String getRenderCacheKey(RenderObject renderObject );

	// node builder

	/**
	 * Returns a node builder for the given render object.
	 *
	 * @abstract
	 * @param {RenderObject} renderObject - The render object.
	 * @param {Renderer} renderer - The renderer.
	 * @return {NodeBuilder} The node builder.
	 */
	NodeBuilder createNodeBuilder(RenderObject renderObject, Renderer renderer ) { }

	// textures

	/**
	 * Creates a GPU sampler for the given texture.
	 *
	 * @abstract
	 * @param {Texture} texture - The texture to create the sampler for.
	 */
	void createSampler(Texture texture );

	/**
	 * Destroys the GPU sampler for the given texture.
	 *
	 * @abstract
	 * @param {Texture} texture - The texture to destroy the sampler for.
	 */
	void destroySampler(Texture texture );

	/**
	 * Creates a default texture for the given texture that can be used
	 * as a placeholder until the actual texture is ready for usage.
	 *
	 * @abstract
	 * @param {Texture} texture - The texture to create a default texture for.
	 */
	void createDefaultTexture(Texture texture ) { }

	/**
	 * Defines a texture on the GPU for the given texture object.
	 *
	 * @abstract
	 * @param {Texture} texture - The texture.
	 * @param {Object} [options={}] - Optional configuration parameter.
	 */
	void createTexture(Texture texture, [Map<String,dynamic>? options]) { }

	/**
	 * Uploads the updated texture data to the GPU.
	 *
	 * @abstract
	 * @param {Texture} texture - The texture.
	 * @param {Object} [options={}] - Optional configuration parameter.
	 */
	void updateTexture(Texture texture, [Map<String,dynamic>? options]) { }

	/**
	 * Generates mipmaps for the given texture.
	 *
	 * @abstract
	 * @param {Texture} texture - The texture.
	 */
	void generateMipmaps(Texture texture ) { }

	/**
	 * Destroys the GPU data for the given texture object.
	 *
	 * @abstract
	 * @param {Texture} texture - The texture.
	 */
	void destroyTexture(Texture texture ) { }

	/**
	 * Returns texture data as a typed array.
	 *
	 * @abstract
	 * @async
	 * @param {Texture} texture - The texture to copy.
	 * @param {number} x - The x coordinate of the copy origin.
	 * @param {number} y - The y coordinate of the copy origin.
	 * @param {number} width - The width of the copy.
	 * @param {number} height - The height of the copy.
	 * @param {number} faceIndex - The face index.
	 * @return {Promise<TypedArray>} A Promise that resolves with a typed array when the copy operation has finished.
	 */
	Future<TypedData> copyTextureToBuffer( Texture texture, int x, int y, int width, int height, int faceIndex );

	/**
	 * Copies data of the given source texture to the given destination texture.
	 *
	 * @abstract
	 * @param {Texture} srcTexture - The source texture.
	 * @param {Texture} dstTexture - The destination texture.
	 * @param {?(Box3|Box2)} [srcRegion=null] - The region of the source texture to copy.
	 * @param {?(Vector2|Vector3)} [dstPosition=null] - The destination position of the copy.
	 * @param {number} [srcLevel=0] - The source mip level to copy from.
	 * @param {number} [dstLevel=0] - The destination mip level to copy to.
	 */
	copyTextureToTexture( /*srcTexture, dstTexture, srcRegion = null, dstPosition = null, srcLevel = 0, dstLevel = 0*/ ) {}

	/**
	* Copies the current bound framebuffer to the given texture.
	*
	* @abstract
	* @param {Texture} texture - The destination texture.
	* @param {RenderContext} renderContext - The render context.
	* @param {Vector4} rectangle - A four dimensional vector defining the origin and dimension of the copy.
	*/
	copyFramebufferToTexture(Texture texture, RenderContext renderContext, Vector4 rectangle) {}

	// attributes

	/**
	 * Creates the GPU buffer of a shader attribute.
	 *
	 * @abstract
	 * @param {BufferAttribute} attribute - The buffer attribute.
	 */
	createAttribute(BufferAttribute attribute) { }

	/**
	 * Creates the GPU buffer of an indexed shader attribute.
	 *
	 * @abstract
	 * @param {BufferAttribute} attribute - The indexed buffer attribute.
	 */
	createIndexAttribute(BufferAttribute attribute ) { }

	/**
	 * Creates the GPU buffer of a storage attribute.
	 *
	 * @abstract
	 * @param {BufferAttribute} attribute - The buffer attribute.
	 */
	createStorageAttribute( BufferAttribute attribute) { }

	/**
	 * Updates the GPU buffer of a shader attribute.
	 *
	 * @abstract
	 * @param {BufferAttribute} attribute - The buffer attribute to update.
	 */
	updateAttribute(BufferAttribute attribute ) { }

	/**
	 * Destroys the GPU buffer of a shader attribute.
	 *
	 * @abstract
	 * @param {BufferAttribute} attribute - The buffer attribute to destroy.
	 */
	destroyAttribute(BufferAttribute attribute ) { }

	// canvas

	/**
	 * Returns the backend's rendering context.
	 *
	 * @abstract
	 * @return {Object} The rendering context.
	 */
	getContext() { }

	/**
	 * Backends can use this method if they have to run
	 * logic when the renderer gets resized.
	 *
	 * @abstract
	 */
	updateSize() { }

	/**
	 * Updates the viewport with the values from the given render context.
	 *
	 * @abstract
	 * @param {RenderContext} renderContext - The render context.
	 */
	updateViewport( /*renderContext*/ ) {}

	// utils

	/**
	 * Returns `true` if the given 3D object is fully occluded by other
	 * 3D objects in the scene. Backends must implement this method by using
	 * a Occlusion Query API.
	 *
	 * @abstract
	 * @param {RenderContext} renderContext - The render context.
	 * @param {Object3D} object - The 3D object to test.
	 * @return {boolean} Whether the 3D object is fully occluded or not.
	 */
	isOccluded( /*renderContext, object*/ ) {}

	/**
	 * Resolves the time stamp for the given render context and type.
	 *
	 * @async
	 * @abstract
	 * @param {string} [type='render'] - The type of the time stamp.
	 * @return {Promise<number>} A Promise that resolves with the time stamp.
	 */
	Future<num> resolveTimestampsAsync([String type = 'render' ]) async{
		if (!this.trackTimestamp) {
			warnOnce( 'WebGPURenderer: Timestamp tracking is disabled.' );
			return;
		}

		final queryPool = this.timestampQueryPool[ type ];
		if (queryPool == null) {
			warnOnce( 'WebGPURenderer: No timestamp query pool for type "${type}" found.' );
			return;
		}

		final duration = await queryPool.resolveQueriesAsync();

		this.renderer.info[ type ].timestamp = duration;

		return duration;
	}

	/**
	 * Can be used to synchronize CPU operations with GPU tasks. So when this method is called,
	 * the CPU waits for the GPU to complete its operation (e.g. a compute task).
	 *
	 * @async
	 * @abstract
	 * @return {Promise} A Promise that resolves when synchronization has been finished.
	 */
	 Future<void> waitForGPU() async{}

	/**
	 * This method performs a readback operation by moving buffer data from
	 * a storage buffer attribute from the GPU to the CPU.
	 *
	 * @async
	 * @param {StorageBufferAttribute} attribute - The storage buffer attribute.
	 * @return {Promise<ArrayBuffer>} A promise that resolves with the buffer data when the data are ready.
	 */
	Future<bool> getArrayBufferAsync( /* attribute */ );

	/**
	 * Checks if the given feature is supported by the backend.
	 *
	 * @async
	 * @abstract
	 * @param {string} name - The feature's name.
	 * @return {Promise<boolean>} A Promise that resolves with a bool that indicates whether the feature is supported or not.
	 */
	Future<bool> hasFeatureAsync(String name);

	/**
	 * Checks if the given feature is supported  by the backend.
	 *
	 * @abstract
	 * @param {string} name - The feature's name.
	 * @return {boolean} Whether the feature is supported or not.
	 */
	bool hasFeature(String name);

	/**
	 * Returns the maximum anisotropy texture filtering value.
	 *
	 * @abstract
	 * @return {number} The maximum anisotropy texture filtering value.
	 */
	double getMaxAnisotropy();

	/**
	 * Returns the drawing buffer size.
	 *
	 * @return {Vector2} The drawing buffer size.
	 */
	Vector2 getDrawingBufferSize() {
		_vector2 = _vector2 ?? new Vector2();
		return this.renderer?.getDrawingBufferSize( _vector2 );
	}

	/**
	 * Defines the scissor test.
	 *
	 * @abstract
	 * @param {boolean} boolean - Whether the scissor test should be enabled or not.
	 */
	void setScissorTest( /*boolean*/ ) { }

	/**
	 * Returns the clear color and alpha into a single
	 * color object.
	 *
	 * @return {Color4} The clear color.
	 */
	Color? getClearColor() {
		final renderer = this.renderer;

		_color4 = _color4 ?? Color();
		renderer?.getClearColor( _color4 );
		_color4?.getRGB( _color4! );
		return _color4;
	}

	/**
	 * Returns the DOM element. If no DOM element exists, the backend
	 * creates a new one.
	 *
	 * @return {HTMLCanvasElement} The DOM element.
	 */
	getDomElement() {
		let domElement = this.domElement;

		if ( domElement == null ) {

			domElement = ( this.parameters.canvas != null ) ? this.parameters.canvas : createCanvasElement();

			// OffscreenCanvas does not have setAttribute, see #22811
			if ( 'setAttribute' in domElement ) domElement.setAttribute( 'data-engine', 'three.js r${REVISION} webgpu' );

			this.domElement = domElement;

		}

		return domElement;
	}

	/**
	 * Sets a dictionary for the given object into the
	 * internal data structure.
	 *
	 * @param {Object} object - The object.
	 * @param {Object} value - The dictionary to set.
	 */
	set( object, value ) {
		this.data.set( object, value );
	}

	/**
	 * Returns the dictionary for the given object.
	 *
	 * @param {Object} object - The object.
	 * @return {Object} The object's dictionary.
	 */
	Map? get( object ) {
		Map? map = this.data.get( object );

		if ( map == null ) {
			map = {};
			this.data.set( object, map );
		}

		return map;
	}

	bool has( object ) {
		return this.data.has( object );
	}

	void delete( object ) {
		this.data.delete( object );
	}

	void dispose() { }
}
