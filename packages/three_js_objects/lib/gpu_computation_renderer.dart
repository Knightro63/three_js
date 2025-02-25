import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

/**
 * GPUComputationRenderer, based on SimulationRenderer by zz85
 *
 * The GPUComputationRenderer uses the concept of variables. These variables are RGBA float textures that hold 4 floats
 * for each compute element (texel)
 *
 * Each variable has a fragment shader that defines the computation made to obtain the variable in question.
 * You can use as many variables you need, and make dependencies so you can use textures of other variables in the shader
 * (the sampler uniforms are added automatically) Most of the variables will need themselves as dependency.
 *
 * The renderer has actually two render targets per variable, to make ping-pong. Textures from the current frame are used
 * as inputs to render the textures of the next frame.
 *
 * The render targets of the variables can be used as input textures for your visualization shaders.
 *
 * Variable names should be valid identifiers and should not collide with THREE GLSL used identifiers.
 * a common approach could be to use 'texture' prefixing the variable name; i.e texturePosition, textureVelocity...
 *
 * The size of the computation (sizeX * sizeY) is defined as 'resolution' automatically in the shader. For example:
 * #DEFINE resolution vec2( 1024.0, 1024.0 )
 *
 * -------------
 *
 * Basic use:
 *
 * // Initialization...
 *
 * // Create computation renderer
 * final gpuCompute = GPUComputationRenderer( 1024, 1024, renderer );
 *
 * // Create initial state float textures
 * final pos0 = gpuCompute.createTexture();
 * final vel0 = gpuCompute.createTexture();
 * // and fill in here the texture data...
 *
 * // Add texture variables
 * final velVar = gpuCompute.addVariable( "textureVelocity", fragmentShaderVel, pos0 );
 * final posVar = gpuCompute.addVariable( "texturePosition", fragmentShaderPos, vel0 );
 *
 * // Add variable dependencies
 * gpuCompute.setVariableDependencies( velVar, [ velVar, posVar ] );
 * gpuCompute.setVariableDependencies( posVar, [ velVar, posVar ] );
 *
 * // Add custom uniforms
 * velVar.material.uniforms.time = { value: 0.0 };
 *
 * // Check for completeness
 * final error = gpuCompute.init();
 * if ( error !== null ) {
 *		console.error( error );
  * }
 *
 *
 * // In each frame...
 *
 * // Compute!
 * gpuCompute.compute();
 *
 * // Update texture uniforms in your visualization materials with the gpu renderer output
 * myMaterial.uniforms.myTexture.value = gpuCompute.getCurrentRenderTarget( posVar ).texture;
 *
 * // Do your rendering
 * renderer.render( myScene, myCamera );
 *
 * -------------
 *
 * Also, you can use utility functions to create ShaderMaterial and perform computations (rendering between textures)
 * Note that the shaders can have multiple input textures.
 *
 * final myFilter1 = gpuCompute.createShaderMaterial( myFilterFragmentShader1, { theTexture: { value: null } } );
 * final myFilter2 = gpuCompute.createShaderMaterial( myFilterFragmentShader2, { theTexture: { value: null } } );
 *
 * final inputTexture = gpuCompute.createTexture();
 *
 * // Fill in here inputTexture...
 *
 * myFilter1.uniforms.theTexture.value = inputTexture;
 *
 * final myRenderTarget = gpuCompute.createRenderTarget();
 * myFilter2.uniforms.theTexture.value = myRenderTarget.texture;
 *
 * final outputRenderTarget = gpuCompute.createRenderTarget();
 *
 * // Now use the output texture where you want:
 * myMaterial.uniforms.map.value = outputRenderTarget.texture;
 *
 * // And compute each frame, before rendering to screen:
 * gpuCompute.doRenderTarget( myFilter1, myRenderTarget );
 * gpuCompute.doRenderTarget( myFilter2, outputRenderTarget );
 *
 *
 *
 * @param {int} sizeX Computation problem size is always 2d: sizeX * sizeY elements.
 * @param {int} sizeY Computation problem size is always 2d: sizeX * sizeY elements.
 * @param {WebGLRenderer} renderer The renderer
  */

