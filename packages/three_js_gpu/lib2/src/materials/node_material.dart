import 'package:three_js_core/three_js_core.dart';

/**
 * Base class for all node materials.
 *
 * @augments Material
 */
class NodeMaterial extends Material {
	String get type =>'NodeMaterial';

  /**
   * Whether this material uses hardware clipping or not.
   * This property is managed by the engine and should not be
   * modified by apps.
   */
  bool hardwareClipping = false;

  /**
   * Node materials which set their `lights` property to `true`
   * are affected by all lights of the scene. Sometimes selective
   * lighting is wanted which means only _some_ lights in the scene
   * affect a material. This can be achieved by creating an instance
   * of {@link LightsNode} with a list of selective
   * lights and assign the node to this property.
   *
   * ```js
   * final customLightsNode = lights( [ light1, light2 ] );
   * material.lightsNode = customLightsNode;
   * ```
   *
   * @type {?LightsNode}
   * @default null
   */
  LightsNode? lightsNode;

  /**
   * The environment of node materials can be defined by an environment
   * map assigned to the `envMap` property or by `Scene.environment`
   * if the node material is a PBR material. This node property allows to overwrite
   * the default behavior and define the environment with a custom node.
   *
   * ```js
   * material.envNode = pmremTexture( renderTarget.texture );
   * ```
   */
  Node<vec3>? envNode;

  /**
   * The lighting of node materials might be influenced by ambient occlusion.
   * The default AO is inferred from an ambient occlusion map assigned to `aoMap`
   * and the respective `aoMapIntensity`. This node property allows to overwrite
   * the default and define the ambient occlusion with a custom node instead.
   *
   * If you don't want to overwrite the diffuse color but modify the existing
   * values instead, use {@link materialAO}.
   */
  Node<float>? aoNode;

  /**
   * The diffuse color of node materials is by default inferred from the
   * `color` and `map` properties. This node property allows to overwrite the default
   * and define the diffuse color with a node instead.
   *
   * ```js
   * material.colorNode = color( 0xff0000 ); // define red color
   * ```
   *
   * If you don't want to overwrite the diffuse color but modify the existing
   * values instead, use {@link materialColor}.
   *
   * ```js
   * material.colorNode = materialColor.mul( color( 0xff0000 ) ); // give diffuse colors a red tint
   * ```
   */
  Node<vec3>? colorNode;

  /**
   * The opacity of node materials is by default inferred from the `opacity`
   * and `alphaMap` properties. This node property allows to overwrite the default
   * and define the opacity with a node instead.
   *
   * If you don't want to overwrite the opacity but modify the existing
   * value instead, use {@link materialOpacity}.
   *
   * @type {?}
   * @default null
   */
  Node<float>? opacityNode;

  /**
   * This node can be used to implement a variety of filter-like effects. The idea is
   * to store the current rendering into a texture e.g. via `viewportSharedTexture()`, use it
   * to create an arbitrary effect and then assign the node composition to this property.
   * Everything behind the object using this material will now be affected by a filter.
   *
   * ```js
   * final material = new NodeMaterial()
   * material.transparent = true;
   *
   * // everything behind the object will be monochromatic
   * material.backdropNode = saturation( viewportSharedTexture().rgb, 0 );
   * ```
   *
   * Backdrop computations are part of the lighting so only lit materials can use this property.
   */
  Node<vec3>? backdropNode;

  /**
   * This node allows to modulate the influence of `backdropNode` to the outgoing light.
   *
   * @type {?Node<float>}
   * @default null
   */
  Node<float>? backdropAlphaNode = null;

  /**
   * The alpha test of node materials is by default inferred from the `alphaTest`
   * property. This node property allows to overwrite the default and define the
   * alpha test with a node instead.
   *
   * If you don't want to overwrite the alpha test but modify the existing
   * value instead, use {@link materialAlphaTest}.
   *
   * @type {?Node<float>}
   * @default null
   */
  Node<float>? alphaTestNode = null;


  /**
   * Discards the fragment if the mask value is `false`.
   *
   * @type {?Node<bool>}
   * @default null
   */
  Node<bool>? maskNode = null;

