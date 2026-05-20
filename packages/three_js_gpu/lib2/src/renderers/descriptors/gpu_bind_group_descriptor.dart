/**
 * Reusable descriptor for `GPUDevice.createBindGroup()`.
 *
 * @private
 */
class GPUBindGroupDescriptor {
  String label = '';
  GPUBindGroupLayout? layout;
  List<Map<String, dynamic>> entries = [];

	/**
	 * Resets the descriptor to its default state. The internal `entries` array
	 * is emptied without releasing its backing storage.
	 */
	void reset() {
		this.label = '';
		this.layout = null;
		this.entries.clear();
	}
}