class GPUComputationRenderer {
  final scene = Scene();
  final camera = Camera();
  List<Map<String,dynamic>> variables = [];
  int currentTextureIndex = 0;
  late GPUComputationRenderer Function(int) setDataType;
  late Map<String, dynamic> Function(String,String,DataTexture) addVariable;
  late String? Function() init;
  late void Function() compute;
  late void Function() dispose;
  late ShaderMaterial Function(String,[Map<String,dynamic>?]) createShaderMaterial;
  late void Function(Material,RenderTarget) doRenderTarget;
  late void Function(Texture,RenderTarget) renderTexture;
  late DataTexture Function() createTexture;
  late WebGLRenderTarget Function(dynamic,dynamic,dynamic,dynamic,dynamic,dynamic) createRenderTarget;
  late void Function(Map<String,dynamic>,dynamic) setVariableDependencies;
  late WebGLRenderTarget Function(Map<String,dynamic>) getCurrentRenderTarget;
  late WebGLRenderTarget Function(Map<String,dynamic>) getAlternateRenderTarget;
  late void Function(dynamic) addResolutionDefine;

	GPUComputationRenderer(int sizeX, int sizeY, WebGLRenderer renderer ) {
		int dataType = FloatType;
		camera.position.z = 1;

		final Map<String,dynamic> passThruUniforms = {
			'passThruTexture': { 'value': null }
		};

		String getPassThroughVertexShader() {
			return	'void main()	{\n' +
					'\n' +
					'	gl_Position = vec4( position, 1.0 );\n' +
					'\n' +
					'}\n';
		}
		String getPassThroughFragmentShader() {
			return	'uniform sampler2D passThruTexture;\n' +
					'\n' +
					'void main() {\n' +
					'\n' +
					'	vec2 uv = gl_FragCoord.xy / resolution.xy;\n' +
					'\n' +
					'	gl_FragColor = texture2D( passThruTexture, uv );\n' +
					'\n' +
					'}\n';
		}
		void addResolutionDefine( materialShader ) {
			materialShader.defines['resolution'] = 'vec2( ' + sizeX.toStringAsFixed( 1 ) + ', ' + sizeY.toStringAsFixed( 1 ) + ' )';
		}

		ShaderMaterial createShaderMaterial(String computeFragmentShader,[Map<String,dynamic>? uniforms ]) {
			uniforms = uniforms ?? {};

			final material = ShaderMaterial.fromMap( {
				'name': 'GPUComputationShader',
				'uniforms': uniforms,
				'vertexShader': getPassThroughVertexShader(),
				'fragmentShader': computeFragmentShader
			});

			addResolutionDefine( material );

			return material;
		}

		final passThruShader = createShaderMaterial( getPassThroughFragmentShader(), passThruUniforms );

		final mesh = Mesh( PlaneGeometry( 2, 2 ), passThruShader );
		scene.add( mesh );


		setDataType = ( type ) {
			dataType = type;
			return this;
		};

		addVariable = ( variableName, computeFragmentShader, initialValueTexture ) {
			final material = this.createShaderMaterial( computeFragmentShader );

			final variable = {
				'name': variableName,
				'initialValueTexture': initialValueTexture,
				'material': material,
				'dependencies': null,
				'renderTargets': [],
				'wrapS': null,
				'wrapT': null,
				'minFilter': NearestFilter,
				'magFilter': NearestFilter
			};

			variables.add( variable );

			return variable;
		};

		setVariableDependencies = ( variable, dependencies ) {
			variable['dependencies'] = dependencies;
		};

		init = () {
			if ( renderer.capabilities.maxVertexTextures == 0 ) {
				return 'No support for vertex shader textures.';
			}

			for ( int i = 0; i < variables.length; i ++ ) {
				final variable = variables[ i ];

        // Creates rendertargets and initialize them with input texture
        variable['renderTargets'].add(createRenderTarget( sizeX, sizeY, variable['wrapS'], variable['wrapT'], variable['minFilter'], variable['magFilter'] ));
        variable['renderTargets'].add(createRenderTarget( sizeX, sizeY, variable['wrapS'], variable['wrapT'], variable['minFilter'], variable['magFilter'] ));
        renderTexture( variable['initialValueTexture'], variable['renderTargets'][ 0 ] );
        renderTexture( variable['initialValueTexture'], variable['renderTargets'][ 1 ] );

				// Adds dependencies uniforms to the ShaderMaterial
				final material = variable['material'] as Material?;
				final uniforms = material?.uniforms;

				if ( variable['dependencies'] != null ) {
					for (int d = 0; d < variable['dependencies'].length; d ++ ) {
						final Map<String,dynamic> depVar = variable['dependencies'][d];

						if ( depVar['name'] != variable['name'] ) {
							// Checks if variable exists
							bool found = false;

							for ( int j = 0; j < variables.length; j ++ ) {
								if ( depVar['name'] == variables[j]['name'] ) {
									found = true;
									break;
								}
							}

							if ( ! found ) {
								return 'Variable dependency not found. Variable=' + variable['name'] + ', dependency=' + depVar['name'];
							}
						}

						uniforms?[depVar['name']] = { 'value': null };
						material?.fragmentShader = '\nuniform sampler2D ' + depVar['name'] + ';\n${material.fragmentShader}';
					}
				}
			}

			currentTextureIndex = 0;
			return null;
		};

		compute = () {

			final currentTextureIndex = this.currentTextureIndex;
			final nextTextureIndex = this.currentTextureIndex == 0 ? 1 : 0;

			for (int i = 0, il = variables.length; i < il; i ++ ) {

				final variable = variables[i];

				// Sets texture dependencies uniforms
				if ( variable['dependencies'] != null ) {
					final Map<String,dynamic> uniforms = variable['material'].uniforms;

					for ( int d = 0, dl = variable['dependencies'].length; d < dl; d ++ ) {
						final Map<String,dynamic> depVar = variable['dependencies'][ d ];
            uniforms[depVar['name']] = {'value' :depVar['renderTargets'][ currentTextureIndex ].texture};
					}
				}

				// Performs the computation for this variable
				doRenderTarget( variable['material'], variable['renderTargets'][ nextTextureIndex ] );
			}
			this.currentTextureIndex = nextTextureIndex;
		};

		getCurrentRenderTarget = (Map<String,dynamic> variable ) {
			return variable['renderTargets'][ currentTextureIndex ];
		};

		getAlternateRenderTarget = (Map<String,dynamic> variable ) {
			return variable['renderTargets'][ currentTextureIndex == 0 ? 1 : 0 ];
		};

		dispose = () {
			mesh.geometry?.dispose();
			mesh.material?.dispose();

			final variables = this.variables;

			for (int i = 0; i < variables.length; i ++ ) {
				final variable = variables[ i ];
				if ( variable['initialValueTexture'] ) variable['initialValueTexture'].dispose();
				final renderTargets = variable['renderTargets'];
				for ( int j = 0; j < renderTargets.length; j ++ ) {
					final renderTarget = renderTargets[ j ];
					renderTarget.dispose();
				}
			}
		};

		this.addResolutionDefine = addResolutionDefine;

		// The following functions can be used to compute things manually
		this.createShaderMaterial = createShaderMaterial;

		createRenderTarget = ( sizeXTexture, sizeYTexture, wrapS, wrapT, minFilter, magFilter ) {

			sizeXTexture = sizeXTexture ?? sizeX;
			sizeYTexture = sizeYTexture ?? sizeY;

			wrapS = wrapS ?? ClampToEdgeWrapping;
			wrapT = wrapT ?? ClampToEdgeWrapping;

			minFilter = minFilter ?? NearestFilter;
			magFilter = magFilter ?? NearestFilter;

			final renderTarget = WebGLRenderTarget( sizeXTexture, sizeYTexture, WebGLRenderTargetOptions({
				'wrapS': wrapS,
				'wrapT': wrapT,
				'minFilter': minFilter,
				'magFilter': magFilter,
				'format': RGBAFormat,
				'type': dataType,
				'depthBuffer': false
      }));

			return renderTarget;
		};

		createTexture = () {
			final data = Float32Array( sizeX * sizeY * 4 );
			final texture = DataTexture( data, sizeX, sizeY, RGBAFormat, FloatType );
			texture.needsUpdate = true;
			return texture;
		};

		renderTexture = (Texture input, RenderTarget output ) {
			// Takes a texture, and render out in rendertarget
			// input = Texture
			// output = RenderTarget
			passThruUniforms['passThruTexture'] = {'value': input};
			doRenderTarget( passThruShader, output );
			passThruUniforms['passThruTexture']= {'value': null};
		};

		doRenderTarget = (Material material, RenderTarget output ) {
			final currentRenderTarget = renderer.getRenderTarget();

			final currentXrEnabled = renderer.xr.enabled;
			final currentShadowAutoUpdate = renderer.shadowMap.autoUpdate;

			renderer.xr.enabled = false; // Avoid camera modification
			renderer.shadowMap.autoUpdate = false; // Avoid re-computing shadows
			mesh.material = material;
			renderer.setRenderTarget( output );
			renderer.render( scene, camera );
			mesh.material = passThruShader;

			renderer.xr.enabled = currentXrEnabled;
			renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;
			renderer.setRenderTarget( currentRenderTarget );
		};
	}
}
