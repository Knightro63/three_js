import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/nodes/node_library.dart';
import 'package:three_js_math/three_js_math.dart';

/**
 * This version of a node library represents the standard version
 * used in {@link WebGPURenderer}. It maps lights, tone mapping
 * techniques and materials to node-based implementations.
 *
 * @private
 * @augments NodeLibrary
 */
class StandardNodeLibrary extends NodeLibrary {

	/**
	 * Constructs a new standard node library.
	 */
	StandardNodeLibrary():super() {
		this.addMaterial( MeshPhongNodeMaterial, 'MeshPhongMaterial' );
		this.addMaterial( MeshStandardNodeMaterial, 'MeshStandardMaterial' );
		this.addMaterial( MeshPhysicalNodeMaterial, 'MeshPhysicalMaterial' );
		this.addMaterial( MeshToonNodeMaterial, 'MeshToonMaterial' );
		this.addMaterial( MeshBasicNodeMaterial, 'MeshBasicMaterial' );
		this.addMaterial( MeshLambertNodeMaterial, 'MeshLambertMaterial' );
		this.addMaterial( MeshNormalNodeMaterial, 'MeshNormalMaterial' );
		this.addMaterial( MeshMatcapNodeMaterial, 'MeshMatcapMaterial' );
		this.addMaterial( LineBasicNodeMaterial, 'LineBasicMaterial' );
		this.addMaterial( LineDashedNodeMaterial, 'LineDashedMaterial' );
		this.addMaterial( PointsNodeMaterial, 'PointsMaterial' );
		this.addMaterial( SpriteNodeMaterial, 'SpriteMaterial' );
		this.addMaterial( ShadowNodeMaterial, 'ShadowMaterial' );

		this.addLight( PointLightNode, PointLight );
		this.addLight( DirectionalLightNode, DirectionalLight );
		this.addLight( RectAreaLightNode, RectAreaLight );
		this.addLight( SpotLightNode, SpotLight );
		this.addLight( AmbientLightNode, AmbientLight );
		this.addLight( HemisphereLightNode, HemisphereLight );
		this.addLight( LightProbeNode, LightProbe );
		this.addLight( IESSpotLightNode, IESSpotLight );
		this.addLight( ProjectorLightNode, ProjectorLight );

		this.addToneMapping( linearToneMapping, LinearToneMapping );
		this.addToneMapping( reinhardToneMapping, ReinhardToneMapping );
		this.addToneMapping( cineonToneMapping, CineonToneMapping );
		this.addToneMapping( acesFilmicToneMapping, ACESFilmicToneMapping );
		this.addToneMapping( agxToneMapping, AgXToneMapping );
		this.addToneMapping( neutralToneMapping, NeutralToneMapping );
	}
}
