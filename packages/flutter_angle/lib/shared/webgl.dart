/// Amalgamation of the WebGL constants from the IDL interfaces in
/// WebGLRenderingContextBase, WebGL2RenderingContextBase, & WebGLDrawBuffers.
/// Because the RenderingContextBase interfaces are hidden they would be
/// replicated in more than one class (e.g., RenderingContext and
/// RenderingContext2) to prevent that duplication these 600+ constants are
/// defined in one abstract class (WebGL).
// JS "WebGL")
abstract class WebGL {
  // To suppress missing implicit constructor warnings.
  factory WebGL._() {
    throw new UnsupportedError("Not supported");
  }

  static const int ACTIVE_ATTRIBUTES = 0x8B89;

  static const int ACTIVE_TEXTURE = 0x84E0;

  static const int ACTIVE_UNIFORMS = 0x8B86;

  static const int ACTIVE_UNIFORM_BLOCKS = 0x8A36;

  static const int ALIASED_LINE_WIDTH_RANGE = 0x846E;

  static const int ALIASED_POINT_SIZE_RANGE = 0x846D;

  static const int ALPHA = 0x1906;

  static const int ALPHA_BITS = 0x0D55;

  static const int ALREADY_SIGNALED = 0x911A;

  static const int ALWAYS = 0x0207;

  static const int ANY_SAMPLES_PASSED = 0x8C2F;

  static const int ANY_SAMPLES_PASSED_CONSERVATIVE = 0x8D6A;

  static const int ARRAY_BUFFER = 0x8892;

  static const int ARRAY_BUFFER_BINDING = 0x8894;

  static const int ATTACHED_SHADERS = 0x8B85;

  static const int BACK = 0x0405;

  static const int BLEND = 0x0BE2;

  static const int BLEND_COLOR = 0x8005;

  static const int BLEND_DST_ALPHA = 0x80CA;

  static const int BLEND_DST_RGB = 0x80C8;

  static const int BLEND_EQUATION = 0x8009;

  static const int BLEND_EQUATION_ALPHA = 0x883D;

  static const int BLEND_EQUATION_RGB = 0x8009;

  static const int BLEND_SRC_ALPHA = 0x80CB;

  static const int BLEND_SRC_RGB = 0x80C9;

  static const int BLUE_BITS = 0x0D54;

  static const int BOOL = 0x8B56;

  static const int BOOL_VEC2 = 0x8B57;

  static const int BOOL_VEC3 = 0x8B58;

  static const int BOOL_VEC4 = 0x8B59;

  static const int BROWSER_DEFAULT_WEBGL = 0x9244;

  static const int BUFFER_SIZE = 0x8764;

  static const int BUFFER_USAGE = 0x8765;

  static const int BYTE = 0x1400;

  static const int CCW = 0x0901;

  static const int CLAMP_TO_EDGE = 0x812F;

  static const int COLOR = 0x1800;

  static const int COLOR_ATTACHMENT0 = 0x8CE0;

  static const int COLOR_ATTACHMENT0_WEBGL = 0x8CE0;

  static const int COLOR_ATTACHMENT1 = 0x8CE1;

  static const int COLOR_ATTACHMENT10 = 0x8CEA;

  static const int COLOR_ATTACHMENT10_WEBGL = 0x8CEA;

  static const int COLOR_ATTACHMENT11 = 0x8CEB;

  static const int COLOR_ATTACHMENT11_WEBGL = 0x8CEB;

  static const int COLOR_ATTACHMENT12 = 0x8CEC;

  static const int COLOR_ATTACHMENT12_WEBGL = 0x8CEC;

  static const int COLOR_ATTACHMENT13 = 0x8CED;

  static const int COLOR_ATTACHMENT13_WEBGL = 0x8CED;

  static const int COLOR_ATTACHMENT14 = 0x8CEE;

  static const int COLOR_ATTACHMENT14_WEBGL = 0x8CEE;

  static const int COLOR_ATTACHMENT15 = 0x8CEF;

  static const int COLOR_ATTACHMENT15_WEBGL = 0x8CEF;

  static const int COLOR_ATTACHMENT1_WEBGL = 0x8CE1;

  static const int COLOR_ATTACHMENT2 = 0x8CE2;

  static const int COLOR_ATTACHMENT2_WEBGL = 0x8CE2;

  static const int COLOR_ATTACHMENT3 = 0x8CE3;

  static const int COLOR_ATTACHMENT3_WEBGL = 0x8CE3;

  static const int COLOR_ATTACHMENT4 = 0x8CE4;

  static const int COLOR_ATTACHMENT4_WEBGL = 0x8CE4;

  static const int COLOR_ATTACHMENT5 = 0x8CE5;

