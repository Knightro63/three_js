/**
 * Reusable descriptor for `GPUTexture.createView()`.
 *
 * @private
 */
class GPUTextureViewDescriptor {
  /**
   * The label of the texture view.
   *
   * @type {string}
   */
  String label = '';

  /**
   * The format of the texture view.
   *
   * @type {string|undefined}
   */
  String? format;

  /**
   * The dimension of the texture view.
   *
   * @type {string|undefined}
   */
  String? dimension;

  /**
   * The allowed usages for the texture view.
   *
   * @type {number}
   * @default 0
   */
  int usage = 0;

  /**
   * Which aspect of the texture is referenced.
   *
   * @type {string}
   * @default 'all'
   */
  String aspect = 'all';

  /**
   * The first mip level accessible to the texture view.
   *
   * @type {number}
   * @default 0
   */
  int baseMipLevel = 0;

  /**
   * The number of mip levels accessible to the texture view.
   *
   * @type {number|undefined}
   */
  int? mipLevelCount;

  /**
   * The first array layer accessible to the texture view.
   *
   * @type {number}
   * @default 0
   */
  int baseArrayLayer = 0;

  /**
   * The number of array layers accessible to the texture view.
   *
   * @type {number|undefined}
   */
  int? arrayLayerCount;

  /**
   * The component swizzle to apply when sampling the texture view.
   * Requires the `'texture-component-swizzle'` feature; ignored otherwise.
   *
   * @type {string}
   * @default 'rgba'
   */
  String swizzle = 'rgba';

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.label = '';
		this.format = null;
		this.dimension = null;
		this.usage = 0;
		this.aspect = 'all';
		this.baseMipLevel = 0;
		this.mipLevelCount = null;
		this.baseArrayLayer = 0;
		this.arrayLayerCount = null;
		this.swizzle = 'rgba';
	}
}
