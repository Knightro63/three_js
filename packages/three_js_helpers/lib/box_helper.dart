
import 'dart:typed_data';

import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

final _box = BoundingBox();

/// Helper object to graphically show the world-axis-aligned bounding box
/// around an object. The actual bounding box is handled with [BoundingBox],
/// this is just a visual helper for debugging. It can be automatically
/// resized with the [BoxHelper.update] method when the object it's
/// created from is transformed. Note that the object must have a
/// [BufferGeometry] for this to work, so it won't work with [Sprites].
/// 
/// ```
/// final sphere = SphereGeometry();
/// final object = Mesh( sphere, MeshBasicMaterial({MaterialProperty.color: 0xff0000}));
/// final box = BoxHelper( object, color: 0xffff00 );
/// scene.add( box );
/// ```
class BoxHelper extends LineSegments {
  Object3D? object;

  BoxHelper.create(super.geometry, super.material);

  /// [object] -- (optional) the object3D to show the
  /// world-axis-aligned boundingbox.
  /// 
  /// [color] -- (optional) hexadecimal value that defines the box's
  /// color. Default is 0xffff00.
  /// 
  /// Creates a new wireframe box that bounds the passed object. Internally this
  /// uses [setFromObject] to calculate the dimensions. Note that this
  /// includes any children.
  factory BoxHelper(object, {int color = 0xffff00}) {
    final indices = Uint16List.fromList([
      0,
      1,
      1,
      2,
      2,
      3,
      3,
      0,
      4,
      5,
      5,
      6,
      6,
      7,
      7,
      4,
      0,
      4,
      1,
      5,
      2,
      6,
      3,
      7
    ]);
    final positions = Float32List(8 * 3);

    final geometry = BufferGeometry();
    geometry.setIndex(Uint16BufferAttribute.fromList(indices, 1, false));
    geometry.setAttributeFromString('position', Float32BufferAttribute.fromList(positions, 3, false));

    final boxHelper = BoxHelper.create(
        geometry, LineBasicMaterial.fromMap({"color": color, "toneMapped": false}));

    boxHelper.object = object;
    boxHelper.type = 'BoxHelper';

    boxHelper.matrixAutoUpdate = false;

    boxHelper.update();

    return boxHelper;
  }

  /// Updates the helper's geometry to match the dimensions of the object,
  /// including any children. See [setFromObject].
  void update() {
    if (object != null) {
      _box.setFromObject(object!);
    }

    if (_box.isEmpty()) return;

    final min = _box.min;
    final max = _box.max;

    /*
			5____4
		1/___0/|
		| 6__|_7
		2/___3/

		0: max.x, max.y, max.z
		1: min.x, max.y, max.z
		2: min.x, min.y, max.z
		3: max.x, min.y, max.z
		4: max.x, max.y, min.z
		5: min.x, max.y, min.z
		6: min.x, min.y, min.z
		7: max.x, min.y, min.z
		*/

    final position = geometry!.attributes["position"];
    final array = position.array;

    array[0] = max.x;
    array[1] = max.y;
    array[2] = max.z;
    array[3] = min.x;
    array[4] = max.y;
    array[5] = max.z;
    array[6] = min.x;
    array[7] = min.y;
    array[8] = max.z;
    array[9] = max.x;
    array[10] = min.y;
    array[11] = max.z;
    array[12] = max.x;
    array[13] = max.y;
    array[14] = min.z;
    array[15] = min.x;
    array[16] = max.y;
    array[17] = min.z;
    array[18] = min.x;
    array[19] = min.y;
    array[20] = min.z;
    array[21] = max.x;
    array[22] = min.y;
    array[23] = min.z;

    position.needsUpdate = true;

    geometry!.computeBoundingSphere();
  }

  /// [object] - [Object3D] to create the helper of.
  /// 
  /// Updates the wireframe box for the passed object.
  BoxHelper setFromObject(object) {
    this.object = object;
    update();

    return this;
  }

  // copy( BoxHelper source ) {

  // 	LineSegments.prototype.copy.call( this, source );

  // 	this.object = source.object;

  // 	return this;

  // }

}
