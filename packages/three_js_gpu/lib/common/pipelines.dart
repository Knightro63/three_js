import 'package:three_js_gpu/common/backend.dart';
import 'package:three_js_gpu/common/bind_group.dart';
import 'package:three_js_gpu/common/bindings.dart';
import 'package:three_js_gpu/common/compute_pipeline.dart';
import 'package:three_js_gpu/common/data_map.dart';
import 'package:three_js_gpu/common/nodes/nodes.dart';
import 'package:three_js_gpu/common/pipeline.dart';
import 'package:three_js_gpu/common/programmable_stage.dart';
import 'package:three_js_gpu/common/render_object.dart';
import 'package:three_js_gpu/common/render_pipeline.dart';

/**
 * This renderer module manages the pipelines of the renderer.
 *
 * @private
 * @augments DataMap
 */
class Pipelines extends DataMap {
  Backend backend;
  Nodes nodes;
  Bindings? bindings;
  Map<String,Pipeline> caches = {};
  Map<String,Map> programs = {
    'vertex': {},
    'fragment': {},
    'compute': {}
  };

	Pipelines(this.backend, this.nodes ):super();

	/**
	 * Returns a compute pipeline for the given compute node.
	 *
	 * @param {Node} computeNode - The compute node.
	 * @param {Array<BindGroup>} bindings - The bindings.
	 * @return {ComputePipeline} The compute pipeline.
	 */
	getForCompute(Node computeNode, List<BindGroup> bindings ) {
		final backend = this.backend;

		final data = this.get( computeNode );

		if ( this._needsComputeUpdate( computeNode ) ) {
			final previousPipeline = data.pipeline;
			if ( previousPipeline != null) {
				previousPipeline.usedTimes --;
				previousPipeline.computeProgram.usedTimes --;
			}

			// get shader

			final nodeBuilderState = this.nodes.getForCompute( computeNode );

			// programmable stage

			ProgrammableStage? stageCompute = this.programs['compute']?[nodeBuilderState.computeShader];

			if ( stageCompute == null ) {
				if ( previousPipeline != null&& previousPipeline.computeProgram.usedTimes == 0 ) this._releaseProgram( previousPipeline.computeProgram );
				stageCompute = new ProgrammableStage( nodeBuilderState.computeShader, 'compute', computeNode.name, nodeBuilderState.transforms, nodeBuilderState.nodeAttributes );
				this.programs['compute'].set( nodeBuilderState.computeShader, stageCompute );
				backend.createProgram( stageCompute );
			}

			// determine compute pipeline

			final cacheKey = this._getComputeCacheKey( computeNode, stageCompute );

			Pipeline? pipeline = this.caches[cacheKey];

			if ( pipeline == null ) {
				if ( previousPipeline && previousPipeline.usedTimes == 0 ) this._releasePipeline( previousPipeline );
				pipeline = this._getComputePipeline( computeNode, stageCompute, cacheKey, bindings );
			}

			// keep track of all used times

			pipeline.usedTimes ++;
			stageCompute.usedTimes ++;

			data.version = computeNode.version;
			data.pipeline = pipeline;
		}

		return data.pipeline;
	}

