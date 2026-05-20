/**
 * Reusable descriptor for `GPUDevice.createRenderBundleEncoder()`.
 *
 * @private
 */
class GPURenderBundleEncoderDescriptor {
	String label = '';
  List<String>? colorFormats;

  /**
   * The format of the depth/stencil attachment the bundle is compatible with.
   *
   * @type {string|undefined}
   */
  String? depthStencilFormat;

  /**
   * The number of samples per pixel the bundle is compatible with.
   *
   * @type {number}
   * @default 1
   */
  int sampleCount = 1;

  /**
   * Whether the depth attachment is read-only.
   *
   * @type {boolean}
   * @default false
   */
  bool depthReadOnly = false;

  /**
   * Whether the stencil attachment is read-only.
   *
   * @type {boolean}
   * @default false
   */
  bool stencilReadOnly = false;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.label = '';
		this.colorFormats = null;
		this.depthStencilFormat = null;
		this.sampleCount = 1;
		this.depthReadOnly = false;
		this.stencilReadOnly = false;
	}
}