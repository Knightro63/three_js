import 'dart:typed_data';

class NV21 {
  static void convertNV21(Uint8List rgba, Uint8List src, int width, int height, bool androidSimMac) {
    final uvStart = width * height;
    int index = 0, rgbaIndex = 0;
    int y, u, v;
    int r, g, b, a;
    int uvIndex = 0;

    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        uvIndex = (i ~/ 2 * width + j - j % 2).toInt();

        y = src[rgbaIndex];
        u = src[uvStart + uvIndex];
        v = src[uvStart + uvIndex + 1];

        r = y + (1.164 * (v - 128)).toInt(); // r
        g = y - (0.392 * (u - 128)).toInt() - (0.813 * (v - 128)).toInt(); // g
        b = y + (2.017 * (u - 128)).toInt(); // b
        a = 255;

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        index = rgbaIndex % width + i * width;
        rgba[index * 4 + 0] = androidSimMac?b:r;//flip if not on mac for android sim
        rgba[index * 4 + 1] = g;
        rgba[index * 4 + 2] = androidSimMac?r:b;//flip if not on mac for android sim
        rgba[index * 4 + 3] = a;
        rgbaIndex++;
      }
    }
  }
}