  /**
   * This node can be used to implement a shadow mask for the material.
   *
   * @type {?Node<bool>}
   * @default null
   */
  Node<bool>? maskShadowNode = null;

  /**
   * The local vertex positions are computed based on multiple factors like the
   * attribute data, morphing or skinning. This node property allows to overwrite
   * the default and define local vertex positions with nodes instead.
   *
   * If you don't want to overwrite the vertex positions but modify the existing
   * values instead, use {@link positionLocal}.
   *
   *```js
    * material.positionNode = positionLocal.add( displace );
    * ```
    *
    * @type {?Node<vec3>}
    * @default null
    */
  Node<vec3>? positionNode = null;

  /**
   * This node property is intended for logic which modifies geometry data once or per animation step.
   * Apps usually place such logic randomly in initialization routines or in the animation loop.
   * `geometryNode` is intended as a dedicated API so there is an intended spot where geometry modifications
   * can be implemented.
   *
   * The idea is to assign a `Fn` definition that holds the geometry modification logic. A typical example
   * would be a GPU based particle system that provides a node material for usage on app level. The particle
   * simulation would be implemented as compute shaders and managed inside a `Fn` function. This function is
   * eventually assigned to `geometryNode`.
   *
   * @type {?Function}
   * @default null
   */
  Function? geometryNode = null;

  /**
   * Allows to overwrite depth values in the fragment shader.
   *
   * @type {?Node<float>}
   * @default null
   */
  Node<float>? depthNode = null;

  /**
   * Allows to overwrite the position used for shadow map rendering which
   * is by default {@link positionWorld}, the vertex position
   * in world space.
   *
   * @type {?Node<float>}
   * @default null
   */
  Node<float>? receivedShadowPositionNode = null;

  /**
   * Allows to overwrite the geometry position used for shadow map projection which
   * is by default {@link positionLocal}, the vertex position in local space.
   *
   * @type {?Node<float>}
   * @default null
   */
  Node<float>? castShadowPositionNode = null;

  /**
   * This node can be used to influence how an object using this node material
   * receive shadows.
   *
   * ```js
   * final totalShadows = float( 1 ).toVar();
   * material.receivedShadowNode = Fn( ( [ shadow ] ) => {
   * 	totalShadows.mulAssign( shadow );
   * 	//return float( 1 ); // bypass received shadows
   * 	return shadow.mix( color( 0xff0000 ), 1 ); // modify shadow color
   * } );
   *
   * @type {?(Function|FunctionNode<vec4>)}
   * @default null
   */
  Function?receivedShadowNode = null;

  /**
   * This node can be used to influence how an object using this node material
   * casts shadows. To apply a color to shadows, you can simply do:
   *
   * ```js
   * material.castShadowNode = vec4( 1, 0, 0, 1 );
   * ```
   *
   * Which can be nice to fake colored shadows of semi-transparent objects. It
   * is also common to use the property with `Fn` function so checks are performed
   * per fragment.
   *
   * ```js
   * materialCustomShadow.castShadowNode = Fn( () => {
   * 	hash( vertexIndex ).greaterThan( 0.5 ).discard();
   * 	return materialColor;
   * } )();
   *  ```
   *
   * @type {?Node<vec4>}
   * @default null
   */
  Node<float>? castShadowNode = null;

  /**
   * This node can be used to define the final output of the material.
   *
   * TODO: Explain the differences to `fragmentNode`.
   *
   * @type {?Node<vec4>}
   * @default null
   */
  Node<vec4>? outputNode = null;

  /**
   * MRT configuration is done on renderer or pass level. This node allows to
   * overwrite what values are written into MRT targets on material level. This
   * can be useful for implementing selective FX features that should only affect
   * specific objects.
   *
   * @type {?MRTNode}
   * @default null
   */
  MRTNode? mrtNode = null;

  /**
   * This node property can be used if you need complete freedom in implementing
   * the fragment shader. Assigning a node will replace the built-in material
   * logic used in the fragment stage.
   *
   * @type {?Node<vec4>}
   * @default null
   */
  Node<vec4>? fragmentNode = null;

