import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:three_js_core/three_js_core.dart';

import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

final _origin = Vector3();
final _cubeCamera = PerspectiveCamera( 90, 1 );

class PMREMGeneratorOptions{
  int size;
  late final Vector3 position;
  WebGLRenderTarget? renderTarget;

  PMREMGeneratorOptions({
    Vector3? position,
    this.size = 256,
    this.renderTarget
  }){
    this.position = position ?? _origin;
  }
}

/// This class generates a Prefiltered, Mipmapped Radiance Environment Map
/// (PMREM) from a cubeMap environment texture. This allows different levels of
/// blur to be quickly accessed based on material roughness. It is packed into a
/// special CubeUV format that allows us to perform custom interpolation so that
/// we can support nonlinear formats such as RGBE. Unlike a traditional mipmap
/// chain, it only goes down to the lodMin level (above), and then creates extra
/// even more filtered 'mips' at the same lodMin resolution, associated with
/// higher roughness levels. In this way we maintain resolution to smoothly
/// interpolate diffuse lighting while limiting sampling computation.
int lodMin = 4;

// The standard deviations (radians) associated with the extra mips. These are
// chosen to approximate a Trowbridge-Reitz distribution times the
// geometric shadowing  These sigma values squared must match the
// variance #defines in cube_uv_reflection_fragment.glsl.js.
final extraLodSigma = [0.125, 0.215, 0.35, 0.446, 0.526, 0.582];

class PMREMGenerator {
  bool _didDispose = false;
  late int totalLods;

  // The maximum length of the blur for loop. Smaller sigmas will use fewer
  // samples and exit early, but not recompile the shader.
  final maxSamples = 20;

  dynamic _lodPlanes;
  dynamic _sizeLods;
  dynamic _sigmas;

  final _flatCamera = OrthographicCamera();
  final _clearColor = Color(1, 1, 1);
  RenderTarget? _oldTarget;
  int _oldActiveCubeFace = 0;
  int _oldActiveMipmapLevel = 0;
  Mesh? _backgroundBox;

  late final double phi;
  late final double invPhi;
  late final List<Vector3> _axisDirections;

  late WebGLRenderer _renderer;
  dynamic _pingPongRenderTarget;
  dynamic _blurMaterial;
  dynamic _equirectMaterial;
  dynamic _cubemapMaterial;

  late int _lodMax;
  late int _cubeSize;

  PMREMGenerator(WebGLRenderer renderer) {
    // Golden Ratio
    phi = (1 + math.sqrt(5)) / 2;
    invPhi = 1 / phi;

    // Vertices of a dodecahedron (except the opposites, which represent the
    // same axis), used as axis directions evenly spread on a sphere.
    _axisDirections = [
      Vector3(-phi, invPhi, 0),
      Vector3(phi, invPhi, 0),
      Vector3(-invPhi, 0, phi),
      Vector3(invPhi, 0, phi),
      Vector3(0, phi, -invPhi),
      Vector3(0, phi, invPhi),
      Vector3(-1, 1, -1),
      Vector3(1, 1, -1),
      Vector3(-1, 1, 1),
      Vector3(1, 1, 1),
    ];

    _renderer = renderer;
    _pingPongRenderTarget = null;

    _lodMax = 0;
    _cubeSize = 0;
    _lodPlanes = [];
    _sizeLods = [];
    _sigmas = [];

    _compileMaterial(_blurMaterial);
  }

	bool get _hasInitialized => this._renderer.hasInitialized();
	

  /// *
	/// * Generates a PMREM from a supplied Scene, which can be faster than using an
	/// * image if networking bandwidth is low. Optional sigma specifies a blur radius
	/// * in radians to be applied to the scene before PMREM generation. Optional near
	/// * and far planes ensure the scene is rendered in its entirety (the cubeCamera
	/// * is placed at the origin).
	/// *
  WebGLRenderTarget fromScene(Scene scene, {double sigma = 0, double near = 0.1, double far = 100, PMREMGeneratorOptions? options}) {
    options ??= PMREMGeneratorOptions();

    _setSize(options.size);

		if ( this._hasInitialized == false ) {
			console.warning( 'THREE.PMREMGenerator: .fromScene() called before the backend is initialized. Try using .fromSceneAsync() instead.' );
			final cubeUVRenderTarget = options.renderTarget ?? this._allocateTargets();
			options.renderTarget = cubeUVRenderTarget;
			this.fromSceneAsync( scene, sigma, near, far, options );
			return cubeUVRenderTarget;
		}

    _oldTarget = _renderer.getRenderTarget();
		_oldActiveCubeFace = _renderer.getActiveCubeFace();
		_oldActiveMipmapLevel = _renderer.getActiveMipmapLevel();

    final cubeUVRenderTarget = options.renderTarget ?? this._allocateTargets();
    cubeUVRenderTarget.depthBuffer = true;

    _sceneToCubeUV(scene, near, far, cubeUVRenderTarget, options.position);
    if (sigma > 0) {
      _blur(cubeUVRenderTarget, 0, 0, sigma);
    }

    _applyPMREM(cubeUVRenderTarget);
    _cleanup(cubeUVRenderTarget);

    return cubeUVRenderTarget;
  }

