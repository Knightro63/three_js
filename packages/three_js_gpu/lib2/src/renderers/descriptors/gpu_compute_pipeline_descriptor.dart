/**
 * Reusable descriptor for `GPUDevice.createComputePipeline()`.
 *
 * @private
 */
class GPUComputePipelineDescriptor {
  String label = '';
  GPUPipelineLayout? layout = null;
  Map<String,dynamic>? compute;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.label = '';
		this.layout = null;
		this.compute = null;
	}
}