  /**
   * This node property can be used if you need complete freedom in implementing
   * the vertex shader. Assigning a node will replace the built-in material logic
   * used in the vertex stage.
   *
   * @type {?Node<vec4>}
   * @default null
   */
  Node<vec4>? vertexNode = null;

  /**
   * This node can be used as a global context management component for this material.
   *
   * @type {?ContextNode}
   * @default null
   */
  ContextNode? contextNode;

	NodeMaterial():super() {
		this.fog = true;
		this.lights = false;
		this.normalNode = null;
	}

	/**
	 * Returns an array of child nodes for this material.
	 *
	 * @private
	 * @returns {Array<{property: string, childNode: Node}>}
	 */
	_getNodeChildren() {
		final children = [];

		for ( final property of Object.getOwnPropertyNames( this ) ) {

			if ( property.startsWith( '_' ) == true ) continue;

			final object = this[ property ];

			if ( object && object.isNode == true ) {
				children.add( { property, childNode: object } );
			}
		}

		return children;
	}

	/**
	 * Allows to define a custom cache key that influence the material key computation
	 * for render objects.
	 *
	 * @return {string} The custom cache key.
	 */
	String customProgramCacheKey() {
		final values = [];

		for ( final pcN in this._getNodeChildren() ) {
      final childNode = pcN.childNode;
      final property = pcN.property;

			values.add( hashString( property.slice( 0, - 4 ) ), childNode.getCacheKey() );
		}

		return this.type + hashArray( values );
	}

	/**
	 * Builds this material with the given node builder.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 */
	void build(NodeBuilder builder ) {
		this.setup( builder );
	}

	/**
	 * Setups a node material observer with the given builder.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {NodeMaterialObserver} The node material observer.
	 */
	NodeMaterialObserver setupObserver(NodeBuilder builder ) {
		return new NodeMaterialObserver( builder );
	}

	/**
	 * Setups the vertex and fragment stage of this node material.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 */
	setup(NodeBuilder builder ) {

		builder.context.setupNormal = () => subBuild( this.setupNormal( builder ), 'NORMAL', 'vec3' );
		builder.context.setupPositionView = () => this.setupPositionView( builder );
		builder.context.setupModelViewProjection = () => this.setupModelViewProjection( builder );

		final renderer = builder.renderer;
		final renderTarget = renderer.getRenderTarget();

		// < VERTEX STAGE >

		builder.addStack();

		final mvp = this.setupVertex( builder );

		final vertexNode = subBuild( this.vertexNode || mvp, 'VERTEX' );

		builder.context.clipSpace = vertexNode;

		builder.stack.outputNode = vertexNode;

		this.setupHardwareClipping( builder );

		if ( this.geometryNode !== null ) {

			builder.stack.outputNode = builder.stack.outputNode.bypass( this.geometryNode );

		}

		builder.addFlow( 'vertex', builder.removeStack() );

		// < FRAGMENT STAGE >

		builder.addStack();

		let resultNode;

		final clippingNode = this.setupClipping( builder );

		if ( this.depthWrite == true || this.depthTest == true ) {

			// only write depth if depth buffer is configured

			if ( renderTarget !== null ) {

				if ( renderTarget.depthBuffer == true ) this.setupDepth( builder );

			} else {

				if ( renderer.depth == true ) this.setupDepth( builder );

			}

		}

		if ( this.fragmentNode == null ) {

			this.setupDiffuseColor( builder );
			this.setupVariants( builder );

			final outgoingLightNode = this.setupLighting( builder );

			if ( clippingNode != null ) builder.stack.addToStack( clippingNode );

			// force unsigned floats - useful for RenderTargets

			final basicOutput = vec4( outgoingLightNode, diffuseColor.a ).max( 0 );

			resultNode = this.setupOutput( builder, basicOutput );

			// OUTPUT NODE

			output.assign( resultNode );

			//

			final isCustomOutput = this.outputNode !== null;

			if ( isCustomOutput ) resultNode = this.outputNode;

			//

			if ( builder.context.getOutput ) {

				resultNode = builder.context.getOutput( resultNode, builder );

			}

			// MRT

			if ( renderTarget !== null ) {

				final mrt = renderer.getMRT();
				final materialMRT = this.mrtNode;

				if ( mrt !== null ) {

					if ( isCustomOutput ) output.assign( resultNode );

					resultNode = mrt;

					if ( materialMRT !== null ) {

						resultNode = mrt.merge( materialMRT );

					}

				} else if ( materialMRT !== null ) {

					resultNode = materialMRT;

				}

			}

		} else {

			let fragmentNode = this.fragmentNode;

			if ( fragmentNode.isOutputStructNode !== true ) {

				fragmentNode = fragmentNode.convert( builder.getOutputType() );

			}

			resultNode = this.setupOutput( builder, fragmentNode );

		}

		builder.stack.outputNode = resultNode;

		builder.addFlow( 'fragment', builder.removeStack() );

		// < OBSERVER >

		builder.observer = this.setupObserver( builder );

	}