	Future<WebGLRenderTarget> fromSceneAsync( scene, [double sigma = 0, double near = 0.1, double far = 100, options]) async{
		if ( this._hasInitialized == false ) await this._renderer.init();
		return this.fromScene( scene, sigma:sigma, near:near, far:far, options:options );
	}
	/// * Generates a PMREM from an equirectangular texture, which can be either LDR
	/// * or HDR. The ideal input image size is 1k (1024 x 512),
	/// * as this matches best with the 256 x 256 cubemap output.
  Future<RenderTarget> fromEquirectangularAsync(Texture equirectangular, [RenderTarget? renderTarget]) async{
    if ( this._hasInitialized == false ) await _renderer.init();
    return _fromTexture(equirectangular, renderTarget);
  }

	RenderTarget fromEquirectangular(Texture equirectangular, [RenderTarget? renderTarget]) {
		if ( this._hasInitialized == false ) {
			console.warning( 'THREE.PMREMGenerator: .fromEquirectangular() called before the backend is initialized. Try using .fromEquirectangularAsync() instead.' );
			this._setSizeFromTexture( equirectangular );
			final cubeUVRenderTarget = renderTarget ?? this._allocateTargets();
			this.fromEquirectangularAsync( equirectangular, cubeUVRenderTarget );
			return cubeUVRenderTarget;
		}

		return this._fromTexture( equirectangular, renderTarget );
	}

	/// * Generates a PMREM from an cubemap texture, which can be either LDR
	/// * or HDR. The ideal input cube size is 256 x 256,
	/// * as this matches best with the 256 x 256 cubemap output.
	/// *
	/// * @param {Texture} cubemap - The cubemap texture to be converted.
	/// * @param {?RenderTarget} [renderTarget=null] - The render target to use.
	/// * @return {RenderTarget} The resulting PMREM.
	/// * @see {@link PMREMGenerator#fromCubemapAsync}
	RenderTarget fromCubemap(Texture cubemap, [RenderTarget? renderTarget ]) {
		if ( this._hasInitialized == false ) {
			console.warning( 'THREE.PMREMGenerator: .fromCubemap() called before the backend is initialized. Try using .fromCubemapAsync() instead.' );

			this._setSizeFromTexture( cubemap );
			final cubeUVRenderTarget = renderTarget ?? this._allocateTargets();
			this.fromCubemapAsync( cubemap, renderTarget );
			return cubeUVRenderTarget;
		}

		return this._fromTexture( cubemap, renderTarget );
	}


  /// *
	/// * Generates a PMREM from an cubemap texture, which can be either LDR
	/// * or HDR. The ideal input cube size is 256 x 256,
	/// * as this matches best with the 256 x 256 cubemap output.
	/// *
  Future<RenderTarget> fromCubemapAsync(Texture cubemap, [RenderTarget? renderTarget]) async{
    if ( this._hasInitialized == false ) await this._renderer.init();
    return _fromTexture(cubemap, renderTarget);
  }

  /// *
	/// * Pre-compiles the cubemap shader. You can get faster start-up by invoking this method during
	/// * your texture's network fetch for increased concurrency.
	/// *
  void compileCubemapShader() {
    if (_cubemapMaterial == null) {
      _cubemapMaterial = _getCubemapShader();
      _compileMaterial(_cubemapMaterial);
    }
  }

  /// *
	/// * Pre-compiles the equirectangular shader. You can get faster start-up by invoking this method during
	/// * your texture's network fetch for increased concurrency.
	/// *
  void compileEquirectangularShader() {
    if (_equirectMaterial == null) {
      _equirectMaterial = _getEquirectMaterial();
      _compileMaterial(_equirectMaterial);
    }
  }

