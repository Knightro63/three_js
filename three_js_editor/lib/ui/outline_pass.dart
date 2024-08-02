import 'package:three_js_postprocessing/three_js_postprocessing.dart';
import 'package:three_js/three_js.dart';
import 'dart:math' as math;



class OutlinePass extends Pass {
  static Vector2 BlurDirectionX = Vector2( 1.0, 0.0 );
  static Vector2 BlurDirectionY = Vector2( 0.0, 1.0 );

  late Scene renderScene;
  late Camera renderCamera;
  late List<Object3D> selectedObjects;
  Color visibleEdgeColor = Color( 1, 1, 1 );
  Color hiddenEdgeColor = Color( 0.1, 0.04, 0.02 );
  double edgeGlow = 0.0;
  bool usePatternTexture = false;
  double edgeThickness = 1.0;
  double edgeStrength = 3.0;
  double downSampleRatio = 2;
  int pulsePeriod = 0;
  final Map _visibilityCache = {};
  MeshDepthMaterial depthMaterial = MeshDepthMaterial();
  late Vector2 resolution;
  late WebGLRenderTarget renderTargetMaskBuffer;
  late WebGLRenderTarget renderTargetDepthBuffer;
  late WebGLRenderTarget renderTargetMaskDownSampleBuffer;
  late WebGLRenderTarget renderTargetBlurBuffer1;
  late WebGLRenderTarget renderTargetBlurBuffer2;
  late WebGLRenderTarget renderTargetEdgeBuffer1;
  late WebGLRenderTarget renderTargetEdgeBuffer2;
  late ShaderMaterial prepareMaskMaterial;
  late ShaderMaterial separableBlurMaterial1;
  late ShaderMaterial edgeDetectionMaterial;
  late ShaderMaterial separableBlurMaterial2;
  late ShaderMaterial materialCopy;
  late ShaderMaterial overlayMaterial;
  late Map<String, dynamic> copyUniforms;

	Color _oldClearColor = Color();
	double oldClearAlpha = 1;
	Color tempPulseColor1 = Color();
	Color tempPulseColor2 = Color();
	Matrix4 textureMatrix = Matrix4();

  Texture? patternTexture;

