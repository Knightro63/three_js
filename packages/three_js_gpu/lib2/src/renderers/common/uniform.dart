import 'package:three_js_math/three_js_math.dart';

/**
 * Abstract base class for uniforms.
 *
 * @abstract
 * @private
 */
class Uniform {
  dynamic value;
  String name;
  int boundary = 0;
  int offset = 0;
  int itemSize = 0;

	Uniform(this.name, [this.value ]);

	/**
	 * Sets the uniform's value.
	 *
	 * @param {any} value - The value to set.
	 */
	void setValue( value ) {
		this.value = value;
	}

	dynamic getValue() {
		return this.value;
	}
}

/**
 * Represents a Number uniform.
 *
 * @private
 * @augments Uniform
 */
class NumberUniform extends Uniform {
  bool isNumberUniform = true;

	NumberUniform(String name, [double value = 0 ]):super( name, value ){
    boundary = 4;
    itemSize = 1;
  }
}

/**
 * Represents a Vector2 uniform.
 *
 * @private
 * @augments Uniform
 */
class Vector2Uniform extends Uniform {
  bool isVector2Uniform = true;

  Vector2Uniform(String name, Vector2 value):super( name, value ){
    this.boundary = 8;
		this.itemSize = 2;
  }

	factory Vector2Uniform.create(String name, [Vector2? value]) {
    return Vector2Uniform(name, value ?? new Vector2());
	}
}

/**
 * Represents a Vector3 uniform.
 *
 * @private
 * @augments Uniform
 */
class Vector3Uniform extends Uniform {
  bool isVector3Uniform = true;

  Vector3Uniform(String name, Vector3 value):super( name, value ){
    this.boundary = 16;
		this.itemSize = 3;
  }

	factory Vector3Uniform.create(String name, [Vector3? value]) {
    return Vector3Uniform(name, value ?? new Vector3());
	}
}

/**
 * Represents a Vector4 uniform.
 *
 * @private
 * @augments Uniform
 */
class Vector4Uniform extends Uniform {
  bool isVector4Uniform = true;

  Vector4Uniform(String name, Vector4 value):super( name, value ){
    this.boundary = 16;
		this.itemSize = 4;
  }

	factory Vector4Uniform.create(String name, [Vector4? value]) {
    return Vector4Uniform(name, value ?? new Vector4());
	}
}

/**
 * Represents a Color uniform.
 *
 * @private
 * @augments Uniform
 */
class ColorUniform extends Uniform {
  bool isColorUniform = true;

  ColorUniform(String name, Color value):super( name, value ){
    this.boundary = 16;
		this.itemSize = 3;
  }

	factory ColorUniform.create(String name, [Color? value]) {
    return ColorUniform(name, value ?? new Color());
	}
}

/**
 * Represents a Matrix2 uniform.
 *
 * @private
 * @augments Uniform
 */
class Matrix2Uniform extends Uniform {
  bool isMatrix2Uniform = true;

  Matrix2Uniform(String name, Matrix2 value):super( name, value ){
    this.boundary = 8;
		this.itemSize = 4;
  }

	factory Matrix2Uniform.create(String name, [Matrix2? value]) {
    return Matrix2Uniform(name, value ?? new Matrix2.identity());
	}
}

/**
 * Represents a Matrix3 uniform.
 *
 * @private
 * @augments Uniform
 */
class Matrix3Uniform extends Uniform {
  bool isMatrix3Uniform = true;

  Matrix3Uniform(String name, Matrix3 value):super( name, value ){
    this.boundary = 8;
		this.itemSize = 4;
  }

	factory Matrix3Uniform.create(String name, [Matrix3? value]) {
    return Matrix3Uniform(name, value ?? Matrix3.identity());
	}
}

/**
 * Represents a Matrix4 uniform.
 *
 * @private
 * @augments Uniform
 */
class Matrix4Uniform extends Uniform {
  bool isMatrix4Uniform = true;

  Matrix4Uniform(String name, Matrix4 value):super( name, value ){
    this.boundary = 8;
		this.itemSize = 4;
  }

	factory Matrix4Uniform.create(String name, [Matrix4? value]) {
    return Matrix4Uniform(name, value ?? Matrix4.identity());
	}
}