	/**
	 * Returns a render pipeline for the given render object.
	 *
	 * @param {RenderObject} renderObject - The render object.
	 * @param {?Array<Promise>} [promises=null] - An array of compilation promises which is only relevant in context of `Renderer.compileAsync()`.
	 * @return {RenderPipeline} The render pipeline.
	 */
	RenderPipeline getForRender(RenderObject renderObject, [promises = null ]) {
		final backend = this.backend;
		final data = this.get( renderObject );

		if ( this._needsRenderUpdate( renderObject ) ) {
			final previousPipeline = data.pipeline;

			if ( previousPipeline ) {
				previousPipeline.usedTimes --;
				previousPipeline.vertexProgram.usedTimes --;
				previousPipeline.fragmentProgram.usedTimes --;
			}

			// get shader

			final nodeBuilderState = renderObject.getNodeBuilderState();
			final name = renderObject.material ? renderObject.material.name : '';

			// programmable stages

			dynamic stageVertex = this.programs['vertex']?[nodeBuilderState.vertexShader];

			if ( stageVertex == null ) {
				if ( previousPipeline && previousPipeline.vertexProgram.usedTimes == 0 ) this._releaseProgram( previousPipeline.vertexProgram );
				stageVertex = new ProgrammableStage( nodeBuilderState.vertexShader, 'vertex', name );
				this.programs['vertex'].set( nodeBuilderState.vertexShader, stageVertex );

				backend.createProgram( stageVertex );
			}
      
			dynamic stageFragment = this.programs['fragment']?[nodeBuilderState.fragmentShader];

			if ( stageFragment == null ) {
				if ( previousPipeline && previousPipeline.fragmentProgram.usedTimes == 0 ) this._releaseProgram( previousPipeline.fragmentProgram );

				stageFragment = new ProgrammableStage( nodeBuilderState.fragmentShader, 'fragment', name );
				this.programs['fragment'].set( nodeBuilderState.fragmentShader, stageFragment );

				backend.createProgram( stageFragment );
			}

			// determine render pipeline

			final cacheKey = this._getRenderCacheKey( renderObject, stageVertex, stageFragment );

			Pipeline? pipeline = this.caches[cacheKey];

			if ( pipeline == null ) {
				if ( previousPipeline && previousPipeline.usedTimes == 0 ) this._releasePipeline( previousPipeline );
				pipeline = this._getRenderPipeline( renderObject, stageVertex, stageFragment, cacheKey, promises );
			} 
      else {
				renderObject.pipeline = pipeline;
			}

			// keep track of all used times

			pipeline?.usedTimes ++;
			stageVertex.usedTimes ++;
			stageFragment.usedTimes ++;

			data.pipeline = pipeline;
		}

		return data.pipeline;
	}

	/**
	 * Deletes the pipeline for the given render object.
	 *
	 * @param {RenderObject} object - The render object.
	 * @return {?Object} The deleted dictionary.
	 */
	Map? delete(RenderObject object ) {
		final Pipeline? pipeline = this.get( object ).pipeline;

		if ( pipeline != null) {
			pipeline.usedTimes --;

			if ( pipeline.usedTimes == 0 ) this._releasePipeline( pipeline );
			if ( pipeline is ComputePipeline ) {
				pipeline.computeProgram.usedTimes --;
				if ( pipeline.computeProgram.usedTimes == 0 ) this._releaseProgram( pipeline.computeProgram );
			} 
      else if( pipeline is RenderPipeline ){
				pipeline.fragmentProgram.usedTimes --;
				pipeline.vertexProgram.usedTimes --;

				if ( pipeline.vertexProgram.usedTimes == 0 ) this._releaseProgram( pipeline.vertexProgram );
				if ( pipeline.fragmentProgram.usedTimes == 0 ) this._releaseProgram( pipeline.fragmentProgram );
			}
		}

		return super.delete( object );
	}

	void dispose() {
		super.dispose();

		this.caches = new Map();
		this.programs = {
			'vertex': new Map(),
			'fragment': new Map(),
			'compute': new Map()
		};

	}

	void updateForRender(RenderObject renderObject ) {
		this.getForRender( renderObject );
	}

	ComputePipeline _getComputePipeline(Node computeNode, ProgrammableStage stageCompute, String? cacheKey, List<BindGroup> bindings ) {
		cacheKey = cacheKey ?? this._getComputeCacheKey( computeNode, stageCompute );

		dynamic pipeline = this.caches[cacheKey];

		if ( pipeline == null ) {
			pipeline = new ComputePipeline( cacheKey, stageCompute );
			this.caches.set( cacheKey, pipeline );
			this.backend.createComputePipeline( pipeline, bindings );
		}

		return pipeline;
	}

