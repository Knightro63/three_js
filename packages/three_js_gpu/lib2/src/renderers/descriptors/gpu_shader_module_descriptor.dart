/**
 * Reusable descriptor for `GPUDevice.createShaderModule()`.
 *
 * @private
 */
class GPUShaderModuleDescriptor {
  /**
   * The label of the shader module.
   *
   * @type {string}
   */
  String label = '';

  /**
   * The WGSL source code of the shader module.
   *
   * @type {string}
   */
  String code = '';

  /**
   * Compilation hints that may help the implementation produce optimized code.
   *
   * @type {Array<Object>}
   */
  List compilationHints = [];

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.label = '';
		this.code = '';
		this.compilationHints.length = 0;
	}
}
