import '../cameras/index.dart';
import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import 'light_shadow.dart';

/// This is used internally by [PointLights] for calculating
/// shadows.
/// 
/// ```
/// //Create a WebGLRenderer and turn on shadows in the renderer
/// final renderer = WebGLRenderer();
/// renderer.shadowMap.enabled = true;
/// renderer.shadowMap.type = PCFSoftShadowMap; // default PCFShadowMap
///
/// //Create a PointLight and turn on shadows for the light
/// final light = PointLight( 0xffffff, 1, 100 );
/// light.position.setValues( 0, 10, 4 );
/// light.castShadow = true; // default false
/// scene.add( light );
///
/// //Set up shadow properties for the light
/// light.shadow.mapSize.width = 512; // default
/// light.shadow.mapSize.height = 512; // default
/// light.shadow.camera.near = 0.5; // default
/// light.shadow.camera.far = 500; // default
///
/// //Create a sphere that cast shadows (but does not receive them)
/// final sphereGeometry = SphereGeometry( 5, 32, 32 );
/// final sphereMaterial = MeshStandardMaterial( { MaterialProperty.color: 0xff0000 } );
/// final sphere = Mesh( sphereGeometry, sphereMaterial );
/// sphere.castShadow = true; //default is false
/// sphere.receiveShadow = false; //default
/// scene.add( sphere );
///
/// //Create a plane that receives shadows (but does not cast them)
/// final planeGeometry = PlaneGeometry( 20, 20, 32, 32 );
/// final planeMaterial = MeshStandardMaterial( { MaterialProperty.color: 0x00ff00 } );
/// final plane = Mesh( planeGeometry, planeMaterial );
/// plane.receiveShadow = true;
/// scene.add( plane );
///
/// //Create a helper for the shadow camera (optional)
/// final helper = CameraHelper( light.shadow.camera );
/// scene.add( helper );
/// ```
class PointLightShadow extends LightShadow {
  late List<Vector3> _cubeDirections;
  late List<Vector3> _cubeUps;

  /// Creates a new [name]. This is not intended to be called directly - it is
  /// called internally by [PointLight].
  PointLightShadow():super(PerspectiveCamera(90, 1, 0.5, 500)) {
    frameExtents.setFrom(Vector2(4, 2));

    viewportCount = 6;
    
    viewports.removeAt(0);
    viewports.addAll([
      // These viewports map a cube-map onto a 2D texture with the
      // following orientation:
      //
      //  xzXZ
      //   y Y
      //
      // X - Positive x direction
      // x - Negative x direction
      // Y - Positive y direction
      // y - Negative y direction
      // Z - Positive z direction
      // z - Negative z direction

      // positive X
      Vector4(2, 1, 1, 1),
      // negative X
      Vector4(0, 1, 1, 1),
      // positive Z
      Vector4(3, 1, 1, 1),
      // negative Z
      Vector4(1, 1, 1, 1),
      // positive Y
      Vector4(3, 0, 1, 1),
      // negative Y
      Vector4(1, 0, 1, 1)
    ]);

    _cubeDirections = [
      Vector3(1, 0, 0),
      Vector3(-1, 0, 0),
      Vector3(0, 0, 1),
      Vector3(0, 0, -1),
      Vector3(0, 1, 0),
      Vector3(0, -1, 0)
    ];

    _cubeUps = [
      Vector3(0, 1, 0),
      Vector3(0, 1, 0),
      Vector3(0, 1, 0),
      Vector3(0, 1, 0),
      Vector3(0, 0, 1),
      Vector3(0, 0, -1)
    ];
  }

  PointLightShadow.fromJson(Map<String, dynamic> json, Map<String,dynamic> rootJson):super.fromJson(json,rootJson) {
    camera = Object3D.castJson(json["camera"],rootJson) as Camera;
  }

  /// Update the matrices for the camera and shadow, used internally by the
  /// renderer.
  /// 
  /// [light] - the light for which the shadow is being rendered.
  /// 
  /// [viewportIndex] - calculates the matrix for this viewport
  @override
  void updateMatrices(light, {viewportIndex = 0}) {
    final camera = this.camera;
    final shadowMatrix = matrix;

    final far = light.distance ?? camera!.far;

    if (far != camera!.far) {
      camera.far = far;
      camera.updateProjectionMatrix();
    }

    lightPositionWorld.setFromMatrixPosition(light.matrixWorld);
    camera.position.setFrom(lightPositionWorld);

    lookTarget.setFrom(camera.position);
    lookTarget.add(_cubeDirections[viewportIndex]);
    camera.up.setFrom(_cubeUps[viewportIndex]);
    camera.lookAt(lookTarget);
    camera.updateMatrixWorld(false);

    shadowMatrix.makeTranslation(-lightPositionWorld.x, -lightPositionWorld.y, -lightPositionWorld.z);
    projScreenMatrix.multiply2(camera.projectionMatrix, camera.matrixWorldInverse);
    frustum.setFromMatrix(projScreenMatrix);
  }
}
