import "./constants.dart";

int getFloatLength(int? floatLength ) {
  if(floatLength == null) return 0;
	return floatLength + ( ( gpuChunkBytes - ( floatLength % gpuChunkBytes ) ) % gpuChunkBytes );
}

int getVectorLength(int count, [int vectorLength = 4 ]) {
	final strideLength = getStrideLength( vectorLength );
	final floatLength = strideLength * count;
	return getFloatLength( floatLength );
}

int getStrideLength(int vectorLength ) {
	final strideLength = 4;
	return vectorLength + ( ( strideLength - ( vectorLength % strideLength ) ) % strideLength );
}