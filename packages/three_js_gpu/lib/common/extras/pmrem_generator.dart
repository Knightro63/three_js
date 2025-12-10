import 'package:flutter/foundation.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/renderer.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

final _origin = Vector3();

class PMREMGeneratorOptions{
  int size;
  late final Vector3 position;
  RenderTarget? renderTarget;
  PMREMGeneratorOptions({
    Vector3? position,
    this.size = 256,
    this.renderTarget,
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
// chosen to approximate a Trowbridge-Reitz distribution function times the
// geometric shadowing function. These sigma values squared must match the
// variance #defines in cube_uv_reflection_fragment.glsl.js.
final extraLodSigma = [0.125, 0.215, 0.35, 0.446, 0.526, 0.582];

class PMREMGenerator {
  bool _didDispose = false;
  late int totalLods;

  // The maximum length of the blur for loop. Smaller sigmas will use fewer
  // samples and exit early, but not recompile the shader.
  final maxSamples = 20;

  List _lodPlanes = [];
  List _lodMeshes = [];
  List _sizeLods = [];
  List _sigmas = [];

  final _flatCamera = OrthographicCamera();
  final _clearColor = Color(1, 1, 1);
  RenderTarget? _oldTarget;
  int _oldActiveCubeFace = 0;
  int _oldActiveMipmapLevel = 0;
  Mesh? _backgroundBox;

  late final double phi;
  late final double invPhi;
  late final List<Vector3> _axisDirections;

  late Renderer _renderer;
  dynamic _pingPongRenderTarget;
  dynamic _blurMaterial;
  dynamic _equirectMaterial;
  dynamic _cubemapMaterial;

  late int _lodMax;
  late int _cubeSize;
	bool get _hasInitialized => _renderer.hasInitialized();

  final List<int> _faceLib = [
    3, 1, 5,
    0, 4, 2
  ];

  PMREMGenerator(Renderer renderer) {
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
	

  /// *
	/// * Generates a PMREM from a supplied Scene, which can be faster than using an
	/// * image if networking bandwidth is low. Optional sigma specifies a blur radius
	/// * in radians to be applied to the scene before PMREM generation. Optional near
	/// * and far planes ensure the scene is rendered in its entirety (the cubeCamera
	/// * is placed at the origin).
	/// *
  RenderTarget fromScene(Scene scene, {double sigma = 0, double near = 0.1, double far = 100, PMREMGeneratorOptions? options}) {
    options ??= PMREMGeneratorOptions();
    _setSize(options.size);

		if ( this._hasInitialized == false ) {
			console.warning( 'THREE.PMREMGenerator: .fromScene() called before the backend is initialized. Try using .fromSceneAsync() instead.' );
			final cubeUVRenderTarget = options.renderTarget ?? this._allocateTarget();
			options.renderTarget = cubeUVRenderTarget;
			this.fromSceneAsync( scene, sigma:sigma, near:near, far:far, options:options );
			return cubeUVRenderTarget;
		}

    _oldTarget = _renderer.getRenderTarget();
		_oldActiveCubeFace = _renderer.getActiveCubeFace();
		_oldActiveMipmapLevel = _renderer.getActiveMipmapLevel();


    final cubeUVRenderTarget = options.renderTarget ?? this._allocateTarget();
    cubeUVRenderTarget.depthBuffer = true;

    _init( cubeUVRenderTarget );

    _sceneToCubeUV(scene, near, far, cubeUVRenderTarget, options.position);
    if (sigma > 0) {
      _blur(cubeUVRenderTarget, 0, 0, sigma);
    }

    _applyPMREM(cubeUVRenderTarget);
    _cleanup(cubeUVRenderTarget);

    return cubeUVRenderTarget;
  }
  
  Future<RenderTarget> fromSceneAsync(Scene scene, {double sigma = 0, double near = 0.1, double far = 100, PMREMGeneratorOptions? options}) async{
    options ??= PMREMGeneratorOptions();
		if ( this._hasInitialized == false ) await this._renderer.init();
		return this.fromScene( scene, sigma: sigma, near: near, far:far , options:options );
	}

  /// *
	/// * Generates a PMREM from an equirectangular texture, which can be either LDR
	/// * or HDR. The ideal input image size is 1k (1024 x 512),
	/// * as this matches best with the 256 x 256 cubemap output.
	/// *
  RenderTarget fromEquirectangular(Texture equirectangular, [RenderTarget? renderTarget]) {
		if ( this._hasInitialized == false ) {
			console.warning( 'THREE.PMREMGenerator: .fromEquirectangular() called before the backend is initialized. Try using .fromEquirectangularAsync() instead.' );
			this._setSizeFromTexture( equirectangular );
			final cubeUVRenderTarget = renderTarget ?? this._allocateTarget();
			this.fromEquirectangularAsync( equirectangular, cubeUVRenderTarget );
			
      return cubeUVRenderTarget;
		}
    return _fromTexture(equirectangular, renderTarget);
  }

	Future<RenderTarget> fromEquirectangularAsync(Texture equirectangular, [RenderTarget?renderTarget]) async{
		if ( this._hasInitialized == false ) await this._renderer.init();
		return this._fromTexture( equirectangular, renderTarget );
	}

  /// *
	/// * Generates a PMREM from an cubemap texture, which can be either LDR
	/// * or HDR. The ideal input cube size is 256 x 256,
	/// * as this matches best with the 256 x 256 cubemap output.
	/// *
  RenderTarget fromCubemap(Texture cubemap, [RenderTarget? renderTarget]) {
		if ( this._hasInitialized == false ) {
			console.warning( 'THREE.PMREMGenerator: .fromCubemap() called before the backend is initialized. Try using .fromCubemapAsync() instead.' );
			this._setSizeFromTexture( cubemap );
			final cubeUVRenderTarget = renderTarget ?? this._allocateTarget();
			this.fromCubemapAsync( cubemap, renderTarget );
			return cubeUVRenderTarget;
		}
    return _fromTexture(cubemap, renderTarget);
  }

	Future<RenderTarget> fromCubemapAsync(Texture cubemap, [RenderTarget? renderTarget]) async{
		if ( this._hasInitialized == false ) await this._renderer.init();
		return this._fromTexture( cubemap, renderTarget );
	}

  /// *
	/// * Pre-compiles the cubemap shader. You can get faster start-up by invoking this method during
	/// * your texture's network fetch for increased concurrency.
	/// *
  void compileCubemapShader() {
    if (_cubemapMaterial == null) {
      _cubemapMaterial = _getCubemapMaterial();
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

    _backgroundBox?.geometry?.dispose();
    _backgroundBox?.material?.dispose();

    _flatCamera.dispose();
    _oldTarget?.dispose();
    _axisDirections.clear();
    _renderer.dispose();  
  }

  // private interface

	_setSizeFromTexture(Texture texture ) {
		if ( texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping ) {
			this._setSize( texture.image.length == 0 ? 16 : ( texture.image[ 0 ].width ?? texture.image[ 0 ].image.width ) );
		} else { // Equirectangular
			this._setSize( texture.image.width / 4 );
		}
	}

  void _setSize(int cubeSize) {
    _lodMax = MathUtils.log2(cubeSize.toDouble()).floor();
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

  RenderTarget _fromTexture(Texture texture, [RenderTarget? renderTarget]) {
    this._setSizeFromTexture( texture );

    _oldTarget = _renderer.getRenderTarget();
		_oldActiveCubeFace = _renderer.getActiveCubeFace();
		_oldActiveMipmapLevel = _renderer.getActiveMipmapLevel();

    final cubeUVRenderTarget = renderTarget ?? _allocateTarget();
    this._init( cubeUVRenderTarget );
    _textureToCubeUV(texture, cubeUVRenderTarget);
    _applyPMREM(cubeUVRenderTarget);
    _cleanup(cubeUVRenderTarget);

    return cubeUVRenderTarget;
  }

  WebGLRenderTarget _allocateTarget() {
    int width = 3 * math.max(_cubeSize, 16 * 7);
    int height = 4 * _cubeSize;

    final cubeUVRenderTarget = _createRenderTarget(width, height);
    return cubeUVRenderTarget;
  }

  _init(RenderTarget renderTarget){
    if (this._pingPongRenderTarget == null || this._pingPongRenderTarget.width != renderTarget.width || this._pingPongRenderTarget.height != renderTarget.height ) {
      if (_pingPongRenderTarget != null) {
        _dispose();
      }

      _pingPongRenderTarget = _createRenderTarget(renderTarget.width, renderTarget.height);

      final _lodMax = this._lodMax;
      final createPlanes = _createPlanes( _lodMax );
			final sizeLods = createPlanes['sizeLods']; 
      final lodPlanes = createPlanes['lodPlanes'];
      final sigmas = createPlanes['sigmas']; 
      final lodMeshes = createPlanes['lodMeshes'];

      _sizeLods = sizeLods;
      _lodPlanes = lodPlanes;
      _sigmas = sigmas;

      _blurMaterial = _getBlurShader(_lodMax, renderTarget.width, renderTarget.height);
    }
  }

  void _compileMaterial(Material? material) {
    final tmpMesh = Mesh(_lodPlanes[ 0 ], material);
    _renderer.compile(tmpMesh, _flatCamera);
  }

  void _sceneToCubeUV(Scene scene, double near, double far, RenderTarget cubeUVRenderTarget, Vector3 position) {
    final double fov = 90;
    final double aspect = 1;
    final cubeCamera = PerspectiveCamera(fov, aspect, near, far);
    List<double> upSign = [1, 1, 1, 1, - 1, 1];
    List<double> forwardSign = [1, -1, 1, -1, 1, -1];
    final renderer = _renderer;

    final originalAutoClear = renderer.autoClear;
    renderer.getClearColor(_clearColor);

    Mesh? backgroundBox = this._backgroundBox;
    renderer.autoClear = false;
    if ( backgroundBox == null ) {
      final backgroundMaterial = MeshBasicMaterial.fromMap({
        "name": 'PMREM.Background',
        "side": BackSide,
        "depthWrite": false,
        "depthTest": false,
      });
      backgroundBox = Mesh(BoxGeometry(), backgroundMaterial);
    }

    bool useSolidColor = false;
    final background = scene.background;
    if (background != null) {
      if (background is Color) {
        backgroundBox.material?.color.setFrom(background);
        scene.background = null;
        useSolidColor = true;
      }
    } 
    else {
      backgroundBox.material?.color.setFrom(_clearColor);
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

		if ( isCubeTexture ) {
			if ( this._cubemapMaterial == null ) {
				this._cubemapMaterial = _getCubemapMaterial( texture );
			}

		} 
    else {
			if ( this._equirectMaterial == null ) {
				this._equirectMaterial = _getEquirectMaterial( texture );
			}
		}

    final material = isCubeTexture ? _cubemapMaterial : _equirectMaterial;
    material.fragmentNode.value = texture;

    final mesh = _lodMeshes[ 0 ];
    mesh.material = material;

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
  void _blur(RenderTarget cubeUVRenderTarget, int lodIn, int lodOut, double sigma, [Vector3? poleAxis]) {
    final RenderTarget? pingPongRenderTarget = _pingPongRenderTarget;
    _halfBlur(cubeUVRenderTarget, pingPongRenderTarget, lodIn, lodOut, sigma, 'latitudinal', poleAxis);
    _halfBlur(pingPongRenderTarget, cubeUVRenderTarget, lodOut, lodOut, sigma,'longitudinal', poleAxis);
  }

  void _halfBlur(RenderTarget? targetIn, RenderTarget? targetOut, int lodIn, int lodOut, double sigmaRadians, String direction, Vector3? poleAxis) {
    final renderer = _renderer;
    final blurMaterial = _blurMaterial;

    if (direction != 'latitudinal' && direction != 'longitudinal') {
      console.warning('blur direction must be either latitudinal or longitudinal!');
    }

    // Number of standard deviations at which to cut off the discrete approximation.
    final standardDeviations = 3;

		final blurMesh = _lodMeshes[ lodOut ];
		blurMesh.material = blurMaterial;

    final blurUniforms = blurMaterial?.uniforms;

    final pixels = _sizeLods[lodIn] - 1;
    final radiansPerPixel = isFinite(sigmaRadians)? math.pi / (2 * pixels): 2 * math.pi / (2 * maxSamples - 1);
    final sigmaPixels = sigmaRadians / radiansPerPixel;
    final samples = isFinite(sigmaRadians)? 1 + (standardDeviations * sigmaPixels).floor(): maxSamples;

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
      } 
      else if (i < samples) {
        sum += 2 * weight;
      }
    }

    for (int i = 0; i < weights.length; i++) {
      weights[i] = weights[i] / sum;
    }

    targetIn?.texture.frame = ( targetIn.texture.frame ?? 0 ) + 1;

    blurUniforms['envMap']["value"] = targetIn?.texture;
    blurUniforms['samples']["value"] = samples;
    blurUniforms['weights']["value"] = Float32List.fromList(weights);
    blurUniforms['latitudinal']["value"] = direction == 'latitudinal';

    if (poleAxis != null) {
      blurUniforms['poleAxis']["value"] = poleAxis;
    }

    final _lodMax = this._lodMax;

    blurUniforms['dTheta']["value"] = radiansPerPixel;
    blurUniforms['mipInt']["value"] = _lodMax - lodIn;

    final double outputSize = _sizeLods[lodOut].toDouble();
    final x = 3 * outputSize *(lodOut > _lodMax - lodMin ? lodOut - _lodMax + lodMin : 0);
    final y = 4 * (this._cubeSize - outputSize);

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

      final cubeFaces = 6;
      final vertices = 6;
      final positionSize = 3;
      final uvSize = 2;
      final faceIndexSize = 1;

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

        final faceIdx = _faceLib[ face ];
        position.set(coordinates, positionSize * vertices * face);
        uv.set(uv1, uvSize * vertices * face);
        final fill = [ faceIdx, faceIdx, faceIdx, faceIdx, faceIdx, faceIdx ];
        faceIndex.set( fill, (faceIndexSize * vertices * faceIdx).toInt() );
      }

      final planes = BufferGeometry();
      planes.setAttributeFromString('position', Float32BufferAttribute.fromList(position, positionSize));
      planes.setAttributeFromString('uv', Float32BufferAttribute.fromList(uv, uvSize));
      planes.setAttributeFromString('faceIndex', Int32BufferAttribute.fromList(faceIndex, faceIndexSize));
      lodPlanes.add(planes);
      _lodMeshes.add( Mesh( planes, null ) );

      if (lod > lodMin) {
        lod--;
      }
    }

    return {"lodPlanes": lodPlanes, "sizeLods": sizeLods, "sigmas": sigmas};
  }

  WebGLRenderTarget _createRenderTarget(int width, int height) {
    final params = {
      'magFilter': LinearFilter,
      'minFilter': LinearFilter,
      'generateMipmaps': false,
      'type': HalfFloatType,
      'format': RGBAFormat,
      'colorSpace': LinearSRGBColorSpace,
      //depthBuffer: false
    };
    
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
    final material = NodeMaterial();
    material.depthTest = false;
    material.depthWrite = false;
    material.blending = NoBlending;
    material.name = 'PMREM_${ type }';
    return material;
  }

  _getBlurShader( lodMax, width, height ) {
    final weights = uniformArray( new Array( MAX_SAMPLES ).fill( 0 ) );
    final poleAxis = uniform( new Vector3( 0, 1, 0 ) );
    final dTheta = uniform( 0 );
    final n = float( MAX_SAMPLES );
    final latitudinal = uniform( 0 ); // false, bool
    final samples = uniform( 1 ); // int
    final envMap = texture( null );
    final mipInt = uniform( 0 ); // int
    final CUBEUV_TEXEL_WIDTH = float( 1 / width );
    final CUBEUV_TEXEL_HEIGHT = float( 1 / height );
    final CUBEUV_MAX_MIP = float( lodMax );

    final materialUniforms = {
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

    final material = _getMaterial( 'blur' );
    material.fragmentNode = blur( { ...materialUniforms, latitudinal: latitudinal.equal( 1 ) } );

    _uniformsMap.set( material, materialUniforms );

    return material;

  }

  _getCubemapMaterial( [envTexture] ) {
    final material = _getMaterial( 'cubemap' );
    material.fragmentNode = cubeTexture( envTexture, _outputDirection );
    return material;
  }

  _getEquirectMaterial( [envTexture] ) {
    final material = _getMaterial( 'equirect' );
    material.fragmentNode = texture( envTexture, equirectUV( _outputDirection ), 0 );
    return material;
  }
}
