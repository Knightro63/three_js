const String batchingVertex = /* glsl */'''
#ifdef USE_BATCHING
	mat4 batchingMatrix = getBatchingMatrix( batchId );
#endif
''';
