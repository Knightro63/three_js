import 'backend.dart';
import 'bind_group.dart';
import 'bindings.dart';
import 'compute_pipeline.dart';
import 'data_map.dart';
import 'nodes/nodes.dart';
import 'pipeline.dart';
import 'programmable_stage.dart';
import 'render_object.dart';
import 'render_pipeline.dart';
import '../../nodes/core/node.dart';

/// This renderer module manages the pipelines of the renderer.
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

	getForCompute(Node computeNode, List<BindGroup> bindings ) {
		final backend = this.backend;

		final data = get( computeNode );

		if ( _needsComputeUpdate( computeNode ) ) {
			final previousPipeline = data.pipeline;
			if ( previousPipeline != null) {
				previousPipeline.usedTimes --;
				previousPipeline.computeProgram.usedTimes --;
			}

			// get shader

			final nodeBuilderState = nodes.getForCompute( computeNode );

			// programmable stage

			ProgrammableStage? stageCompute = programs['compute']?[nodeBuilderState.computeShader];

			if ( stageCompute == null ) {
				if ( previousPipeline != null&& previousPipeline.computeProgram.usedTimes == 0 ) _releaseProgram( previousPipeline.computeProgram );
				stageCompute = ProgrammableStage( nodeBuilderState.computeShader, 'compute', computeNode.name, nodeBuilderState.transforms, nodeBuilderState.nodeAttributes );
				programs['compute']?[nodeBuilderState.computeShader] = stageCompute;
				backend.createProgram( stageCompute );
			}

			// determine compute pipeline

			final cacheKey = _getComputeCacheKey( computeNode, stageCompute );

			Pipeline? pipeline = caches[cacheKey];

			if ( pipeline == null ) {
				if ( previousPipeline && previousPipeline.usedTimes == 0 ) _releasePipeline( previousPipeline );
				pipeline = _getComputePipeline( computeNode, stageCompute, cacheKey, bindings );
			}

			// keep track of all used times
			pipeline.usedTimes ++;
			stageCompute.usedTimes ++;

			data.version = computeNode.version;
			data.pipeline = pipeline;
		}

		return data.pipeline;
	}

	RenderPipeline getForRender(RenderObject renderObject, [promises = null ]) {
		final backend = this.backend;
		final data = get( renderObject );

		if ( _needsRenderUpdate( renderObject ) ) {
			final previousPipeline = data.pipeline;

			if ( previousPipeline ) {
				previousPipeline.usedTimes --;
				previousPipeline.vertexProgram.usedTimes --;
				previousPipeline.fragmentProgram.usedTimes --;
			}

			// get shader

			final nodeBuilderState = renderObject.getNodeBuilderState();
			final name = renderObject.material != null? renderObject.material.name : '';

			// programmable stages

			dynamic stageVertex = programs['vertex']?[nodeBuilderState.vertexShader];

			if ( stageVertex == null ) {
				if ( previousPipeline && previousPipeline.vertexProgram.usedTimes == 0 ) _releaseProgram( previousPipeline.vertexProgram );
				stageVertex = ProgrammableStage( nodeBuilderState.vertexShader, 'vertex', name );
				programs['vertex']?[nodeBuilderState.vertexShader] = stageVertex;

				backend.createProgram( stageVertex );
			}
      
			dynamic stageFragment = programs['fragment']?[nodeBuilderState.fragmentShader];

			if ( stageFragment == null ) {
				if ( previousPipeline && previousPipeline.fragmentProgram.usedTimes == 0 ) _releaseProgram( previousPipeline.fragmentProgram );

				stageFragment = ProgrammableStage( nodeBuilderState.fragmentShader, 'fragment', name );
				programs['fragment']?[nodeBuilderState.fragmentShader] = stageFragment;

				backend.createProgram( stageFragment );
			}

			// determine render pipeline

			final cacheKey = _getRenderCacheKey( renderObject, stageVertex, stageFragment );

			Pipeline? pipeline = caches[cacheKey];

			if ( pipeline == null ) {
				if ( previousPipeline && previousPipeline.usedTimes == 0 ) _releasePipeline( previousPipeline );
				pipeline = _getRenderPipeline( renderObject, stageVertex, stageFragment, cacheKey, promises );
			} 
      else {
				renderObject.pipeline = pipeline;
			}

			// keep track of all used times
			pipeline.usedTimes ++;
			stageVertex.usedTimes ++;
			stageFragment.usedTimes ++;

			data.pipeline = pipeline;
		}

		return data.pipeline;
	}

	/// Deletes the pipeline for the given render object.
	Map? delete(RenderObject object ) {
		final Pipeline? pipeline = get( object ).pipeline;

		if ( pipeline != null) {
			pipeline.usedTimes --;

			if ( pipeline.usedTimes == 0 ) _releasePipeline( pipeline );
			if ( pipeline is ComputePipeline ) {
				pipeline.computeProgram.usedTimes --;
				if ( pipeline.computeProgram.usedTimes == 0 ) _releaseProgram( pipeline.computeProgram );
			} 
      else if( pipeline is RenderPipeline ){
				pipeline.fragmentProgram.usedTimes --;
				pipeline.vertexProgram.usedTimes --;

				if ( pipeline.vertexProgram.usedTimes == 0 ) _releaseProgram( pipeline.vertexProgram );
				if ( pipeline.fragmentProgram.usedTimes == 0 ) _releaseProgram( pipeline.fragmentProgram );
			}
		}

		return super.delete( object );
	}

  @override
	void dispose() {
		super.dispose();

		caches = {};
		programs = {
			'vertex': {},
			'fragment': {},
			'compute': {}
		};
	}

	void updateForRender(RenderObject renderObject ) {
		getForRender( renderObject );
	}

	ComputePipeline _getComputePipeline(Node computeNode, ProgrammableStage stageCompute, String? cacheKey, List<BindGroup> bindings ) {
		cacheKey = cacheKey ?? _getComputeCacheKey( computeNode, stageCompute );

		dynamic pipeline = caches[cacheKey];

		if ( pipeline == null ) {
			pipeline = ComputePipeline( cacheKey, stageCompute );
			caches[cacheKey] = pipeline;
			backend.createComputePipeline( pipeline, bindings );
		}

		return pipeline;
	}

	ComputePipeline _getRenderPipeline(RenderObject renderObject, ProgrammableStage stageVertex, ProgrammableStage stageFragment, [String? cacheKey, List? promises] ) {
		cacheKey = cacheKey ?? _getRenderCacheKey( renderObject, stageVertex, stageFragment );
		dynamic pipeline = caches[cacheKey];

		if ( pipeline == null ) {
			pipeline = RenderPipeline( cacheKey, stageVertex, stageFragment );
			caches[cacheKey] = pipeline;
			renderObject.pipeline = pipeline;

			// The `promises` array is `null` by default and only set to an empty array when
			// `Renderer.compileAsync()` is used. The next call actually fills the array with
			// pending promises that resolve when the render pipelines are ready for rendering.

			backend.createRenderPipeline( renderObject, promises );
		}

		return pipeline;
	}

	/// Computes a cache key representing a compute pipeline.
	String _getComputeCacheKey(Node computeNode, ProgrammableStage stageCompute ) {
		return '${computeNode.id},${stageCompute.id}';
	}

	/// Computes a cache key representing a render pipeline.
	String _getRenderCacheKey(RenderObject renderObject, ProgrammableStage stageVertex, ProgrammableStage stageFragment ) {
		return '${stageVertex.id},${stageFragment.id},${backend.getRenderCacheKey( renderObject )}';
	}

	void _releasePipeline(Pipeline pipeline ) {
		this.caches.remove( pipeline.cacheKey );
	}

	void _releaseProgram(ProgrammableStage program ) {
		final code = program.code;
		final stage = program.stage;

		programs[ stage ]?.remove( code );
	}

	bool _needsComputeUpdate(Node computeNode ) {
		final data = get( computeNode );
		return data.pipeline == null || data.version != computeNode.version;
	}

	bool _needsRenderUpdate(RenderObject renderObject ) {
		final data = get( renderObject );
		return data.pipeline == null || backend.needsRenderUpdate( renderObject );
	}
}