	/**
	 * Setups the clipping node.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {ClippingNode} The clipping node.
	 */
	setupClipping( builder ) {

		if ( builder.clippingContext == null ) return null;

		final { unionPlanes, intersectionPlanes } = builder.clippingContext;

		let result = null;

		if ( unionPlanes.length > 0 || intersectionPlanes.length > 0 ) {

			final samples = builder.renderer.currentSamples;

			if ( this.alphaToCoverage && samples > 1 ) {

				// to be added to flow when the color/alpha value has been determined
				result = clippingAlpha();

			} else {

				builder.stack.addToStack( clipping() );

			}

		}

		return result;

	}

	/**
	 * Setups the hardware clipping if available on the current device.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 */
	setupHardwareClipping( builder ) {

		this.hardwareClipping = false;

		if ( builder.clippingContext == null ) return;

		final candidateCount = builder.clippingContext.unionPlanes.length;

		// 8 planes supported by WebGL ANGLE_clip_cull_distance and WebGPU clip-distances

		if ( candidateCount > 0 && candidateCount <= 8 && builder.isAvailable( 'clipDistance' ) ) {

			builder.stack.addToStack( hardwareClipping() );

			this.hardwareClipping = true;

		}

		return;

	}

	/**
	 * Setups the depth of this material.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 */
	setupDepth( builder ) {

		final { renderer, camera } = builder;

		// Depth

		let depthNode = this.depthNode;

		if ( depthNode == null ) {

			final mrt = renderer.getMRT();

			if ( mrt && mrt.has( 'depth' ) ) {

				depthNode = mrt.get( 'depth' );

			} else if ( renderer.logarithmicDepthBuffer == true ) {

				if ( camera.isPerspectiveCamera ) {

					depthNode = viewZToLogarithmicDepth( positionView.z, cameraNear, cameraFar );

				} else {

					depthNode = viewZToOrthographicDepth( positionView.z, cameraNear, cameraFar );

				}

			}

		}

		if ( depthNode !== null ) {

			depth.assign( depthNode ).toStack();

		}

	}

	/**
	 * Setups the position node in view space. This method exists
	 * so derived node materials can modify the implementation e.g. sprite materials.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {Node<vec3>} The position in view space.
	 */
	setupPositionView( /*builder*/ ) {

		return modelViewMatrix.mul( positionLocal ).xyz;

	}

	/**
	 * Setups the position in clip space.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {Node<vec4>} The position in view space.
	 */
	setupModelViewProjection( /*builder*/ ) {

		return cameraProjectionMatrix.mul( positionView );

	}

	/**
	 * Setups the logic for the vertex stage.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {Node<vec4>} The position in clip space.
	 */
	setupVertex( builder ) {

		builder.addStack();

		this.setupPosition( builder );

		builder.context.position = builder.removeStack();

		return modelViewProjection;

	}

