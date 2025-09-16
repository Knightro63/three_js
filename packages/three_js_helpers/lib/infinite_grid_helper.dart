import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class InfiniteGridHelper extends Mesh {
  InfiniteGridHelper.create(super.geometry, super.material) {
    type = "InfiniteGridHelper";
  }

  /// [size1] - Dimensions of the inner grid. By default, it is 10.
  ///
  /// [size2] - Dimensions of the outer  grid. By default, it is 100.
  ///
  /// [Color] - A hexadecimal value and an CSS-Color name. Default is 0x444444
  ///
  /// [distance] - It is the distance from the camera at which the grid starts to
  /// disappear. This helps create a smooth fading effect. By default it is 8000.
  ///
  /// [axes] - Axes directions along which the grid will be constructed.
  /// By default, it is ‘xzy’.
  factory InfiniteGridHelper({
    double? size1,
    double? size2,
    Color? color,
    double? distance,
    RotationOrders axes = RotationOrders.xyz
  }) {
    color = color ?? Color.fromHex32(0x444444);
    size1 = size1 ?? 10;
    size2 = size2 ?? 100;
    distance = distance ?? 8000;

    String planeAxes = axes.name.substring(0, 2);

    PlaneGeometry geometry = PlaneGeometry(2, 2, 1, 1);

    final vertexShader = '''
    varying vec3 worldPosition;
    uniform float uDistance;

    void main() {
        vec3 pos = position.${axes.name} * uDistance;
        pos.$planeAxes += cameraPosition.$planeAxes;
        
        worldPosition = pos;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    }
    ''';

    final fragmentShader = '''
     varying vec3 worldPosition;
     
     uniform float uSize1;
     uniform float uSize2;
     uniform vec3 uColor;
     uniform float uDistance;
     
        float getGrid(float size) {
            vec2 r = worldPosition.$planeAxes / size;
            
            vec2 grid = abs(fract(r - 0.5) - 0.5) / fwidth(r);
            float line = min(grid.x, grid.y);
            
            return 1.0 - min(line, 1.0);
        }

        void main() {
            float d = 1.0 - min(distance(cameraPosition.$planeAxes, worldPosition.$planeAxes) / uDistance, 1.0);
            
            float g1 = getGrid(uSize1);
            float g2 = getGrid(uSize2);
            
            gl_FragColor = vec4(uColor.rgb, mix(g2, g1, g1) * pow(d, 3.0));
            gl_FragColor.a = mix(0.5 * gl_FragColor.a, gl_FragColor.a, g2);
            
            if ( gl_FragColor.a <= 0.0 ) discard;
        }
    ''';

    final material = ShaderMaterial.fromMap({
      'side': DoubleSide,
      'uniforms': {
        'uSize1': {'value': size1},
        'uSize2': {'value': size2},
        'uColor': {'value': color},
        'uDistance': {'value': distance}
      },
      'transparent': true,
      'extensions': {
        'derivatives': {'value': true}
      },
      'vertexShader': vertexShader,
      'fragmentShader': fragmentShader
    });

    return InfiniteGridHelper.create(geometry, material);
  }
}