  static const int COLOR_ATTACHMENT5_WEBGL = 0x8CE5;

  static const int COLOR_ATTACHMENT6 = 0x8CE6;

  static const int COLOR_ATTACHMENT6_WEBGL = 0x8CE6;

  static const int COLOR_ATTACHMENT7 = 0x8CE7;

  static const int COLOR_ATTACHMENT7_WEBGL = 0x8CE7;

  static const int COLOR_ATTACHMENT8 = 0x8CE8;

  static const int COLOR_ATTACHMENT8_WEBGL = 0x8CE8;

  static const int COLOR_ATTACHMENT9 = 0x8CE9;

  static const int COLOR_ATTACHMENT9_WEBGL = 0x8CE9;

  static const int COLOR_BUFFER_BIT = 0x00004000;

  static const int COLOR_CLEAR_VALUE = 0x0C22;

  static const int COLOR_WRITEMASK = 0x0C23;

  static const int COMPARE_REF_TO_TEXTURE = 0x884E;

  static const int COMPILE_STATUS = 0x8B81;

  static const int COMPRESSED_TEXTURE_FORMATS = 0x86A3;

  static const int CONDITION_SATISFIED = 0x911C;

  static const int CONSTANT_ALPHA = 0x8003;

  static const int CONSTANT_COLOR = 0x8001;

  static const int CONTEXT_LOST_WEBGL = 0x9242;

  static const int COPY_READ_BUFFER = 0x8F36;

  static const int COPY_READ_BUFFER_BINDING = 0x8F36;

  static const int COPY_WRITE_BUFFER = 0x8F37;

  static const int COPY_WRITE_BUFFER_BINDING = 0x8F37;

  static const int CULL_FACE = 0x0B44;

  static const int CULL_FACE_MODE = 0x0B45;

  static const int CURRENT_PROGRAM = 0x8B8D;

  static const int CURRENT_QUERY = 0x8865;

  static const int CURRENT_VERTEX_ATTRIB = 0x8626;

  static const int CW = 0x0900;

  static const int DECR = 0x1E03;

  static const int DECR_WRAP = 0x8508;

  static const int DELETE_STATUS = 0x8B80;

  static const int DEPTH = 0x1801;

  static const int DEPTH24_STENCIL8 = 0x88F0;

  static const int DEPTH32F_STENCIL8 = 0x8CAD;

  static const int DEPTH_ATTACHMENT = 0x8D00;

  static const int DEPTH_BITS = 0x0D56;

  static const int DEPTH_BUFFER_BIT = 0x00000100;

  static const int DEPTH_CLEAR_VALUE = 0x0B73;

  static const int DEPTH_COMPONENT = 0x1902;

  static const int DEPTH_COMPONENT16 = 0x81A5;

  static const int DEPTH_COMPONENT24 = 0x81A6;

  static const int DEPTH_COMPONENT32F = 0x8CAC;

  static const int DEPTH_FUNC = 0x0B74;

  static const int DEPTH_RANGE = 0x0B70;

  static const int DEPTH_STENCIL = 0x84F9;

  static const int DEPTH_STENCIL_ATTACHMENT = 0x821A;

  static const int DEPTH_TEST = 0x0B71;

  static const int DEPTH_WRITEMASK = 0x0B72;

  static const int DITHER = 0x0BD0;

  static const int DONT_CARE = 0x1100;

  static const int DRAW_BUFFER0 = 0x8825;

  static const int DRAW_BUFFER0_WEBGL = 0x8825;

  static const int DRAW_BUFFER1 = 0x8826;

  static const int DRAW_BUFFER10 = 0x882F;

  static const int DRAW_BUFFER10_WEBGL = 0x882F;

  static const int DRAW_BUFFER11 = 0x8830;

  static const int DRAW_BUFFER11_WEBGL = 0x8830;

  static const int DRAW_BUFFER12 = 0x8831;

  static const int DRAW_BUFFER12_WEBGL = 0x8831;

  static const int DRAW_BUFFER13 = 0x8832;

  static const int DRAW_BUFFER13_WEBGL = 0x8832;

  static const int DRAW_BUFFER14 = 0x8833;

  static const int DRAW_BUFFER14_WEBGL = 0x8833;

  static const int DRAW_BUFFER15 = 0x8834;

  static const int DRAW_BUFFER15_WEBGL = 0x8834;

  static const int DRAW_BUFFER1_WEBGL = 0x8826;

  static const int DRAW_BUFFER2 = 0x8827;

  static const int DRAW_BUFFER2_WEBGL = 0x8827;

  static const int DRAW_BUFFER3 = 0x8828;