	/**
	 * Setups the computation of the position in local space.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {Node<vec3>} The position in local space.
	 */
	setupPosition( builder ) {

		final { object, geometry } = builder;

		if ( geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color ) {

			morphReference( object ).toStack();

		}

		if ( object.isSkinnedMesh == true ) {

			skinning( object ).toStack();

		}

		if ( this.displacementMap ) {

			final displacementMap = materialReference( 'displacementMap', 'texture' );
			final displacementScale = materialReference( 'displacementScale', 'float' );
			final displacementBias = materialReference( 'displacementBias', 'float' );

			positionLocal.addAssign( normalLocal.normalize().mul( ( displacementMap.x.mul( displacementScale ).add( displacementBias ) ) ) );

		}

		if ( object.isBatchedMesh ) {

			batch( object ).toStack();

		}

		if ( ( object.isInstancedMesh && object.instanceMatrix && object.instanceMatrix.isInstancedBufferAttribute == true ) ) {

			instancedMesh( object ).toStack();

		}

		if ( this.positionNode !== null ) {

			positionLocal.assign( subBuild( this.positionNode, 'POSITION', 'vec3' ) );

		}

		return positionLocal;

	}

	/**
	 * Setups the computation of the material's diffuse color.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @param {BufferGeometry} geometry - The geometry.
	 */
	setupDiffuseColor( builder ) {

		final { object, geometry } = builder;

		// MASK

		if ( this.maskNode !== null ) {

			// Discard if the mask is `false`

			bool( this.maskNode ).not().discard();

		}

		// COLOR

		let colorNode = this.colorNode ? vec4( this.colorNode ) : materialColor;

		// VERTEX COLORS

		if ( this.vertexColors == true && geometry.hasAttribute( 'color' ) ) {

			colorNode = colorNode.mul( vertexColor() );

		}

		// INSTANCED COLORS

		if ( object.instanceColor ) {

			final instanceColor = varyingProperty( 'vec3', 'vInstanceColor' );

			colorNode = instanceColor.mul( colorNode );

		}

		if ( object.isBatchedMesh && object._colorsTexture ) {

			final batchColor = varyingProperty( 'vec3', 'vBatchColor' );

			colorNode = batchColor.mul( colorNode );

		}

		// DIFFUSE COLOR

		diffuseColor.assign( colorNode );

		// OPACITY

		final opacityNode = this.opacityNode ? float( this.opacityNode ) : materialOpacity;
		diffuseColor.a.assign( diffuseColor.a.mul( opacityNode ) );

		// ALPHA TEST

		let alphaTestNode = null;

		if ( this.alphaTestNode !== null || this.alphaTest > 0 ) {

			alphaTestNode = this.alphaTestNode !== null ? float( this.alphaTestNode ) : materialAlphaTest;

			if ( this.alphaToCoverage == true ) {

				diffuseColor.a = smoothstep( alphaTestNode, alphaTestNode.add( fwidth( diffuseColor.a ) ), diffuseColor.a );
				diffuseColor.a.lessThanEqual( 0 ).discard();

			} else {

				diffuseColor.a.lessThanEqual( alphaTestNode ).discard();

			}

		}

		// ALPHA HASH

		if ( this.alphaHash == true ) {

			diffuseColor.a.lessThan( getAlphaHashThreshold( positionLocal ) ).discard();

		}

		// OPAQUE

		if ( builder.isOpaque() ) {

			diffuseColor.a.assign( 1.0 );

		}

	}

	/**
	 * Abstract interface method that can be implemented by derived materials
	 * to setup material-specific node variables.
	 *
	 * @abstract
	 * @param {NodeBuilder} builder - The current node builder.
	 */
	setupVariants( /*builder*/ ) {

		// Interface function.

	}

	/**
	 * Setups the outgoing light node variable
	 *
	 * @return {Node<vec3>} The outgoing light node.
	 */
	setupOutgoingLight() {

		return ( this.lights == true ) ? vec3( 0 ) : diffuseColor.rgb;

	}

	/**
	 * Setups the normal node from the material.
	 *
	 * @return {Node<vec3>} The normal node.
	 */
	setupNormal() {

		return this.normalNode ? vec3( this.normalNode ) : materialNormal;

	}

