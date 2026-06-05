import 'node_function.dart';

/**
 * Base class for node parsers. A derived parser must be implemented
 * for each supported native shader language.
 */
abstract class NodeParser {
	/// The method parses the given native code an returns a node function.
	NodeFunction parseFunction(String source);
}
