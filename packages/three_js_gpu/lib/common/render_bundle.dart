import 'package:three_js_core/three_js_core.dart';
import './bundle_group.dart';

class RenderBundle {
  Camera camera;
  BundleGroup bundleGroup;
	RenderBundle(this.bundleGroup, this.camera );
}
