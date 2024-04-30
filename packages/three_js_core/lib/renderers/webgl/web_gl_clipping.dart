part of three_webgl;

class WebGLClipping {
  WebGLProperties properties;

  Matrix3 viewNormalMatrix = Matrix3.identity();
  Plane plane = Plane();
  int numGlobalPlanes = 0;

  bool localClippingEnabled = false;
  bool renderingShadows = false;

  dynamic globalState;

  Map<String, dynamic> uniform = {"value": null, "needsUpdate": false};

  int numPlanes = 0;
  int numIntersection = 0;

  WebGLClipping(this.properties);

  bool init(List<Plane> planes, bool enableLocalClipping, Camera camera) {
    final enabled = planes.isNotEmpty ||
        enableLocalClipping ||
        // enable state of previous frame - the clipping code has to
        // run another frame in order to reset the state:
        numGlobalPlanes != 0 ||
        localClippingEnabled;

    localClippingEnabled = enableLocalClipping;

    globalState = projectPlanes(planes, camera, 0, null);
    numGlobalPlanes = planes.length;

    return enabled;
  }

  void beginShadows() {
    renderingShadows = true;
    projectPlanes();
  }

  void endShadows() {
    renderingShadows = false;
    resetGlobalState();
  }

  void setState(Material material, Camera camera, bool useCache) {
    final planes = material.clippingPlanes;
    final clipIntersection = material.clipIntersection;
    final clipShadows = material.clipShadows;

    final materialProperties = properties.get(material);

    if (!localClippingEnabled || planes == null || planes.isEmpty || renderingShadows && !clipShadows) {
      // there's no local clipping

      if (renderingShadows) {
        // there's no global clipping

        projectPlanes();
      } else {
        resetGlobalState();
      }
    } else {
      final nGlobal = renderingShadows ? 0 : numGlobalPlanes;
      final lGlobal = nGlobal * 4;

      List<double>? dstArray = materialProperties["clippingState"];

      uniform["value"] = dstArray; // ensure unique state

      dstArray = projectPlanes(planes, camera, lGlobal, useCache);

      for (int i = 0; i != lGlobal; ++i) {
        dstArray?[i] = globalState[i];
      }

      materialProperties["clippingState"] = dstArray;
      numIntersection = clipIntersection ? numPlanes : 0;
      numPlanes += nGlobal;
    }
  }

  void resetGlobalState() {
    if (uniform["value"] != globalState) {
      uniform["value"] = globalState;
      uniform["needsUpdate"] = numGlobalPlanes > 0;
    }

    numPlanes = numGlobalPlanes;
    numIntersection = 0;
  }

  List<double>? projectPlanes([planes, camera, dstOffset, skipTransform]) {
    final nPlanes = planes != null ? planes.length : 0;
    List<double>? dstArray;

    if (nPlanes != 0) {
      dstArray = uniform["value"];

      if (skipTransform != true || dstArray == null) {
        final flatSize = dstOffset + nPlanes * 4, viewMatrix = camera.matrixWorldInverse;

        viewNormalMatrix.getNormalMatrix(viewMatrix);

        if (dstArray == null || dstArray.length < flatSize) {
          dstArray = List<double>.filled(flatSize, 0.0);
        }

        for (int i = 0, i4 = dstOffset; i != nPlanes; ++i, i4 += 4) {
          plane..copyFrom(planes[i])..applyMatrix4(viewMatrix, viewNormalMatrix);

          plane.normal.copyIntoArray(dstArray, i4);
          dstArray[i4 + 3] = plane.constant;
        }
      }

      uniform["value"] = dstArray;
      uniform["needsUpdate"] = true;
    }

    numPlanes = nPlanes;
    numIntersection = 0;

    return dstArray;
  }
}
