/**
 * Reusable descriptor for `GPUDevice.createTexture()`.
 *
 * @private
 */
class GPUTextureDescriptor {
  /**
   * The label of the texture.
   *
   * @type {string}
   */
  String label = '';

  /**
   * The size of the texture.
   *
   * @type {{width: number, height: number, depthOrArrayLayers: number}}
   */
  Map<String,dynamic> size = { 'width': 0, 'height': 1, 'depthOrArrayLayers': 1 };

  /**
   * The number of mip levels the texture will contain.
   *
   * @type {number}
   * @default 1
   */
  int mipLevelCount = 1;

  /**
   * The sample count of the texture.
   *
   * @type {number}
   * @default 1
   */
  int sampleCount = 1;

  /**
   * The dimension of the set of texel coordinates.
   *
   * @type {string}
   * @default '2d'
   */
  String dimension = '2d';

  /**
   * The format of the texture.
   *
   * @type {string|undefined}
   */
  String? format;

  /**
   * The allowed usages for the texture.
   *
   * @type {number|undefined}
   */
  int? usage;

  /**
   * The formats that views of this texture may use.
   *
   * @type {Array<string>}
   */
  List<String> viewFormats = [];

  /**
   * The view dimension to use when binding the texture (compatibility mode).
   *
   * @type {string|undefined}
   */
  String? textureBindingViewDimension;


	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.label = '';
		this.size['width'] = 0;
		this.size['height'] = 1;
		this.size['depthOrArrayLayers'] = 1;
		this.mipLevelCount = 1;
		this.sampleCount = 1;
		this.dimension = '2d';
		this.format = null;
		this.usage = null;
		this.viewFormats.length = 0;
		this.textureBindingViewDimension = null;
	}
}
