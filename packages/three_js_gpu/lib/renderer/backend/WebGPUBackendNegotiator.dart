import 'dart:async';
import 'package:gpux/gpux.dart'; // Adjust imports to match your specific gpux structure

/// WebGPU backend negotiator for Flutter platforms.
/// Probes WebGPU/WGPU adapter capabilities and creates WebGPU surfaces.
class WebGPUBackendNegotiator extends AbstractBackendNegotiator {
  
  @override
  Future<DeviceCapabilityReport> detectCapabilities(CapabilityRequest request) async {
    // 1. Check if the underlying GPU hardware/API is initialized and available
    if (!Gpu.isAvailable()) {
      return _createUnsupportedReport("WebGPU/WGPU not available on this platform");
    }

    try {
      // 2. Request a high-performance adapter via gpux
      final adapter = await Gpu.requestAdapter(
        options: GpuAdapterOptions(
          powerPreference: GpuPowerPreference.highPerformance,
        ),
      );

      final adapterInfo = _getAdapterInfo(adapter);
      final features = _detectWebGpuFeatures(adapter);

      return DeviceCapabilityReport(
        deviceId: adapterInfo.device ?? "unknown-webgpu-device",
        driverVersion: adapterInfo.driver ?? "WebGPU/WGPU API",
        osBuild: adapterInfo.description ?? "Native/Browser Hybrid",
        featureFlags: features,
        preferredBackend: _allFeaturesSupported(features) ? BackendId.webgpu : null,
        limitations: _detectLimitations(features),
        timestamp: DateTime.now().toUtc().toIso8601String(),
      );
    } catch (e) {
      return _createUnsupportedReport("WebGPU adapter request failed: ${e.toString()}");
    }
  }

  @override
  Future<RenderSurfaceDescriptor> performPlatformInitialization({
    required BackendId backendId,
    required SurfaceConfig surface,
    required dynamic nativeViewHandle, // Pass your target Flutter Texture ID or Surface widget reference here
  }) async {
    assert(backendId == BackendId.webgpu, "WebGPU negotiator can only initialize WEBGPU backend, got $backendId");

    // 3. Initialize your surface target context via gpux
    final context = Gpu.createContextFromNativeHandle(nativeViewHandle);

    // 4. Configure the active swapchain properties
    _configureWebGpuSwapchain(context, surface);

    return RenderSurfaceDescriptor(
      surfaceId: "webgpu-surface-$nativeViewHandle",
      backendId: BackendId.webgpu,
      width: surface.width,
      height: surface.height,
      colorFormat: surface.colorFormat,
      depthFormat: surface.depthFormat,
      presentMode: surface.presentMode,
      isXRSurface: surface.isXRSurface,
    );
  }

  AdapterInfo _getAdapterInfo(GpuAdapter adapter) {
    // gpux wraps the native adapter properties safely without privacy leaks
    return AdapterInfo(
      device: adapter.name,
      driver: "WGPU/WebGPU Core",
      description: "Cross-platform hardware instance",
    );
  }

  Map<BackendFeature, FeatureStatus> _detectWebGpuFeatures(GpuAdapter adapter) {
    final features = <BackendFeature, FeatureStatus>{};

    // Check for 16-bit float capabilities in shaders
    features[BackendFeature.compute] = adapter.features.contains("shader-f16")
        ? FeatureStatus.supported
        : FeatureStatus.emulated;

    // Ray tracing is missing/unstable on standard cross-platform wrappers
    features[BackendFeature.rayTracing] = FeatureStatus.missing;

    // Flutter XR/VR surfaces can be evaluated here if needed
    features[BackendFeature.xrSurface] = FeatureStatus.missing;

    return features;
  }

  List<String> _detectLimitations(Map<BackendFeature, FeatureStatus> features) {
    final limitations = <String>[];
    features.forEach((feature, status) {
      if (status == FeatureStatus.missing) {
        limitations.add("$feature not supported");
      } else if (status == FeatureStatus.emulated) {
        limitations.add("$feature emulated (reduced performance)");
      }
    });
    return limitations;
  }

  DeviceCapabilityReport _createUnsupportedReport(String reason) {
    return DeviceCapabilityReport(
      deviceId: "unsupported",
      driverVersion: "N/A",
      osBuild: "Platform Layer",
      featureFlags: {
        BackendFeature.compute: FeatureStatus.missing,
        BackendFeature.rayTracing: FeatureStatus.missing,
        BackendFeature.xrSurface: FeatureStatus.missing,
      },
      preferredBackend: null,
      limitations: [reason],
      timestamp: DateTime.now().toUtc().toIso8601String(),
    );
  }

  void _configureWebGpuSwapchain(GpuContext context, SurfaceConfig surface) {
    // 5. Map the Materia configuration properties to actual gpux Canvas/Surface configurations
    final format = surface.colorFormat == ColorFormat.bgra8Unorm
        ? GpuTextureFormat.bgra8unorm
        : GpuTextureFormat.rgba16float;

    context.configure(GpuCanvasConfiguration(
      format: format,
      usage: GpuTextureUsage.renderAttachment,
      alphaMode: GpuCanvasAlphaMode.opaque,
    ));
  }

  bool _allFeaturesSupported(Map<BackendFeature, FeatureStatus> features) {
    return features.values.every((status) => status == FeatureStatus.supported);
  }
}

/// Factory function implementation mapping to Kotlin's actual fun pattern
BackendNegotiator createBackendNegotiator() {
  return WebGPUBackendNegotiator();
}

class AdapterInfo {
  final String? device;
  final String? driver;
  final String? description;
  AdapterInfo({this.device, this.driver, this.description});
}