	OutlinePass(Vector2? resolution, Scene scene, Camera camera, [List<Object3D>? selectedObjects ]):super(){
		renderScene = scene;
		renderCamera = camera;
		this.selectedObjects = selectedObjects ?? [];


		this.resolution = ( resolution != null ) ? Vector2( resolution.x, resolution.y ) : Vector2( 256, 256 );

		final resx = ( this.resolution.x / downSampleRatio ).round();
		final resy = ( this.resolution.y / downSampleRatio ).round();

		renderTargetMaskBuffer = WebGLRenderTarget( this.resolution.x.toInt(), this.resolution.y.toInt() );
		renderTargetMaskBuffer.texture.name = 'OutlinePass.mask';
		renderTargetMaskBuffer.texture.generateMipmaps = false;

		depthMaterial.side = DoubleSide;
		depthMaterial.depthPacking = RGBADepthPacking;
		depthMaterial.blending = NoBlending;

		prepareMaskMaterial = getPrepareMaskMaterial();
		prepareMaskMaterial.side = DoubleSide;
		prepareMaskMaterial.fragmentShader = _replaceDepthToViewZ(prepareMaskMaterial.fragmentShader,renderCamera );

		renderTargetDepthBuffer = WebGLRenderTarget( this.resolution.x.toInt(), this.resolution.y.toInt(), WebGLRenderTargetOptions({ 'type': HalfFloatType }) );
		renderTargetDepthBuffer.texture.name = 'OutlinePass.depth';
		renderTargetDepthBuffer.texture.generateMipmaps = false;

		renderTargetMaskDownSampleBuffer = WebGLRenderTarget( resx, resy, WebGLRenderTargetOptions({ 'type': HalfFloatType }));
		renderTargetMaskDownSampleBuffer.texture.name = 'OutlinePass.depthDownSample';
		renderTargetMaskDownSampleBuffer.texture.generateMipmaps = false;

		renderTargetBlurBuffer1 = WebGLRenderTarget( resx, resy, WebGLRenderTargetOptions({ 'type': HalfFloatType }));
		renderTargetBlurBuffer1.texture.name = 'OutlinePass.blur1';
		renderTargetBlurBuffer1.texture.generateMipmaps = false;
		renderTargetBlurBuffer2 = WebGLRenderTarget(( resx / 2 ).round(), ( resy / 2 ).round(), WebGLRenderTargetOptions({ 'type': HalfFloatType }));
		renderTargetBlurBuffer2.texture.name = 'OutlinePass.blur2';
		renderTargetBlurBuffer2.texture.generateMipmaps = false;

		edgeDetectionMaterial = getEdgeDetectionMaterial();
		renderTargetEdgeBuffer1 = WebGLRenderTarget( resx, resy, WebGLRenderTargetOptions({ 'type': HalfFloatType }));
		renderTargetEdgeBuffer1.texture.name = 'OutlinePass.edge1';
		renderTargetEdgeBuffer1.texture.generateMipmaps = false;
		renderTargetEdgeBuffer2 = WebGLRenderTarget( ( resx / 2 ).round(), ( resy / 2 ).round(), WebGLRenderTargetOptions({ 'type': HalfFloatType }));
		renderTargetEdgeBuffer2.texture.name = 'OutlinePass.edge2';
		renderTargetEdgeBuffer2.texture.generateMipmaps = false;

		const MAX_EDGE_THICKNESS = 4.0;
		const MAX_EDGE_GLOW = 4.0;

		separableBlurMaterial1 = getSeperableBlurMaterial( MAX_EDGE_THICKNESS );
		separableBlurMaterial1.uniforms[ 'texSize' ]['value'].setValues( resx.toDouble(), resy.toDouble() );
		separableBlurMaterial1.uniforms[ 'kernelRadius' ]['value'] = 1.0;
		separableBlurMaterial2 = getSeperableBlurMaterial( MAX_EDGE_GLOW );
		separableBlurMaterial2.uniforms[ 'texSize' ]['value'].setValues( ( resx / 2 ).roundToDouble(), ( resy / 2 ).roundToDouble() );
		separableBlurMaterial2.uniforms[ 'kernelRadius' ]['value'] = MAX_EDGE_GLOW;

		// Overlay material
		overlayMaterial = getOverlayMaterial();

		// copy material

		//final copyShader = CopyShader;

		copyUniforms = UniformsUtils.clone( copyShader['uniforms'] );

		materialCopy = ShaderMaterial.fromMap( {
			'uniforms': copyUniforms,
			'vertexShader': copyShader['vertexShader'],
			'fragmentShader': copyShader['fragmentShader'],
			'blending': NoBlending,
			'depthTest': false,
			'depthWrite': false
		} );

		enabled = true;
		needsSwap = false;
		fsQuad = FullScreenQuad( );
	}

  String? _replaceDepthToViewZ(String? string, Camera camera ) {
    final type = camera is PerspectiveCamera ? 'perspective' : 'orthographic';
    return string?.replaceAll( 'DEPTH_TO_VIEW_Z',  '${type}DepthToViewZ' );
  }

	void dispose() {
		renderTargetMaskBuffer.dispose();
		renderTargetDepthBuffer.dispose();
		renderTargetMaskDownSampleBuffer.dispose();
		renderTargetBlurBuffer1.dispose();
		renderTargetBlurBuffer2.dispose();
		renderTargetEdgeBuffer1.dispose();
		renderTargetEdgeBuffer2.dispose();

		depthMaterial.dispose();
		prepareMaskMaterial.dispose();
		edgeDetectionMaterial.dispose();
		separableBlurMaterial1.dispose();
		separableBlurMaterial2.dispose();
		overlayMaterial.dispose();
		materialCopy.dispose();
		fsQuad.dispose();
	}

  @override
	void setSize(int width,int height ) {
		renderTargetMaskBuffer.setSize( width, height );
		renderTargetDepthBuffer.setSize( width, height );

		int resx = ( width / downSampleRatio ).round();
		int resy = ( height / downSampleRatio ).round();
		renderTargetMaskDownSampleBuffer.setSize( resx, resy );
		renderTargetBlurBuffer1.setSize( resx, resy );
		renderTargetEdgeBuffer1.setSize( resx, resy );
		separableBlurMaterial1.uniforms[ 'texSize' ]['value'].setValues( resx.toDouble(), resy.toDouble() );

		resx = ( resx / 2 ).round();
		resy = ( resy / 2 ).round();

		renderTargetBlurBuffer2.setSize( resx, resy );
		renderTargetEdgeBuffer2.setSize( resx, resy );

		separableBlurMaterial2.uniforms[ 'texSize' ]['value'].setValues( resx.toDouble(), resy.toDouble() );
	}

