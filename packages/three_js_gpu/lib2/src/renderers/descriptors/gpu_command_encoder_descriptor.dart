/**
 * Reusable descriptor for `GPUDevice.createCommandEncoder()`.
 *
 * @private
 */
class GPUCommandEncoderDescriptor {
	String label = '';

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.label = '';
	}
}
