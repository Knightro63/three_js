import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'octree.dart';

class OctreeHelper extends LineSegments {
  late Octree octree;
  late int color;

  OctreeHelper(this.octree, [this.color = 0xffff00]):super(BufferGeometry(),LineBasicMaterial.fromMap({'color': color, 'toneMapped': false})){
    type = 'OctreeHelper';
    update();
  }
  
  void update (){
		List<double> vertices = [];

		void traverse(List<Octree> tree){
			for (int i = 0; i < tree.length; i ++) {
				Vector3 min = tree[i].box.min;
				Vector3 max = tree[i].box.max;
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

				//traverse(tree[i].subTrees);
			}
		}

		traverse(octree.subTrees);
    geometry?.dispose();
    Float32Array array = Float32Array.fromList(vertices);
		geometry = BufferGeometry();
		geometry?.setAttributeFromString('position', Float32BufferAttribute(array, 3));
    array.dispose();
  }

  @override
	void dispose() {
		geometry?.dispose();
		material?.dispose();
	}
}