  static const int DRAW_BUFFER3_WEBGL = 0x8828;

  static const int DRAW_BUFFER4 = 0x8829;

  static const int DRAW_BUFFER4_WEBGL = 0x8829;

  static const int DRAW_BUFFER5 = 0x882A;

  static const int DRAW_BUFFER5_WEBGL = 0x882A;

  static const int DRAW_BUFFER6 = 0x882B;

  static const int DRAW_BUFFER6_WEBGL = 0x882B;

  static const int DRAW_BUFFER7 = 0x882C;

  static const int DRAW_BUFFER7_WEBGL = 0x882C;

  static const int DRAW_BUFFER8 = 0x882D;

  static const int DRAW_BUFFER8_WEBGL = 0x882D;

  static const int DRAW_BUFFER9 = 0x882E;

  static const int DRAW_BUFFER9_WEBGL = 0x882E;

  static const int DRAW_FRAMEBUFFER = 0x8CA9;

  static const int DRAW_FRAMEBUFFER_BINDING = 0x8CA6;

  static const int DST_ALPHA = 0x0304;

  static const int DST_COLOR = 0x0306;

  static const int DYNAMIC_COPY = 0x88EA;

  static const int DYNAMIC_DRAW = 0x88E8;

  static const int DYNAMIC_READ = 0x88E9;

  static const int ELEMENT_ARRAY_BUFFER = 0x8893;

  static const int ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;

  static const int EQUAL = 0x0202;

  static const int FASTEST = 0x1101;

  static const int FLOAT = 0x1406;

  static const int FLOAT_32_UNSIGNED_INT_24_8_REV = 0x8DAD;

  static const int FLOAT_MAT2 = 0x8B5A;

  static const int FLOAT_MAT2x3 = 0x8B65;

  static const int FLOAT_MAT2x4 = 0x8B66;

  static const int FLOAT_MAT3 = 0x8B5B;

  static const int FLOAT_MAT3x2 = 0x8B67;

  static const int FLOAT_MAT3x4 = 0x8B68;

  static const int FLOAT_MAT4 = 0x8B5C;

  static const int FLOAT_MAT4x2 = 0x8B69;

  static const int FLOAT_MAT4x3 = 0x8B6A;

  static const int FLOAT_VEC2 = 0x8B50;

  static const int FLOAT_VEC3 = 0x8B51;

  static const int FLOAT_VEC4 = 0x8B52;

  static const int FRAGMENT_SHADER = 0x8B30;

  static const int FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B;

  static const int FRAMEBUFFER = 0x8D40;

  static const int FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE = 0x8215;

  static const int FRAMEBUFFER_ATTACHMENT_BLUE_SIZE = 0x8214;

  static const int FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING = 0x8210;

  static const int FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE = 0x8211;

  static const int FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE = 0x8216;

  static const int FRAMEBUFFER_ATTACHMENT_GREEN_SIZE = 0x8213;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;

  static const int FRAMEBUFFER_ATTACHMENT_RED_SIZE = 0x8212;

  static const int FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER = 0x8CD4;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;

  static const int FRAMEBUFFER_BINDING = 0x8CA6;

  static const int FRAMEBUFFER_COMPLETE = 0x8CD5;

  static const int FRAMEBUFFER_DEFAULT = 0x8218;

  static const int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;

  static const int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;

  static const int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;

  static const int FRAMEBUFFER_INCOMPLETE_MULTISAMPLE = 0x8D56;

  static const int FRAMEBUFFER_UNSUPPORTED = 0x8CDD;

  static const int FRONT = 0x0404;

  static const int FRONT_AND_BACK = 0x0408;

  static const int FRONT_FACE = 0x0B46;

  static const int FUNC_ADD = 0x8006;

  static const int FUNC_REVERSE_SUBTRACT = 0x800B;

  static const int FUNC_SUBTRACT = 0x800A;

  static const int GENERATE_MIPMAP_HINT = 0x8192;

  static const int GEQUAL = 0x0206;

  static const int GREATER = 0x0204;

  static const int GREEN_BITS = 0x0D53;

  static const int HALF_FLOAT = 0x140B;

  static const int HIGH_FLOAT = 0x8DF2;

  static const int HIGH_INT = 0x8DF5;

  static const int IMPLEMENTATION_COLOR_READ_FORMAT = 0x8B9B;

  static const int IMPLEMENTATION_COLOR_READ_TYPE = 0x8B9A;

  static const int INCR = 0x1E02;

  static const int INCR_WRAP = 0x8507;

  static const int INT = 0x1404;

  static const int INTERLEAVED_ATTRIBS = 0x8C8C;

  static const int INT_2_10_10_10_REV = 0x8D9F;