  /// *
	/// * Disposes of the PMREMGenerator's internal memory. Note that PMREMGenerator is a static class,
	/// * so you should not need more than one PMREMGenerator object. If you do, calling dispose() on
	/// * one of them will cause any others to also become unusable.
	/// *
  void dispose() {
    if(_didDispose) return;
    _didDispose = true;
    _dispose();
    _cubemapMaterial?.dispose();
    _equirectMaterial?.dispose();
    _blurMaterial?.dispose();
    _pingPongRenderTarget?.dispose();

    _flatCamera.dispose();
    _oldTarget?.dispose();
    _axisDirections.clear();
    _renderer.dispose();  }

  // private interface

	_setSizeFromTexture(Texture texture ) {
    if (texture.mapping == CubeReflectionMapping ||
        texture.mapping == CubeRefractionMapping) {
      _setSize(texture.image.length == 0
          ? 16
          : (texture.image[0].width ?? texture.image[0].image.width));
    } else {
      // Equirectangular

      _setSize(texture.image.width ~/ 4 ?? 256);
    }

	}

  void _setSize(int cubeSize) {
    _lodMax = (MathUtils.log2(cubeSize.toDouble())).floor();
    _cubeSize = math.pow(2, _lodMax).toInt();
  }

  void _dispose() {
    _blurMaterial?.dispose();
    _pingPongRenderTarget?.dispose();

    for (int i = 0; i < _lodPlanes.length; i++) {
      _lodPlanes[i].dispose();
    }
  }

  void _cleanup(RenderTarget outputTarget) {
    _renderer.setRenderTarget(_oldTarget,_oldActiveCubeFace, _oldActiveMipmapLevel);
    outputTarget.scissorTest = false;
    _setViewport(outputTarget, 0, 0, outputTarget.width.toDouble(), outputTarget.height.toDouble());
  }

  RenderTarget _fromTexture(texture, [RenderTarget? renderTarget]) {
    _setSizeFromTexture( texture );

    _oldTarget = _renderer.getRenderTarget();
		_oldActiveCubeFace = _renderer.getActiveCubeFace();
		_oldActiveMipmapLevel = _renderer.getActiveMipmapLevel();

    final cubeUVRenderTarget = renderTarget ?? _allocateTargets();
    _textureToCubeUV(texture, cubeUVRenderTarget);
    _applyPMREM(cubeUVRenderTarget);
    _cleanup(cubeUVRenderTarget);

    return cubeUVRenderTarget;
  }

  WebGLRenderTarget _allocateTargets() {
    int width = 3 * math.max(_cubeSize, 16 * 7);
    int height = 4 * _cubeSize;

    final params = {
      "magFilter": LinearFilter,
      "minFilter": LinearFilter,
      "generateMipmaps": false,
      "type": HalfFloatType,
      "format": RGBAFormat,
      'colorSpace': LinearSRGBColorSpace,
      //"depthBuffer": false
    };

    final cubeUVRenderTarget = _createRenderTarget(width, height, params);

    if (_pingPongRenderTarget == null || _pingPongRenderTarget.width != width) {
      if (_pingPongRenderTarget != null) {
        _dispose();
      }

      _pingPongRenderTarget = _createRenderTarget(width, height, params);

      final result = _createPlanes(_lodMax);

      _sizeLods = result["sizeLods"];
      _lodPlanes = result["lodPlanes"];
      _sigmas = result["sigmas"];

      _blurMaterial = _getBlurShader(_lodMax, width, height);
    }

    return cubeUVRenderTarget;
  }

  void _compileMaterial(Material? material) {
    BufferGeometry? geometry;
    if (_lodPlanes.length >= 1) {
      geometry = _lodPlanes[0];
    }

    final tmpMesh = Mesh(geometry, material);
    _renderer.compile(tmpMesh, _flatCamera);
  }

