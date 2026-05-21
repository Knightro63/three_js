import './programmable_stage.dart';
import './pipeline.dart';

class ComputePipeline extends Pipeline {
  ProgrammableStage computeProgram;
	ComputePipeline(super.cacheKey, this.computeProgram );
}
