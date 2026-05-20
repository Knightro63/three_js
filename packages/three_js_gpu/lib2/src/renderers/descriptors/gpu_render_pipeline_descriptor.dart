/**
 * Reusable descriptor for `GPUDevice.createRenderPipeline()` and
 * `createRenderPipelineAsync()`.
 *
 * @private
 */
class GPURenderPipelineDescriptor {
  /**
   * The label of the render pipeline.
   *
   * @type {string}
   */
  String label = '';

  /**
   * The pipeline layout the pipeline conforms to, or `'auto'`.
   *
   * @type {?GPUPipelineLayout|string}
   * @default null
   */
  GPUPipelineLayout? layout;

  /**
   * The programmable vertex stage.
   *
   * @type {?Object}
   * @default null
   */
  Map<String,dynamic>? vertex;

  /**
   * The primitive-assembly state.
   *
   * @type {Object}
   */
  Map<String,dynamic> primitive = {};

  /**
   * The depth/stencil state, omitted when the pipeline has no depth or stencil aspect.
   *
   * @type {Object|undefined}
   */
  Map<String,dynamic>? depthStencil = null;

  /**
   * The multisample state.
   *
   * @type {GPUMultisampleState}
   */
  GPUMultisampleState multisample = new GPUMultisampleState();

  /**
   * The programmable fragment stage. Omitted for vertex-only pipelines.
   *
   * @type {?Object}
   * @default null
   */
  Map<String,dynamic>? fragment;

	/**
	 * Resets the descriptor to its default state.
	 */
	void reset() {
		this.label = '';
		this.layout = null;
		this.vertex = null;
		this.primitive = {};
		this.depthStencil = null;
		this.multisample.reset();
		this.fragment = null;
	}
}

/**
 * Reusable nested state for `GPURenderPipelineDescriptor.multisample`.
 *
 * @private
 */
class GPUMultisampleState {
  /**
   * The number of samples per pixel.
   *
   * @type {number}
   * @default 1
   */
  int count = 1;

  /**
   * A bitmask determining which samples are written to.
   *
   * @type {number}
   * @default 0xFFFFFFFF
   */
  int mask = 0xFFFFFFFF;

  /**
   * Whether a fragment's alpha channel is used to generate a sample coverage mask.
   *
   * @type {boolean}
   * @default false
   */
  bool alphaToCoverageEnabled = false;

	/**
	 * Resets the state to its default values.
	 */
	void reset() {
		this.count = 1;
		this.mask = 0xFFFFFFFF;
		this.alphaToCoverageEnabled = false;
	}
}