	void changeVisibilityOfSelectedObjects(bool bVisible ) {
		final cache = _visibilityCache;

		void gatherSelectedMeshesCallBack( object ) {
			if ( object is Mesh ) {
				if ( bVisible == true ) {
					object.visible = cache[object];
				} 
        else {
					cache[object] = object.visible;
					object.visible = bVisible;
				}
			}
		}

		for (int i = 0; i < selectedObjects.length; i ++ ) {
			final selectedObject = selectedObjects[ i ];
			selectedObject.traverse( gatherSelectedMeshesCallBack );
		}
	}

	changeVisibilityOfNonSelectedObjects( bVisible ) {
		final cache = _visibilityCache;
		final selectedMeshes = [];

		void gatherSelectedMeshesCallBack( object ) {
			if ( object is Mesh ) selectedMeshes.add( object );
		}

		for ( int i = 0; i < selectedObjects.length; i ++ ) {
			final selectedObject = selectedObjects[ i ];
			selectedObject.traverse( gatherSelectedMeshesCallBack );
		}

		void VisibilityChangeCallBack(Object3D object ) {

			if ( object is Mesh || object is Sprite ) {

				// only meshes and sprites are supported by OutlinePass

				bool bFound = false;

				for (int i = 0; i < selectedMeshes.length; i ++ ) {
					final selectedObjectId = selectedMeshes[ i ].id;

					if ( selectedObjectId == object.id ) {
						bFound = true;
						break;
					}
				}

				if ( bFound == false ) {
					final visibility = object.visible;
					if ( bVisible == false || cache[object] == true ) {
						object.visible = bVisible;
					}

					cache[object] = visibility;
				}

			} 
      else if ( object is Points || object is Line ) {

				// the visibilty of points and lines is always set to false in order to
				// not affect the outline computation

				if ( bVisible == true ) {
					object.visible = cache[object]; // restore
				} else {
					cache[object] = object.visible;
					object.visible = bVisible;
				}
			}
		}

		renderScene.traverse( VisibilityChangeCallBack );
	}

	void updateTextureMatrix() {
		textureMatrix.setValues( 0.5, 0.0, 0.0, 0.5,
			0.0, 0.5, 0.0, 0.5,
			0.0, 0.0, 0.5, 0.5,
			0.0, 0.0, 0.0, 1.0 );
		textureMatrix.multiply( renderCamera.projectionMatrix );
		textureMatrix.multiply( renderCamera.matrixWorldInverse );
	}

