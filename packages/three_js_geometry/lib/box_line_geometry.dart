import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/buffer/buffer_attribute.dart';

class BoxLineGeometry extends BufferGeometry {

  ///
  /// constructs a new box line geometry.
	///
  /// @param {number} [width=1] - The width. That is, the length of the edges parallel to the X axis.
  /// @param {number} [height=1] - The height. That is, the length of the edges parallel to the Y axis.
  /// @param {number} [depth=1] - The depth. That is, the length of the edges parallel to the Z axis.
  /// @param {number} [widthSegments=1] - Number of segmented rectangular sections along the width of the sides.
  /// @param {number} [heightSegments=1] - Number of segmented rectangular sections along the height of the sides.
  /// @param {number} [depthSegments=1] - Number of segmented rectangular sections along the depth of the sides.
	///
	BoxLineGeometry([double width = 1, double height = 1, double depth = 1, int widthSegments = 1, int heightSegments = 1, int depthSegments = 1 ]):super() {
		widthSegments = widthSegments.floor();
		heightSegments = heightSegments.floor();
		depthSegments = depthSegments.floor();

		final widthHalf = width / 2;
		final heightHalf = height / 2;
		final depthHalf = depth / 2;

		final segmentWidth = width / widthSegments;
		final segmentHeight = height / heightSegments;
		final segmentDepth = depth / depthSegments;

		final List<double> vertices = [];

		double x = - widthHalf;
		double y = - heightHalf;
		double z = - depthHalf;

		for (int i = 0; i <= widthSegments; i ++ ) {
			vertices.addAll([ x, - heightHalf, - depthHalf, x, heightHalf, - depthHalf ]);
			vertices.addAll([ x, heightHalf, - depthHalf, x, heightHalf, depthHalf ]);
			vertices.addAll([ x, heightHalf, depthHalf, x, - heightHalf, depthHalf ]);
			vertices.addAll([ x, - heightHalf, depthHalf, x, - heightHalf, - depthHalf ]);

			x += segmentWidth;
		}

		for ( int i = 0; i <= heightSegments; i ++ ) {
			vertices.addAll([ - widthHalf, y, - depthHalf, widthHalf, y, - depthHalf ]);
			vertices.addAll([ widthHalf, y, - depthHalf, widthHalf, y, depthHalf ]);
			vertices.addAll([ widthHalf, y, depthHalf, - widthHalf, y, depthHalf ]);
			vertices.addAll([ - widthHalf, y, depthHalf, - widthHalf, y, - depthHalf ]);

			y += segmentHeight;
		}

		for (int i = 0; i <= depthSegments; i ++ ) {
			vertices.addAll([ - widthHalf, - heightHalf, z, - widthHalf, heightHalf, z ]);
			vertices.addAll([ - widthHalf, heightHalf, z, widthHalf, heightHalf, z ]);
			vertices.addAll([ widthHalf, heightHalf, z, widthHalf, - heightHalf, z ]);
			vertices.addAll([ widthHalf, - heightHalf, z, - widthHalf, - heightHalf, z ]);

			z += segmentDepth;
		}

		this.setAttributeFromString( 'position', new Float32BufferAttribute.fromList( vertices, 3 ) );
	}
}