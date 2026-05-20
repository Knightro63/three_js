/**
 * Reusable descriptor for `GPUDevice.createPipelineLayout()`.
 *
 * @private
 */
class GPUPipelineLayoutDescriptor {
  String label = '';
  List<GPUBindGroupLayout?>? bindGroupLayouts;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.label = '';
		this.bindGroupLayouts = null;
	}
}