	/**
	 * Setups the environment node from the material.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {Node<vec4>} The environment node.
	 */
	setupEnvironment( /*builder*/ ) {

		let node = null;

		if ( this.envNode ) {

			node = this.envNode;

		} else if ( this.envMap ) {

			node = this.envMap.isCubeTexture ? materialReference( 'envMap', 'cubeTexture' ) : materialReference( 'envMap', 'texture' );

		}

		return node;

	}

	/**
	 * Setups the light map node from the material.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {Node<vec3>} The light map node.
	 */
	setupLightMap( builder ) {

		let node = null;

		if ( builder.material.lightMap ) {

			node = new IrradianceNode( materialLightMap );

		}

		return node;

	}

	/**
	 * Setups the lights node based on the scene, environment and material.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {LightsNode} The lights node.
	 */
	setupLights( builder ) {

		final materialLightsNode = [];

		//

		final envNode = this.setupEnvironment( builder );

		if ( envNode && envNode.isLightingNode ) {

			materialLightsNode.push( envNode );

		}

		final lightMapNode = this.setupLightMap( builder );

		if ( lightMapNode && lightMapNode.isLightingNode ) {

			materialLightsNode.push( lightMapNode );

		}

		let aoNode = this.aoNode;

		if ( aoNode == null && builder.material.aoMap ) {

			aoNode = materialAO;

		}

		if ( builder.context.getAO ) {

			aoNode = builder.context.getAO( aoNode, builder );

		}

		if ( aoNode ) {

			materialLightsNode.push( new AONode( aoNode ) );

		}

		let lightsN = this.lightsNode || builder.lightsNode;

		if ( materialLightsNode.length > 0 ) {

			lightsN = builder.renderer.lighting.createNode( [ ...lightsN.getLights(), ...materialLightsNode ] );

		}

		return lightsN;

	}

	/**
	 * This method should be implemented by most derived materials
	 * since it defines the material's lighting model.
	 *
	 * @abstract
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {LightingModel} The lighting model.
	 */
	setupLightingModel( /*builder*/ ) {

		// Interface function.

	}

	/**
	 * Setups the outgoing light node.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @return {Node<vec3>} The outgoing light node.
	 */
	setupLighting( builder ) {

		final { material } = builder;
		final { backdropNode, backdropAlphaNode, emissiveNode } = this;

		// OUTGOING LIGHT

		final lights = this.lights == true || this.lightsNode !== null;

		final lightsNode = lights ? this.setupLights( builder ) : null;

		let outgoingLightNode = this.setupOutgoingLight( builder );

		if ( lightsNode && lightsNode.getScope().hasLights ) {

			final lightingModel = this.setupLightingModel( builder ) || null;

			outgoingLightNode = lightingContext( lightsNode, lightingModel, backdropNode, backdropAlphaNode );

		} else if ( backdropNode !== null ) {

			outgoingLightNode = vec3( backdropAlphaNode !== null ? mix( outgoingLightNode, backdropNode, backdropAlphaNode ) : backdropNode );

		}

		// EMISSIVE

		if ( ( emissiveNode && emissiveNode.isNode == true ) || ( material.emissive && material.emissive.isColor == true ) ) {

			emissive.assign( vec3( emissiveNode ? emissiveNode : materialEmissive ) );

			outgoingLightNode = outgoingLightNode.add( emissive );

		}

		return outgoingLightNode;

	}

	/**
	 * Setup the fog.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @param {Node<vec4>} outputNode - The existing output node.
	 * @return {Node<vec4>} The output node.
	 */
	setupFog( builder, outputNode ) {
		final fogNode = builder.fogNode;

		if ( fogNode ) {
			output.assign( outputNode );
			outputNode = vec4( fogNode.toVar() );
		}

		return outputNode;
	}

	/**
	 * Setups premultiplied alpha.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @param {Node<vec4>} outputNode - The existing output node.
	 * @return {Node<vec4>} The output node.
	 */
	setupPremultipliedAlpha( builder, outputNode ) {
		return premultiplyAlpha( outputNode );
	}