  static const int INT_SAMPLER_2D = 0x8DCA;

  static const int INT_SAMPLER_2D_ARRAY = 0x8DCF;

  static const int INT_SAMPLER_3D = 0x8DCB;

  static const int INT_SAMPLER_CUBE = 0x8DCC;

  static const int INT_VEC2 = 0x8B53;

  static const int INT_VEC3 = 0x8B54;

  static const int INT_VEC4 = 0x8B55;

  static const int INVALID_ENUM = 0x0500;

  static const int INVALID_FRAMEBUFFER_OPERATION = 0x0506;

  static const int INVALID_INDEX = 0xFFFFFFFF;

  static const int INVALID_OPERATION = 0x0502;

  static const int INVALID_VALUE = 0x0501;

  static const int INVERT = 0x150A;

  static const int KEEP = 0x1E00;

  static const int LEQUAL = 0x0203;

  static const int LESS = 0x0201;

  static const int LINEAR = 0x2601;

  static const int LINEAR_MIPMAP_LINEAR = 0x2703;

  static const int LINEAR_MIPMAP_NEAREST = 0x2701;

  static const int LINES = 0x0001;

  static const int LINE_LOOP = 0x0002;

  static const int LINE_STRIP = 0x0003;

  static const int LINE_WIDTH = 0x0B21;

  static const int LINK_STATUS = 0x8B82;

  static const int LOW_FLOAT = 0x8DF0;

  static const int LOW_INT = 0x8DF3;

  static const int LUMINANCE = 0x1909;

  static const int LUMINANCE_ALPHA = 0x190A;

  static const int MAX = 0x8008;

  static const int MAX_3D_TEXTURE_SIZE = 0x8073;

  static const int MAX_ARRAY_TEXTURE_LAYERS = 0x88FF;

  static const int MAX_CLIENT_WAIT_TIMEOUT_WEBGL = 0x9247;

  static const int MAX_COLOR_ATTACHMENTS = 0x8CDF;

  static const int MAX_COLOR_ATTACHMENTS_WEBGL = 0x8CDF;

  static const int MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS = 0x8A33;

  static const int MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;

  static const int MAX_COMBINED_UNIFORM_BLOCKS = 0x8A2E;

  static const int MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS = 0x8A31;

  static const int MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;

  static const int MAX_DRAW_BUFFERS = 0x8824;

  static const int MAX_DRAW_BUFFERS_WEBGL = 0x8824;

  static const int MAX_ELEMENTS_INDICES = 0x80E9;

  static const int MAX_ELEMENTS_VERTICES = 0x80E8;

  static const int MAX_ELEMENT_INDEX = 0x8D6B;

  static const int MAX_FRAGMENT_INPUT_COMPONENTS = 0x9125;

  static const int MAX_FRAGMENT_UNIFORM_BLOCKS = 0x8A2D;

  static const int MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49;

  static const int MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;

  static const int MAX_PROGRAM_TEXEL_OFFSET = 0x8905;

  static const int MAX_RENDERBUFFER_SIZE = 0x84E8;

  static const int MAX_SAMPLES = 0x8D57;

  static const int MAX_SERVER_WAIT_TIMEOUT = 0x9111;

  static const int MAX_TEXTURE_IMAGE_UNITS = 0x8872;

  static const int MAX_TEXTURE_LOD_BIAS = 0x84FD;

  static const int MAX_TEXTURE_SIZE = 0x0D33;

  static const int MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS = 0x8C8A;

  static const int MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS = 0x8C8B;

  static const int MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS = 0x8C80;

  static const int MAX_UNIFORM_BLOCK_SIZE = 0x8A30;

  static const int MAX_UNIFORM_BUFFER_BINDINGS = 0x8A2F;

  static const int MAX_VARYING_COMPONENTS = 0x8B4B;

  static const int MAX_VARYING_VECTORS = 0x8DFC;

  static const int MAX_VERTEX_ATTRIBS = 0x8869;

  static const int MAX_VERTEX_OUTPUT_COMPONENTS = 0x9122;

  static const int MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;

  static const int MAX_VERTEX_UNIFORM_BLOCKS = 0x8A2B;

  static const int MAX_VERTEX_UNIFORM_COMPONENTS = 0x8B4A;

  static const int MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;

  static const int MAX_VIEWPORT_DIMS = 0x0D3A;

  static const int MEDIUM_FLOAT = 0x8DF1;

  static const int MEDIUM_INT = 0x8DF4;

  static const int MIN = 0x8007;

  static const int MIN_PROGRAM_TEXEL_OFFSET = 0x8904;

  static const int MIRRORED_REPEAT = 0x8370;

  static const int NEAREST = 0x2600;

