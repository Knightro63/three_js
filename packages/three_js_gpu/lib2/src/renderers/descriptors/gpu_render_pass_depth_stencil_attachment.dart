/**
 * Reusable descriptor for `GPURenderPassDepthStencilAttachment`, the
 * `depthStencilAttachment` field of `GPURenderPassDescriptor`.
 *
 * @private
 */
class GPURenderPassDepthStencilAttachment {
  /**
   * The depth/stencil texture view the pass renders into.
   *
   * @type {?GPUTextureView}
   * @default null
   */
  GPUTextureView? view;

  /**
   * The load operation applied to the depth aspect at the start of the pass.
   *
   * @type {string|undefined}
   */
  String? depthLoadOp;

  /**
   * The store operation applied to the depth aspect at the end of the pass.
   *
   * @type {string|undefined}
   */
  String? depthStoreOp;

  /**
   * The clear value used when `depthLoadOp` is `'clear'`.
   *
   * @type {number|undefined}
   */
  double? depthClearValue;

  /**
   * Whether the depth aspect is read-only.
   *
   * @type {boolean}
   * @default false
   */
  bool depthReadOnly = false;

  /**
   * The load operation applied to the stencil aspect at the start of the pass.
   *
   * @type {string|undefined}
   */
  String? stencilLoadOp;

  /**
   * The store operation applied to the stencil aspect at the end of the pass.
   *
   * @type {string|undefined}
   */
  String? stencilStoreOp;

  /**
   * The clear value used when `stencilLoadOp` is `'clear'`.
   *
   * @type {number}
   * @default 0
   */
  double stencilClearValue = 0;

  /**
   * Whether the stencil aspect is read-only.
   *
   * @type {boolean}
   * @default false
   */
  bool stencilReadOnly = false;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.view = null;
		this.depthLoadOp = null;
		this.depthStoreOp = null;
		this.depthClearValue = null;
		this.depthReadOnly = false;
		this.stencilLoadOp = null;
		this.stencilStoreOp = null;
		this.stencilClearValue = 0;
		this.stencilReadOnly = false;
	}
}
