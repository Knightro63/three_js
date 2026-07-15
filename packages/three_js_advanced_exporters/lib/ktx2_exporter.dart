import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

// --- Format Lookup Maps ---
// Maps: format -> type -> colorSpace -> vkFormat value
final Map<int, Map<int, Map<String, int>>> vkFormatMap = {
  RGBAFormat: {
    FloatType: { 'no-color-space': RGBAFormat, 'linear': RGBAFormat },
    HalfFloatType: { 'no-color-space': RGBAFormat, 'linear': RGBAFormat },
    UnsignedByteType: { 'no-color-space': RGBAFormat, 'linear': RGBAFormat, 'srgb': RGBAFormat },
  },
  RGFormat: {
    FloatType: { 'no-color-space': RGFormat, 'linear': RGFormat },
    HalfFloatType: { 'no-color-space': RGFormat, 'linear': RGFormat },
    UnsignedByteType: { 'no-color-space': RGFormat, 'linear': RGFormat, 'srgb': RGFormat },
  },
  RedFormat: {
    FloatType: { 'no-color-space': RedFormat, 'linear': RedFormat },
    HalfFloatType: { 'no-color-space': RedFormat, 'linear': RedFormat },
    UnsignedByteType: { 'no-color-space': RedFormat, 'linear': RedFormat, 'srgb': RedFormat },
  },
};

const int KHR_DF_CHANNEL_RGBSDA_RED = 0;
const int KHR_DF_CHANNEL_RGBSDA_GREEN = 1;
const int KHR_DF_CHANNEL_RGBSDA_BLUE = 2;
const int KHR_DF_CHANNEL_RGBSDA_ALPHA = 3;
const int KHR_DF_MODEL_RGBSDA = 1;
const int KHR_DF_PRIMARIES_UNSPECIFIED = 0;
const int KHR_DF_PRIMARIES_BT709 = 1;
const int KHR_DF_TRANSFER_LINEAR = 1;
const int KHR_DF_TRANSFER_SRGB = 2;
const int KHR_DF_SAMPLE_DATATYPE_LINEAR = 0x40;
const int KHR_DF_SAMPLE_DATATYPE_FLOAT  = 0x20;
const int KHR_DF_SAMPLE_DATATYPE_SIGNED = 0x80; 

final List<int> khrDfChannelMap = [
  KHR_DF_CHANNEL_RGBSDA_RED,
  KHR_DF_CHANNEL_RGBSDA_GREEN,
  KHR_DF_CHANNEL_RGBSDA_BLUE,
  KHR_DF_CHANNEL_RGBSDA_ALPHA,
];

final Map<int, List<int>> khrDfChannelSampleLowerUpper = {
  FloatType: [0xbf800000, 0x3f800000],
  HalfFloatType: [0xbf800000, 0x3f800000],
  UnsignedByteType: [ 0, 255 ],
};

const String errorInput = 'THREE.KTX2Exporter: Supported inputs are DataTexture, Data3DTexture, or WebGLRenderer and WebGLRenderTarget.';
const String errorFormat = 'THREE.KTX2Exporter: Supported formats are RGBAFormat, RGFormat, or RedFormat.';
const String errorType = 'THREE.KTX2Exporter: Supported types are FloatType, HalfFloatType, or UnsignedByteType.';
const String errorColorSpace = 'THREE.KTX2Exporter: Supported color spaces are SRGBColorSpace (UnsignedByteType only), LinearSRGBColorSpace, or NoColorSpace.';

class KTX2Exporter {
  KTX2Exporter();

