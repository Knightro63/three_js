import 'dart:convert';
import 'dart:typed_data';
import 'package:gpux/gpux.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

import '../../nodes/core/constants.dart';
import '../../nodes/core/node_utils.dart';
import '../common/nodes/node_sampled_texture.dart';
import '../common/sampled_texture.dart';
import '../common/storage_buffer.dart';
import '../common/uniform_buffer.dart';
import '../descriptors/gpu_bind_group_descriptor.dart';
import '../descriptors/gpu_buffer_descriptor.dart';
import '../descriptors/gpu_texture_view_descriptor.dart';

// Shared file descriptors initialized from your recently converted files
final GPUBindGroupDescriptor _bindGroupDescriptor = GPUBindGroupDescriptor();
final GPUBufferDescriptor _bufferDescriptor = GPUBufferDescriptor();
final GPUTextureViewDescriptor _viewDescriptor = GPUTextureViewDescriptor();

/// Class representing a WebGPU bind group layout template track.
class BindGroupLayout {
  /// The current native hardware GPUBindGroupLayout reference layer.
  dynamic layoutGPU;

  /// The number of bind groups that use this layout context.
  int usedTimes = 0;

  /// Constructs a new layout cache node tracker.
  BindGroupLayout(this.layoutGPU);
}

/// A WebGPU backend utility module for managing bindings pipelines.
class WebGPUBindingUtils {
  /// A reference to the WebGPU backend instance context.
  final dynamic backend;

  /// A cache that maps unique hash combinations of layout entries to existing layouts.
  final Map<int, BindGroupLayout> _bindGroupLayoutCache = {};

  /// Constructs a new utility object context.
  WebGPUBindingUtils(this.backend);


  /// Creates a GPU bind group layout for the given bind group.
  /// 
  /// [bindGroup] - The bind group definition mapping.
  /// Returns the native hardware GPUBindGroupLayout context.
  dynamic createBindingsLayout(dynamic bindGroup) {
    final dynamic backend = this.backend;
    final dynamic device = backend.device;
    
    // Enforcing map directive bracket syntax rules instead of backend.get()
    final dynamic bindingsData = backend[bindGroup]; 

    // Check if the the bind group already has an assigned hardware layout structure
    if (bindingsData?['layout'] != null) {
      return bindingsData['layout'].layoutGPU;
    }

    // Allocate structural metadata descriptors for the active bind slots
    final List<Map<String, dynamic>> entries = this._createLayoutEntries(bindGroup);
    
    // Serialization string hash generator replacing javascript's JSON.stringify(entries)
    final String layoutStringSignature = jsonEncode(entries);
    final int bindGroupLayoutKey = NodeUtils.hashString(layoutStringSignature);

    // Try to locate an existing, identical layout inside the internal reuse cache
    BindGroupLayout? bindGroupLayout = this._bindGroupLayoutCache[bindGroupLayoutKey];

    // If an existing layout match is not present, compile a new one natively
    if (bindGroupLayout == null) {
      bindGroupLayout = BindGroupLayout(
        device.createBindGroupLayout({
          'entries': entries
        })
      );
      this._bindGroupLayoutCache[bindGroupLayoutKey] = bindGroupLayout;
    }

    bindGroupLayout.usedTimes++;
    bindingsData['layout'] = bindGroupLayout;
    bindingsData['layoutKey'] = bindGroupLayoutKey;

    return bindGroupLayout.layoutGPU;
  }

  /// Creates bindings from the given bind group definition.
  /// 
  /// [bindGroup] - The target bind group definition map.
  /// [bindings] - Array list of active bind groups.
  /// [cacheIndex] - The active cache tracking identifier.
  /// [version] - The layout evaluation version signature layer.
  void createBindings(dynamic bindGroup, List<dynamic> bindings, int cacheIndex, [int version = 0]) {
    final dynamic backend = this.backend;
    final dynamic bindingsData = backend[bindGroup];

    // Ensure our (static) binding layout is compiled or safely pulled from cache entries
    final dynamic bindLayoutGPU = this.createBindingsLayout(bindGroup);
    dynamic bindGroupGPU;

    if (cacheIndex > 0) {
      if (bindingsData['groups'] == null) {
        bindingsData['groups'] = <dynamic>[];
        bindingsData['versions'] = <int>[];
      }

      final List<int> versionsList = bindingsData['versions'];
      if (cacheIndex < versionsList.length && versionsList[cacheIndex] == version) {
        final List<dynamic> groupsList = bindingsData['groups'];
        if (cacheIndex < groupsList.length) {
          bindGroupGPU = groupsList[cacheIndex];
        }
      }
    }

    // Construct the (dynamic) hardware binding execution block context if absent
    if (bindGroupGPU == null) {
      bindGroupGPU = this.createBindGroup(bindGroup, bindLayoutGPU);
      
      if (cacheIndex > 0) {
        // Grow structural lists manually if the targeting cache index exceeds current bounds
        final List<dynamic> groupsList = bindingsData['groups'];
        final List<int> versionsList = bindingsData['versions'];

        while (groupsList.length <= cacheIndex) {
          groupsList.add(null);
        }
        while (versionsList.length <= cacheIndex) {
          versionsList.add(-1);
        }

        groupsList[cacheIndex] = bindGroupGPU;
        versionsList[cacheIndex] = version;
      }
    }

    bindingsData['group'] = bindGroupGPU;
  }

