import './binding.dart';

int _id = 0;

/**
 * A bind group represents a collection of bindings and thus a collection
 * or resources. Bind groups are assigned to pipelines to provide them
 * with the required resources (like uniform buffers or textures).
 *
 * @private
 */
class BindGroup {
  String name;
  int index;
  int id = _id ++;
  late List<Binding> bindings;
  late List<Binding> bindingsReference;

	BindGroup([this.name = '', List<Binding>? bindings, this.index = 0, List<Binding>? bindingsReference]) {
		this.bindings = bindings ?? [];
		this.bindingsReference = bindingsReference ?? [];
	}
}