	/**
	 * Returns a render pipeline for the given parameters.
	 *
	 * @private
	 * @param {RenderObject} renderObject - The render object.
	 * @param {ProgrammableStage} stageVertex - The programmable stage representing the vertex shader.
	 * @param {ProgrammableStage} stageFragment - The programmable stage representing the fragment shader.
	 * @param {string} cacheKey - The cache key.
	 * @param {?Array<Promise>} promises - An array of compilation promises which is only relevant in context of `Renderer.compileAsync()`.
	 * @return {ComputePipeline} The compute pipeline.
	 */
	_getRenderPipeline(RenderObject renderObject, ProgrammableStage stageVertex, ProgrammableStage stageFragment, [String? cacheKey, List? promises] ) {
		cacheKey = cacheKey ?? this._getRenderCacheKey( renderObject, stageVertex, stageFragment );
		dynamic pipeline = this.caches[cacheKey];

		if ( pipeline == null ) {
			pipeline = RenderPipeline( cacheKey, stageVertex, stageFragment );
			this.caches.set( cacheKey, pipeline );
			renderObject.pipeline = pipeline;

			// The `promises` array is `null` by default and only set to an empty array when
			// `Renderer.compileAsync()` is used. The next call actually fills the array with
			// pending promises that resolve when the render pipelines are ready for rendering.

			this.backend.createRenderPipeline( renderObject, promises );
		}

		return pipeline;
	}

	/**
	 * Computes a cache key representing a compute pipeline.
	 *
	 * @private
	 * @param {Node} computeNode - The compute node.
	 * @param {ProgrammableStage} stageCompute - The programmable stage representing the compute shader.
	 * @return {string} The cache key.
	 */
	String _getComputeCacheKey(Node computeNode, ProgrammableStage stageCompute ) {
		return computeNode.id + ',' + stageCompute.id;
	}

	/**
	 * Computes a cache key representing a render pipeline.
	 *
	 * @private
	 * @param {RenderObject} renderObject - The render object.
	 * @param {ProgrammableStage} stageVertex - The programmable stage representing the vertex shader.
	 * @param {ProgrammableStage} stageFragment - The programmable stage representing the fragment shader.
	 * @return {string} The cache key.
	 */
	String _getRenderCacheKey(RenderObject renderObject, ProgrammableStage stageVertex, ProgrammableStage stageFragment ) {
		return '${stageVertex.id},${stageFragment.id},${this.backend.getRenderCacheKey( renderObject )}';
	}

	/**
	 * Releases the given pipeline.
	 *
	 * @private
	 * @param {Pipeline} pipeline - The pipeline to release.
	 */
	void _releasePipeline(Pipeline pipeline ) {
		this.caches.remove( pipeline.cacheKey );
	}

	/**
	 * Releases the shader program.
	 *
	 * @private
	 * @param {Object} program - The shader program to release.
	 */
	void _releaseProgram(ProgrammableStage program ) {
		final code = program.code;
		final stage = program.stage;

		this.programs[ stage ]?.remove( code );
	}

	/**
	 * Returns `true` if the compute pipeline for the given compute node requires an update.
	 *
	 * @private
	 * @param {Node} computeNode - The compute node.
	 * @return {boolean} Whether the compute pipeline for the given compute node requires an update or not.
	 */
	bool _needsComputeUpdate(Node computeNode ) {
		final data = this.get( computeNode );
		return data.pipeline == null || data.version != computeNode.version;
	}

	/**
	 * Returns `true` if the render pipeline for the given render object requires an update.
	 *
	 * @private
	 * @param {RenderObject} renderObject - The render object.
	 * @return {boolean} Whether the render object for the given render object requires an update or not.
	 */
	bool _needsRenderUpdate(RenderObject renderObject ) {
		final data = this.get( renderObject );
		return data.pipeline == null || this.backend.needsRenderUpdate( renderObject );
	}
}