  /// Updates a buffer binding.
  /// 
  /// [binding] - The buffer binding to update.
  void updateBinding(dynamic binding) {
    final dynamic backend = this.backend;
    final dynamic device = backend.device;
    final dynamic array = binding.buffer; // CPU memory payload list
    
    // Enforcing your map directive bracket syntax rules instead of backend.get()
    final dynamic bufferData = backend[binding];
    final dynamic buffer = bufferData?['buffer']; // GPU target hardware buffer

    final List<dynamic> updateRanges = binding.updateRanges ?? [];

    if (updateRanges.isEmpty) {
      // Overwrite the entire destination memory allocation
      device.queue.writeBuffer(buffer, 0, array, 0, array.length);
    } else {
      // Dart standard lists (Float32List, Uint32List, etc.) always match true arrays,
      // making our index element offset factor 1, while pure byte parameters query bytes directly.
      const int elementOffsetFactor = 1;
      final int bytesPerElement = array.elementSizeInBytes;

      for (int i = 0, l = updateRanges.length; i < l; i++) {
        final dynamic range = updateRanges[i];
        final int dataOffset = range.start * elementOffsetFactor;
        final int size = range.count * elementOffsetFactor;
        
        // bufferOffset is always passed explicitly in bytes to the hardware queue
        final int bufferOffset = dataOffset * bytesPerElement;

        device.queue.writeBuffer(buffer, bufferOffset, array, dataOffset, size);
      }
    }
  }

  /// Creates a GPU bind group for the camera index (used in multi-camera layers rendering).
  /// 
  /// [data] - The integer index data buffer list.
  /// [layoutGPU] - The GPU bind group layout context.
  /// Returns the completed native hardware GPUBindGroup instance.
  dynamic createBindGroupIndex(Uint32List data, dynamic layoutGPU) {
    final dynamic backend = this.backend;
    final dynamic device = backend.device;
    
    // WebGPU pipeline configuration parameters bitmask using standard lowercase enums
    final int usage = GpuBufferUsage.uniform | GpuBufferUsage.copyDst;
    final int index = data[0];

    _bufferDescriptor.label = 'bindingCameraIndex_$index';
    _bufferDescriptor.size = 16; // uint(4) * 4 alignment layout size
    _bufferDescriptor.usage = usage;
    
    final dynamic buffer = device.createBuffer(_bufferDescriptor);
    _bufferDescriptor.reset();

    // Write the primitive array values into hardware uniform blocks
    device.queue.writeBuffer(buffer, 0, data, 0, data.length);

    _bindGroupDescriptor.label = 'bindGroupCameraIndex_$index';
    _bindGroupDescriptor.layout = layoutGPU;
    _bindGroupDescriptor.entries.add({
      'binding': 0,
      'resource': {
        'buffer': buffer
      }
    });

    final dynamic bindGroup = device.createBindGroup(_bindGroupDescriptor);
    _bindGroupDescriptor.reset();

    return bindGroup;
  }