	/**
	 * Setups the output node.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 * @param {Node<vec4>} outputNode - The existing output node.
	 * @return {Node<vec4>} The output node.
	 */
	setupOutput( builder, outputNode ) {
		// FOG
		if ( this.fog == true ) {
			outputNode = this.setupFog( builder, outputNode );
		}

		// PREMULTIPLIED ALPHA

		if ( this.premultipliedAlpha == true ) {
			outputNode = this.setupPremultipliedAlpha( builder, outputNode );
		}

		return outputNode;
	}

	/**
	 * Most classic material types have a node pendant e.g. for `MeshBasicMaterial`
	 * there is `MeshBasicNodeMaterial`. This utility method is intended for
	 * defining all material properties of the classic type in the node type.
	 *
	 * @param {Material} material - The material to copy properties with their values to this node material.
	 */
	setDefaultValues( material ) {
		// This approach is to reuse the native refreshUniforms*
		// and turn available the use of features like transmission and environment in core

		for ( final property in material ) {
			final value = material[ property ];

			if ( this[ property ] == null ) {
				this[ property ] = value;
				if ( value && value.clone ) this[ property ] = value.clone();
			}
		}

		final descriptors = Object.getOwnPropertyDescriptors( material.constructor.prototype );

		for ( final key in descriptors ) {

			if ( Object.getOwnPropertyDescriptor( this.constructor.prototype, key ) == null &&
			     descriptors[ key ].get != null ) {

				Object.defineProperty( this.constructor.prototype, key, descriptors[ key ] );

			}
		}
	}

	/**
	 * Serializes this material to JSON.
	 *
	 * @param {?(Object|string)} meta - The meta information for serialization.
	 * @return {Object} The serialized node.
	 */
  @override
	Map<String, dynamic> toJson([Map<String,dynamic>? meta]) {

		final isRoot = meta == null;

		if ( isRoot ) {
			meta = {
				'textures': {},
				'images': {},
				'nodes': {}
			};
		}

		final data = Material.prototype.toJSON.call( this, meta );
		data.inputNodes = {};

		for ( final { property, childNode } of this._getNodeChildren() ) {
			data.inputNodes[ property ] = childNode.toJSON( meta ).uuid;
		}

		// TODO: Copied from Object3D.toJSON

		List extractFromCache( cache ) {
			final values = [];

			for ( final key in cache ) {
				final data = cache[ key ];
				delete data.metadata;
				values.add( data );
			}

			return values;
		}

		if ( isRoot ) {
			final textures = extractFromCache( meta.textures );
			final images = extractFromCache( meta.images );
			final nodes = extractFromCache( meta.nodes );

			if ( textures.length > 0 ) data.textures = textures;
			if ( images.length > 0 ) data.images = images;
			if ( nodes.length > 0 ) data.nodes = nodes;
		}

		return data;
	}

	/**
	 * Copies the properties of the given node material to this instance.
	 *
	 * @param {NodeMaterial} source - The material to copy.
	 * @return {NodeMaterial} A reference to this node material.
	 */
	NodeMaterial copy( source ) {
    source as NodeMaterial;
    super.copy( source );

		this.lightsNode = source.lightsNode;
		this.envNode = source.envNode;
		this.aoNode = source.aoNode;

		this.colorNode = source.colorNode;
		this.normalNode = source.normalNode;
		this.opacityNode = source.opacityNode;
		this.backdropNode = source.backdropNode;
		this.backdropAlphaNode = source.backdropAlphaNode;
		this.alphaTestNode = source.alphaTestNode;
		this.maskNode = source.maskNode;
		this.maskShadowNode = source.maskShadowNode;

		this.positionNode = source.positionNode;
		this.geometryNode = source.geometryNode;

		this.depthNode = source.depthNode;
		this.receivedShadowPositionNode = source.receivedShadowPositionNode;
		this.castShadowPositionNode = source.castShadowPositionNode;
		this.receivedShadowNode = source.receivedShadowNode;
		this.castShadowNode = source.castShadowNode;

		this.outputNode = source.outputNode;
		this.mrtNode = source.mrtNode;

		this.fragmentNode = source.fragmentNode;
		this.vertexNode = source.vertexNode;

		this.contextNode = source.contextNode;

		return this;
	}
}