  static const int NEAREST_MIPMAP_LINEAR = 0x2702;

  static const int NEAREST_MIPMAP_NEAREST = 0x2700;

  static const int NEVER = 0x0200;

  static const int NICEST = 0x1102;

  static const int NONE = 0;

  static const int NOTEQUAL = 0x0205;

  static const int NO_ERROR = 0;

  static const int OBJECT_TYPE = 0x9112;

  static const int ONE = 1;

  static const int ONE_MINUS_CONSTANT_ALPHA = 0x8004;

  static const int ONE_MINUS_CONSTANT_COLOR = 0x8002;

  static const int ONE_MINUS_DST_ALPHA = 0x0305;

  static const int ONE_MINUS_DST_COLOR = 0x0307;

  static const int ONE_MINUS_SRC_ALPHA = 0x0303;

  static const int ONE_MINUS_SRC_COLOR = 0x0301;

  static const int OUT_OF_MEMORY = 0x0505;

  static const int PACK_ALIGNMENT = 0x0D05;

  static const int PACK_ROW_LENGTH = 0x0D02;

  static const int PACK_SKIP_PIXELS = 0x0D04;

  static const int PACK_SKIP_ROWS = 0x0D03;

  static const int PIXEL_PACK_BUFFER = 0x88EB;

  static const int PIXEL_PACK_BUFFER_BINDING = 0x88ED;

  static const int PIXEL_UNPACK_BUFFER = 0x88EC;

  static const int PIXEL_UNPACK_BUFFER_BINDING = 0x88EF;

  static const int POINTS = 0x0000;

  static const int POLYGON_OFFSET_FACTOR = 0x8038;

  static const int POLYGON_OFFSET_FILL = 0x8037;

  static const int POLYGON_OFFSET_UNITS = 0x2A00;

  static const int QUERY_RESULT = 0x8866;

  static const int QUERY_RESULT_AVAILABLE = 0x8867;

  static const int R11F_G11F_B10F = 0x8C3A;

  static const int R16F = 0x822D;

  static const int R16I = 0x8233;

  static const int R16UI = 0x8234;

  static const int R32F = 0x822E;

  static const int R32I = 0x8235;

  static const int R32UI = 0x8236;

  static const int R8 = 0x8229;

  static const int R8I = 0x8231;

  static const int R8UI = 0x8232;

  static const int R8_SNORM = 0x8F94;

  static const int RASTERIZER_DISCARD = 0x8C89;

  static const int READ_BUFFER = 0x0C02;

  static const int READ_FRAMEBUFFER = 0x8CA8;

  static const int READ_FRAMEBUFFER_BINDING = 0x8CAA;

  static const int RED = 0x1903;

  static const int RED_BITS = 0x0D52;

  static const int RED_INTEGER = 0x8D94;

  static const int RENDERBUFFER = 0x8D41;

  static const int RENDERBUFFER_ALPHA_SIZE = 0x8D53;

  static const int RENDERBUFFER_BINDING = 0x8CA7;

  static const int RENDERBUFFER_BLUE_SIZE = 0x8D52;

  static const int RENDERBUFFER_DEPTH_SIZE = 0x8D54;

  static const int RENDERBUFFER_GREEN_SIZE = 0x8D51;

  static const int RENDERBUFFER_HEIGHT = 0x8D43;

  static const int RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;

  static const int RENDERBUFFER_RED_SIZE = 0x8D50;

  static const int RENDERBUFFER_SAMPLES = 0x8CAB;

  static const int RENDERBUFFER_STENCIL_SIZE = 0x8D55;

  static const int RENDERBUFFER_WIDTH = 0x8D42;

  static const int RENDERER = 0x1F01;

  static const int REPEAT = 0x2901;

  static const int REPLACE = 0x1E01;

  static const int RG = 0x8227;

  static const int RG16F = 0x822F;

  static const int RG16I = 0x8239;

  static const int RG16UI = 0x823A;

  static const int RG32F = 0x8230;

  static const int RG32I = 0x823B;

  static const int RG32UI = 0x823C;

  static const int RG8 = 0x822B;

  static const int RG8I = 0x8237;

  static const int RG8UI = 0x8238;

  static const int RG8_SNORM = 0x8F95;

  static const int RGB = 0x1907;

  static const int RGB10_A2 = 0x8059;

  static const int RGB10_A2UI = 0x906F;

  static const int RGB16F = 0x881B;

  static const int RGB16I = 0x8D89;

  static const int RGB16UI = 0x8D77;

  static const int RGB32F = 0x8815;

  static const int RGB32I = 0x8D83;

  static const int RGB32UI = 0x8D71;

