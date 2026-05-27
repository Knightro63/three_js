import './gpu_constants.dart'; // Holds the GPU_CHUNK_BYTES definition

/// This function is usually called with the length in bytes of an array buffer.
/// It returns a padded value which ensures chunk size alignment according to STD140 layout.
/// 
/// [floatLength] - The buffer length in bytes.
/// Returns the padded length.
int getFloatLength(int floatLength) {
  // Ensure chunk size alignment according to WebGPU/STD140 specs
  return floatLength + ((gpuChunkBytes - (floatLength % gpuChunkBytes)) % gpuChunkBytes);
}

/// Given the count of vectors and their vector length, this function computes
/// a total length in bytes with buffer alignment according to STD140 layout.
/// 
/// [count] - The number of vectors.
/// [vectorLength] - The length of individual vectors.
/// Returns the padded length.
int getVectorLength(int count, [int vectorLength = 4]) {
  final int strideLength = getStrideLength(vectorLength);
  final int floatLength = strideLength * count;
  return getFloatLength(floatLength);
}

/// This function is called with a vector length and ensures the computed length
/// matches a predefined structural stride boundary (in this case `4`).
/// 
/// [vectorLength] - The vector length.
/// Returns the padded length.
int getStrideLength(int vectorLength) {
  const int strideLength = 4;
  return vectorLength + ((strideLength - (vectorLength % strideLength)) % strideLength);
}
