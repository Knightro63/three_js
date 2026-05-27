// Global File-Scope Shared Automated ID Counter
int _id = 0;

/// A bind group represents a collection of bindings and thus a collection
/// of resources. Bind groups are assigned to pipelines to provide them
/// with the required resources (like uniform buffers or textures).
class BindGroup {
  /// The bind group's name.
  String name;

  /// An array list of active bindings resources descriptors.
  List<dynamic> bindings; // Maps to Binding collections

  /// The group's unique auto-incremented tracking ID number.
  final int id;

  /// Constructs a new bind group container layout module.
  /// 
  /// [name] - The bind group's name.
  /// [bindings] - An array list of bindings.
  BindGroup([String name = '', List<dynamic>? bindings])
      : this.name = name,
        this.bindings = bindings ?? <dynamic>[],
        this.id = _id++;
}