  void _sceneToCubeUV(Scene scene, double near, double far, RenderTarget cubeUVRenderTarget, Vector3 position) {
    final Camera cubeCamera = _cubeCamera;
		cubeCamera.near = near;
		cubeCamera.far = far;
    final List<double> upSign = [1, 1, 1, 1, - 1, 1];
    final List<double> forwardSign = [1, - 1, 1, - 1, 1, - 1];
    final renderer = _renderer;

    final originalAutoClear = renderer.autoClear;
    renderer.getClearColor(_clearColor);

    renderer.autoClear = false;
    final backgroundMaterial = MeshBasicMaterial.fromMap({
      "name": 'PMREM.Background',
      "side": BackSide,
      "depthWrite": false,
      "depthTest": false,
    });

    Mesh? backgroundBox = _backgroundBox;
		if ( backgroundBox == null ) {
			final backgroundMaterial = MeshBasicMaterial.fromMap( {
				'name': 'PMREM.Background',
				'side': BackSide,
				'depthWrite': false,
				'depthTest': false
			} );

			backgroundBox = Mesh( BoxGeometry(), backgroundMaterial );
		}

    bool useSolidColor = false;
    final background = scene.background;
    if (background != null) {
      if (background is Color) {
        backgroundMaterial.color.setFrom(background);
        scene.background = null;
        useSolidColor = true;
      }
    } 
    else {
      backgroundMaterial.color.setFrom(_clearColor);
      useSolidColor = true;
    }

		renderer.setRenderTarget( cubeUVRenderTarget );
		renderer.clear();

		if ( useSolidColor ) {
			renderer.render( backgroundBox, cubeCamera );
		}

    for (int i = 0; i < 6; i++) {
      final col = i % 3;
      if (col == 0) {
        cubeCamera.up.setValues(0, upSign[i], 0);
        cubeCamera.position.setValues( position.x, position.y, position.z );
        cubeCamera.lookAt(Vector3(position.x + forwardSign[ i ], position.y, position.z));
      } 
      else if (col == 1) {
        cubeCamera.up.setValues(0, 0, upSign[i]);
        cubeCamera.position.setValues( position.x, position.y, position.z );
        cubeCamera.lookAt(Vector3(position.x, position.y + forwardSign[ i ], position.z));
      } 
      else {
        cubeCamera.up.setValues(0, upSign[i], 0);
        cubeCamera.position.setValues( position.x, position.y, position.z );
        cubeCamera.lookAt(Vector3(position.x, position.y, position.z + forwardSign[ i ]));
      }
      final size = _cubeSize.toDouble();
      _setViewport(cubeUVRenderTarget, col * size, i > 2 ? size : 0, size, size);
      renderer.render(scene, cubeCamera);
    }

    renderer.autoClear = originalAutoClear;
    scene.background = background;
  }

  void _textureToCubeUV(Texture texture, RenderTarget cubeUVRenderTarget) {
    final renderer = _renderer;

    bool isCubeTexture = (texture.mapping == CubeReflectionMapping ||
        texture.mapping == CubeRefractionMapping);

    if (isCubeTexture) {
      _cubemapMaterial ??= _getCubemapShader();

      _cubemapMaterial.uniforms["flipEnvMap"]["value"] =
          (texture.isRenderTargetTexture == false) ? -1 : 1;
    } else {
      _equirectMaterial ??= _getEquirectMaterial();
    }

    final material = isCubeTexture ? _cubemapMaterial : _equirectMaterial;

    BufferGeometry? geometry;
    if (_lodPlanes.length >= 1) {
      geometry = _lodPlanes[0];
    }
    final mesh = Mesh(geometry, material);

    final uniforms = material.uniforms;

    uniforms['envMap']["value"] = texture;

    final size = _cubeSize.toDouble();
    _setViewport(cubeUVRenderTarget, 0, 0, 3 * size, 2 * size);

    renderer.setRenderTarget(cubeUVRenderTarget);
    renderer.render(mesh, _flatCamera);
  }

  void _applyPMREM(RenderTarget cubeUVRenderTarget) {
    final renderer = _renderer;
    final autoClear = renderer.autoClear;
    renderer.autoClear = false;

    for (int i = 1; i < _lodPlanes.length; i++) {
      final sigma = math.sqrt(_sigmas[i] * _sigmas[i] - _sigmas[i - 1] * _sigmas[i - 1]);
      final poleAxis = _axisDirections[(i - 1) % _axisDirections.length];
      _blur(cubeUVRenderTarget, i - 1, i, sigma, poleAxis);
    }

    renderer.autoClear = autoClear;
  }

