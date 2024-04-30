import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gl/flutter_gl.dart';

import 'package:three_js_math/three_js_math.dart';
import '../renderers/index.dart';
import '../cameras/index.dart';
import '../scenes/index.dart';
import '../geometries/index.dart';
import '../core/index.dart';
import '../materials/index.dart';
import '../objects/mesh.dart';
import 'dart:math' as math;

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

  late double phi;
  late double invPhi;
  late List<Vector3> _axisDirections;

  late WebGLRenderer _renderer;
  dynamic _pingPongRenderTarget;
  dynamic _blurMaterial;
  dynamic _equirectMaterial;
  dynamic _cubemapMaterial;

  late int _lodMax;
  late int _cubeSize;

  PMREMGenerator(renderer) {
    // Golden Ratio
    phi = (1 + math.sqrt(5)) / 2;
    invPhi = 1 / phi;

    // Vertices of a dodecahedron (except the opposites, which represent the
    // same axis), used as axis directions evenly spread on a sphere.
    _axisDirections = [
      Vector3(1, 1, 1),
      Vector3(-1, 1, 1),
      Vector3(1, 1, -1),
      Vector3(-1, 1, -1),
      Vector3(0, phi, invPhi),
      Vector3(0, phi, -invPhi),
      Vector3(invPhi, 0, phi),
      Vector3(-invPhi, 0, phi),
      Vector3(phi, invPhi, 0),
      Vector3(-phi, invPhi, 0)
    ];

    _renderer = renderer;
    _pingPongRenderTarget = null;

    _lodMax = 0;
    _cubeSize = 0;
    _lodPlanes = [];
    _sizeLods = [];
    _sigmas = [];

    _blurMaterial = null;

    // this._blurMaterial = _getBlurShader(maxSamples);
    _equirectMaterial = null;
    _cubemapMaterial = null;

    _compileMaterial(_blurMaterial);
  }

  /// *
	/// * Generates a PMREM from a supplied Scene, which can be faster than using an
	/// * image if networking bandwidth is low. Optional sigma specifies a blur radius
	/// * in radians to be applied to the scene before PMREM generation. Optional near
	/// * and far planes ensure the scene is rendered in its entirety (the cubeCamera
	/// * is placed at the origin).
	/// *
  WebGLRenderTarget fromScene(Scene scene, [double sigma = 0, double near = 0.1, double far = 100]) {
    _oldTarget = _renderer.getRenderTarget();

    _setSize(256);
    final cubeUVRenderTarget = _allocateTargets();
    cubeUVRenderTarget.depthBuffer = true;

    _sceneToCubeUV(scene, near, far, cubeUVRenderTarget);
    if (sigma > 0) {
      _blur(cubeUVRenderTarget, 0, 0, sigma, null);
    }

    _applyPMREM(cubeUVRenderTarget);
    _cleanup(cubeUVRenderTarget);

    return cubeUVRenderTarget;
  }

  /// *
	/// * Generates a PMREM from an equirectangular texture, which can be either LDR
	/// * or HDR. The ideal input image size is 1k (1024 x 512),
	/// * as this matches best with the 256 x 256 cubemap output.
	/// *
  RenderTarget fromEquirectangular(equirectangular, [RenderTarget? renderTarget]) {
    return _fromTexture(equirectangular, renderTarget);
  }

  /// *
	/// * Generates a PMREM from an cubemap texture, which can be either LDR
	/// * or HDR. The ideal input cube size is 256 x 256,
	/// * as this matches best with the 256 x 256 cubemap output.
	/// *
  RenderTarget fromCubemap(cubemap, [RenderTarget? renderTarget]) {
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
    _dispose();

    if (_cubemapMaterial != null) _cubemapMaterial.dispose();
    if (_equirectMaterial != null) _equirectMaterial.dispose();
  }

  // private interface

  void _setSize(int cubeSize) {
    _lodMax = (MathUtils.log2(cubeSize.toDouble())).floor();
    _cubeSize = math.pow(2, _lodMax).toInt();
  }

  void _dispose() {
    _blurMaterial?.dispose();

    if (_pingPongRenderTarget != null) _pingPongRenderTarget.dispose();

    for (int i = 0; i < _lodPlanes.length; i++) {
      _lodPlanes[i].dispose();
    }
  }

  void _cleanup(RenderTarget outputTarget) {
    _renderer.setRenderTarget(_oldTarget);
    outputTarget.scissorTest = false;
    _setViewport(outputTarget, 0, 0, outputTarget.width.toDouble(), outputTarget.height.toDouble());
  }

  RenderTarget _fromTexture(texture, [RenderTarget? renderTarget]) {
    if (texture.mapping == CubeReflectionMapping ||
        texture.mapping == CubeRefractionMapping) {
      _setSize(texture.image.length == 0
          ? 16
          : (texture.image[0].width ?? texture.image[0].image.width));
    } else {
      // Equirectangular

      _setSize(texture.image.width ~/ 4 ?? 256);
    }

    _oldTarget = _renderer.getRenderTarget();

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
      "encoding": LinearEncoding,
      "depthBuffer": false
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

  void _sceneToCubeUV(Scene scene, double near, double far, RenderTarget cubeUVRenderTarget) {
    const double fov = 90;
    const double aspect = 1;
    final cubeCamera = PerspectiveCamera(fov, aspect, near, far);
    List<double> upSign = [1, -1, 1, 1, 1, 1];
    List<double> forwardSign = [1, 1, 1, -1, -1, -1];
    final renderer = _renderer;

    final originalAutoClear = renderer.autoClear;
    final toneMapping = renderer.toneMapping;
    renderer.getClearColor(_clearColor);

    renderer.toneMapping = NoToneMapping;
    renderer.autoClear = false;
    final backgroundMaterial = MeshBasicMaterial.fromMap({
      "name": 'PMREM.Background',
      "side": BackSide,
      "depthWrite": false,
      "depthTest": false,
    });
    final backgroundBox = Mesh(BoxGeometry(), backgroundMaterial);
    bool useSolidColor = false;
    final background = scene.background;
    if (background != null) {
      if (background is Color) {
        backgroundMaterial.color.setFrom(background);
        scene.background = null;
        useSolidColor = true;
      }
    } else {
      backgroundMaterial.color.setFrom(_clearColor);
      useSolidColor = true;
    }
    for (int i = 0; i < 6; i++) {
      final col = i % 3;
      if (col == 0) {
        cubeCamera.up.setValues(0, upSign[i], 0);
        cubeCamera.lookAt(Vector3(forwardSign[i], 0, 0));
      } else if (col == 1) {
        cubeCamera.up.setValues(0, 0, upSign[i]);
        cubeCamera.lookAt(Vector3(0, forwardSign[i], 0));
      } else {
        cubeCamera.up.setValues(0, upSign[i], 0);
        cubeCamera.lookAt(Vector3(0, 0, forwardSign[i]));
      }
      final size = _cubeSize.toDouble();
      _setViewport(cubeUVRenderTarget, col * size, i > 2 ? size : 0, size, size);
      renderer.setRenderTarget(cubeUVRenderTarget);
      if (useSolidColor) {
        renderer.render(backgroundBox, cubeCamera);
      }
      renderer.render(scene, cubeCamera);
    }
    backgroundBox.geometry?.dispose();
    backgroundBox.material?.dispose();

    renderer.toneMapping = toneMapping;
    renderer.autoClear = originalAutoClear;
    scene.background = background;
  }

  void _textureToCubeUV(texture, RenderTarget cubeUVRenderTarget) {
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
      final sigma =
          math.sqrt(_sigmas[i] * _sigmas[i] - _sigmas[i - 1] * _sigmas[i - 1]);

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
  void _blur(RenderTarget cubeUVRenderTarget, int lodIn, int lodOut, double sigma, poleAxis) {
    final pingPongRenderTarget = _pingPongRenderTarget;
    _halfBlur(cubeUVRenderTarget, pingPongRenderTarget, lodIn, lodOut, sigma,'latitudinal', poleAxis);
    _halfBlur(pingPongRenderTarget, cubeUVRenderTarget, lodOut, lodOut, sigma,'longitudinal', poleAxis);
  }

  void _halfBlur(RenderTarget targetIn, RenderTarget targetOut, int lodIn, int lodOut, double sigmaRadians, String direction, poleAxis) {
    final renderer = _renderer;
    final blurMaterial = _blurMaterial;

    if (direction != 'latitudinal' && direction != 'longitudinal') {
      print('blur direction must be either latitudinal or longitudinal!');
    }

    // Number of standard deviations at which to cut off the discrete approximation.
    const standardDeviations = 3;

    BufferGeometry? geometry;

    if (lodOut < _lodPlanes.length) {
      geometry = _lodPlanes[lodOut];
    }

    final blurMesh = Mesh(geometry, blurMaterial);
    final blurUniforms = blurMaterial.uniforms;

    final pixels = _sizeLods[lodIn] - 1;
    final radiansPerPixel = isFinite(sigmaRadians)
        ? math.pi / (2 * pixels)
        : 2 * math.pi / (2 * maxSamples - 1);
    final sigmaPixels = sigmaRadians / radiansPerPixel;
    final samples = isFinite(sigmaRadians)
        ? 1 + (standardDeviations * sigmaPixels).floor()
        : maxSamples;

    if (samples > maxSamples) {
      print("sigmaRadians, $sigmaRadians, is too large and will clip, as it requested $samples samples when the maximum is set to $maxSamples");
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

    blurUniforms['envMap']["value"] = targetIn.texture;
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
    return value == double.infinity;
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

      const cubeFaces = 6;
      const vertices = 6;
      const positionSize = 3;
      const uvSize = 2;
      const faceIndexSize = 1;

      final position = Float32Array(positionSize * vertices * cubeFaces);
      final uv = Float32Array(uvSize * vertices * cubeFaces);
      final faceIndex = Int32Array(faceIndexSize * vertices * cubeFaces);

      for (int face = 0; face < cubeFaces; face++) {
        double x = (face % 3) * 2 / 3 - 1;
        double y = face > 2 ? 0 : -1;
        List<double> coordinates = [
          x,
          y,
          0,
          x + 2 / 3,
          y,
          0,
          x + 2 / 3,
          y + 1,
          0,
          x,
          y,
          0,
          x + 2 / 3,
          y + 1,
          0,
          x,
          y + 1,
          0
        ];
        position.set(coordinates, positionSize * vertices * face);
        uv.set(uv1, uvSize * vertices * face);
        final faces = [face, face, face, face, face, face];
        faceIndex.set(faces, faceIndexSize * vertices * face);
      }

      final planes = BufferGeometry();
      planes.setAttributeFromString('position', Float32BufferAttribute(position, positionSize, false));
      planes.setAttributeFromString('uv', Float32BufferAttribute(uv, uvSize, false));
      planes.setAttributeFromString('faceIndex', Int32BufferAttribute(faceIndex, faceIndexSize, false));
      lodPlanes.add(planes);

      if (lod > lodMin) {
        lod--;
      }
    }

    return {"lodPlanes": lodPlanes, "sizeLods": sizeLods, "sigmas": sigmas};
  }

  WebGLRenderTarget _createRenderTarget(int width, int height, Map<String,dynamic> params) {
    final cubeUVRenderTarget = WebGLRenderTarget(width, height, WebGLRenderTargetOptions(params));
    cubeUVRenderTarget.texture.mapping = CubeUVReflectionMapping;
    cubeUVRenderTarget.texture.name = 'PMREM.cubeUv';
    cubeUVRenderTarget.scissorTest = true;
    return cubeUVRenderTarget;
  }

  void _setViewport(RenderTarget target, double x, double y, double width, double height) {
    target.viewport.setValues(x, y, width, height);
    target.scissor.setValues(x, y, width, height);
  }

  String _getPlatformHelper() {
    if (kIsWeb) {
      return "";
    }

    // if (Platform.isMacOS) {
    //   return """
    //     #define varying in
    //     out highp vec4 pc_fragColor;
    //     #define gl_FragColor pc_fragColor
    //     #define gl_FragDepthEXT gl_FragDepth
    //     #define texture2D texture
    //     #define textureCube texture
    //     #define texture2DProj textureProj
    //     #define texture2DLodEXT textureLod
    //     #define texture2DProjLodEXT textureProjLod
    //     #define textureCubeLodEXT textureLod
    //     #define texture2DGradEXT textureGrad
    //     #define texture2DProjGradEXT textureProjGrad
    //     #define textureCubeGradEXT textureGrad
    //   """;
    // }
    return """
      
    """;
  }

  ShaderMaterial _getBlurShader(int lodMax, int width, int height) {
    final weights = Float32List(maxSamples);
    final poleAxis = Vector3(0, 1, 0);
    final shaderMaterial = ShaderMaterial.fromMap({
      "name": 'SphericalGaussianBlur',
      "defines": {
        'n': maxSamples,
        'CUBEUV_TEXEL_WIDTH': 1.0 / width,
        'CUBEUV_TEXEL_HEIGHT': 1.0 / height,
        // 'CUBEUV_MAX_MIP': "$lodMax.0",
      },
      "uniforms": {
        'envMap': {},
        'samples': {"value": 1},
        'weights': {"value": weights},
        'latitudinal': {"value": false},
        'dTheta': {"value": 0.0},
        'mipInt': {"value": 0},
        'poleAxis': {"value": poleAxis}
      },
      "vertexShader": _getCommonVertexShader(),
      "fragmentShader": """
        ${_getPlatformHelper()}

        precision mediump float;
        precision mediump int;

        varying vec3 vOutputDirection;

        uniform sampler2D envMap;
        uniform int samples;
        uniform float weights[ n ];
        uniform bool latitudinal;
        uniform float dTheta;
        uniform float mipInt;
        uniform vec3 poleAxis;

        #define ENVMAP_TYPE_CUBE_UV
        #include <cube_uv_reflection_fragment>

        vec3 getSample( float theta, vec3 axis ) {

          float cosTheta = cos( theta );
          // Rodrigues' axis-angle rotation
          vec3 sampleDirection = vOutputDirection * cosTheta
            + cross( axis, vOutputDirection ) * sin( theta )
            + axis * dot( axis, vOutputDirection ) * ( 1.0 - cosTheta );

          return bilinearCubeUV( envMap, sampleDirection, mipInt );

        }

        void main() {

          vec3 axis = latitudinal ? poleAxis : cross( poleAxis, vOutputDirection );

          if ( all( equal( axis, vec3( 0.0 ) ) ) ) {

            axis = vec3( vOutputDirection.z, 0.0, - vOutputDirection.x );

          }

          axis = normalize( axis );

          gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );
          gl_FragColor.rgb += weights[ 0 ] * getSample( 0.0, axis );

          for ( int i = 1; i < n; i++ ) {

            if ( i >= samples ) {

              break;

            }

            float theta = dTheta * float( i );
            gl_FragColor.rgb += weights[ i ] * getSample( -1.0 * theta, axis );
            gl_FragColor.rgb += weights[ i ] * getSample( theta, axis );

          }

        }
      """,
      "blending": NoBlending,
      "depthTest": false,
      "depthWrite": false
    });

    return shaderMaterial;
  }

  ShaderMaterial _getEquirectMaterial() {
    final shaderMaterial = ShaderMaterial.fromMap({
      "name": 'EquirectangularToCubeUV',
      "uniforms": {'envMap': {}},
      "vertexShader": _getCommonVertexShader(),
      "fragmentShader": """
        ${_getPlatformHelper()}

        precision mediump float;
        precision mediump int;

        varying vec3 vOutputDirection;

        uniform sampler2D envMap;

        #include <common>

        void main() {
          vec3 outputDirection = normalize( vOutputDirection );
          vec2 uv = equirectUv( outputDirection );
          gl_FragColor = vec4( texture2D ( envMap, uv ).rgb, 1.0 );
        }
      """,
      "blending": NoBlending,
      "depthTest": false,
      "depthWrite": false
    });

    return shaderMaterial;
  }

  ShaderMaterial _getCubemapShader() {
    final shaderMaterial = ShaderMaterial.fromMap({
      "name": 'CubemapToCubeUV',
      "uniforms": {
        'envMap': {},
        'flipEnvMap': {"value": -1}
      },
      "vertexShader": _getCommonVertexShader(),
      "fragmentShader": """
        ${_getPlatformHelper()}
        
        precision mediump float;
        precision mediump int;

        uniform float flipEnvMap;

        varying vec3 vOutputDirection;

        uniform samplerCube envMap;

        void main() {

          gl_FragColor = textureCube( envMap, vec3( flipEnvMap * vOutputDirection.x, vOutputDirection.yz ) );

        }
      """,
      "blending": NoBlending,
      "depthTest": false,
      "depthWrite": false
    });

    return shaderMaterial;
  }

  String _getPlatformVertexHelper() {
    if (kIsWeb) {
      return "";
    }

    if (Platform.isMacOS) {
      return """
        #define attribute in
        #define varying out
        #define texture2D texture
      """;
    }

    return """
    """;
  }

  String _getCommonVertexShader() {
    return """

      ${_getPlatformVertexHelper()}

      precision mediump float;
      precision mediump int;

      attribute float faceIndex;

      varying vec3 vOutputDirection;

      // RH coordinate system; PMREM face-indexing convention
      vec3 getDirection( vec2 uv, float face ) {

        uv = 2.0 * uv - 1.0;

        vec3 direction = vec3( uv, 1.0 );

        if ( face == 0.0 ) {

          direction = direction.zyx; // ( 1, v, u ) pos x

        } else if ( face == 1.0 ) {

          direction = direction.xzy;
          direction.xz *= -1.0; // ( -u, 1, -v ) pos y

        } else if ( face == 2.0 ) {

          direction.x *= -1.0; // ( -u, v, 1 ) pos z

        } else if ( face == 3.0 ) {

          direction = direction.zyx;
          direction.xz *= -1.0; // ( -1, v, -u ) neg x

        } else if ( face == 4.0 ) {

          direction = direction.xzy;
          direction.xy *= -1.0; // ( -u, -1, v ) neg y

        } else if ( face == 5.0 ) {

          direction.z *= -1.0; // ( u, v, -1 ) neg z

        }

        return direction;

      }

      void main() {

        vOutputDirection = getDirection( uv, faceIndex );
        gl_Position = vec4( position, 1.0 );

      }
    """;
  }
}
