import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

class RoomEnvironment extends Scene {
  RoomEnvironment() : super() {
    final geometry = BoxGeometry();
    geometry.deleteAttributeFromString('uv');

    final roomMaterial = MeshStandardMaterial.fromMap({"side": BackSide});
    final boxMaterial = MeshStandardMaterial({});

    final mainLight = PointLight(0xffffff, 900, 28, 2);
    mainLight.position.setValues(0.418, 16.199, 0.300);
    add(mainLight);

    final room = Mesh(geometry, roomMaterial);
    room.position.setValues(-0.757, 13.219, 0.717);
    room.scale.setValues(31.713, 28.305, 28.591);
    add(room);

    final box1 = Mesh(geometry, boxMaterial);
    box1.position.setValues(-10.906, 2.009, 1.846);
    box1.rotation.set(0, -0.195, 0);
    box1.scale.setValues(2.328, 7.905, 4.651);
    add(box1);

    final box2 = Mesh(geometry, boxMaterial);
    box2.position.setValues(-5.607, -0.754, -0.758);
    box2.rotation.set(0, 0.994, 0);
    box2.scale.setValues(1.970, 1.534, 3.955);
    add(box2);

    final box3 = Mesh(geometry, boxMaterial);
    box3.position.setValues(6.167, 0.857, 7.803);
    box3.rotation.set(0, 0.561, 0);
    box3.scale.setValues(3.927, 6.285, 3.687);
    add(box3);

    final box4 = Mesh(geometry, boxMaterial);
    box4.position.setValues(-2.017, 0.018, 6.124);
    box4.rotation.set(0, 0.333, 0);
    box4.scale.setValues(2.002, 4.566, 2.064);
    add(box4);

    final box5 = Mesh(geometry, boxMaterial);
    box5.position.setValues(2.291, -0.756, -2.621);
    box5.rotation.set(0, -0.286, 0);
    box5.scale.setValues(1.546, 1.552, 1.496);
    add(box5);

    final box6 = Mesh(geometry, boxMaterial);
    box6.position.setValues(-2.193, -0.369, -5.547);
    box6.rotation.set(0, 0.516, 0);
    box6.scale.setValues(3.875, 3.487, 2.986);
    add(box6);

    // -x right
    final light1 = Mesh(geometry, createAreaLightMaterial(50.0));
    light1.position.setValues(-16.116, 14.37, 8.208);
    light1.scale.setValues(0.1, 2.428, 2.739);
    add(light1);

    // -x left
    final light2 = Mesh(geometry, createAreaLightMaterial(50.0));
    light2.position.setValues(-16.109, 18.021, -8.207);
    light2.scale.setValues(0.1, 2.425, 2.751);
    add(light2);

    // +x
    final light3 = Mesh(geometry, createAreaLightMaterial(17.0));
    light3.position.setValues(14.904, 12.198, -1.832);
    light3.scale.setValues(0.15, 4.265, 6.331);
    add(light3);

    // +z
    final light4 = Mesh(geometry, createAreaLightMaterial(43));
    light4.position.setValues(-0.462, 8.89, 14.520);
    light4.scale.setValues(4.38, 5.441, 0.088);
    add(light4);

    // -z
    final light5 = Mesh(geometry, createAreaLightMaterial(20));
    light5.position.setValues(3.235, 11.486, -12.541);
    light5.scale.setValues(2.5, 2.0, 0.1);
    add(light5);

    // +y
    final light6 = Mesh(geometry, createAreaLightMaterial(100));
    light6.position.setValues(0.0, 20.0, 0.0);
    light6.scale.setValues(1.0, 0.1, 1.0);
    add(light6);
  }

	void dispose() {
		final resources = new Set();

		this.traverse( ( object ){
			if ( object is Mesh ) {
				resources.add( object.geometry );
				resources.add( object.material );
			}
		} );

		for (final resource in resources ) {
			resource.dispose();
		}
	}
}

Function createAreaLightMaterial = (num intensity) {
  final material = MeshBasicMaterial();
  material.color.setScalar(intensity.toDouble());
  return material;
};
