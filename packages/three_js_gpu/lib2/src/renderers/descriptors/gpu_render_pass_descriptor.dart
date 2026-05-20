/**
 * Reusable descriptor for `GPUCommandEncoder.beginRenderPass()`.
 *
 * @private
 */
class GPURenderPassDescriptor {
  /**
   * The label of the render pass.
   *
   * @type {string}
   */
  String label = '';

  /**
   * The color attachments of the render pass.
   *
   * @type {Array<?Object>}
   */
  List colorAttachments = [];

  /**
   * The depth-stencil attachment of the render pass.
   *
   * @type {Object|undefined}
   */
  Map<String,dynamic>? depthStencilAttachment;

  /**
   * The query set used for occlusion queries during the pass.
   *
   * @type {?GPUQuerySet|undefined}
   */
  GPUQuerySet? occlusionQuerySet;

  /**
   * Defines which timestamp values are written and where.
   *
   * @type {Object|undefined}
   */
  Map<String,dynamic>? timestampWrites;

  /**
   * The maximum number of draw calls that can be issued during the pass.
   *
   * @type {number}
   * @default 50000000
   */
  int maxDrawCount = 50000000;

	/**
	 * Resets the descriptor to its default state. The internal `colorAttachments`
	 * array is emptied without releasing its backing storage.
	 */
	void reset() {
		this.label = '';
		this.colorAttachments.length = 0;
		this.depthStencilAttachment = undefined;
		this.occlusionQuerySet = undefined;
		this.timestampWrites = undefined;
		this.maxDrawCount = 50000000;
	}
}
