import 'package:three_js_core/materials/line_dashed_material.dart';
import 'node_material.dart';

final _defaultValues = /*@__PURE__*/ LineDashedMaterial();

class LineDashedNodeMaterial extends NodeMaterial {
	String get type => 'LineDashedNodeMaterial';
  int dashOffset = 0;

  /**
   * The offset of dash materials is by default inferred from the `dashOffset`
   * property. This node property allows to overwrite the default
   * and define the offset with a node instead.
   *
   * If you don't want to overwrite the offset but modify the existing
   * value instead, use {@link materialLineDashOffset}.
   *
   * @type {?}
   * @default null
   */
  Node<float>? offsetNode;

  /**
   * The scale of dash materials is by default inferred from the `scale`
   * property. This node property allows to overwrite the default
   * and define the scale with a node instead.
   *
   * If you don't want to overwrite the scale but modify the existing
   * value instead, use {@link materialLineScale}.
   *
   * @type {?Node<float>}
   * @default null
   */
  Node<float>? dashScaleNode;

  /**
   * The dash size of dash materials is by default inferred from the `dashSize`
   * property. This node property allows to overwrite the default
   * and define the dash size with a node instead.
   *
   * If you don't want to overwrite the dash size but modify the existing
   * value instead, use {@link materialLineDashSize}.
   *
   * @type {?Node<float>}
   * @default null
   */
  Node<float>? dashSizeNode;

  /**
   * The gap size of dash materials is by default inferred from the `gapSize`
   * property. This node property allows to overwrite the default
   * and define the gap size with a node instead.
   *
   * If you don't want to overwrite the gap size but modify the existing
   * value instead, use {@link materialLineGapSize}.
   *
   * @type {?Node<float>}
   * @default null
   */
  Node<float>? gapSizeNode;

	/**
	 * Constructs a new line dashed node material.
	 *
	 * @param {Object} [parameters] - The configuration parameter.
	 */
	LineDashedNodeMaterial( parameters ):super() {
		this.setDefaultValues( _defaultValues );
		this.setValues( parameters );
	}

	/**
	 * Setups the dash specific node variables.
	 *
	 * @param {NodeBuilder} builder - The current node builder.
	 */
	setupVariants( /* builder */ ) {
		final offsetNode = this.offsetNode ? float( this.offsetNode ) : materialLineDashOffset;
		final dashScaleNode = this.dashScaleNode ? float( this.dashScaleNode ) : materialLineScale;
		final dashSizeNode = this.dashSizeNode ? float( this.dashSizeNode ) : materialLineDashSize;
		final gapSizeNode = this.gapSizeNode ? float( this.gapSizeNode ) : materialLineGapSize;

		dashSize.assign( dashSizeNode );
		gapSize.assign( gapSizeNode );

		final vLineDistance = varying( attribute( 'lineDistance' ).mul( dashScaleNode ) );
		final vLineDistanceOffset = offsetNode ? vLineDistance.add( offsetNode ) : vLineDistance;

		vLineDistanceOffset.mod( dashSize.add( gapSize ) ).greaterThan( dashSize ).discard();
	}
}
