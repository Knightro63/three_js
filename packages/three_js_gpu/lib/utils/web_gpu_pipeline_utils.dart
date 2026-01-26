import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/gpu_backend.dart';
import 'package:three_js_math/three_js_math.dart';


///
/// A WebGPU backend utility module for managing pipelines.
///
/// @private
///
class WebGPUPipelineUtils {
  WebGPUBackend backend;
  WeakMap _activePipelines = WeakMap();

	///
	/// Constructs a new utility object.
	///
	/// @param {WebGPUBackend} backend - The WebGPU backend.
	///
	WebGPUPipelineUtils( this.backend );

	///
	/// Sets the given pipeline for the given pass. The method makes sure to only set the
	/// pipeline when necessary.
	///
	/// @param {(GPURenderPassEncoder|GPUComputePassEncoder)} pass - The pass encoder.
	/// @param {(GPURenderPipeline|GPUComputePipeline)} pipeline - The pipeline.
	///
	setPipeline( pass, pipeline ) {

		final currentPipeline = this._activePipelines.get( pass );

		if ( currentPipeline != pipeline ) {

			pass.setPipeline( pipeline );

			this._activePipelines.set( pass, pipeline );

		}

	}

	///
	/// Returns the sample count derived from the given render context.
	///
	/// @private
	/// @param {RenderContext} renderContext - The render context.
	/// @return {number} The sample count.
	///
	_getSampleCount( renderContext ) {

		return this.backend.utils.getSampleCountRenderContext( renderContext );

	}

	///
	/// Creates a render pipeline for the given render object.
	///
	/// @param {RenderObject} renderObject - The render object.
	/// @param {Array<Promise>} promises - An array of compilation promises which are used in `compileAsync()`.
	///
	createRenderPipeline( renderObject, promises ) {

		final object = renderObject.object;
    final material = renderObject.material;
    final geometry = renderObject.geometry;
    final pipeline = renderObject.pipeline;

		final vertexProgram = pipeline.vertexProgram;
    final fragmentProgram = pipeline.fragmentProgram;

		final backend = this.backend;
		final device = backend.device;
		final utils = backend.utils;

		final pipelineData = backend.get( pipeline );

		// bind group layouts

		final bindGroupLayouts = [];

		for ( final bindGroup in renderObject.getBindings() ) {

			final bindingsData = backend.get( bindGroup );

			bindGroupLayouts.add( bindingsData.layout );

		}

		// vertex buffers

		final vertexBuffers = backend.attributeUtils.createShaderVertexBuffers( renderObject );

		// blending

		var blending;

		if ( material.blending != NoBlending && ( material.blending != NormalBlending || material.transparent != false ) ) {

			blending = this._getBlending( material );

		}

		// stencil

		Map<String,dynamic> stencilFront = {};

		if ( material.stencilWrite == true ) {

			stencilFront = {
				'compare': this._getStencilCompare( material ),
				'failOp': this._getStencilOperation( material.stencilFail ),
				'depthFailOp': this._getStencilOperation( material.stencilZFail ),
				'passOp': this._getStencilOperation( material.stencilZPass )
			};

		}

		final colorWriteMask = this._getColorWriteMask( material );

		final targets = [];

		if ( renderObject.context.textures != null ) {

			final textures = renderObject.context.textures;

			for ( int i = 0; i < textures.length; i ++ ) {

				final colorFormat = utils.getTextureFormatGPU( textures[ i ] );

				targets.add( {
					'format': colorFormat,
					'blend': blending,
					'writeMask': colorWriteMask
				} );

			}

		} else {

			final colorFormat = utils.getCurrentColorFormat( renderObject.context );

			targets.add( {
				'format': colorFormat,
				'blend': blending,
				'writeMask': colorWriteMask
			} );

		}

		final vertexModule = backend.get( vertexProgram ).module;
		final fragmentModule = backend.get( fragmentProgram ).module;

		final primitiveState = this._getPrimitiveState( object, geometry, material );
		final depthCompare = this._getDepthCompare( material );
		final depthStencilFormat = utils.getCurrentDepthStencilFormat( renderObject.context );

		final sampleCount = this._getSampleCount( renderObject.context );

		final pipelineDescriptor = {
			'label': 'renderPipeline_${ material.name || material.type }_${ material.id }',
			'vertex': Object.assign( {}, vertexModule, { 'buffers': vertexBuffers } ),
			'fragment': Object.assign( {}, fragmentModule, { 'targets': targets } ),
			'primitive': primitiveState,
			'multisample': {
				'count': sampleCount,
				'alphaToCoverageEnabled': material.alphaToCoverage && sampleCount > 1
			},
			'layout': device.createPipelineLayout( {
				'bindGroupLayouts': bindGroupLayouts
			} )
		};


		final Map<String, dynamic> depthStencil = {};
		final renderDepth = renderObject.context.depth;
		final renderStencil = renderObject.context.stencil;

		if ( renderDepth == true || renderStencil == true ) {

			if ( renderDepth == true ) {

				depthStencil['format'] = depthStencilFormat;
				depthStencil['depthWriteEnabled'] = material.depthWrite;
				depthStencil['depthCompare'] = depthCompare;

			}

			if ( renderStencil == true ) {

				depthStencil['stencilFront'] = stencilFront;
				depthStencil['stencilBack'] = {}; // three.js does not provide an API to configure the back function (gl.stencilFuncSeparate() was never used)
				depthStencil['stencilReadMask'] = material.stencilFuncMask;
				depthStencil['stencilWriteMask'] = material.stencilWriteMask;

			}

			if ( material.polygonOffset == true ) {

				depthStencil['depthBias'] = material.polygonOffsetUnits;
				depthStencil['depthBiasSlopeScale'] = material.polygonOffsetFactor;
				depthStencil['depthBiasClamp'] = 0; // three.js does not provide an API to configure this value

			}

			pipelineDescriptor['depthStencil'] = depthStencil;

		}


		if ( promises == null ) {
			pipelineData.pipeline = device.createRenderPipeline( pipelineDescriptor );
		} 
    else {
			final p = new Future( () {

				device.createRenderPipelineAsync( pipelineDescriptor ).then( (pipeline){
					pipelineData.pipeline = pipeline;
					//resolve();
				} );
			} );

			promises.add( p );
		}
	}