  /// *
	/// * This is a two-pass Gaussian blur for a cubemap. Normally this is done
	/// * vertically and horizontally, but this breaks down on a cube. Here we apply
	/// * the blur latitudinally (around the poles), and then longitudinally (towards
	/// * the poles) to approximate the orthogonally-separable blur. It is least
	/// * accurate at the poles, but still does a decent job.
	/// *
  void _blur(RenderTarget cubeUVRenderTarget, int lodIn, int lodOut, double sigma, [poleAxis]) {
    final RenderTarget? pingPongRenderTarget = _pingPongRenderTarget;
    _halfBlur(cubeUVRenderTarget, pingPongRenderTarget, lodIn, lodOut, sigma,'latitudinal', poleAxis);
    _halfBlur(pingPongRenderTarget, cubeUVRenderTarget, lodOut, lodOut, sigma,'longitudinal', poleAxis);
  }

  void _halfBlur(RenderTarget? targetIn, RenderTarget? targetOut, int lodIn, int lodOut, double sigmaRadians, String direction, poleAxis) {
    final renderer = _renderer;
    final blurMaterial = _blurMaterial;

    if (direction != 'latitudinal' && direction != 'longitudinal') {
      console.warning('blur direction must be either latitudinal or longitudinal!');
    }

    // Number of standard deviations at which to cut off the discrete approximation.
    const standardDeviations = 3;

    BufferGeometry? geometry;

    if (lodOut < _lodPlanes.length) {
      geometry = _lodPlanes[lodOut];
    }

    final blurMesh = Mesh(geometry, blurMaterial);
    final blurUniforms = blurMaterial?.uniforms;

    final pixels = _sizeLods[lodIn] - 1;
    final radiansPerPixel = isFinite(sigmaRadians)
        ? math.pi / (2 * pixels)
        : 2 * math.pi / (2 * maxSamples - 1);
    final sigmaPixels = sigmaRadians / radiansPerPixel;
    final samples = isFinite(sigmaRadians)
        ? 1 + (standardDeviations * sigmaPixels).floor()
        : maxSamples;

    if (samples > maxSamples) {
      console.warning("sigmaRadians, $sigmaRadians, is too large and will clip, as it requested $samples samples when the maximum is set to $maxSamples");
    }

    List<double> weights = [];
    double sum = 0;

    for (int i = 0; i < maxSamples; ++i) {
      final x = i / sigmaPixels;
      final weight = math.exp(-x * x / 2);
      weights.add(weight);

      if (i == 0) {
        sum += weight;
      } else if (i < samples) {
        sum += 2 * weight;
      }
    }

    for (int i = 0; i < weights.length; i++) {
      weights[i] = weights[i] / sum;
    }

    blurUniforms['envMap']["value"] = targetIn?.texture;
    blurUniforms['samples']["value"] = samples;
    blurUniforms['weights']["value"] = Float32List.fromList(weights);
    blurUniforms['latitudinal']["value"] = direction == 'latitudinal';

    if (poleAxis != null) {
      blurUniforms['poleAxis']["value"] = poleAxis;
    }

    blurUniforms['dTheta']["value"] = radiansPerPixel;
    blurUniforms['mipInt']["value"] = _lodMax - lodIn;

    final double outputSize = _sizeLods[lodOut].toDouble();
    final x = 3 * outputSize *(lodOut > _lodMax - lodMin ? lodOut - _lodMax + lodMin : 0);
    final y = 4 * (_cubeSize - outputSize);

    _setViewport(targetOut, x, y, 3 * outputSize, 2 * outputSize);
    renderer.setRenderTarget(targetOut);
    renderer.render(blurMesh, _flatCamera);
  }

  bool isFinite(double value) {
    return value == double.maxFinite;
  }

