/**
 * Reusable descriptor for `GPURenderPassTimestampWrites`, the
 * `timestampWrites` field of `GPURenderPassDescriptor`. The same shape is
 * also accepted as `GPUComputePassTimestampWrites`.
 *
 * @private
 */
class GPURenderPassTimestampWrites {
  /**
   * The query set the timestamps are written to.
   *
   * @type {?GPUQuerySet}
   * @default null
   */
  GPUQuerySet? querySet;

  /**
   * The index in the query set the beginning timestamp is written to.
   *
   * @type {number|undefined}
   */
  int? beginningOfPassWriteIndex;

  /**
   * The index in the query set the ending timestamp is written to.
   *
   * @type {number|undefined}
   */
  int? endOfPassWriteIndex;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.querySet = null;
		this.beginningOfPassWriteIndex = null;
		this.endOfPassWriteIndex = null;
	}
}
