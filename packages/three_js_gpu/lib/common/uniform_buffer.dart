import "package:three_js_math/three_js_math.dart";
/**
 * Represents a uniform buffer binding type.
 *
 * @private
 * @augments Buffer
 */
class UniformBuffer extends Buffer {
  String name;
	UniformBuffer(this.name, [super.buffer]);
}