  Map<String,dynamic> _createPlanes(int lodMax) {
    final lodPlanes = [];
    final sizeLods = [];
    final sigmas = [];
    final lodMeshes = [];

    int lod = lodMax;

    final totalLods = lodMax - lodMin + 1 + extraLodSigma.length;

    for (int i = 0; i < totalLods; i++) {
      final sizeLod = math.pow(2, lod);
      sizeLods.add(sizeLod);
      double sigma = 1.0 / sizeLod;

      if (i > lodMax - lodMin) {
        sigma = extraLodSigma[i - lodMax + lodMin - 1];
      } else if (i == 0) {
        sigma = 0;
      }

      sigmas.add(sigma);

      final texelSize = 1.0 / (sizeLod - 2);
      final min = -texelSize;
      final max = 1 + texelSize;
      final uv1 = [min, min, max, min, max, max, min, min, max, max, min, max];

      const cubeFaces = 6;
      const vertices = 6;
      const positionSize = 3;
      const uvSize = 2;
      const faceIndexSize = 1;

      final position = Float32List(positionSize * vertices * cubeFaces);
      final uv = Float32List(uvSize * vertices * cubeFaces);
      final faceIndex = Int32List(faceIndexSize * vertices * cubeFaces);

      for (int face = 0; face < cubeFaces; face++) {
        double x = (face % 3) * 2 / 3 - 1;
        double y = face > 2 ? 0 : -1;
        List<double> coordinates = [
          x, y, 0,
          x + 2 / 3, y, 0,
          x + 2 / 3, y + 1, 0,
          x, y, 0,
          x + 2 / 3, y + 1, 0,
          x, y + 1, 0
        ];
        position.set(coordinates, positionSize * vertices * face);
        uv.set(uv1, uvSize * vertices * face);
        final faces = [face, face, face, face, face, face];
        faceIndex.set(faces, faceIndexSize * vertices * face);
      }

      final planes = BufferGeometry();
      planes.setAttributeFromString('position', Float32BufferAttribute.fromList(position, positionSize));
      planes.setAttributeFromString('uv', Float32BufferAttribute.fromList(uv, uvSize));
      planes.setAttributeFromString('faceIndex', Int32BufferAttribute.fromList(faceIndex, faceIndexSize));
      lodPlanes.add(planes);
      lodMeshes.add(Mesh( planes, null ) );

      if (lod > lodMin) {
        lod--;
      }
    }

    return {"lodPlanes": lodPlanes, "sizeLods": sizeLods, "sigmas": sigmas, 'loadmeshes': lodMeshes};
  }

  WebGLRenderTarget _createRenderTarget(int width, int height, Map<String,dynamic> params) {
    final cubeUVRenderTarget = WebGLRenderTarget(width, height, WebGLRenderTargetOptions(params));
    cubeUVRenderTarget.texture.mapping = CubeUVReflectionMapping;
    cubeUVRenderTarget.texture.name = 'PMREM.cubeUv';
    cubeUVRenderTarget.scissorTest = true;
    return cubeUVRenderTarget;
  }

  void _setViewport(RenderTarget? target, double x, double y, double width, double height) {
    target?.viewport.setValues(x, y, width, height);
    target?.scissor.setValues(x, y, width, height);
  }
  
  _getMaterial( type ) {
    final Material material = new NodeMaterial();
    material.depthTest = false;
    material.depthWrite = false;
    material.blending = NoBlending;
    material.name = 'PMREM_${ type }';

    return material;
  }

  _getBlurShader( lodMax, width, height ) {

    const weights = uniformArray( new Array( MAX_SAMPLES ).fill( 0 ) );
    const poleAxis = uniform( new Vector3( 0, 1, 0 ) );
    const dTheta = uniform( 0 );
    const n = float( MAX_SAMPLES );
    const latitudinal = uniform( 0 ); // false, bool
    const samples = uniform( 1 ); // int
    const envMap = texture( null );
    const mipInt = uniform( 0 ); // int
    const CUBEUV_TEXEL_WIDTH = float( 1 / width );
    const CUBEUV_TEXEL_HEIGHT = float( 1 / height );
    const CUBEUV_MAX_MIP = float( lodMax );

    const materialUniforms = {
      n,
      latitudinal,
      weights,
      poleAxis,
      outputDirection: _outputDirection,
      dTheta,
      samples,
      envMap,
      mipInt,
      CUBEUV_TEXEL_WIDTH,
      CUBEUV_TEXEL_HEIGHT,
      CUBEUV_MAX_MIP
    };

    const material = _getMaterial( 'blur' );
    material.fragmentNode = blur( { ...materialUniforms, latitudinal: latitudinal.equal( 1 ) } );

    _uniformsMap.set( material, materialUniforms );

    return material;

  }

  _getCubemapMaterial( envTexture ) {

    const material = _getMaterial( 'cubemap' );
    material.fragmentNode = cubeTexture( envTexture, _outputDirection );

    return material;

  }

  _getEquirectMaterial( envTexture ) {

    const material = _getMaterial( 'equirect' );
    material.fragmentNode = texture( envTexture, equirectUV( _outputDirection ), 0 );

    return material;

  }
}