	void render(WebGLRenderer renderer, writeBuffer, readBuffer, {double? deltaTime,bool? maskActive }) {
    maskActive ??= false;
		if (selectedObjects.isNotEmpty) {

			renderer.getClearColor( _oldClearColor );
			oldClearAlpha = renderer.getClearAlpha();
			final oldAutoClear = renderer.autoClear;

			renderer.autoClear = false;

			if ( maskActive ) renderer.state.buffers['stencil'].setTest( false );

			renderer.setClearColor(Color.fromHex32(0xffffff), 1 );

			// Make selected objects invisible
			changeVisibilityOfSelectedObjects( false );

			final currentBackground = renderScene.background;
			renderScene.background = null;

			// 1. Draw Non Selected objects in the depth buffer
			renderScene.overrideMaterial = depthMaterial;
			renderer.setRenderTarget( renderTargetDepthBuffer );
			renderer.clear();
			renderer.render( renderScene, renderCamera );

			// Make selected objects visible
			changeVisibilityOfSelectedObjects( true );
			_visibilityCache.clear();

			// Update Texture Matrix for Depth compare
			updateTextureMatrix();

			// Make non selected objects invisible, and draw only the selected objects, by comparing the depth buffer of non selected objects
			changeVisibilityOfNonSelectedObjects( false );
			renderScene.overrideMaterial = prepareMaskMaterial;
			prepareMaskMaterial.uniforms[ 'cameraNearFar' ]['value'].setValues( renderCamera.near, renderCamera.far );
			prepareMaskMaterial.uniforms[ 'depthTexture' ]['value'] = renderTargetDepthBuffer.texture;
			prepareMaskMaterial.uniforms[ 'textureMatrix' ]['value'] = textureMatrix;
			renderer.setRenderTarget( renderTargetMaskBuffer );
			renderer.clear();
			renderer.render( renderScene, renderCamera );
			renderScene.overrideMaterial = null;
			changeVisibilityOfNonSelectedObjects( true );
			_visibilityCache.clear();

			renderScene.background = currentBackground;

			// 2. Downsample to Half resolution
			fsQuad.material = materialCopy;
			copyUniforms[ 'tDiffuse' ]['value'] = renderTargetMaskBuffer.texture;
			renderer.setRenderTarget( renderTargetMaskDownSampleBuffer );
			renderer.clear();
			fsQuad.render( renderer );

			tempPulseColor1.setFrom( visibleEdgeColor );
			tempPulseColor2.setFrom( hiddenEdgeColor );

			if ( pulsePeriod > 0 ) {
				final scalar = ( 1 + 0.25 ) / 2 + math.cos( DateTime.now().millisecondsSinceEpoch * 0.01 / pulsePeriod ) * ( 1.0 - 0.25 ) / 2;
				tempPulseColor1.scale( scalar );
				tempPulseColor2.scale( scalar );
			}

			// 3. Apply Edge Detection Pass
			fsQuad.material = edgeDetectionMaterial;
			edgeDetectionMaterial.uniforms[ 'maskTexture' ]['value'] = renderTargetMaskDownSampleBuffer.texture;
			edgeDetectionMaterial.uniforms[ 'texSize' ]['value'].setValues( renderTargetMaskDownSampleBuffer.width.toDouble(), renderTargetMaskDownSampleBuffer.height.toDouble() );
			edgeDetectionMaterial.uniforms[ 'visibleEdgeColor' ]['value'] = tempPulseColor1;
			edgeDetectionMaterial.uniforms[ 'hiddenEdgeColor' ]['value'] = tempPulseColor2;
			renderer.setRenderTarget( renderTargetEdgeBuffer1 );
			renderer.clear();
			fsQuad.render( renderer );

			// 4. Apply Blur on Half res
			fsQuad.material = separableBlurMaterial1;
			separableBlurMaterial1.uniforms[ 'colorTexture' ]['value'] = renderTargetEdgeBuffer1.texture;
			separableBlurMaterial1.uniforms[ 'direction' ]['value'] = OutlinePass.BlurDirectionX;
			separableBlurMaterial1.uniforms[ 'kernelRadius' ]['value'] = edgeThickness;
			renderer.setRenderTarget( renderTargetBlurBuffer1 );
			renderer.clear();
			fsQuad.render( renderer );
			separableBlurMaterial1.uniforms[ 'colorTexture' ]['value'] = renderTargetBlurBuffer1.texture;
			separableBlurMaterial1.uniforms[ 'direction' ]['value'] = OutlinePass.BlurDirectionY;
			renderer.setRenderTarget( renderTargetEdgeBuffer1 );
			renderer.clear();
			fsQuad.render( renderer );

			// Apply Blur on quarter res
			fsQuad.material = separableBlurMaterial2;
			separableBlurMaterial2.uniforms[ 'colorTexture' ]['value'] = renderTargetEdgeBuffer1.texture;
			separableBlurMaterial2.uniforms[ 'direction' ]['value'] = OutlinePass.BlurDirectionX;
			renderer.setRenderTarget( renderTargetBlurBuffer2 );
			renderer.clear();
			fsQuad.render( renderer );
			separableBlurMaterial2.uniforms[ 'colorTexture' ]['value'] = renderTargetBlurBuffer2.texture;
			separableBlurMaterial2.uniforms[ 'direction' ]['value'] = OutlinePass.BlurDirectionY;
			renderer.setRenderTarget( renderTargetEdgeBuffer2 );
			renderer.clear();
			fsQuad.render( renderer );

			// Blend it additively over the input texture
			fsQuad.material = overlayMaterial;
			overlayMaterial.uniforms[ 'maskTexture' ]['value'] = renderTargetMaskBuffer.texture;
			overlayMaterial.uniforms[ 'edgeTexture1' ]['value'] = renderTargetEdgeBuffer1.texture;
			overlayMaterial.uniforms[ 'edgeTexture2' ]['value'] = renderTargetEdgeBuffer2.texture;
			overlayMaterial.uniforms[ 'patternTexture' ]['value'] = null;//patternTexture;
			overlayMaterial.uniforms[ 'edgeStrength' ]['value'] = edgeStrength;
			overlayMaterial.uniforms[ 'edgeGlow' ]['value'] = edgeGlow;
			overlayMaterial.uniforms[ 'usePatternTexture' ]['value'] = usePatternTexture;


			if ( maskActive ) renderer.state.buffers['stencil'].setTest( true );

			renderer.setRenderTarget( readBuffer );
			fsQuad.render( renderer );

			renderer.setClearColor( _oldClearColor, oldClearAlpha );
			renderer.autoClear = oldAutoClear;
		}

		if ( renderToScreen ) {
			fsQuad.material = materialCopy;
			copyUniforms[ 'tDiffuse' ]['value'] = readBuffer.texture;
			renderer.setRenderTarget( null );
			fsQuad.render( renderer );
		}
	}

