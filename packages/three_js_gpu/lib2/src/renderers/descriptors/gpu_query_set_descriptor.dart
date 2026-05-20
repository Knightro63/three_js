/**
 * Reusable descriptor for `GPUDevice.createQuerySet()`.
 *
 * @private
 */
class GPUQuerySetDescriptor {
  String label = '';
  String? type;
  int count = 0;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.label = '';
		this.type = null;
		this.count = 0;
	}
}
