import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/nodes/node_library.dart';
import 'package:three_js_math/three_js_math.dart';
import '../../materials/node_materials.dart';

/**
 * This version of a node library represents the standard version
 * used in {@link WebGPURenderer}. It maps lights, tone mapping
 * techniques and materials to node-based implementations.
 *
 * @private
 * @augments NodeLibrary
 */
class StandardNodeLibrary extends NodeLibrary {

	StandardNodeLibrary():super() {
		addMaterial( MeshPhongNodeMaterial, 'MeshPhongMaterial' );
		addMaterial( MeshStandardNodeMaterial, 'MeshStandardMaterial' );
		addMaterial( MeshPhysicalNodeMaterial, 'MeshPhysicalMaterial' );
		addMaterial( MeshToonNodeMaterial, 'MeshToonMaterial' );
		addMaterial( MeshBasicNodeMaterial, 'MeshBasicMaterial' );
		addMaterial( MeshLambertNodeMaterial, 'MeshLambertMaterial' );
		addMaterial( MeshNormalNodeMaterial, 'MeshNormalMaterial' );
		addMaterial( MeshMatcapNodeMaterial, 'MeshMatcapMaterial' );
		addMaterial( LineBasicNodeMaterial, 'LineBasicMaterial' );
		addMaterial( LineDashedNodeMaterial, 'LineDashedMaterial' );
		addMaterial( PointsNodeMaterial, 'PointsMaterial' );
		addMaterial( SpriteNodeMaterial, 'SpriteMaterial' );
		addMaterial( ShadowNodeMaterial, 'ShadowMaterial' );

		addLight( PointLightNode, PointLight );
		addLight( DirectionalLightNode, DirectionalLight );
		addLight( RectAreaLightNode, RectAreaLight );
		addLight( SpotLightNode, SpotLight );
		addLight( AmbientLightNode, AmbientLight );
		addLight( HemisphereLightNode, HemisphereLight );
		addLight( LightProbeNode, LightProbe );
		addLight( IESSpotLightNode, IESSpotLight );
		addLight( ProjectorLightNode, ProjectorLight );

		addToneMapping( linearToneMapping, LinearToneMapping );
		addToneMapping( reinhardToneMapping, ReinhardToneMapping );
		addToneMapping( cineonToneMapping, CineonToneMapping );
		addToneMapping( acesFilmicToneMapping, ACESFilmicToneMapping );
		addToneMapping( agxToneMapping, AgXToneMapping );
		addToneMapping( neutralToneMapping, NeutralToneMapping );
	}
}
