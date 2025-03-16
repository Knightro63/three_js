import 'package:three_js_math/math/index.dart';

import '../cameras/index.dart';
import 'light.dart';
import 'light_shadow.dart';

/// This is used internally by [SpotLights] for calculating
/// shadows.
/// 
/// ```
/// //Create a WebGLRenderer and turn on shadows in the renderer
/// final renderer = WebGLRenderer();
/// renderer.shadowMap.enabled = true;
/// renderer.shadowMap.type = PCFSoftShadowMap; // default PCFShadowMap
///
/// //Create a SpotLight and turn on shadows for the light
/// final light = SpotLight( 0xffffff );
/// light.castShadow = true; // default false
/// scene.add( light );
///
/// //Set up shadow properties for the light
/// light.shadow.mapSize.width = 512; // default
/// light.shadow.mapSize.height = 512; // default
/// light.shadow.camera.near = 0.5; // default
/// light.shadow.camera.far = 500; // default
/// light.shadow.focus = 1; // default
///
/// //Create a sphere that cast shadows (but does not receive them)
/// final sphereGeometry = SphereGeometry( 5, 32, 32 );
/// final sphereMaterial = MeshStandardMaterial( { MaterilaProperty.color: 0xff0000 } );
/// final sphere = Mesh( sphereGeometry, sphereMaterial );
/// sphere.castShadow = true; //default is false
/// sphere.receiveShadow = false; //default
/// scene.add( sphere );
///
/// //Create a plane that receives shadows (but does not cast them)
/// final planeGeometry = PlaneGeometry( 20, 20, 32, 32 );
/// final planeMaterial = MeshStandardMaterial( { MaterilaProperty.color: 0x00ff00 } );
/// final plane = Mesh( planeGeometry, planeMaterial );
/// plane.receiveShadow = true;
/// scene.add( plane );
///
/// //Create a helper for the shadow camera (optional)
/// final helper = CameraHelper( light.shadow.camera );
/// scene.add( helper );
/// ```
class SpotLightShadow extends LightShadow {
  /// The constructor creates a [PerspectiveCamera] to
  /// manage the shadow's view of the world.
  SpotLightShadow() : super(PerspectiveCamera(50, 1, 0.5, 500)) {
    focus = 1;
  }

  @override
  void updateMatrices(Light light, {int viewportIndex = 0}) {
    PerspectiveCamera camera = this.camera as PerspectiveCamera;
    final fov = light.angle!.toDeg()* 2 * focus;
    final aspect = mapSize.x / mapSize.y;
    final far = light.distance ?? camera.far;

    if (fov != camera.fov || aspect != camera.aspect || far != camera.far) {
      camera.fov = fov;
      camera.aspect = aspect;
      camera.far = far;
      camera.updateProjectionMatrix();
    }

    super.updateMatrices(light, viewportIndex: viewportIndex);
  }

  @override
  SpotLightShadow copy(LightShadow source) {
    super.copy(source);
    focus = source.focus;
    return this;
  }
}
