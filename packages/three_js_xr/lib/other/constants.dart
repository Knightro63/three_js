import 'dart:convert';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_xr/app/index.dart';
import 'package:three_js_xr/models/component.dart';
import 'package:three_js_xr/models/controller/motion_controllers_modle.dart';
import 'package:three_js_xr/models/controller/visual_response.dart';
import 'package:three_js_xr/models/controller/xr_controller_modle.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

const DEFAULT_PROFILES_PATH = 'https://cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0/dist/profiles';
const DEFAULT_PROFILE = 'generic-trigger';

enum DistorsionType{pincushion,barrel}

class XROptions{
  double k1 = 0.022;
  double k2 = 0.024;
  double eyeSep = 0.064;
  late Vector2 lensSize;
  late Vector2 eyeOffset;
  DistorsionType distorsionType = DistorsionType.barrel;

  double width;
  double height;
  double dpr;

  XROptions({
    this.eyeSep = 0.064,
    this.k1 = 0.022, // Adjust for desired distortion
    this.k2 = 0.024, // Adjust for desired distortion
    Vector2? lensSize,
    Vector2? eyeOffset,
    this.distorsionType = DistorsionType.barrel,
    this.width = 0,
    this.height = 0,
    this.dpr = 1.0
  }){
    this.lensSize = lensSize ?? Vector2(1,1);
    this.eyeOffset = eyeOffset ?? Vector2(0,0);
  }
}

final Map<String,dynamic> constants = {
  'Handedness': {
    'NONE': 'none',
    'LEFT': 'left',
    'RIGHT': 'right'
  },
  'ComponentState': {
    'DEFAULT': 'default',
    'TOUCHED': 'touched',
    'PRESSED': 'pressed'
  },
  'ComponentProperty': {
    'BUTTON': 'button',
    'X_AXIS': 'xAxis',
    'Y_AXIS': 'yAxis',
    'STATE': 'state'
  },
  'ComponentType': {
    'TRIGGER': 'trigger',
    'SQUEEZE': 'squeeze',
    'TOUCHPAD': 'touchpad',
    'THUMBSTICK': 'thumbstick',
    'BUTTON': 'button'
  },
  'ButtonTouchThreshold': 0.05,
  'AxisTouchThreshold': 0.1,
  'VisualResponseProperty': {
    'TRANSFORM': 'transform',
    'VISIBILITY': 'visibility'
  }
};

Future<Map> fetchJsonFile(String path) async{
  final response = await FileLoader().unknown(path);
  if(response == null) throw("Error getting profileList.json.");
  return jsonDecode(String.fromCharCodes(response.data));
}

Future<Map> fetchProfilesList(String basePath) async{
  final profileListFileName = 'profilesList.json';
  final profilesList = await fetchJsonFile('$basePath/$profileListFileName');
  return profilesList;
}

Future<Map> fetchProfile(XRInputSource xrInputSource, String basePath, [defaultProfile, bool getAssetPath = true]) async{
  // Get the list of profiles
  final supportedProfilesList = await fetchProfilesList(basePath);

  // Find the relative path to the first requested profile that is recognized
  Map? match;
  xrInputSource.profilesList?.any((profileId){
    final supportedProfile = supportedProfilesList[profileId] as Map<String,dynamic>?;
    if (supportedProfile != null) {
      match = {
        'profileId': profileId,
        'profilePath': '$basePath/${supportedProfile['path']}',
        'deprecated': supportedProfile['deprecated'] != null && supportedProfile['deprecated'] != false
      };
    }
    return match != null;
  });

  if (match == null) {
    if (!defaultProfile) {
      throw('No matching profile name found');
    }

    final supportedProfile = supportedProfilesList[defaultProfile];
    if (supportedProfile == null) {
      throw ('No matching profile name found and default profile "$defaultProfile" missing.');
    }

    match = {
      'profileId': defaultProfile,
      'profilePath': '$basePath/${supportedProfile['path']}',
      'deprecated': supportedProfile['deprecated'] != null && supportedProfile['deprecated'] != false
    };
  }

  final profile = await fetchJsonFile(match!['profilePath']);

  String? assetPath;
  if (getAssetPath) {
    dynamic layout;
    if (xrInputSource.handedness != null) {
      final map = profile['layouts']?.keys?.toList();
      layout = profile['layouts'][map[0]];
    } 
    else {
      layout = profile['layouts'][xrInputSource.handedness];
    }

    if (layout == null) {
      throw(
        'No matching handedness, ${xrInputSource.handedness}, in profile ${match!['profileId']}'
      );
    }

    if (layout['assetPath'] != null) {
      assetPath = (match!['profilePath'] as String?)?.replaceAll('profile.json', layout['assetPath']);
    }
  }

  return { 
    'profile': profile, 
    'assetPath': assetPath 
  };
}

void addAssetSceneToControllerModel(XRControllerModel controllerModel, Object3D? scene ) {
	// Find the nodes needed for animation and cache them on the motionController.
	findNodes( controllerModel.motionController!, scene );

	// Apply any environment map that the mesh already has set.
	if ( controllerModel.envMap != null) {
		scene?.traverse( ( child ){
			if ( child is Mesh ) {
				child.material?.envMap = controllerModel.envMap;
				child.material?.needsUpdate = true;
			}
		});
	}

	// Add the glTF scene to the controllerModel.
	controllerModel.add( scene );
}

void findNodes(MotionController motionController, Object3D? scene ) {
	// Loop through the components and find the nodes needed for each components' visual responses
	motionController.components.forEach((key, component ){
    component as Component;
		final type = component.type;
    final touchPointNodeName = component.touchPointNodeName;
    final visualResponses = component.visualResponses as Map;

		if ( type == constants['ComponentType']['TOUCHPAD'] ) {
			component.touchPointNode = scene?.getObjectByName( touchPointNodeName );
			if ( component.touchPointNode != null) {
				// Attach a touch dot to the touchpad.
				final sphereGeometry = SphereGeometry( 0.001 );
				final material = MeshBasicMaterial.fromMap( { 'color': 0x0000FF } );
				final sphere = Mesh( sphereGeometry, material );
				component.touchPointNode?.add( sphere );
			} 
      else {
				console.warning('Could not find touch dot, ${component.touchPointNodeName}, in touchpad component ${component.id}');
			}
		}

		// Loop through all the visual responses to be applied to this component
		visualResponses.forEach( (key, visualResponse ){
      visualResponse as VisualResponse;
			final valueNodeName = visualResponse.valueNodeName;
      final minNodeName = visualResponse.minNodeName;
      final maxNodeName = visualResponse.maxNodeName;
      final valueNodeProperty = visualResponse.valueNodeProperty;

			// If animating a transform, find the two nodes to be interpolated between.
			if ( valueNodeProperty == constants['VisualResponseProperty']['TRANSFORM'] ) {
				visualResponse.minNode = scene?.getObjectByName( minNodeName! );
				visualResponse.maxNode = scene?.getObjectByName( maxNodeName! );

				// If the extents cannot be found, skip this animation
				if (visualResponse.minNode == null) {
					console.warning('Could not find $minNodeName in the model');
					return;
				}

				if (visualResponse.maxNode == null) {
					console.warning('Could not find $maxNodeName in the model');
					return;
				}
			}

			// If the target node cannot be found, skip this animation
			visualResponse.valueNode = scene?.getObjectByName( valueNodeName! );
			if (visualResponse.valueNode == null) {
				console.warning('Could not find $valueNodeName in the model');
			}
		});
	});
}