  /// Creates a GPU bind group for the given bind group and GPU layout.
  /// 
  /// [bindGroup] - The bind group definition blueprint.
  /// [layoutGPU] - The native hardware GPU bind group layout context.
  /// Returns the completed native hardware GPUBindGroup instance.
  dynamic createBindGroup(dynamic bindGroup, dynamic layoutGPU) {
    final dynamic backend = this.backend;
    final dynamic device = backend.device;
    int bindingPoint = 0;

    _bindGroupDescriptor.label = 'bindGroup_${bindGroup.name}';
    _bindGroupDescriptor.layout = layoutGPU;

    final List<dynamic> bindingsList = bindGroup.bindings ?? [];

    for (final dynamic binding in bindingsList) {
      if (binding.isUniformBuffer == true) {
        // Enforcing map directive bracket syntax rules instead of backend.get()
        final dynamic bindingData = backend[binding];
        _bindGroupDescriptor.entries.add({
          'binding': bindingPoint,
          'resource': {
            'buffer': bindingData?['buffer']
          }
        });
      } 
      else if (binding.isStorageBuffer == true) {
        final dynamic attributeData = backend[binding.attribute];
        final dynamic buffer = attributeData?['buffer'];
        _bindGroupDescriptor.entries.add({
          'binding': bindingPoint,
          'resource': {
            'buffer': buffer
          }
        });
      } 
      else if (binding.isSampledTexture == true) {
        final dynamic textureData = backend[binding.texture];
        dynamic resourceGPU;

        if (textureData?['externalTexture'] != null) {
          resourceGPU = device.importExternalTexture({
            'source': textureData['externalTexture']
          });
        } 
        else {
          final int mipLevelCount = (binding.store == true) ? 1 : textureData['texture'].mipLevelCount;
          final int baseMipLevel = (binding.store == true) ? (binding.mipLevel ?? 0) : 0;
          
          // Assemble a unique runtime texture dimensions property hash string key
          String propertyName = 'view-${textureData['texture'].width}-${textureData['texture'].height}';
          
          if (textureData['texture'].depthOrArrayLayers > 1) {
            propertyName += '-${textureData['texture'].depthOrArrayLayers}';
          }
          propertyName += '-$mipLevelCount-$baseMipLevel';

          // Extract cached view context using map direct brackets notation
          resourceGPU = textureData?[propertyName];

          if (resourceGPU == null) {
            const GpuTextureAspect aspectGPU = GpuTextureAspect.all;
            GpuTextureViewDimension dimensionViewGPU;

            if (binding.isSampledCubeTexture == true) {
              dimensionViewGPU = GpuTextureViewDimension.cube;
            } 
            else if (binding.texture.isArrayTexture == true || 
                     binding.texture.isDataArrayTexture == true || 
                     binding.texture.isCompressedArrayTexture == true) {
              dimensionViewGPU = GpuTextureViewDimension.d2;
            } 
            else if (binding.isSampledTexture3D == true) {
              dimensionViewGPU = GpuTextureViewDimension.d3;
            } 
            else {
              dimensionViewGPU = GpuTextureViewDimension.d2;
            }

            _viewDescriptor.aspect = aspectGPU;
            _viewDescriptor.dimension = dimensionViewGPU;
            _viewDescriptor.mipLevelCount = mipLevelCount;
            _viewDescriptor.baseMipLevel = baseMipLevel;

            // Cache and create view references dynamically using map assignments
            resourceGPU = textureData?[propertyName] = textureData['texture'].createView(_viewDescriptor);
            _viewDescriptor.reset();
          }
        }

        _bindGroupDescriptor.entries.add({
          'binding': bindingPoint,
          'resource': resourceGPU
        });
      } 
      else if (binding.isSampler == true) {
        final dynamic textureGPU = backend[binding.texture];
        _bindGroupDescriptor.entries.add({
          'binding': bindingPoint,
          'resource': textureGPU?['sampler']
        });
      }

      bindingPoint++;
    }

    final dynamic bindGroupGPU = device.createBindGroup(_bindGroupDescriptor);
    _bindGroupDescriptor.reset();

    return bindGroupGPU;
  }

