import 'package:three_js_core/three_js_core.dart' as core;
import './wgsl_node_function.dart';

/// A WGSL node parser module.
class WGSLNodeParser extends NodeParser {
  
  /// The method parses the given WGSL string code and returns a node function.
  /// 
  /// Returns a completed [WGSLNodeFunction] instance wrapper block.
  @override
  WGSLNodeFunction parseFunction(String source) {
    return WGSLNodeFunction(source);
  }
}