  static const int RGB565 = 0x8D62;

  static const int RGB5_A1 = 0x8057;

  static const int RGB8 = 0x8051;

  static const int RGB8I = 0x8D8F;

  static const int RGB8UI = 0x8D7D;

  static const int RGB8_SNORM = 0x8F96;

  static const int RGB9_E5 = 0x8C3D;

  static const int RGBA = 0x1908;

  static const int RGBA16F = 0x881A;

  static const int RGBA16I = 0x8D88;

  static const int RGBA16UI = 0x8D76;

  static const int RGBA32F = 0x8814;

  static const int RGBA32I = 0x8D82;

  static const int RGBA32UI = 0x8D70;

  static const int RGBA4 = 0x8056;

  static const int RGBA8 = 0x8058;

  static const int RGBA8I = 0x8D8E;

  static const int RGBA8UI = 0x8D7C;

  static const int RGBA8_SNORM = 0x8F97;

  static const int RGBA_INTEGER = 0x8D99;

  static const int RGB_INTEGER = 0x8D98;

  static const int RG_INTEGER = 0x8228;

  static const int SAMPLER_2D = 0x8B5E;

  static const int SAMPLER_2D_ARRAY = 0x8DC1;

  static const int SAMPLER_2D_ARRAY_SHADOW = 0x8DC4;

  static const int SAMPLER_2D_SHADOW = 0x8B62;

  static const int SAMPLER_3D = 0x8B5F;

  static const int SAMPLER_BINDING = 0x8919;

  static const int SAMPLER_CUBE = 0x8B60;

  static const int SAMPLER_CUBE_SHADOW = 0x8DC5;

  static const int SAMPLES = 0x80A9;

  static const int SAMPLE_ALPHA_TO_COVERAGE = 0x809E;

  static const int SAMPLE_BUFFERS = 0x80A8;

  static const int SAMPLE_COVERAGE = 0x80A0;

  static const int SAMPLE_COVERAGE_INVERT = 0x80AB;

  static const int SAMPLE_COVERAGE_VALUE = 0x80AA;

  static const int SCISSOR_BOX = 0x0C10;

  static const int SCISSOR_TEST = 0x0C11;

  static const int SEPARATE_ATTRIBS = 0x8C8D;

  static const int SHADER_TYPE = 0x8B4F;

  static const int SHADING_LANGUAGE_VERSION = 0x8B8C;

  static const int SHORT = 0x1402;

  static const int SIGNALED = 0x9119;

  static const int SIGNED_NORMALIZED = 0x8F9C;

  static const int SRC_ALPHA = 0x0302;

  static const int SRC_ALPHA_SATURATE = 0x0308;

  static const int SRC_COLOR = 0x0300;

  static const int SRGB = 0x8C40;

  static const int SRGB8 = 0x8C41;

  static const int SRGB8_ALPHA8 = 0x8C43;

  static const int STATIC_COPY = 0x88E6;

  static const int STATIC_DRAW = 0x88E4;

  static const int STATIC_READ = 0x88E5;

  static const int STENCIL = 0x1802;

  static const int STENCIL_ATTACHMENT = 0x8D20;

  static const int STENCIL_BACK_FAIL = 0x8801;

  static const int STENCIL_BACK_FUNC = 0x8800;

  static const int STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;

  static const int STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;

  static const int STENCIL_BACK_REF = 0x8CA3;

  static const int STENCIL_BACK_VALUE_MASK = 0x8CA4;

  static const int STENCIL_BACK_WRITEMASK = 0x8CA5;

  static const int STENCIL_BITS = 0x0D57;

  static const int STENCIL_BUFFER_BIT = 0x00000400;

  static const int STENCIL_CLEAR_VALUE = 0x0B91;

  static const int STENCIL_FAIL = 0x0B94;

  static const int STENCIL_FUNC = 0x0B92;

  static const int STENCIL_INDEX8 = 0x8D48;

  static const int STENCIL_PASS_DEPTH_FAIL = 0x0B95;

  static const int STENCIL_PASS_DEPTH_PASS = 0x0B96;

  static const int STENCIL_REF = 0x0B97;

  static const int STENCIL_TEST = 0x0B90;

  static const int STENCIL_VALUE_MASK = 0x0B93;

  static const int STENCIL_WRITEMASK = 0x0B98;

  static const int STREAM_COPY = 0x88E2;

  static const int STREAM_DRAW = 0x88E0;

  static const int STREAM_READ = 0x88E1;

  static const int SUBPIXEL_BITS = 0x0D50;

  static const int SYNC_CONDITION = 0x9113;

  static const int SYNC_FENCE = 0x9116;

  static const int SYNC_FLAGS = 0x9115;

