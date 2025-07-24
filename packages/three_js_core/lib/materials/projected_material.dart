import 'dart:async';

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class ProjectedMaterial extends MeshPhysicalMaterial {
  Camera? _camera;
  bool _cover = false;
  double _textureScale = 1;

  Camera? get camera => _camera;
  set camera(Camera? camera) {
    if (camera == null) {
      throw('Invalid camera set to the ProjectedMaterial');
    }

    if (camera.type != _camera?.type) {
      throw('Cannot change camera type after the material has been created. Use another material.');
    }

    _camera = camera;
    _saveDimensions();
  }

  Texture? get texture => this.uniforms['projectedTexture']['value'];
  
  set texture(Texture? texture) {
    this.uniforms['projectedTexture']['value'] = texture;
    this.uniforms['isTextureLoaded']['value'] = texture?.image != null;

    if (this.uniforms['isTextureLoaded']['value'] == null) {
      ProjectedMaterialUtils.addLoadListener(texture!, (t){
        this.uniforms['isTextureLoaded']['value'] = true;
        this.dispatchEvent(Event(type: 'textureload'));
        _saveDimensions();
      });
    } else {
      _saveDimensions();
    }
  }

  get textureScale => _textureScale;
  set textureScale(textureScale) {
    _textureScale = textureScale;
    _saveDimensions();
  }

  get textureOffset => this.uniforms['textureOffset']['value'];
  set textureOffset(textureOffset) {
    this.uniforms['textureOffset']['value'] = textureOffset;
  }

  get backgroundOpacity => this.uniforms['backgroundOpacity']['value'];
  
  set backgroundOpacity(backgroundOpacity) {
    this.uniforms['backgroundOpacity']['value'] = backgroundOpacity;
    if (backgroundOpacity < 1 && !this.transparent) {
      console.warning('You have to pass "transparent: true" to the ProjectedMaterial for the backgroundOpacity option to work');
    }
  }

  get cover => _cover;
  set cover(cover) {
    _cover = cover;
    _saveDimensions();
  }

  ProjectedMaterial({
    Camera? camera,
    required Texture texture,
    textureScale = 1,
    Vector2? textureOffset,
    backgroundOpacity = 1,
    cover = false,
    Map<String,dynamic>? options
  }):super.fromMap(options){
    if (backgroundOpacity < 1 && options?['transparent'] == false) {
      console.warning('You have to pass "transparent: true" to the ProjectedMaterial for the backgroundOpacity option to work');
    }

    //Object.defineProperty(this, 'isProjectedMaterial', { 'value': true });

    // save the private variables
    _camera = camera ?? PerspectiveCamera();
    _cover = cover;
    _textureScale = textureScale;

    // scale to keep the image proportions and apply textureScale
    final [widthScaled, heightScaled] = ProjectedMaterialUtils.computeScaledDimensions(
      texture,
      camera!,
      textureScale,
      cover
    );

    this.uniforms = {
      'projectedTexture': { 'value': texture },
      // this avoids rendering black if the texture
      // hasn't loaded yet
      'isTextureLoaded': { 'value': texture.image != null},
      // don't show the texture if we haven't called project()
      'isTextureProjected': { 'value': false },
      // if we have multiple materials we want to show the
      // background only of the first material
      'backgroundOpacity': { 'value': backgroundOpacity },
      // these will be set on project()
      'viewMatrixCamera': { 'value': Matrix4() },
      'projectionMatrixCamera': { 'value': Matrix4() },
      'projPosition': { 'value': Vector3() },
      'projDirection': { 'value': Vector3(0, 0, -1) },
      // we will set this later when we will have positioned the object
      'savedModelMatrix': { 'value': Matrix4() },
      'widthScaled': { 'value': widthScaled },
      'heightScaled': { 'value': heightScaled },
      'textureOffset': { 'value': textureOffset },
    };

    this.onBeforeCompile = (ShaderMaterial shader){
      // expose also the material's uniforms
      this.uniforms.addAll(shader.uniforms);
      shader.uniforms = this.uniforms;

      if (camera is OrthographicCamera) {
        shader.defines?['ORTHOGRAPHIC'] = '';
      }

      shader.vertexShader = ProjectedMaterialUtils.monkeyPatch(shader.vertexShader!,
        header: /* glsl */ '''
          uniform mat4 viewMatrixCamera;
          uniform mat4 projectionMatrixCamera;

          #ifdef USE_INSTANCING
          attribute vec4 savedModelMatrix0;
          attribute vec4 savedModelMatrix1;
          attribute vec4 savedModelMatrix2;
          attribute vec4 savedModelMatrix3;
          #else
          uniform mat4 savedModelMatrix;
          #endif

          varying vec3 vSavedNormal;
          varying vec4 vTexCoords;
          #ifndef ORTHOGRAPHIC
          varying vec4 vWorldPosition;
          #endif
        ''',
        main: /* glsl */ '''
          #ifdef USE_INSTANCING
          mat4 savedModelMatrix = mat4(
            savedModelMatrix0,
            savedModelMatrix1,
            savedModelMatrix2,
            savedModelMatrix3
          );
          #endif

          vSavedNormal = mat3(savedModelMatrix) * normal;
          vTexCoords = projectionMatrixCamera * viewMatrixCamera * savedModelMatrix * vec4(position, 1.0);
          #ifndef ORTHOGRAPHIC
          vWorldPosition = savedModelMatrix * vec4(position, 1.0);
          #endif
        '''
      );

      shader.fragmentShader = ProjectedMaterialUtils.monkeyPatch(shader.fragmentShader!,
        header: /* glsl */ '''
          uniform sampler2D projectedTexture;
          uniform bool isTextureLoaded;
          uniform bool isTextureProjected;
          uniform float backgroundOpacity;
          uniform vec3 projPosition;
          uniform vec3 projDirection;
          uniform float widthScaled;
          uniform float heightScaled;
          uniform vec2 textureOffset;

          varying vec3 vSavedNormal;
          varying vec4 vTexCoords;
          #ifndef ORTHOGRAPHIC
          varying vec4 vWorldPosition;
          #endif

          float mapRange(float value, float min1, float max1, float min2, float max2) {
            return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
          }
        ''',
        replaces: {
          'vec4 diffuseColor = vec4( diffuse, opacity );': /* glsl */ '''
            // clamp the w to make sure we don't project behind
            float w = max(vTexCoords.w, 0.0);

            vec2 uv = (vTexCoords.xy / w) * 0.5 + 0.5;

            uv += textureOffset;

            // apply the corrected width and height
            uv.x = mapRange(uv.x, 0.0, 1.0, 0.5 - widthScaled / 2.0, 0.5 + widthScaled / 2.0);
            uv.y = mapRange(uv.y, 0.0, 1.0, 0.5 - heightScaled / 2.0, 0.5 + heightScaled / 2.0);

            // this makes sure we don't sample out of the texture
            bool isInTexture = (max(uv.x, uv.y) <= 1.0 && min(uv.x, uv.y) >= 0.0);

            // this makes sure we don't render also the back of the object
            #ifdef ORTHOGRAPHIC
            vec3 projectorDirection = projDirection;
            #else
            vec3 projectorDirection = normalize(projPosition - vWorldPosition.xyz);
            #endif
            float dotProduct = dot(vSavedNormal, projectorDirection);
            bool isFacingProjector = dotProduct > 0.0000001;


            vec4 diffuseColor = vec4(diffuse, opacity * backgroundOpacity);

            if (isFacingProjector && isInTexture && isTextureLoaded && isTextureProjected) {
              vec4 textureColor = texture2D(projectedTexture, uv);

              // apply the material opacity
              textureColor.a *= opacity;

              // https://learnopengl.com/Advanced-OpenGL/Blending
              diffuseColor = textureColor * textureColor.a + diffuseColor * (1.0 - textureColor.a);
            }
          '''
        }
      );
    };

    // Listen on resize if the camera used for the projection
    // is the same used to render.
    // We do this on window resize because there is no way to
    // listen for the resize of the renderer
    addEventListener('resize', _saveCameraProjectionMatrix);

    // If the image texture passed hasn't loaded yet,
    // wait for it to load and compute the correct proportions.
    // This avoids rendering black while the texture is loading
    ProjectedMaterialUtils.addLoadListener(texture, (t){
      this.uniforms['isTextureLoaded']['value'] = true;
      this.dispatchEvent(Event( type: 'textureload'));
      _saveDimensions();
    });
  }

  void _saveCameraProjectionMatrix(){
    this.uniforms['projectionMatrixCamera']['value'].setFrom(this.camera!.projectionMatrix);
    _saveDimensions();
  }

  void _saveDimensions() {
    final [widthScaled, heightScaled] = ProjectedMaterialUtils.computeScaledDimensions(
      this.texture!,
      this.camera!,
      this.textureScale,
      this.cover
    );

    this.uniforms['widthScaled']['value'] = widthScaled;
    this.uniforms['heightScaled']['value'] = heightScaled;
  }

  void _saveCameraMatrices() {
    // make sure the camera matrices are updated
    this.camera?.updateProjectionMatrix();
    this.camera?.updateMatrixWorld();
    this.camera?.updateWorldMatrix(true,false);

    // update the uniforms from the camera so they're
    // fixed in the camera's position at the projection time
    final viewMatrixCamera = this.camera?.matrixWorldInverse;
    final projectionMatrixCamera = this.camera?.projectionMatrix;
    final modelMatrixCamera = this.camera?.matrixWorld;

    this.uniforms['viewMatrixCamera']['value'].setFrom(viewMatrixCamera);
    this.uniforms['projectionMatrixCamera']['value'].setFrom(projectionMatrixCamera);
    this.uniforms['projPosition']['value'].setFromMatrixPosition(modelMatrixCamera);
    this.uniforms['projDirection']['value'].setValues(0, 0, 1).applyMatrix4(modelMatrixCamera);

    // tell the shader we've projected
    this.uniforms['isTextureProjected']['value'] = true;
  }

  void project(Mesh mesh) {
    if (
      !(mesh.material is GroupMaterial
        ? (mesh.material as GroupMaterial).children.any((m) => m is ProjectedMaterial)
        : mesh.material is ProjectedMaterial)
    ) {
      throw ('The mesh material must be a ProjectedMaterial');
    }

    if (
      !(mesh.material is GroupMaterial
        ? (mesh.material as GroupMaterial).children.any((m) => m == this)
        : mesh.material == this)
    ) {
      throw ('''The provided mesh doesn't have the same material as where project() has been called from''');
    }

    // make sure the matrix is updated
    mesh.updateWorldMatrix(true, false);

    // we save the object model matrix so it's projected relative
    // to that position, like a snapshot
    this.uniforms['savedModelMatrix']['value'].setFrom(mesh.matrixWorld);

    // if the material is not the first, output just the texture
    if (mesh.material is GroupMaterial) {
      final materialIndex = (mesh.material  as GroupMaterial).children.indexOf(this);
      if (!(mesh.material  as GroupMaterial).children[materialIndex].transparent) {
        console.warning('''You have to pass "transparent: true" to the ProjectedMaterial if you're working with multiple materials.''');
      }
      if (materialIndex > 0) {
        this.uniforms['backgroundOpacity']['value'] = 0;
      }
    }

    // persist also the current camera position and matrices
    _saveCameraMatrices();
  }

  projectInstanceAt(int index, InstancedMesh instancedMesh, Matrix4 matrixWorld, { bool forceCameraSave = false }) {
    if (
      !(instancedMesh.material is GroupMaterial
        ? (instancedMesh.material as GroupMaterial).children.every((m) => m is ProjectedMaterial)
        : instancedMesh.material is ProjectedMaterial)
    ) {
      throw ('The InstancedMesh material must be a ProjectedMaterial');
    }

    if (
      !(instancedMesh.material is GroupMaterial
        ? (instancedMesh.material as GroupMaterial).children.any((m) => m == this)
        : instancedMesh.material == this)
    ) {
      throw ('''The provided InstancedMeshhave't i samenclude thas e material where project() has been called from''');
    }

    if (
      instancedMesh.geometry?.attributes['savedModelMatrix0'] == false ||
      instancedMesh.geometry?.attributes['savedModelMatrix1'] == false ||
      instancedMesh.geometry?.attributes['savedModelMatrix2'] == false ||
      instancedMesh.geometry?.attributes['savedModelMatrix3'] == false 
    ) {
      throw ('No allocated data found on the geometry, please call "ProjectedMaterialUtils.allocateProjectionData(geometry, instancesCount)}"');
    }

    instancedMesh.geometry?.attributes['savedModelMatrix0'].setXYZW(
      index,
      matrixWorld.storage[0],
      matrixWorld.storage[1],
      matrixWorld.storage[2],
      matrixWorld.storage[3]
    );
    instancedMesh.geometry?.attributes['savedModelMatrix1'].setXYZW(
      index,
      matrixWorld.storage[4],
      matrixWorld.storage[5],
      matrixWorld.storage[6],
      matrixWorld.storage[7]
    );
    instancedMesh.geometry?.attributes['savedModelMatrix2'].setXYZW(
      index,
      matrixWorld.storage[8],
      matrixWorld.storage[9],
      matrixWorld.storage[10],
      matrixWorld.storage[11]
    );
    instancedMesh.geometry?.attributes['savedModelMatrix3'].setXYZW(
      index,
      matrixWorld.storage[12],
      matrixWorld.storage[13],
      matrixWorld.storage[14],
      matrixWorld.storage[15]
    );

    // if the material is not the first, output just the texture
    if (instancedMesh.material is GroupMaterial) {
      final materialIndex = (instancedMesh.material as GroupMaterial).children.indexOf(this);
      if (!(instancedMesh.material as GroupMaterial).children[materialIndex].transparent) {
        console.warning('''You have to pass "transparent: true" to the ProjectedMaterial if you're working with multiple materials.''');
      }
      if (materialIndex > 0) {
        this.uniforms['backgroundOpacity']['value'] = 0;
      }
    }

    // persist the current camera position and matrices
    // only if it's the first instance since most surely
    // in all other instances the camera won't change
    if (index == 0 || forceCameraSave) {
      _saveCameraMatrices();
    }
  }

  ProjectedMaterial copy(source) {
    super.copy(source);
    if(source is ProjectedMaterial){
      this.camera = source.camera;
      this.texture = source.texture;
      this.textureScale = source.textureScale;
      this.textureOffset = source.textureOffset;
      this.cover = source.cover;
    }

    return this;
  }

  void dispose() {
    super.dispose();
    removeEventListener('resize', _saveCameraProjectionMatrix);
  }
}

