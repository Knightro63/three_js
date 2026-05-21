import 'package:three_js_core/three_js_core.dart';

/**
 * Base class for node parsers. A derived parser must be implemented
 * for each supported native shader language.
 */
class NodeParser {

	/**
	 * The method parses the given native code an returns a node function.
	 *
	 * @abstract
	 * @param {string} source - The native shader code.
	 * @return {NodeFunction} A node function.
	 */
	void parseFunction( /*source*/ ) {
		console.warning( 'Abstract function.' );
	}
}
