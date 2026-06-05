import 'node_function_input.dart';

/// Base class for node functions. A derived module must be implemented
/// for each supported native shader language. Similar to other `Node*` modules,
/// this class is only relevant during the building process and not used
/// in user-level code.
abstract class NodeFunction {
  String type;
  List<NodeFunctionInput> inputs;
  String name;
  String precision;

	NodeFunction(this.type, this.inputs, [this.name = '', this.precision = ''] );

	/// This method returns the native code of the node function.
	String getCode([String? name]) {
    name ??= this.name;
		throw( 'getCode in NodeFunction is an Abstract function.' );
	}
}
