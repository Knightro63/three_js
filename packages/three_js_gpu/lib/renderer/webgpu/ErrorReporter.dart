import 'dart:core';

/// Error handling and logging for WebGPU renderer.
/// T040: Clear, actionable error messages for debugging.
class ErrorReporter {
  // Enforce non-instantiability to match Kotlin's object semantic
  ErrorReporter._();

  static final List<ErrorRecord> _errorLog = [];
  static int _errorCount = 0;
  static int _warningCount = 0;

  // ==========================================
  // PART 1: SHADER, BUFFER, TEXTURE, PIPELINE
  // ==========================================

  /// Reports a shader compilation error.
  static void reportShaderError({
    required String shaderType, 
    required String errors, 
    required String source,
  }) {
    _errorCount++;
    
    final buffer = StringBuffer()
      ..writeln("Shader Compilation Error ($shaderType):")
      ..writeln(errors)
      ..writeln()
      ..writeln("Suggestions:")
      ..writeln("- Check WGSL syntax and built-in functions")
      ..writeln("- Verify attribute locations match vertex buffer layout")
      ..writeln("- Ensure uniform buffer bindings are correct");

    final message = buffer.toString();
    final record = ErrorRecord(
      category: ErrorCategory.shader,
      severity: ErrorSeverity.error,
      message: message,
      context: {
        "shaderType": shaderType,
        "errors": errors,
        "sourceLength": source.length.toString(),
      },
    );

    _errorLog.add(record);
    print("ERROR: $message");
  }

  /// Reports a buffer allocation or upload error.
  static void reportBufferError({
    required String operation, 
    required int bufferSize, 
    required String error,
  }) {
    _errorCount++;
    
    final buffer = StringBuffer()
      ..writeln("Buffer Error ($operation):")
      ..writeln("Failed to $operation buffer of size $bufferSize bytes")
      ..writeln("Error: $error")
      ..writeln()
      ..writeln("Suggestions:")
      ..writeln("- Check available GPU memory")
      ..writeln("- Verify buffer size doesn't exceed maxBufferSize limit")
      ..writeln("- Ensure buffer usage flags are compatible");

    final message = buffer.toString();
    final record = ErrorRecord(
      category: ErrorCategory.buffer,
      severity: ErrorSeverity.error,
      message: message,
      context: {
        "operation": operation,
        "bufferSize": bufferSize.toString(),
        "error": error,
      },
    );

    _errorLog.add(record);
    print("ERROR: $message");
  }

  /// Reports a texture creation or upload error.
  static void reportTextureError({
    required String operation,
    required int width,
    required int height,
    required String format,
    required String error,
  }) {
    _errorCount++;
    
    final buffer = StringBuffer()
      ..writeln("Texture Error ($operation):")
      ..writeln("Failed to $operation texture ${width}x$height ($format)")
      ..writeln("Error: $error")
      ..writeln()
      ..writeln("Suggestions:")
      ..writeln("- Check texture dimensions don't exceed maxTextureDimension2D")
      ..writeln("- Verify format is supported by the device")
      ..writeln("- Ensure sufficient GPU memory is available");

    final message = buffer.toString();
    final record = ErrorRecord(
      category: ErrorCategory.texture,
      severity: ErrorSeverity.error,
      message: message,
      context: {
        "operation": operation,
        "width": width.toString(),
        "height": height.toString(),
        "format": format,
        "error": error,
      },
    );

    _errorLog.add(record);
    print("ERROR: $message");
  }

  /// Reports a pipeline creation error.
  static void reportPipelineError({required String error, required String descriptor}) {
    _errorCount++;
    
    final buffer = StringBuffer()
      ..writeln("Pipeline Creation Error:")
      ..writeln("Error: $error")
      ..writeln()
      ..writeln("Pipeline descriptor:")
      ..writeln(descriptor)
      ..writeln()
      ..writeln("Suggestions:")
      ..writeln("- Verify shader modules compiled successfully")
      ..writeln("- Check vertex buffer layout matches shader attributes")
      ..writeln("- Ensure depth/stencil format is compatible");

    final message = buffer.toString();
    final record = ErrorRecord(
      category: ErrorCategory.pipeline,
      severity: ErrorSeverity.error,
      message: message,
      context: {
        "error": error,
        "descriptor": descriptor,
      },
    );

    _errorLog.add(record);
    print("ERROR: $message");
  }