	///
	/// Creates GPU render bundle encoder for the given render context.
	///
	/// @param {RenderContext} renderContext - The render context.
	/// @param {?string} [label='renderBundleEncoder'] - The label.
	/// @return {GPURenderBundleEncoder} The GPU render bundle encoder.
	GPURenderBundleEncoder createBundleEncoder(RenderContext renderContext, [String label = 'renderBundleEncoder'] ) {

		final backend = this.backend;
		final utils = backend.utils;
    final device = backend.device;

		final depthStencilFormat = utils.getCurrentDepthStencilFormat( renderContext );
		final colorFormat = utils.getCurrentColorFormat( renderContext );
		final sampleCount = this._getSampleCount( renderContext );

		final descriptor = {
			'label': label,
			'colorFormats': [ colorFormat ],
			'depthStencilFormat': depthStencilFormat,
			'sampleCount': sampleCount
		};

		return device.createRenderBundleEncoder( descriptor );

	}

	///
	/// Creates a compute pipeline for the given compute node.
	///
	/// @param {ComputePipeline} pipeline - The compute pipeline.
	/// @param {Array<BindGroup>} bindings - The bindings.
	///
	createComputePipeline( ComputePipeline pipeline, List<BindGroup> bindings ) {

		final backend = this.backend;
		final device = backend.device;

		final computeProgram = backend.get( pipeline.computeProgram ).module;

		final pipelineGPU = backend.get( pipeline );

		// bind group layouts

		final bindGroupLayouts = [];

		for ( final bindingsGroup in bindings ) {

			final bindingsData = backend.get( bindingsGroup );

			bindGroupLayouts.add( bindingsData.layout );

		}

		pipelineGPU.pipeline = device.createComputePipeline( {
			'compute': computeProgram,
			'layout': device.createPipelineLayout( {
				'bindGroupLayouts': bindGroupLayouts
			} )
		} );

	}

