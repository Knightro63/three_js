import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_math/three_js_math.dart' as tmath;
import 'package:three_js_gpu/three_js_gpu.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebglGeometries(),
    );
  }
}

class WebglGeometries extends StatefulWidget {
  const WebglGeometries({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglGeometries> {
  late ThreeJS threeJs;

  @override
  void initState() {
    threeJs = ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return threeJs.build(context);
  }

  int startTime = 0;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2000);
    threeJs.camera.position.y = 400;

    threeJs.scene = three.Scene();

    three.Mesh object;

    final ambientLight = three.AmbientLight(0xffffff, 0.8);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);
    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    final material = three.MeshBasicMaterial.fromMap({
      "color": 0xffffff,
      "side": tmath.DoubleSide,
      "clipShadows": true
    });
    object = three.Mesh(three.SphereGeometry(75, 20, 10), material);
    object.position.setValues(-300, 0, 200);
    threeJs.scene.add(object);

    object = three.Mesh(three.PlaneGeometry(100, 100, 4, 4), material);
    object.position.setValues(-300, 0, 0);
    threeJs.scene.add(object);

    object = three.Mesh(three.BoxGeometry(100, 100, 100, 4, 4, 4), material);
    object.position.setValues(-100, 0, 0);
    threeJs.scene.add(object);

    startTime = DateTime.now().millisecondsSinceEpoch;

    threeJs.addAnimationEvent((dt){
      final timer = DateTime.now().millisecondsSinceEpoch * 0.0001;

      threeJs.camera.position.x = math.cos(timer) * 800;
      threeJs.camera.position.z = math.sin(timer) * 800;
      threeJs.camera.lookAt(threeJs.scene.position);

      threeJs.scene.traverse((object) {
        if (object is three.Mesh) {
          object.rotation.x = timer * 5;
          object.rotation.y = timer * 2.5;
        }
      });
    });
  }
}


// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:flutter_gpux/flutter_gpux.dart';

// void main() {
//   runApp(const MaterialApp(home: GraphicsAppHome()));
// }

