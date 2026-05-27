import "../uniforms_group.dart";

int _id = 0;

/**
 * A special form of uniforms group that represents
 * the individual uniforms as node-based uniforms.
 *
 * @private
 * @augments UniformsGroup
 */
class NodeUniformsGroup extends UniformsGroup {
  bool isNodeUniformsGroup = true;
  int id = _id ++;
  UniformGroupNode groupNode;

	NodeUniformsGroup( super.name, this.groupNode );
}
