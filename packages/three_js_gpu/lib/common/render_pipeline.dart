import "./programmable_stage.dart";
import "./pipeline.dart";

class RenderPipeline extends Pipeline {
  ProgrammableStage vertexProgram;
  ProgrammableStage fragmentProgram;
	RenderPipeline(super.cacheKey, this.vertexProgram, this.fragmentProgram );
}