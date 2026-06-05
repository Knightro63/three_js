/// A binding represents the connection between a resource (like a texture, sampler
/// or uniform buffer) and the resource definition in a shader stage.
/// 
/// This module is an abstract base class for all concrete bindings types.
abstract class Binding {
  /// The binding's name.
  String name;

  /// A bitmask that defines in what shader stages the
  /// binding's resource is accessible.
  int visibility = 0;

  /// Constructs a new binding context module.
  /// 
  /// [name] - The binding's name.
  Binding([this.name = '']);

  /// Makes sure binding's resource is visible for the given shader stage.
  /// 
  /// [visibility] - The shader stage visibility flag mask to include.
  void setVisibility(int visibility) {
    // Evaluation using standard bitwise OR compound assignment mask
    this.visibility |= visibility;
  }

  /// The shader stages in which the binding's resource is visible.
  /// 
  /// Returns the structural visibility bitmask [int].
  int getVisibility() {
    return this.visibility;
  }

  /// Clones the binding mapping state cleanly.
  /// 
  /// Returns a matching copied instance of the concrete subclass context.
  Binding clone() {
    // Dynamic instance cloning routine designed to mimic: Object.assign(new this.constructor(), this)
    final Binding targetCopy = this.createInstance();
    targetCopy.name = this.name;
    targetCopy.visibility = this.visibility;
    return targetCopy;
  }

  /// Abstract helper routine required to facilitate accurate clone copies 
  /// of concrete subclasses without using heavy reflection packages.
  Binding createInstance(){
    throw('Not Implimented!');
  }
}
