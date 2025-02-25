import 'package:three_js_core/three_js_core.dart';
import 'line_segments_geometry.dart';
import 'package:three_js_geometry/three_js_geometry.dart';

class WireframeGeometry2 extends LineSegmentsGeometry {
	WireframeGeometry2(BufferGeometry geometry ):super() {
		this.type = 'WireframeGeometry2';
		this.fromWireframeGeometry(WireframeGeometry(geometry));
	}
}
