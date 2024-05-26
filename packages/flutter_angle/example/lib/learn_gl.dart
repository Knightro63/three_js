// Copyright (c) 2013, John Thomas McDole.
/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_angle/flutter_angle.dart';

part 'cube.dart';
part 'gl_program.dart';
// part 'json_object.dart';
// All the lessons
part 'lesson1.dart';
// part 'lesson10.dart';
// part 'lesson11.dart';
// part 'lesson12.dart';
// part 'lesson13.dart';
// part 'lesson14.dart';
// part 'lesson15.dart';
// part 'lesson16.dart';
part 'lesson2.dart';
part 'lesson3.dart';
part 'lesson4.dart';
part 'lesson5.dart';
part 'lesson6.dart';
part 'lesson7.dart';
// part 'lesson8.dart';
// part 'lesson9.dart';
// // Math
part 'matrix4.dart';
part 'pyramid.dart';
// part 'rectangle.dart';
// // Some of our objects that we're going to support
part 'renderable.dart';
// part 'sphere.dart';
// part 'star.dart';

Lesson createLesson(int number,RenderingContext gl) {
  switch (number) {
    case 1:
      return Lesson1(gl);
    // case 2:
    //   return new Lesson2(gl);
    // case 3:
    //   return new Lesson3(gl);
    // case 4:
    //   return new Lesson4(gl);
    // case 5:
    //   return new Lesson5(gl);
    // case 6
    //   return new Lesson6(gl);
    // case 7:
    //   return new Lesson7(gl);
    // case 8:
    //   return new Lesson8(gl);
    // case 9:
    //   return new Lesson9(gl);
    // case 10:
    //   return new Lesson10(gl);
    // case 11:
    //   return new Lesson11(gl);
    // case 12:
    //   return new Lesson12(gl);
    // case 13:
    //   return new Lesson13(gl);
    // case 14:
    //   return new Lesson14(gl);
    // case 15:
    //   return new Lesson15(gl);
    // case 16:
    //   return new Lesson16(gl);
    default:
      return Lesson1(gl);
  }
}

/// The global key-state map.
Set<int> currentlyPressedKeys = new Set<int>();

enum Directions { none, left, right, up, down }

Directions movement = Directions.none;

/// Handle common keys through callbacks, making lessons a little easier to code
void handleDirection({up()?, down()?, left()?, right()?}) {
  if (movement == Directions.left) {
    left?.call();
  }
  if (movement == Directions.right) {
    right?.call();
  }
  if (movement == Directions.down) {
    down?.call();
  }
  if (movement == Directions.up) {
    up?.call();
  }
  movement = Directions.none;
}

/// The base for all Learn WebGL lessons.
abstract class Lesson {
  late RenderingContext gl;

  Lesson(this.gl) {
    mvMatrix = new Matrix4()..identity();
    gl.clearColor(0, 0, 0, 1.0);
  }

  /// Render the scene to the [viewWidth], [viewHeight], and [aspect] ratio.
  void drawScene(int viewWidth, int viewHeight, double aspect);

  /// Animate the scene any way you like. [now] is provided as a clock reference
  /// since the scene rendering started.
  void animate(int now) {}

  /// Handle any keyboard events.
  void handleKeys() {}

  /// Added for your convenience to track time between [animate] callbacks.
  num lastTime = 0;

  /// Perspective matrix
  late Matrix4 pMatrix;

  /// Model-View matrix.
  late Matrix4 mvMatrix;

  List<Matrix4> mvStack = <Matrix4>[];

  /// Add a copy of the current Model-View matrix to the the stack for future
  /// restoration.
  mvPushMatrix() => mvStack.add(new Matrix4.fromMatrix(mvMatrix));

  /// Pop the last matrix off the stack and set the Model View matrix.
  mvPopMatrix() => mvMatrix = mvStack.removeLast();

  /// Load the given image at [url] and call [handle] to execute some GL code.
  /// Return a [Future] to asynchronously notify when the texture is complete.
  Future<WebGLTexture> loadTexture(
      String url, Future Function(WebGLTexture tex, Image data) handle) async {
    var texture = gl.createTexture();
    final data = await gl.loadImageFromAsset('assets/$url');
    await handle(texture, data);
    return texture;
  }

  /// This is a common handler for [loadTexture]. It will be explained in future
  /// lessons that require textures.
  Future handleMipMapTexture(WebGLTexture texture, Image image) async {
    gl.pixelStorei(WebGL.UNPACK_ALIGNMENT, 1);
    gl.bindTexture(WebGL.TEXTURE_2D, texture);
    await gl.texImage2DfromImage(
      WebGL.TEXTURE_2D,
      image,
      internalformat: WebGL.RGBA,
      format: WebGL.RGBA,
      type: WebGL.UNSIGNED_BYTE,
    );
    gl.texParameteri(
      WebGL.TEXTURE_2D,
      WebGL.TEXTURE_MAG_FILTER,
      WebGL.LINEAR,
    );
    gl.texParameteri(
      WebGL.TEXTURE_2D,
      WebGL.TEXTURE_MIN_FILTER,
      WebGL.LINEAR_MIPMAP_NEAREST,
    );
    gl.generateMipmap(WebGL.TEXTURE_2D);
    gl.bindTexture(WebGL.TEXTURE_2D, null);
  }
}



// Future<WebGLTexture> loadMipMapTexture(
//   WebGLTexture texture,
// ) async {
//   gl.pixelStorei(WebGL.UNPACK_ALIGNMENT, 1);
//   gl.bindTexture(WebGL.TEXTURE_2D, texture);
//   final bytes = await rootBundle.load('assets/fromImage.raw');
//   gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, 256, 256, 0, WebGL.RGBA, WebGL.UNSIGNED_BYTE, bytes);
//   gl.texParameteri(
//     WebGL.TEXTURE_2D,
//     WebGL.TEXTURE_MAG_FILTER,
//     WebGL.LINEAR,
//   );
//   gl.texParameteri(
//     WebGL.TEXTURE_2D,
//     WebGL.TEXTURE_MIN_FILTER,
//     WebGL.LINEAR_MIPMAP_NEAREST,
//   );
//   gl.generateMipmap(WebGL.TEXTURE_2D);
//   gl.bindTexture(WebGL.TEXTURE_2D, null);
//   return texture;
// }
// DivElement lessonHook = querySelector("#lesson_html");
// bool trackFrameRate = false;
