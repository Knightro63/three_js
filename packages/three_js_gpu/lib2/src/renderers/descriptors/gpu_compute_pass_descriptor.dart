/**
 * Reusable descriptor for `GPUCommandEncoder.beginComputePass()`.
 *
 * @private
 */
class GPUComputePassDescriptor {
  String label = '';
  Map<String,dynamic>? timestampWrites;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.label = '';
		this.timestampWrites = null;
	}
}