	///
	/// Returns the blending state as a descriptor object required
	/// for the pipeline creation.
	///
	/// @private
	/// @param {Material} material - The material.
	/// @return {Object} The blending state.
	///
	_getBlending( Material material ) {

		Map<String, dynamic> color, alpha;

		final blending = material.blending;
		final blendSrc = material.blendSrc;
		final blendDst = material.blendDst;
		final blendEquation = material.blendEquation;


		if ( blending == CustomBlending ) {

			final blendSrcAlpha = material.blendSrcAlpha ?? blendSrc;
			final blendDstAlpha = material.blendDstAlpha ?? blendDst;
			final blendEquationAlpha = material.blendEquationAlpha ?? blendEquation;

			color = {
				'srcFactor': this._getBlendFactor( blendSrc ),
				'dstFactor': this._getBlendFactor( blendDst ),
				'operation': this._getBlendOperation( blendEquation )
			};

			alpha = {
				'srcFactor': this._getBlendFactor( blendSrcAlpha ),
				'dstFactor': this._getBlendFactor( blendDstAlpha ),
				'operation': this._getBlendOperation( blendEquationAlpha )
			};

		} else {

			final premultipliedAlpha = material.premultipliedAlpha;

			final setBlend = ( srcRGB, dstRGB, srcAlpha, dstAlpha ){

				color = {
					'srcFactor': srcRGB,
					'dstFactor': dstRGB,
					'operation': GPUBlendOperation.Add
				};

				alpha = {
					'srcFactor': srcAlpha,
					'dstFactor': dstAlpha,
					'operation': GPUBlendOperation.Add
				};

			};

			if ( premultipliedAlpha ) {

				switch ( blending ) {

					case NormalBlending:
						setBlend( GPUBlendFactor.One, GPUBlendFactor.OneMinusSrcAlpha, GPUBlendFactor.One, GPUBlendFactor.OneMinusSrcAlpha );
						break;

					case AdditiveBlending:
						setBlend( GPUBlendFactor.One, GPUBlendFactor.One, GPUBlendFactor.One, GPUBlendFactor.One );
						break;

					case SubtractiveBlending:
						setBlend( GPUBlendFactor.Zero, GPUBlendFactor.OneMinusSrc, GPUBlendFactor.Zero, GPUBlendFactor.One );
						break;

					case MultiplyBlending:
						setBlend( GPUBlendFactor.Dst, GPUBlendFactor.OneMinusSrcAlpha, GPUBlendFactor.Zero, GPUBlendFactor.One );
						break;

				}

			} else {

				switch ( blending ) {

					case NormalBlending:
						setBlend( GPUBlendFactor.SrcAlpha, GPUBlendFactor.OneMinusSrcAlpha, GPUBlendFactor.One, GPUBlendFactor.OneMinusSrcAlpha );
						break;

					case AdditiveBlending:
						setBlend( GPUBlendFactor.SrcAlpha, GPUBlendFactor.One, GPUBlendFactor.One, GPUBlendFactor.One );
						break;

					case SubtractiveBlending:
						console.error( 'THREE.WebGPURenderer: SubtractiveBlending requires material.premultipliedAlpha = true' );
						break;

					case MultiplyBlending:
						console.error( 'THREE.WebGPURenderer: MultiplyBlending requires material.premultipliedAlpha = true' );
						break;

				}

			}

		}

		if ( color != null && alpha != null ) {

			return { 'color': color, 'alpha': alpha };

		} else {

			console.error( 'THREE.WebGPURenderer: Invalid blending: ', blending );

		}

	}

