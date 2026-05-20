/**
 * Reusable descriptor for `GPURenderPassColorAttachment`, the type of each
 * entry in `GPURenderPassDescriptor.colorAttachments`.
 *
 * @private
 */
class GPURenderPassColorAttachment {
  /**
   * The texture view the pass renders into.
   *
   * @type {?GPUTextureView}
   * @default null
   */
  GPUTextureView? view;

  /**
   * The depth slice the pass renders into.
   *
   * @type {number|undefined}
   */
  double? depthSlice;

  /**
   * The texture view that receives the resolved output of multisampled rendering.
   *
   * @type {?GPUTextureView|undefined}
   */
  GPUTextureView? resolveTarget;

  /**
   * The clear value used when `loadOp` is `'clear'`.
   *
   * @type {Object|undefined}
   */
  String? clearValue;

  /**
   * The load operation performed at the start of the pass.
   *
   * @type {string|undefined}
   */
  String? loadOp;

  /**
   * The store operation performed at the end of the pass.
   *
   * @type {string|undefined}
   */
  String? storeOp;

	/**
	 * Resets the descriptor to its default state.
	 */
	reset() {
		this.view = null;
		this.depthSlice = null;
		this.resolveTarget = null;
		this.clearValue = null;
		this.loadOp = null;
		this.storeOp = null;
	}
}