class ProjectedMaterialUtils{
  static String monkeyPatch(String shader, { Map<String,String>? defines, String header = '', String main = '', Map<String,String>? replaces}) {
    String patchedShader = shader;

    final replaceAll = (String str, String find, String rep) => str.split(find).join(rep);
    replaces?.keys.forEach((key) {
      patchedShader = replaceAll(patchedShader, key, replaces[key]!);
    });

    patchedShader = patchedShader.replaceAll(
      'void main() {',
      '''
      ${header}
      void main() {
        ${main}
      '''
    );

    final stringDefines = defines?.keys
      .map((d) => '''#define ${d} ${defines[d]}''')
      .join('\n');

    return '''
      ${stringDefines}
      ${patchedShader}
    ''';
  }

  // run the callback when the image will be loaded
  static void addLoadListener(Texture texture, void Function(Texture) callback) {
    // return if it's already loaded
    if (texture.image is VideoTexture && texture.image.width != 0 && texture.image.height != 0) {
      return;
    }

    Timer? interval;

    interval = Timer.periodic(const Duration(milliseconds: 16),(Timer t){
      if (texture.image is VideoTexture && texture.image.width != 0 && texture.image.height != 0) {
        interval?.cancel();
        interval = null;
        return callback(texture);
      }
    });
  }