	///
	/// Returns the GPU blend factor which is required for the pipeline creation.
	///
	/// @private
	/// @param {number} blend - The blend factor as a three.js constant.
	/// @return {string} The GPU blend factor.
	///
	_getBlendFactor( int blend ) {

		String blendFactor;

		switch ( blend ) {

			case ZeroFactor:
				blendFactor = GPUBlendFactor.Zero;
				break;

			case OneFactor:
				blendFactor = GPUBlendFactor.One;
				break;

			case SrcColorFactor:
				blendFactor = GPUBlendFactor.Src;
				break;

			case OneMinusSrcColorFactor:
				blendFactor = GPUBlendFactor.OneMinusSrc;
				break;

			case SrcAlphaFactor:
				blendFactor = GPUBlendFactor.SrcAlpha;
				break;

			case OneMinusSrcAlphaFactor:
				blendFactor = GPUBlendFactor.OneMinusSrcAlpha;
				break;

			case DstColorFactor:
				blendFactor = GPUBlendFactor.Dst;
				break;

			case OneMinusDstColorFactor:
				blendFactor = GPUBlendFactor.OneMinusDst;
				break;

			case DstAlphaFactor:
				blendFactor = GPUBlendFactor.DstAlpha;
				break;

			case OneMinusDstAlphaFactor:
				blendFactor = GPUBlendFactor.OneMinusDstAlpha;
				break;

			case SrcAlphaSaturateFactor:
				blendFactor = GPUBlendFactor.SrcAlphaSaturated;
				break;

			case BlendColorFactor:
				blendFactor = GPUBlendFactor.Constant;
				break;

			case OneMinusBlendColorFactor:
				blendFactor = GPUBlendFactor.OneMinusConstant;
				break;

			default:
				console.error( 'THREE.WebGPURenderer: Blend factor not supported.', blend );

		}

		return blendFactor;

	}

	///
	/// Returns the GPU stencil compare function which is required for the pipeline creation.
	///
	/// @private
	/// @param {Material} material - The material.
	/// @return {string} The GPU stencil compare function.
	///
	_getStencilCompare( Material material ) {

		String stencilCompare;

		final stencilFunc = material.stencilFunc;

		switch ( stencilFunc ) {

			case NeverStencilFunc:
				stencilCompare = GPUCompareFunction.Never;
				break;

			case AlwaysStencilFunc:
				stencilCompare = GPUCompareFunction.Always;
				break;

			case LessStencilFunc:
				stencilCompare = GPUCompareFunction.Less;
				break;

			case LessEqualStencilFunc:
				stencilCompare = GPUCompareFunction.LessEqual;
				break;

			case EqualStencilFunc:
				stencilCompare = GPUCompareFunction.Equal;
				break;

			case GreaterEqualStencilFunc:
				stencilCompare = GPUCompareFunction.GreaterEqual;
				break;

			case GreaterStencilFunc:
				stencilCompare = GPUCompareFunction.Greater;
				break;

			case NotEqualStencilFunc:
				stencilCompare = GPUCompareFunction.NotEqual;
				break;

			default:
				console.error( 'THREE.WebGPURenderer: Invalid stencil function.', stencilFunc );

		}

		return stencilCompare;

	}

	///
	/// Returns the GPU stencil operation which is required for the pipeline creation.
	///
	/// @private
	/// @param {number} op - A three.js constant defining the stencil operation.
	/// @return {string} The GPU stencil operation.
	///
	_getStencilOperation( int op ) {

		String stencilOperation;

		switch ( op ) {

			case KeepStencilOp:
				stencilOperation = GPUStencilOperation.Keep;
				break;

			case ZeroStencilOp:
				stencilOperation = GPUStencilOperation.Zero;
				break;

			case ReplaceStencilOp:
				stencilOperation = GPUStencilOperation.Replace;
				break;

			case InvertStencilOp:
				stencilOperation = GPUStencilOperation.Invert;
				break;

			case IncrementStencilOp:
				stencilOperation = GPUStencilOperation.IncrementClamp;
				break;

			case DecrementStencilOp:
				stencilOperation = GPUStencilOperation.DecrementClamp;
				break;

			case IncrementWrapStencilOp:
				stencilOperation = GPUStencilOperation.IncrementWrap;
				break;

			case DecrementWrapStencilOp:
				stencilOperation = GPUStencilOperation.DecrementWrap;
				break;

			default:
				console.error( 'THREE.WebGPURenderer: Invalid stencil operation.', stencilOperation );

		}

		return stencilOperation;

	}

