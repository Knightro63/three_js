// import 'package:gpux/gpux.dart';

// /// Sealed class defining material structural blueprints.
// /// Enforces complete exhaustiveness during switch validations.
// sealed class MaterialBindingBlueprint {
//   const MaterialBindingBlueprint(this.renderState);

//   final RenderState renderState;

//   GpuVertexBufferLayout get vertexLayout;
//   GpuPrimitiveTopology get primitiveTopology;

//   /// Creates the GPU pipeline based on the modern type-switch evaluation layout.
//   UnlitPipelineResources createPipeline(
//     GpuDevice device,
//     GpuTextureFormat colorFormat, [
//     GpuTextureFormat? depthFormat,
//   ]) {
//     return switch (this) {
//       UnlitColor() => UnlitPipelineFactory.createUnlitColorPipeline(
//           device,
//           colorFormat,
//           renderState,
//           primitiveTopology,
//           depthFormat,
//         ),
//       UnlitLines() => UnlitPipelineFactory.createUnlitColorPipeline(
//           device,
//           colorFormat,
//           renderState,
//           primitiveTopology,
//           depthFormat,
//         ),
//       UnlitPoints() => UnlitPipelineFactory.createUnlitPointsPipeline(
//           device,
//           colorFormat,
//           renderState,
//           depthFormat,
//         ),
//     };
//   }
// }

// class UnlitColor extends MaterialBindingBlueprint {
//   const UnlitColor(super.renderState);

//   @override
//   GpuVertexBufferLayout get vertexLayout => UnlitPipelineFactory.vertexLayoutWithPosition();

//   @override
//   GpuPrimitiveTopology get primitiveTopology => GpuPrimitiveTopology.triangleList;
// }

// class UnlitLines extends MaterialBindingBlueprint {
//   const UnlitLines(super.renderState);

//   @override
//   GpuVertexBufferLayout get vertexLayout => UnlitPipelineFactory.vertexLayoutWithPosition();

//   @override
//   GpuPrimitiveTopology get primitiveTopology => GpuPrimitiveTopology.lineList;
// }

// class UnlitPoints extends MaterialBindingBlueprint {
//   const UnlitPoints(super.renderState);

//   @override
//   GpuVertexBufferLayout get vertexLayout => UnlitPipelineFactory.instancedPointsLayout();

//   @override
//   GpuPrimitiveTopology get primitiveTopology => GpuPrimitiveTopology.pointList;
// }

// /// Extension method providing the mapping conversion on top of core Material classes.
// extension MaterialBindingExtension on Material {
//   MaterialBindingBlueprint toBindingBlueprint() {
//     final self = this;
//     return switch (self) {
//       UnlitColorMaterial() => UnlitColor(self.renderState),
//       UnlitLineMaterial() => UnlitLines(self.renderState),
//       UnlitPointsMaterial() => UnlitPoints(self.renderState),
//       _ => throw ArgumentError('Unsupported material conversion target: $runtimeType'),
//     };
//   }
// }
