import '../cameras/index.dart';
import 'light_shadow.dart';

/// This is used internally by [DirectionalLights] for
/// calculating shadows.
///
/// Unlike the other shadow classes, this uses an [OrthographicCamera] to
/// calculate the shadows, rather than a [PerspectiveCamera]. This is
/// because light rays from a [DirectionalLight] are parallel.
/// 
/// ```
/// final light = DirectionalLight(Color.fromHex32(0xffffff), 1 );
/// light.position.setValues( 0, 1, 0 ); //default; light shining from top
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
/// final sphereMaterial = MeshStandardMaterial({MaterialProperty.color: 0xff0000});
/// final sphere = Mesh( sphereGeometry, sphereMaterial );
/// sphere.castShadow = true; //default is false
/// sphere.receiveShadow = false; //default
/// scene.add( sphere );
///
/// //Create a plane that receives shadows (but does not cast them)
/// final planeGeometry = PlaneGeometry( 20, 20, 32, 32 );
/// final planeMaterial = MeshStandardMaterial({MaterialProperty.color: 0x00ff00});
/// final plane = Mesh( planeGeometry, planeMaterial );
/// plane.receiveShadow = true;
/// scene.add( plane );
///
/// //Create a helper for the shadow camera (optional)
/// final helper = CameraHelper( light.shadow.camera );
/// scene.add( helper );
/// ```
class DirectionalLightShadow extends LightShadow {
  bool isDirectionalLightShadow = true;

  /// Creates a new [name]. This is not intended to be called directly - it is
  /// called internally by [DirectionalLight].
  DirectionalLightShadow():super(OrthographicCamera(-5, 5, 5, -5, 0.5, 500));
}