  /// Exports a texture or a render target context out to a valid KTX2 file.
  Future<Uint8List> parse(dynamic arg1, [RenderTarget? arg2]) async {
    Texture texture;

    // 1. Establish the source input context types
    if (arg1 is DataTexture || arg1 is Data3DTexture) {
      texture = arg1;
    } else if (arg1 is Renderer && arg2 != null) {
      texture = await _toDataTexture(arg1, arg2);
    } else {
      throw Exception(errorInput);
    }

    final int format = texture.format;
    final int type = texture.type;
    final String colorSpace = texture.colorSpace;

    // 2. Validate format configurations
    if (!vkFormatMap.containsKey(format)) throw Exception(errorFormat);
    if (!vkFormatMap[format]!.containsKey(type)) throw Exception(errorType);
    if (!vkFormatMap[format]![type]!.containsKey(colorSpace)) throw Exception(errorColorSpace);

    // 3. Extract backing pixel payload tracking views
    final TypedData array = texture.image.data;
    final int channelCount = _getChannelCount(texture);
    final int bytesPerElement = array.elementSizeInBytes;

    // Initialize your layout descriptor tracking map mimicking createDefaultContainer()
    final Map<String, dynamic> container = _createDefaultContainer();
    container['vkFormat'] = vkFormatMap[format]![type]![colorSpace];
    container['typeSize'] = bytesPerElement;
    container['pixelWidth'] = texture.image.width;
    container['pixelHeight'] = texture.image.height;

    if (texture is Data3DTexture) {
      container['pixelDepth'] = texture.image.depth;
    }

    final Map<String, dynamic> basicDesc = container['dataFormatDescriptor'][0];
    basicDesc['colorModel'] = KHR_DF_MODEL_RGBSDA;
    basicDesc['colorPrimaries'] = (colorSpace == 'no-color-space') ? KHR_DF_PRIMARIES_UNSPECIFIED : KHR_DF_PRIMARIES_BT709;
    
    // In three_js, color management transfer utilities evaluate directly via explicit string flags
    basicDesc['transferFunction'] = (colorSpace == 'srgb') ? KHR_DF_TRANSFER_SRGB : KHR_DF_TRANSFER_LINEAR;
    basicDesc['texelBlockDimension'] = [ 0, 0, 0, 0 ];
    basicDesc['bytesPlane'] = [bytesPerElement * channelCount, 0, 0, 0, 0, 0, 0, 0];

    // 4. Populate samples channels structure map descriptions
    final List<Map<String, dynamic>> samplesList = [];
    for (int i = 0; i < channelCount; ++i) {
      int channelType = khrDfChannelMap[i];

      if (channelType == KHR_DF_CHANNEL_RGBSDA_ALPHA && basicDesc['transferFunction'] != KHR_DF_TRANSFER_LINEAR) {
        channelType |= KHR_DF_SAMPLE_DATATYPE_LINEAR;
      }

      if (type == FloatType || type == HalfFloatType) {
        channelType |= KHR_DF_SAMPLE_DATATYPE_FLOAT;
        channelType |= KHR_DF_SAMPLE_DATATYPE_SIGNED;
      }

      samplesList.add({
        'channelType': channelType,
        'bitOffset': i * bytesPerElement * 8,
        'bitLength': bytesPerElement * 8 - 1,
        'samplePosition': [ 0, 0, 0, 0 ],
        'sampleLower': khrDfChannelSampleLowerUpper[type]![0],
        'sampleUpper': khrDfChannelSampleLowerUpper[type]![1],
      });
    }
    basicDesc['samples'] = samplesList;

    // 5. Package tracking byte bounds
    container['levelCount'] = 1;
    final Uint8List levelDataBytes = array.buffer.asUint8List(array.offsetInBytes, array.lengthInBytes);
    
    container['levels'] = [
      {
        'levelData': levelDataBytes,
        'uncompressedByteLength': levelDataBytes.length,
      }
    ];

    container['keyValue'] = {'KTXwriter': 'three_js_ktx2_exporter'};

    // Bridge directly to your structural writing utility method
    return writeKTX2Container(container, keepWriter: true);
  }

  /// Blits and pulls render target data blocks natively from GPU memory layers asynchronously
  Future<DataTexture> _toDataTexture(Renderer renderer, RenderTarget rtt) async {
    final int channelCount = _getChannelCount(rtt.texture);
    final int totalSize = rtt.width * rtt.height * channelCount;
    TypedDataList view;

    if (rtt.texture.type == FloatType) {
      view = Float32List(totalSize);
    } else if (rtt.texture.type == HalfFloatType) {
      view = Uint16List(totalSize);
    } else if (rtt.texture.type == UnsignedByteType) {
      view = Uint8List(totalSize);
    } else {
      throw Exception(errorType);
    }

    // In three_js, readRenderTargetPixels returns a future wrapper 
    renderer.readRenderTargetPixels(rtt, 0, 0, rtt.width, rtt.height, view);

    final DataTexture texture = DataTexture(view, rtt.width, rtt.height, rtt.texture.format, rtt.texture.type);
    texture.colorSpace = rtt.texture.colorSpace;
    return texture;
  }

  int _getChannelCount(dynamic texture) {
    switch (texture.format) {
      case RGBAFormat:
        return 4;
      case RGFormat:
      case RGIntegerFormat:
        return 2;
      case RedFormat:
      case RedIntegerFormat:
        return 1;
      default:
        throw Exception(errorFormat);
    }
  }

  Map<String, dynamic> _createDefaultContainer() {
    return {
      'dataFormatDescriptor': [
        {
          'colorModel': 0,
          'colorPrimaries': 0,
          'transferFunction': 0,
          'flags': 0,
          'texelBlockDimension': [ 0, 0, 0, 0 ],
          'bytesPlane': [ 0, 0, 0, 0, 0, 0, 0, 0 ],
          'samples': []
        }
      ]
    };
  }

  // Placeholder endpoint for file serialization sequence conversion
  Uint8List writeKTX2Container(Map<String, dynamic> container, {bool keepWriter = true}) {
    // This connects directly to your custom container byte compiler function
    return Uint8List(0); 
  }
}
