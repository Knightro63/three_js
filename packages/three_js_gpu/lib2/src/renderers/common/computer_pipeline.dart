import './pipeline.dart'; // Holds the Base Pipeline class definition

/// Class for representing compute pipelines.
class ComputePipeline extends Pipeline {
  /// The pipeline's compute shader stage data.
  final dynamic computeProgram; // Maps to your ProgrammableStage wrapper

  /// This flag can be used for type testing.
  final bool isComputePipeline = true;

  /// Constructs a new compute pipeline container layout.
  /// 
  /// [cacheKey] - The pipeline's matching cache signature string.
  /// [computeProgram] - The pipeline's compute shader program module.
  ComputePipeline(String cacheKey, this.computeProgram) : super(cacheKey);
}