	ShaderMaterial getPrepareMaskMaterial() {
		return ShaderMaterial.fromMap( {
			'uniforms': <String,dynamic>{
				'depthTexture': <String,dynamic>{ 'value': null },
				'cameraNearFar': { 'value': Vector2( 0.5, 0.5 ) },
				'textureMatrix': <String,dynamic>{ 'value': null }
			},

			'vertexShader':
				'''#include <morphtarget_pars_vertex>
				#include <skinning_pars_vertex>

				varying vec4 projTexCoord;
				varying vec4 vPosition;
				uniform mat4 textureMatrix;

				void main() {

					#include <skinbase_vertex>
					#include <begin_vertex>
					#include <morphtarget_vertex>
					#include <skinning_vertex>
					#include <project_vertex>

					vPosition = mvPosition;

					vec4 worldPosition = vec4( transformed, 1.0 );

					#ifdef USE_INSTANCING

						worldPosition = instanceMatrix * worldPosition;

					#endif
					
					worldPosition = modelMatrix * worldPosition;

					projTexCoord = textureMatrix * worldPosition;

				}''',

			'fragmentShader':
				'''#include <packing>
				varying vec4 vPosition;
				varying vec4 projTexCoord;
				uniform sampler2D depthTexture;
				uniform vec2 cameraNearFar;

				void main() {

					float depth = unpackRGBAToDepth(texture2DProj( depthTexture, projTexCoord ));
					float viewZ = - DEPTH_TO_VIEW_Z( depth, cameraNearFar.x, cameraNearFar.y );
					float depthTest = (-vPosition.z > viewZ) ? 1.0 : 0.0;
					gl_FragColor = vec4(0.0, depthTest, 1.0, 1.0);

				}'''
		} );

	}

	ShaderMaterial getEdgeDetectionMaterial() {
		return ShaderMaterial.fromMap( {
			'uniforms': <String,dynamic>{
				'maskTexture': <String,dynamic>{ 'value': null },
				'texSize': { 'value': Vector2( 0.5, 0.5 ) },
				'visibleEdgeColor': { 'value': Color( 1.0, 1.0, 1.0 ) },
				'hiddenEdgeColor': { 'value': Color( 1.0, 1.0, 1.0 ) },
			},

			'vertexShader':
				'''varying vec2 vUv;

				void main() {
					vUv = uv;
					gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
				}''',

			'fragmentShader':
				'''varying vec2 vUv;

				uniform sampler2D maskTexture;
				uniform vec2 texSize;
				uniform vec3 visibleEdgeColor;
				uniform vec3 hiddenEdgeColor;

				void main() {
					vec2 invSize = 1.0 / texSize;
					vec4 uvOffset = vec4(1.0, 0.0, 0.0, 1.0) * vec4(invSize, invSize);
					vec4 c1 = texture2D( maskTexture, vUv + uvOffset.xy);
					vec4 c2 = texture2D( maskTexture, vUv - uvOffset.xy);
					vec4 c3 = texture2D( maskTexture, vUv + uvOffset.yw);
					vec4 c4 = texture2D( maskTexture, vUv - uvOffset.yw);
					float diff1 = (c1.r - c2.r)*0.5;
					float diff2 = (c3.r - c4.r)*0.5;
					float d = length( vec2(diff1, diff2) );
					float a1 = min(c1.g, c2.g);
					float a2 = min(c3.g, c4.g);
					float visibilityFactor = min(a1, a2);
					vec3 edgeColor = 1.0 - visibilityFactor > 0.001 ? visibleEdgeColor : hiddenEdgeColor;
					gl_FragColor = vec4(edgeColor, 1.0) * vec4(d);
				}'''
		} );

	}

