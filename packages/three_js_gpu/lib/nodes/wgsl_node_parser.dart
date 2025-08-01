

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