  // ==========================================
  // PART 2: RENDERING, CONTEXT, LOG METRICS
  // ==========================================

  /// Reports a rendering error.
  static void reportRenderingError({required String stage, required String error}) {
    _errorCount++;
    
    final buffer = StringBuffer()
      ..writeln("Rendering Error ($stage):")
      ..writeln("Error: $error")
      ..writeln()
      ..writeln("Suggestions:")
      ..writeln("- Check that renderer is initialized")
      ..writeln("- Verify all resources are created successfully")
      ..writeln("- Ensure scene and camera are valid");

    final message = buffer.toString();
    final record = ErrorRecord(
      category: ErrorCategory.rendering,
      severity: ErrorSeverity.error,
      message: message,
      context: {
        "stage": stage,
        "error": error,
      },
    );

    _errorLog.add(record);
    print("ERROR: $message");
  }

  /// Reports a context loss event.
  static void reportContextLoss({required String reason, required bool canRecover}) {
    _warningCount++;
    
    final buffer = StringBuffer()
      ..writeln("GPU Context Lost:")
      ..writeln("Reason: $reason")
      ..writeln("Can recover: $canRecover")
      ..writeln();
      
    if (canRecover) {
      buffer.writeln("Attempting automatic recovery...");
    } else {
      buffer.writeln("Manual page reload required");
    }

    final message = buffer.toString();
    final record = ErrorRecord(
      category: ErrorCategory.context,
      severity: canRecover ? ErrorSeverity.warning : ErrorSeverity.error,
      message: message,
      context: {
        "reason": reason,
        "canRecover": canRecover.toString(),
      },
    );

    _errorLog.add(record);
    if (canRecover) {
      print("WARNING: $message");
    } else {
      print("ERROR: $message");
    }
  }

  /// Reports a warning (non-fatal issue).
  static void reportWarning({required ErrorCategory category, required String message}) {
    _warningCount++;
    
    final record = ErrorRecord(
      category: category,
      severity: ErrorSeverity.warning,
      message: message,
      context: const {},
    );

    _errorLog.add(record);
    print("WARNING: [${category.name}] $message");
  }

  /// Gets error statistics.
  static ErrorStats getStats() {
    final Map<ErrorCategory, int> errorsByCategory = {};
    
    for (final record in _errorLog) {
      errorsByCategory[record.category] = (errorsByCategory[record.category] ?? 0) + 1;
    }

    return ErrorStats(
      errorCount: _errorCount,
      warningCount: _warningCount,
      totalIssues: _errorCount + _warningCount,
      errorsByCategory: errorsByCategory,
    );
  }

  /// Gets recent error records.
  static List<ErrorRecord> getRecentErrors({int limit = 10}) {
    if (_errorLog.isEmpty) return [];
    
    final start = _errorLog.length - limit;
    final actualStart = start < 0 ? 0 : start;
    return _errorLog.sublist(actualStart);
  }

  /// Clears error log.
  static void clear() {
    _errorLog.clear();
    _errorCount = 0;
    _warningCount = 0;
  }
}

// ==========================================
// SUPPORTING DATA STRUCTURES
// ==========================================

/// Error category for classification.
enum ErrorCategory { shader, buffer, texture, pipeline, rendering, context, other }

/// Error severity level.
enum ErrorSeverity { error, warning, info }

/// Error record container class for logging.
class ErrorRecord {
  final ErrorCategory category;
  final ErrorSeverity severity;
  final String message;
  final Map<String, String> context;
  final int timestamp; // Unix milliseconds timestamp

  ErrorRecord({
    required this.category,
    required this.severity,
    required this.message,
    required this.context,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;
}

/// Error statistics layout.
class ErrorStats {
  final int errorCount;
  final int warningCount;
  final int totalIssues;
  final Map<ErrorCategory, int> errorsByCategory;

  const ErrorStats({
    required this.errorCount,
    required this.warningCount,
    required this.totalIssues,
    required this.errorsByCategory,
  });
}