	ShaderMaterial getSeperableBlurMaterial(double maxRadius ) {
		return ShaderMaterial.fromMap( {

			'defines': <String,dynamic>{
				'MAX_RADIUS': maxRadius,
			},

			'uniforms': <String,dynamic>{
				'colorTexture':  <String,dynamic>{ 'value': null },
				'texSize': { 'value': Vector2( 0.5, 0.5 ) },
				'direction': { 'value': Vector2( 0.5, 0.5 ) },
				'kernelRadius': { 'value': 1.0 }
			},

			'vertexShader':
				'''varying vec2 vUv;

				void main() {
					vUv = uv;
					gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
				}''',

			'fragmentShader':
				'''#include <common>
				varying vec2 vUv;
				uniform sampler2D colorTexture;
				uniform vec2 texSize;
				uniform vec2 direction;
				uniform float kernelRadius;

				float gaussianPdf(in float x, in float sigma) {
					return 0.39894 * exp( -0.5 * x * x/( sigma * sigma))/sigma;
				}

				void main() {
					vec2 invSize = 1.0 / texSize;
					float sigma = kernelRadius/2.0;
					float weightSum = gaussianPdf(0.0, sigma);
					vec4 diffuseSum = texture2D( colorTexture, vUv) * weightSum;
					vec2 delta = direction * invSize * kernelRadius/float(MAX_RADIUS);
					vec2 uvOffset = delta;
					for( int i = 1; i <= MAX_RADIUS; i ++ ) {
						float x = kernelRadius * float(i) / float(MAX_RADIUS);
						float w = gaussianPdf(x, sigma);
						vec4 sample1 = texture2D( colorTexture, vUv + uvOffset);
						vec4 sample2 = texture2D( colorTexture, vUv - uvOffset);
						diffuseSum += ((sample1 + sample2) * w);
						weightSum += (2.0 * w);
						uvOffset += delta;
					}
					gl_FragColor = diffuseSum/weightSum;
				}'''
		} );

	}

	ShaderMaterial getOverlayMaterial() {
		return ShaderMaterial.fromMap( {
			'uniforms': <String,dynamic>{
				'maskTexture': <String,dynamic>{ 'value': null },
				'edgeTexture1': <String,dynamic>{ 'value': null },
				'edgeTexture2': <String,dynamic>{ 'value': null },
				'patternTexture': <String,dynamic>{ 'value': null },
				'edgeStrength': { 'value': 1.0 },
				'edgeGlow': { 'value': 1.0 },
				'usePatternTexture': { 'value': 0.0 }
			},

			'vertexShader':
				'''varying vec2 vUv;

				void main() {
					vUv = uv;
					gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
				}''',

			'fragmentShader':
				'''varying vec2 vUv;

				uniform sampler2D maskTexture;
				uniform sampler2D edgeTexture1;
				uniform sampler2D edgeTexture2;
				uniform sampler2D patternTexture;
				uniform float edgeStrength;
				uniform float edgeGlow;
				uniform bool usePatternTexture;

				void main() {
					vec4 edgeValue1 = texture2D(edgeTexture1, vUv);
					vec4 edgeValue2 = texture2D(edgeTexture2, vUv);
					vec4 maskColor = texture2D(maskTexture, vUv);
					vec4 patternColor = texture2D(patternTexture, 6.0 * vUv);
					float visibilityFactor = 1.0 - maskColor.g > 0.0 ? 1.0 : 0.5;
					vec4 edgeValue = edgeValue1 + edgeValue2 * edgeGlow;
					vec4 finalColor = edgeStrength * maskColor.r * edgeValue;
					if(usePatternTexture)
						finalColor += + visibilityFactor * (1.0 - maskColor.r) * (1.0 - patternColor.r);
					gl_FragColor = finalColor;
				}''',
			'blending': AdditiveBlending,
			'depthTest': false,
			'depthWrite': false,
			'transparent': true
		});
	}
}