  // get camera ratio from different types of cameras
  static double getCameraRatio(Camera camera) {
    switch (camera.type) {
      case 'PerspectiveCamera': {
        return camera.aspect;
      }
      case 'OrthographicCamera': {
        final width = (camera.right - camera.left).abs();
        final height = (camera.top - camera.bottom).abs();
        return width / height;
      }
      default: {
        throw ('${camera.type} is currently not supported in ProjectedMaterial');
      }
    }
  }

  // scale to keep the image proportions and apply textureScale
  static List<double> computeScaledDimensions(Texture texture, Camera camera, double textureScale, bool cover) {
    // return some default values if the image hasn't loaded yet
    if (!texture.image) {
      return [1, 1];
    }

    // return if it's a video and if the video hasn't loaded yet
    if (Texture is VideoTexture && texture.image.width == 0 && texture.image.height == 0) {//if (texture.image.videoWidth == 0 && texture.image.videoHeight == 0) {
      return [1, 1];
    }

    final sourceWidth = texture.image.width;// ?? texture.image.videoWidth ?? texture.image.clientWidth;
    final sourceHeight = texture.image.height;// ?? texture.image.videoHeight ?? texture.image.clientHeight;

    final double ratio = sourceWidth / sourceHeight;
    final ratioCamera = getCameraRatio(camera);
    final widthCamera = 1;
    final heightCamera = widthCamera * (1 / ratioCamera);
    double widthScaled;
    double heightScaled;
    if (cover ? ratio > ratioCamera : ratio < ratioCamera) {
      final width = heightCamera * ratio;
      widthScaled = 1 / ((width / widthCamera) * textureScale);
      heightScaled = 1 / textureScale;
    } else {
      final height = widthCamera * (1 / ratio);
      heightScaled = 1 / ((height / heightCamera) * textureScale);
      widthScaled = 1 / textureScale;
    }

    return [widthScaled, heightScaled];
  }

  void allocateProjectionData(BufferGeometry geometry, int instancesCount) {
    geometry.setAttributeFromString(
      'savedModelMatrix0',
      InstancedBufferAttribute(Float32Array(instancesCount * 4), 4)
    );
    geometry.setAttributeFromString(
      'savedModelMatrix1',
      InstancedBufferAttribute(Float32Array(instancesCount * 4), 4)
    );
    geometry.setAttributeFromString(
      'savedModelMatrix2',
      InstancedBufferAttribute(Float32Array(instancesCount * 4), 4)
    );
    geometry.setAttributeFromString(
      'savedModelMatrix3',
      InstancedBufferAttribute(Float32Array(instancesCount * 4), 4)
    );
  }
}