  /// Creates GPU bind group layout entries for the given bind group.
  List<Map<String, dynamic>> _createLayoutEntries(dynamic bindGroup) {
    final List<Map<String, dynamic>> entries = [];
    int index = 0;
    
    final List<dynamic> bindingsList = bindGroup.bindings ?? [];

    for (final dynamic binding in bindingsList) {
      final dynamic backend = this.backend;
      
      final Map<String, dynamic> bindingGPU = {
        'binding': index,
        'visibility': binding.visibility
      };

      if (binding is UniformBuffer == true || binding is StorageBuffer == true) {
        final Map<String, dynamic> buffer = {}; // GPUBufferBindingLayout shape
        
        if (binding is StorageBuffer == true) {
          final int visibility = binding.visibility ?? 0;
          
          // Handle loose bitwise validation logic safely inside standard integer conditions
          if ((visibility & GpuShaderStage.compute) != 0) {
            final dynamic access = binding.access;
            if (access == NodeAccess.readWrite || access == NodeAccess.writeOnly) {
              buffer['type'] = GpuBufferBindingType.storage;
            } else {
              buffer['type'] = GpuBufferBindingType.readOnlyStorage;
            }
          } else {
            buffer['type'] = GpuBufferBindingType.readOnlyStorage;
          }
        }
        
        bindingGPU['buffer'] = buffer;
      } 
      else if (binding is SampledTexture == true && binding.store == true) {
        final Map<String, dynamic> storageTexture = {}; // GPUStorageTextureBindingLayout shape
        
        // Enforcing map directive bracket syntax rules instead of backend.get()
        storageTexture['format'] = this.backend[binding.texture]['texture'].format;
        
        final dynamic access = binding.access;
        if (access == NodeAccess.readWrite) {
          storageTexture['access'] = GpuStorageTextureAccess.readWrite;
        } else if (access == NodeAccess.writeOnly) {
          storageTexture['access'] = GpuStorageTextureAccess.writeOnly;
        } else {
          storageTexture['access'] = GpuStorageTextureAccess.readOnly;
        }

        if (binding.texture.isArrayTexture == true) {
          storageTexture['viewDimension'] = GpuTextureViewDimension.d2Array;
        } else if (binding.texture.is3DTexture == true) {
          storageTexture['viewDimension'] = GpuTextureViewDimension.d3;
        }
        
        bindingGPU['storageTexture'] = storageTexture;
      } 
      else if (binding is SampledTexture == true) {
        final Map<String, dynamic> texture = {}; // GPUTextureBindingLayout shape
        final Map<String, dynamic> sampleData = backend.utils.getTextureSampleData(binding.texture);
        final int primarySamples = sampleData['primarySamples'] ?? 1;

        if (primarySamples > 1) {
          texture['multisampled'] = true;
          if (binding.texture.isDepthTexture != true) {
            texture['sampleType'] = GpuTextureSampleType.unfilterableFloat;
          }
        }

        if (binding.texture is DepthTexture == true) {
          if (backend.compatibilityMode == true && binding.texture.compareFunction == null) {
            texture['sampleType'] = GpuTextureSampleType.unfilterableFloat;
          } else {
            texture['sampleType'] = GpuTextureSampleType.depth;
          }
        } else {
          final dynamic type = binding.texture.type;
          if (type == IntType) {
            texture['sampleType'] = GpuTextureSampleType.sint;
          } else if (type == UnsignedIntType) {
            texture['sampleType'] = GpuTextureSampleType.uint;
          } else if (type == FloatType) {
            if (this.backend.hasFeature('float32-filterable') == true) {
              texture['sampleType'] = GpuTextureSampleType.float;
            } else {
              texture['sampleType'] = GpuTextureSampleType.unfilterableFloat;
            }
          }
        }

        if (binding is SampledCubeTexture == true) {
          texture['viewDimension'] = GpuTextureViewDimension.cube;
        } else if (binding.texture.isArrayTexture == true || 
                 binding.texture is DataArrayTexture == true || 
                 binding.texture is CompressedArrayTexture == true) {
          texture['viewDimension'] = GpuTextureViewDimension.d2Array;
        } else if (binding is NodeSampledTexture3D == true) {
          texture['viewDimension'] = GpuTextureViewDimension.d3;
        }
        
        bindingGPU['texture'] = texture;
      } 
      else if (binding.isSampler == true) {
        final Map<String, dynamic> sampler = {}; // GPUSamplerBindingLayout shape
        
        if (binding.texture is DepthTexture) {
          if (binding.texture.compareFunction != null && 
              binding.textureNode?.compareNode != null && 
              backend.hasCompatibility('textureCompare') == true) {
            sampler['type'] = GpuSamplerBindingType.comparison;
          } else {
            // Depth textures without explicit compare requirements must fall back to a non-filtering sampler
            sampler['type'] = GpuSamplerBindingType.nonFiltering;
          }
        }
        
        bindingGPU['sampler'] = sampler;
      } else {
        console.error('WebGPUBindingUtils: Unsupported binding "$binding".');
      }

      entries.add(bindingGPU);
      index++;
    }

    return entries;
  }

  /// Delete the data associated with a bind group.
  /// 
  /// [bindGroup] - The bind group configuration map to dismantle.
  void deleteBindGroupData(dynamic bindGroup) {
    final dynamic backend = this.backend;
    
    // Enforcing your map directive bracket syntax rules instead of backend.get()
    final dynamic bindingsData = backend[bindGroup];

    if (bindingsData != null && bindingsData['layout'] != null) {
      final dynamic layout = bindingsData['layout'];
      layout.usedTimes--;

      if (layout.usedTimes == 0) {
        final String? layoutKey = bindingsData['layoutKey'];
        if (layoutKey != null) {
          this._bindGroupLayoutCache.remove(layoutKey); // Replaces JavaScript map delete()
        }
      }

      bindingsData['layout'] = null;
      bindingsData['layoutKey'] = null;
    }
  }

  /// Frees all internal resources and cached layouts.
  void dispose() {
    this._bindGroupLayoutCache.clear();
  }
}