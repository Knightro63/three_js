import 'dart:math' as math;
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

///
///  This helper must be added as a child of the light
///

class RectAreaLightHelper extends Line {
  late RectAreaLight light;
  Color? color;

  RectAreaLightHelper.create(super.light, super.color);

	factory RectAreaLightHelper( light, color ) {

		List<double> positions = [ 1, 1, 0, - 1, 1, 0, - 1, - 1, 0, 1, - 1, 0, 1, 1, 0 ];

		final geometry = BufferGeometry();
		geometry.setAttributeFromString( 'position', Float32BufferAttribute( Float32Array.fromList(positions), 3 ) );
		geometry.computeBoundingSphere();

		final material = LineBasicMaterial.fromMap( { 'fog': false } );

		final instance =  RectAreaLightHelper.create( geometry, material );

		instance.light = light;
		instance.color = color; // optional hardwired color for the helper
		instance.type = 'RectAreaLightHelper';

		//

		List<double> positions2 = [ 1, 1, 0, - 1, 1, 0, - 1, - 1, 0, 1, 1, 0, - 1, - 1, 0, 1, - 1, 0 ];

		final geometry2 = BufferGeometry();
		geometry2.setAttributeFromString( 'position', Float32BufferAttribute(  Float32Array.fromList(positions2), 3 ) );
		geometry2.computeBoundingSphere();

		instance.add( Mesh( geometry2, MeshBasicMaterial.fromMap( { 'side': BackSide, 'fog': false } ) ) );

    return instance;
	}

  @override
	void updateMatrixWorld([bool force = false]) {
		scale.setValues( 0.5 * light.width!, 0.5 * light.height!, 1 );

		if (color != null ) {
			material?.color.setFrom(color!);
			children[ 0 ].material?.color.setFrom(color!);
		} 
    else {
			material?.color?..setFrom(light.color!)..scale(light.intensity );

			// prevent hue shift
			final c = material!.color;
			final max = math.max(math.max( c.red, c.green), c.blue);
			if ( max > 1 ) c.scale( 1 / max );

			children[ 0 ].material!.color.setFrom(material!.color);
		}

		// ignore world scale on light
		matrixWorld.extractRotation(light.matrixWorld ).scaleByVector(scale).copyPosition(light.matrixWorld );

		children[ 0 ].matrixWorld.setFrom(matrixWorld );
	}

  final _meshinverseMatrix = Matrix4();
  final _meshray = Ray();
  final _meshsphere = BoundingSphere();

  @override
  void raycast(Raycaster raycaster, List<Intersection> intersects) {
    console.info("==== raycast $this  1 ");

    final geometry = this.geometry!;
    final material = this.material;
    final matrixWorld = this.matrixWorld;

    if (material == null) return;

    // Checking boundingSphere distance to ray

    if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

    _meshsphere.setFrom(geometry.boundingSphere!);
    _meshsphere.applyMatrix4(matrixWorld);

    if (raycaster.ray.intersectsSphere(_meshsphere) == false) return;

    _meshinverseMatrix.setFrom(matrixWorld).invert();
    _meshray.copyFrom(raycaster.ray).applyMatrix4(_meshinverseMatrix);

    // Check boundingBox before continuing

    if (geometry.boundingBox != null) {
      if (_meshray.intersectsBox(geometry.boundingBox!) == false) return;
    }

    Intersection? intersection;
    final index = geometry.index;
    final position = geometry.attributes["position"];
    final morphPosition = geometry.morphAttributes["position"];
    final morphTargetsRelative = geometry.morphTargetsRelative;
    final uv = geometry.attributes["uv"];
    final uv2 = geometry.attributes["uv2"];
    final groups = geometry.groups;
    final drawRange = geometry.drawRange;

    console.info("==== raycast $this  index: $index  ");

    if (index != null) {
      // indexed buffer geometry

      if (material is GroupMaterial) {
        for (int i = 0, il = groups.length; i < il; i++) {
          final group = groups[i];
          final groupMaterial = material.children[group["materialIndex"]];

          final start = math.max<int>(group["start"], drawRange["start"]!);
          final end = math.min<int>((group["start"] + group["count"]),
              (drawRange["start"]! + drawRange["count"]!));

          for (int j = start, jl = end; j < jl; j += 3) {
            int a = index.getX(j)!.toInt();
            int b = index.getX(j + 1)!.toInt();
            int c = index.getX(j + 2)!.toInt();

            intersection = checkBufferGeometryIntersection(
                this,
                groupMaterial,
                raycaster,
                _meshray,
                position,
                morphPosition,
                morphTargetsRelative,
                uv,
                uv2,
                a,
                b,
                c);

            if (intersection != null) {
              intersection.faceIndex = (j / 3).floor();
              // triangle number in indexed buffer semantics
              intersection.face?.materialIndex = group["materialIndex"];
              intersects.add(intersection);
            }
          }
        }
      } 
      else {
        final start = math.max(0, drawRange["start"]!);
        final end = math.min(index.count, (drawRange["start"]! + drawRange["count"]!));

        for (int i = start, il = end; i < il; i += 3) {
          int a = index.getX(i)!.toInt();
          int b = index.getX(i + 1)!.toInt();
          int c = index.getX(i + 2)!.toInt();

          intersection = checkBufferGeometryIntersection(
              this,
              material,
              raycaster,
              _meshray,
              position,
              morphPosition,
              morphTargetsRelative,
              uv,
              uv2,
              a,
              b,
              c);

          if (intersection != null) {
            intersection.faceIndex = (i / 3).floor();
            // triangle number in indexed buffer semantics
            intersects.add(intersection);
          }
        }
      }
    } else if (position != null) {
      // non-indexed buffer geometry

      if (material is GroupMaterial) {
        for (int i = 0, il = groups.length; i < il; i++) {
          final group = groups[i];
          final groupMaterial = material.children[group["materialIndex"]];

          final start = math.max<int>(group["start"], drawRange["start"]!);
          final end = math.min<int>((group["start"] + group["count"]),
              (drawRange["start"]! + drawRange["count"]!));

          for (int j = start, jl = end; j < jl; j += 3) {
            final a = j;
            final b = j + 1;
            final c = j + 2;

            intersection = checkBufferGeometryIntersection(
                this,
                groupMaterial,
                raycaster,
                _meshray,
                position,
                morphPosition,
                morphTargetsRelative,
                uv,
                uv2,
                a,
                b,
                c);

            if (intersection != null) {
              intersection.faceIndex = (j / 3).floor();
              // triangle number in non-indexed buffer semantics
              intersection.face?.materialIndex = group["materialIndex"];
              intersects.add(intersection);
            }
          }
        }
      } 
      else {
        final start = math.max(0, drawRange["start"]!);
        final end = math.min<int>(position.count, (drawRange["start"]! + drawRange["count"]!));

        for (int i = start, il = end; i < il; i += 3) {
          final a = i;
          final b = i + 1;
          final c = i + 2;

          intersection = checkBufferGeometryIntersection(
              this,
              material,
              raycaster,
              _meshray,
              position,
              morphPosition,
              morphTargetsRelative,
              uv,
              uv2,
              a,
              b,
              c);

          if (intersection != null) {
            intersection.faceIndex = (i / 3).floor(); // triangle number in non-indexed buffer semantics
            intersects.add(intersection);
          }
        }
      }
    }
  }

  @override
	void dispose() {
		geometry?.dispose();
		material?.dispose();
		children[ 0 ].geometry?.dispose();
		children[ 0 ].material?.dispose();
	}
}