  static const int SYNC_FLUSH_COMMANDS_BIT = 0x00000001;

  static const int SYNC_GPU_COMMANDS_COMPLETE = 0x9117;

  static const int SYNC_STATUS = 0x9114;

  static const int TEXTURE = 0x1702;

  static const int TEXTURE0 = 0x84C0;

  static const int TEXTURE1 = 0x84C1;

  static const int TEXTURE10 = 0x84CA;

  static const int TEXTURE11 = 0x84CB;

  static const int TEXTURE12 = 0x84CC;

  static const int TEXTURE13 = 0x84CD;

  static const int TEXTURE14 = 0x84CE;

  static const int TEXTURE15 = 0x84CF;

  static const int TEXTURE16 = 0x84D0;

  static const int TEXTURE17 = 0x84D1;

  static const int TEXTURE18 = 0x84D2;

  static const int TEXTURE19 = 0x84D3;

  static const int TEXTURE2 = 0x84C2;

  static const int TEXTURE20 = 0x84D4;

  static const int TEXTURE21 = 0x84D5;

  static const int TEXTURE22 = 0x84D6;

  static const int TEXTURE23 = 0x84D7;

  static const int TEXTURE24 = 0x84D8;

  static const int TEXTURE25 = 0x84D9;

  static const int TEXTURE26 = 0x84DA;

  static const int TEXTURE27 = 0x84DB;

  static const int TEXTURE28 = 0x84DC;

  static const int TEXTURE29 = 0x84DD;

  static const int TEXTURE3 = 0x84C3;

  static const int TEXTURE30 = 0x84DE;

  static const int TEXTURE31 = 0x84DF;

  static const int TEXTURE4 = 0x84C4;

  static const int TEXTURE5 = 0x84C5;

  static const int TEXTURE6 = 0x84C6;

  static const int TEXTURE7 = 0x84C7;

  static const int TEXTURE8 = 0x84C8;

  static const int TEXTURE9 = 0x84C9;

  static const int TEXTURE_2D = 0x0DE1;

  static const int TEXTURE_2D_ARRAY = 0x8C1A;

  static const int TEXTURE_3D = 0x806F;

  static const int TEXTURE_BASE_LEVEL = 0x813C;

  static const int TEXTURE_BINDING_2D = 0x8069;

  static const int TEXTURE_BINDING_2D_ARRAY = 0x8C1D;

  static const int TEXTURE_BINDING_3D = 0x806A;

  static const int TEXTURE_BINDING_CUBE_MAP = 0x8514;

  static const int TEXTURE_COMPARE_FUNC = 0x884D;

  static const int TEXTURE_COMPARE_MODE = 0x884C;

  static const int TEXTURE_CUBE_MAP = 0x8513;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;

  static const int TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;

  static const int TEXTURE_IMMUTABLE_FORMAT = 0x912F;

  static const int TEXTURE_IMMUTABLE_LEVELS = 0x82DF;

  static const int TEXTURE_MAG_FILTER = 0x2800;

  static const int TEXTURE_MAX_LEVEL = 0x813D;

  static const int TEXTURE_MAX_LOD = 0x813B;

  static const int TEXTURE_MIN_FILTER = 0x2801;

  static const int TEXTURE_MIN_LOD = 0x813A;

  static const int TEXTURE_WRAP_R = 0x8072;

  static const int TEXTURE_WRAP_S = 0x2802;

  static const int TEXTURE_WRAP_T = 0x2803;

  static const int TIMEOUT_EXPIRED = 0x911B;

  static const int TIMEOUT_IGNORED = -1;

  static const int TRANSFORM_FEEDBACK = 0x8E22;

  static const int TRANSFORM_FEEDBACK_ACTIVE = 0x8E24;

  static const int TRANSFORM_FEEDBACK_BINDING = 0x8E25;

  static const int TRANSFORM_FEEDBACK_BUFFER = 0x8C8E;

  static const int TRANSFORM_FEEDBACK_BUFFER_BINDING = 0x8C8F;

  static const int TRANSFORM_FEEDBACK_BUFFER_MODE = 0x8C7F;

  static const int TRANSFORM_FEEDBACK_BUFFER_SIZE = 0x8C85;

  static const int TRANSFORM_FEEDBACK_BUFFER_START = 0x8C84;

  static const int TRANSFORM_FEEDBACK_PAUSED = 0x8E23;

  static const int TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN = 0x8C88;

  static const int TRANSFORM_FEEDBACK_VARYINGS = 0x8C83;

  static const int TRIANGLES = 0x0004;

  static const int TRIANGLE_FAN = 0x0006;

  static const int TRIANGLE_STRIP = 0x0005;

