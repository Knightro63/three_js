import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'dart:math' as math;

class TAARenderPass extends SSAARenderPass {
  int sampleLevel = 0;
  bool accumulate = false;
  int accumulateIndex = - 1;
  WebGLRenderTarget? _sampleRenderTarget;
  WebGLRenderTarget? _holdRenderTarget;
  late Map<String, dynamic> copyUniforms;
  Color _oldClearColor = Color(0, 0, 0);

	TAARenderPass(super.scene, super.camera, [super.clearColor, super.clearAlpha ]);

  @override
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, {num? deltaTime, bool? maskActive}) {

		if ( this.accumulate == false ) {
			super.render( renderer, writeBuffer, readBuffer, deltaTime: deltaTime );
			this.accumulateIndex = - 1;
			return;
		}

		final jitterOffsets = _JitterVectors[ 5 ];

		if ( this._sampleRenderTarget == null ) {
			this._sampleRenderTarget = new WebGLRenderTarget( readBuffer.width, readBuffer.height, WebGLRenderTargetOptions({'type': HalfFloatType}));
			this._sampleRenderTarget?.texture.name = 'TAARenderPass.sample';
		}

		if ( this._holdRenderTarget == null ) {
			this._holdRenderTarget = new WebGLRenderTarget( readBuffer.width, readBuffer.height, WebGLRenderTargetOptions({'type': HalfFloatType}));
			this._holdRenderTarget?.texture.name = 'TAARenderPass.hold';
		}

		if ( this.accumulateIndex == - 1 ) {
			super.render( renderer, this._holdRenderTarget!, readBuffer, deltaTime: deltaTime );
			this.accumulateIndex = 0;
		}

		final autoClear = renderer.autoClear;
		renderer.autoClear = false;

		renderer.getClearColor( this._oldClearColor );
		final oldClearAlpha = renderer.getClearAlpha();

		final sampleWeight = 1.0 / ( jitterOffsets.length );

		if ( this.accumulateIndex >= 0 && this.accumulateIndex < jitterOffsets.length ) {
			copyUniforms[ 'opacity' ]['value'] = sampleWeight;
			copyUniforms[ 'tDiffuse' ]['value'] = writeBuffer.texture;

			// render the scene multiple times, each slightly jitter offset from the last and accumulate the results.
			final numSamplesPerFrame = math.pow( 2, this.sampleLevel );
			for (int i = 0; i < numSamplesPerFrame; i ++ ) {

				final j = this.accumulateIndex;
				final jitterOffset = jitterOffsets[ j ];

				if ( camera is PerspectiveCamera ||  camera is OrthographicCamera) {
          dynamic c = camera;
					c.setViewOffset( readBuffer.width, readBuffer.height,
						jitterOffset[ 0 ] * 0.0625, jitterOffset[ 1 ] * 0.0625, // 0.0625 = 1 / 16
						readBuffer.width, readBuffer.height );
				}

				renderer.setRenderTarget( writeBuffer );
				renderer.setClearColor( this.clearColor, this.clearAlpha );
				renderer.clear();
				renderer.render( this.scene, this.camera );

				renderer.setRenderTarget( this._sampleRenderTarget );
				if ( this.accumulateIndex == 0 ) {
					renderer.setClearColor(Color.fromHex32(0x000000), 0.0 );
					renderer.clear();
				}

				this.fsQuad.render( renderer );

				this.accumulateIndex ++;

				if ( this.accumulateIndex >= jitterOffsets.length ) break;
			}

			if ( this.camera is PerspectiveCamera || this.camera is OrthographicCamera){
        dynamic c = camera;
        c.clearViewOffset();
      }
		}

		renderer.setClearColor( this.clearColor, this.clearAlpha );
		final accumulationWeight = this.accumulateIndex * sampleWeight;

		if ( accumulationWeight > 0 ) {
			copyUniforms[ 'opacity' ]['value'] = 1.0;
			copyUniforms[ 'tDiffuse' ]['value'] = this._sampleRenderTarget?.texture;
			renderer.setRenderTarget( writeBuffer );
			renderer.clear();
			this.fsQuad.render( renderer );
		}

		if ( accumulationWeight < 1.0 ) {
			copyUniforms[ 'opacity' ]['value'] = 1.0 - accumulationWeight;
			copyUniforms[ 'tDiffuse' ]['value'] = this._holdRenderTarget?.texture;
			renderer.setRenderTarget( writeBuffer );
			this.fsQuad.render( renderer );
		}

		renderer.autoClear = autoClear;
		renderer.setClearColor( this._oldClearColor, oldClearAlpha );

	}

	/**
	 * Frees the GPU-related resources allocated by this instance. Call this
	 * method whenever the pass is no longer used in your app.
	 */
  @override
	void dispose() {
		super.dispose();
		_holdRenderTarget?.dispose();
	}

}

const List<List<List<int>>> _JitterVectors = [
	[
		[ 0, 0 ]
	],
	[
		[ 4, 4 ], [ - 4, - 4 ]
	],
	[
		[ - 2, - 6 ], [ 6, - 2 ], [ - 6, 2 ], [ 2, 6 ]
	],
	[
		[ 1, - 3 ], [ - 1, 3 ], [ 5, 1 ], [ - 3, - 5 ],
		[ - 5, 5 ], [ - 7, - 1 ], [ 3, 7 ], [ 7, - 7 ]
	],
	[
		[ 1, 1 ], [ - 1, - 3 ], [ - 3, 2 ], [ 4, - 1 ],
		[ - 5, - 2 ], [ 2, 5 ], [ 5, 3 ], [ 3, - 5 ],
		[ - 2, 6 ], [ 0, - 7 ], [ - 4, - 6 ], [ - 6, 4 ],
		[ - 8, 0 ], [ 7, - 4 ], [ 6, 7 ], [ - 7, - 8 ]
	],
	[
		[ - 4, - 7 ], [ - 7, - 5 ], [ - 3, - 5 ], [ - 5, - 4 ],
		[ - 1, - 4 ], [ - 2, - 2 ], [ - 6, - 1 ], [ - 4, 0 ],
		[ - 7, 1 ], [ - 1, 2 ], [ - 6, 3 ], [ - 3, 3 ],
		[ - 7, 6 ], [ - 3, 6 ], [ - 5, 7 ], [ - 1, 7 ],
		[ 5, - 7 ], [ 1, - 6 ], [ 6, - 5 ], [ 4, - 4 ],
		[ 2, - 3 ], [ 7, - 2 ], [ 1, - 1 ], [ 4, - 1 ],
		[ 2, 1 ], [ 6, 2 ], [ 0, 4 ], [ 4, 4 ],
		[ 2, 5 ], [ 7, 5 ], [ 5, 6 ], [ 3, 7 ]
	]
];