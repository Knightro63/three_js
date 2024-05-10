import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter_gl/flutter_gl.dart';

class OctreeHelper extends LineSegments {
  late Octree octree;
  late int color;

	OctreeHelper.create(geometry, material):super(geometry, material);
  
  factory OctreeHelper(Octree octree, [int color = 0xffff00]){
		List<double> vertices = [];

		void traverse(Octree tree){
			for (int i = 0; i < tree.subTrees.length; i ++) {
				Vector3 min = tree.subTrees[i].box.min;
				Vector3 max = tree.subTrees[i].box.max;
				vertices+=[ max.x, max.y, max.z]; vertices+=[ min.x, max.y, max.z]; // 0, 1
				vertices+=[ min.x, max.y, max.z]; vertices+=[ min.x, min.y, max.z]; // 1, 2
				vertices+=[ min.x, min.y, max.z]; vertices+=[ max.x, min.y, max.z]; // 2, 3
				vertices+=[ max.x, min.y, max.z]; vertices+=[ max.x, max.y, max.z]; // 3, 0

				vertices+=[ max.x, max.y, min.z]; vertices+=[ min.x, max.y, min.z]; // 4, 5
				vertices+=[ min.x, max.y, min.z]; vertices+=[ min.x, min.y, min.z]; // 5, 6
				vertices+=[ min.x, min.y, min.z]; vertices+=[ max.x, min.y, min.z]; // 6, 7
				vertices+=[ max.x, min.y, min.z]; vertices+=[ max.x, max.y, min.z]; // 7, 4

				vertices+=[ max.x, max.y, max.z]; vertices+=[ max.x, max.y, min.z]; // 0, 4
				vertices+=[ min.x, max.y, max.z]; vertices+=[ min.x, max.y, min.z]; // 1, 5
				vertices+=[ min.x, min.y, max.z]; vertices+=[ min.x, min.y, min.z]; // 2, 6
				vertices+=[ max.x, min.y, max.z]; vertices+=[ max.x, min.y, min.z]; // 3, 7

				//traverse(tree.subTrees[i]);
			}
		}

		traverse(octree);

    Float32Array array = Float32Array.fromList(vertices);

		BufferGeometry geometry = BufferGeometry();
		geometry.setAttributeFromString('position', Float32BufferAttribute(array, 3));
    array.dispose();

    var oh = OctreeHelper.create(
      geometry, 
      LineBasicMaterial.fromMap({"color": color, "toneMapped": false})
    );

    oh.octree = octree;
    oh.color = color;
    oh.type = 'OctreeHelper';

    return oh;
  }
}