  static const int UNIFORM_ARRAY_STRIDE = 0x8A3C;

  static const int UNIFORM_BLOCK_ACTIVE_UNIFORMS = 0x8A42;

  static const int UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES = 0x8A43;

  static const int UNIFORM_BLOCK_BINDING = 0x8A3F;

  static const int UNIFORM_BLOCK_DATA_SIZE = 0x8A40;

  static const int UNIFORM_BLOCK_INDEX = 0x8A3A;

  static const int UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER = 0x8A46;

  static const int UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER = 0x8A44;

  static const int UNIFORM_BUFFER = 0x8A11;

  static const int UNIFORM_BUFFER_BINDING = 0x8A28;

  static const int UNIFORM_BUFFER_OFFSET_ALIGNMENT = 0x8A34;

  static const int UNIFORM_BUFFER_SIZE = 0x8A2A;

  static const int UNIFORM_BUFFER_START = 0x8A29;

  static const int UNIFORM_IS_ROW_MAJOR = 0x8A3E;

  static const int UNIFORM_MATRIX_STRIDE = 0x8A3D;

  static const int UNIFORM_OFFSET = 0x8A3B;

  static const int UNIFORM_SIZE = 0x8A38;

  static const int UNIFORM_TYPE = 0x8A37;

  static const int UNPACK_ALIGNMENT = 0x0CF5;

  static const int UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;

  static const int UNPACK_FLIP_Y_WEBGL = 0x9240;

  static const int UNPACK_IMAGE_HEIGHT = 0x806E;

  static const int UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;

  static const int UNPACK_ROW_LENGTH = 0x0CF2;

  static const int UNPACK_SKIP_IMAGES = 0x806D;

  static const int UNPACK_SKIP_PIXELS = 0x0CF4;

  static const int UNPACK_SKIP_ROWS = 0x0CF3;

  static const int UNSIGNALED = 0x9118;

  static const int UNSIGNED_BYTE = 0x1401;

  static const int UNSIGNED_INT = 0x1405;

  static const int UNSIGNED_INT_10F_11F_11F_REV = 0x8C3B;

  static const int UNSIGNED_INT_24_8 = 0x84FA;

  static const int UNSIGNED_INT_2_10_10_10_REV = 0x8368;

  static const int UNSIGNED_INT_5_9_9_9_REV = 0x8C3E;

  static const int UNSIGNED_INT_SAMPLER_2D = 0x8DD2;

  static const int UNSIGNED_INT_SAMPLER_2D_ARRAY = 0x8DD7;

  static const int UNSIGNED_INT_SAMPLER_3D = 0x8DD3;

  static const int UNSIGNED_INT_SAMPLER_CUBE = 0x8DD4;

  static const int UNSIGNED_INT_VEC2 = 0x8DC6;

  static const int UNSIGNED_INT_VEC3 = 0x8DC7;

  static const int UNSIGNED_INT_VEC4 = 0x8DC8;

  static const int UNSIGNED_NORMALIZED = 0x8C17;

  static const int UNSIGNED_SHORT = 0x1403;

  static const int UNSIGNED_SHORT_4_4_4_4 = 0x8033;

  static const int UNSIGNED_SHORT_5_5_5_1 = 0x8034;

  static const int UNSIGNED_SHORT_5_6_5 = 0x8363;

  static const int VALIDATE_STATUS = 0x8B83;

  static const int VENDOR = 0x1F00;

  static const int VERSION = 0x1F02;

  static const int VERTEX_ARRAY_BINDING = 0x85B5;

  static const int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

  static const int VERTEX_ATTRIB_ARRAY_DIVISOR = 0x88FE;

  static const int VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;

  static const int VERTEX_ATTRIB_ARRAY_INTEGER = 0x88FD;

  static const int VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;

  static const int VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;

  static const int VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;

  static const int VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;

  static const int VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;

  static const int VERTEX_SHADER = 0x8B31;

  static const int VIEWPORT = 0x0BA2;

  static const int WAIT_FAILED = 0x911D;

  static const int ZERO = 0;
}

// // JS "WebGL2RenderingContextBase")
// abstract class _WebGL2RenderingContextBase extends Interceptor implements _WebGLRenderingContextBase {
//   // To suppress missing implicit constructor warnings.
//   factory _WebGL2RenderingContextBase._() {
//     throw new UnsupportedError("Not supported");
//   }

//   // From WebGLRenderingContextBase
// }

// abstract class _WebGLRenderingContextBase extends Interceptor {
//   // To suppress missing implicit constructor warnings.
//   factory _WebGLRenderingContextBase._() {
//     throw new UnsupportedError("Not supported");
//   }
// }
