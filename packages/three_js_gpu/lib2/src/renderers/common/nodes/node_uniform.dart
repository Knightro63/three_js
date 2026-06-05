import '../../../nodes/core/node_uniform.dart';
import '../uniform.dart';
import 'package:three_js_math/three_js_math.dart';

/// A special form of Number uniform binding type.
/// It's value is managed by a node object.
class NumberNodeUniform extends NumberUniform {
  NodeUniform nodeUniform;

	NumberNodeUniform(this.nodeUniform ):super( nodeUniform.name, nodeUniform.value );

	double getValue() {
		return this.nodeUniform.value;
	}

	String getType() {
		return this.nodeUniform.type;
	}
}

/// A special form of Vector2 uniform binding type.
/// It's value is managed by a node object.
class Vector2NodeUniform extends Vector2Uniform {
  NodeUniform nodeUniform;

	Vector2NodeUniform(this.nodeUniform ):super( nodeUniform.name, nodeUniform.value );

	Vector2 getValue() {
		return this.nodeUniform.value;
	}

	String getType() {
		return this.nodeUniform.type;
	}
}

/// A special form of Vector3 uniform binding type.
/// It's value is managed by a node object.
class Vector3NodeUniform extends Vector3Uniform {
  NodeUniform nodeUniform;

	Vector3NodeUniform(this.nodeUniform ):super( nodeUniform.name, nodeUniform.value );


	Vector3 getValue() {
		return this.nodeUniform.value;
	}

	String getType() {
		return this.nodeUniform.type;
	}

}

/// A special form of Vector4 uniform binding type.
/// It's value is managed by a node object.
class Vector4NodeUniform extends Vector4Uniform {
  NodeUniform nodeUniform;

	Vector4NodeUniform(this.nodeUniform ):super( nodeUniform.name, nodeUniform.value );

	Vector4 getValue() {
		return this.nodeUniform.value;
	}

	String getType() {
		return this.nodeUniform.type;
	}

}

/// A special form of Color uniform binding type.
/// It's value is managed by a node object.
class ColorNodeUniform extends ColorUniform {
  NodeUniform nodeUniform;

	ColorNodeUniform(this.nodeUniform ):super( nodeUniform.name, nodeUniform.value );

	Color getValue() {
		return this.nodeUniform.value;
	}

	String getType() {
		return this.nodeUniform.type;
	}
}


/// A special form of Matrix2 uniform binding type.
/// It's value is managed by a node object.
class Matrix2NodeUniform extends Matrix2Uniform {
  NodeUniform nodeUniform;

	Matrix2NodeUniform(this.nodeUniform ):super( nodeUniform.name, nodeUniform.value );

	Matrix2 getValue() {
		return this.nodeUniform.value;
	}

	String getType() {
		return this.nodeUniform.type;
	}
}

/// A special form of Matrix3 uniform binding type.
/// It's value is managed by a node object.
class Matrix3NodeUniform extends Matrix3Uniform {
  NodeUniform nodeUniform;

	Matrix3NodeUniform(this.nodeUniform ):super( nodeUniform.name, nodeUniform.value );

	Matrix3 getValue() {
		return this.nodeUniform.value;
	}

	String getType() {
		return this.nodeUniform.type;
	}
}

/// A special form of Matrix4 uniform binding type.
/// It's value is managed by a node object.
class Matrix4NodeUniform extends Matrix4Uniform {
  NodeUniform nodeUniform;

	Matrix4NodeUniform(this.nodeUniform ):super( nodeUniform.name, nodeUniform.value );


	Matrix4 getValue() {
		return this.nodeUniform.value;
	}

	String getType() {
		return this.nodeUniform.type;
	}
}

