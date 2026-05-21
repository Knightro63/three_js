import 'package:three_js_gpu/nodes/wgsl_node_function.dart';

/**
 * A WGSL node parser.
 *
 * @augments NodeParser
 */
class WGSLNodeParser extends NodeParser {

	/**
	 * The method parses the given WGSL code an returns a node function.
	 *
	 * @param {string} source - The WGSL code.
	 * @return {WGSLNodeFunction} A node function.
	 */
	parseFunction( source ) {
		return WGSLNodeFunction( source );
	}
}
