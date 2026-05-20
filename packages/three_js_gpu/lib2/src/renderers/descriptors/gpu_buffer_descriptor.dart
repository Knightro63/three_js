/**
 * Reusable descriptor for `GPUDevice.createBuffer()`.
 *
 * @private
 */
class GPUBufferDescriptor {
  String label = '';
  int size = 0;
  int usage = 0;
  bool mappedAtCreation = false;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.label = '';
		this.size = 0;
		this.usage = 0;
		this.mappedAtCreation = false;
	}
}