	///
	/// Returns the GPU blend operation which is required for the pipeline creation.
	///
	/// @private
	/// @param {number} blendEquation - A three.js constant defining the blend equation.
	/// @return {string} The GPU blend operation.
	///
	_getBlendOperation( int blendEquation ) {

		String blendOperation;

		switch ( blendEquation ) {

			case AddEquation:
				blendOperation = GPUBlendOperation.Add;
				break;

			case SubtractEquation:
				blendOperation = GPUBlendOperation.Subtract;
				break;

			case ReverseSubtractEquation:
				blendOperation = GPUBlendOperation.ReverseSubtract;
				break;

			case MinEquation:
				blendOperation = GPUBlendOperation.Min;
				break;

			case MaxEquation:
				blendOperation = GPUBlendOperation.Max;
				break;

			default:
				console.error( 'THREE.WebGPUPipelineUtils: Blend equation not supported.', blendEquation );

		}

		return blendOperation;

	}

	/**
	 * Returns the primitive state as a descriptor object required
	 * for the pipeline creation.
	 *
	 * @private
	 * @param {Object3D} object - The 3D object.
	 * @param {BufferGeometry} geometry - The geometry.
	 * @param {Material} material - The material.
	 * @return {Object} The primitive state.
	 */
	_getPrimitiveState( object, geometry, material ) {

		const descriptor = {};
		const utils = this.backend.utils;

		descriptor.topology = utils.getPrimitiveTopology( object, material );

		if ( geometry.index !== null && object.isLine === true && object.isLineSegments !== true ) {

			descriptor.stripIndexFormat = ( geometry.index.array instanceof Uint16Array ) ? GPUIndexFormat.Uint16 : GPUIndexFormat.Uint32;

		}

		switch ( material.side ) {

			case FrontSide:
				descriptor.frontFace = GPUFrontFace.CCW;
				descriptor.cullMode = GPUCullMode.Back;
				break;

			case BackSide:
				descriptor.frontFace = GPUFrontFace.CCW;
				descriptor.cullMode = GPUCullMode.Front;
				break;

			case DoubleSide:
				descriptor.frontFace = GPUFrontFace.CCW;
				descriptor.cullMode = GPUCullMode.None;
				break;

			default:
				console.error( 'THREE.WebGPUPipelineUtils: Unknown material.side value.', material.side );
				break;

		}

		return descriptor;

	}

	///
	/// Returns the GPU color write mask which is required for the pipeline creation.
	///
	/// @private
	/// @param {Material} material - The material.
	/// @return {string} The GPU color write mask.
	///
	_getColorWriteMask( Material material ) {

		return ( material.colorWrite ) ? GPUColorWriteFlags.All : GPUColorWriteFlags.None;

	}

	///
	/// Returns the GPU depth compare function which is required for the pipeline creation.
	///
	/// @private
	/// @param {Material} material - The material.
	/// @return {string} The GPU depth compare function.
	///
	_getDepthCompare( Material material ) {

		String depthCompare;

		if ( material.depthTest === false ) {

			depthCompare = GPUCompareFunction.Always;

		} else {

			const depthFunc = material.depthFunc;

			switch ( depthFunc ) {

				case NeverDepth:
					depthCompare = GPUCompareFunction.Never;
					break;

				case AlwaysDepth:
					depthCompare = GPUCompareFunction.Always;
					break;

				case LessDepth:
					depthCompare = GPUCompareFunction.Less;
					break;

				case LessEqualDepth:
					depthCompare = GPUCompareFunction.LessEqual;
					break;

				case EqualDepth:
					depthCompare = GPUCompareFunction.Equal;
					break;

				case GreaterEqualDepth:
					depthCompare = GPUCompareFunction.GreaterEqual;
					break;

				case GreaterDepth:
					depthCompare = GPUCompareFunction.Greater;
					break;

				case NotEqualDepth:
					depthCompare = GPUCompareFunction.NotEqual;
					break;

				default:
					console.error( 'THREE.WebGPUPipelineUtils: Invalid depth function.', depthFunc );

			}

		}

		return depthCompare;

	}

}