// class GraphicsAppHome extends StatelessWidget {
//   const GraphicsAppHome({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Materia Engine - gpux Viewport')),
//       body: Center(
//         child: SizedBox(
//           width: 600,
//           height: 600,
//           child: Card(
//             elevation: 8,
//             clipBehavior: Clip.antiAlias,
//             // 1. DefaultGpu boots up the core cross-platform Gpu hardware handle environment background instance
//             child: DefaultGpu(
//               child: GpuView(
//                 // 2. Hook up your custom GpuRenderer drawing pipeline class
//                 renderer: TriangleRenderer(), 
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class TriangleRenderer implements GpuRenderer {
//   GpuRenderPipeline? _pipeline;
//   GpuBuffer? _vertexBuffer;
//   GpuBuffer? _uniformBuffer;
//   GpuBindGroup? _bindGroup;
  
//   double _rotation = 0.0;

//   @override
//   bool render(GpuFrame frame) {
//     // 1. Lazy initialize GPU resources using the device provided by the GpuFrame context
//     // Fixed: Passing frame.device and pulling canvas format out cleanly
//     _ensureResourcesInitialized(frame.device, frame.format);

//     // 2. Animate and update uniform data using the Uint8List buffer view
//     _rotation += 0.01;
//     final uniformsData = Float32List.fromList([_rotation, 0.0, 0.0, 0.0]);
    
//     // Fixed: Converting Float32List to Uint8List for buffer submission compatibility
//     frame.device.queue.writeBuffer(
//       _uniformBuffer!,
//       uniformsData.buffer.asUint8List(),
//     );

//     // 3. Allocate execution command encoder with direct label positional syntax
//     final commandEncoder = frame.device.createCommandEncoder(
//       label: 'Main Command Encoder',
//     );

//     // 4. Begin render pass using GpuColorAttachment structures matching your local package definitions
//     final renderPass = commandEncoder.beginRenderPass(
//       label: 'Primary Render Pass',
//       colorAttachments: [
//         GpuColorAttachment(
//           view: frame.targetView, // Fixed: Extracted correctly from the native frame context loop
//           loadOp: GpuLoadOp.clear,
//           clearValue: const GpuColor(0.05, 0.05, 0.1, 1.0),
//           storeOp: GpuStoreOp.store,
//         ),
//       ],
//     );

//     // 5. Bind Graphics Pipelines and buffers
//     renderPass.setPipeline(_pipeline!);
//     renderPass.setVertexBuffer(0, _vertexBuffer!);
//     renderPass.setBindGroup(0, _bindGroup!);
    
//     // Fixed: Invoking named properties according to your parameter signature limits
//     renderPass.draw(
//       vertexCount: 3, 
//       instanceCount: 1, 
//       firstVertex: 0, 
//       firstInstance: 0,
//     );
//     renderPass.end();

//     // 6. Finalize commands and push right out onto the device frame timeline queue channel
//     final commandBuffer = commandEncoder.finish();
//     frame.device.queue.submit([commandBuffer]);
    
//     return true;
//   }

//   void _ensureResourcesInitialized(GpuDevice device, GpuTextureFormat canvasFormat) {
//     if (_pipeline != null) return;

//     final vertexData = Float32List.fromList([
//        0.0,  0.5, 0.0,  1.0, 0.0, 0.0, // Top Vertex
//       -0.5, -0.5, 0.0,  0.0, 1.0, 0.0, // Bottom Left
//        0.5, -0.5, 0.0,  0.0, 0.0, 1.0, // Bottom Right
//     ]);

//     _vertexBuffer = device.createBuffer(
//       label: 'Vertex Data Buffer',
//       size: vertexData.lengthInBytes,
//       usage: GpuBufferUsage.vertex,
//       mappedAtCreation: true,
//     );
//     _vertexBuffer!.getMappedRange().asFloat32List().setAll(0, vertexData);
//     _vertexBuffer!.unmap();

//     _uniformBuffer = device.createBuffer(
//       label: 'Rotation Uniform Buffer',
//       size: 16,
//       usage: GpuBufferUsage.uniform | GpuBufferUsage.copyDst,
//     );

//     const wgslShaderCode = '''
//       struct Uniforms {
//           rotation: f32,
//       }
//       @group(0) @binding(0) var<uniform> u: Uniforms;

//       struct VertexInput {
//           @location(0) pos: vec3<f32>,
//           @location(1) color: vec3<f32>,
//       }
//       struct VertexOutput {
//           @builtin(position) position: vec4<f32>,
//           @location(0) color: vec3<f32>,
//       }

//       @vertex fn vs_main(in: VertexInput) -> VertexOutput {
//           var out: VertexOutput;
//           let s = sin(u.rotation);
//           let c = cos(u.rotation);
//           let rotX = in.pos.x * c - in.pos.y * s;
//           let rotY = in.pos.x * s + in.pos.y * c;
//           out.position = vec4<f32>(rotX, rotY, in.pos.z, 1.0);
//           out.color = in.color;
//           return out;
//       }

//       @fragment fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
//           return vec4<f32>(in.color, 1.0);
//       }
//     ''';

//     final shaderModule = device.createShaderModule(
//       wgslShaderCode,
//       label: 'Shader Module Source',
//     );

//     // Fixed: Uses list array syntax matching your local GpuBindGroupLayout layout
//     final bindGroupLayout = device.createBindGroupLayout(
//       [
//         GpuBindGroupLayoutEntry.buffer(
//           binding: 0,
//           visibility: GpuShaderStage.vertex,
//         ),
//       ],
//       label: 'Uniforms Bind Layout',
//     );

//     _bindGroup = device.createBindGroup(
//       label: 'Uniforms Material Bind Group',
//       layout: bindGroupLayout,
//       entries: [
//         GpuBindGroupEntry.buffer(binding: 0, buffer: _uniformBuffer!),
//       ],
//     );

//     // Fixed: Pass layout array straight to pipeline constructor wrapper
//     final pipelineLayout = device.createPipelineLayout([bindGroupLayout]);

//     _pipeline = device.createRenderPipeline(
//       GpuRenderPipelineDescriptor(
//         label: 'Triangle Render Pipeline',
//         layout: pipelineLayout,
//         vertexModule: shaderModule,
//         vertexEntryPoint: 'vs_main',
//         vertexBuffers: [
//           GpuVertexBufferLayout(
//             arrayStride: 6 * 4,
//             attributes: const [
//               GpuVertexAttribute(shaderLocation: 0, format: GpuVertexFormat.float32x3, offset: 0),
//               GpuVertexAttribute(shaderLocation: 1, format: GpuVertexFormat.float32x3, offset: 3 * 4),
//             ],
//           ),
//         ],
//         fragmentModule: shaderModule,
//         fragmentEntryPoint: 'fs_main',
//         colorTargets: [GpuColorTargetState(format: canvasFormat)],
//         primitiveTopology: GpuPrimitiveTopology.triangleList,
//         cullMode: GpuCullMode.none,
//       ),
//     );
//   }

//   @override
//   void resize(int width, int height) {
//     // Replaces onResize from previous version
//   }
//  @override
//   void dispose() {
//     _vertexBuffer?.destroy();
//     _uniformBuffer?.destroy();
//     _pipeline = null;
//   }

//   @override
//   void addListener(VoidCallback listener) {
//   }

//   @override
//   void removeListener(VoidCallback listener) {
//   }

//   @override
//   bool shouldUpdate(GpuRenderer oldRenderer) {
//     // Return true if the engine needs to copy state or hot-reload configurations
//     // from a previous widget tree layout rebuild.
//     return true; 
//   }

//   @override
//   bool get shouldSkipNextFrame {
//     // Return false so that the renderer continues drawing animations continuously.
//     // If you ever want to freeze rendering to save battery, switch this to true.
//     return false; 
//   }
// }




