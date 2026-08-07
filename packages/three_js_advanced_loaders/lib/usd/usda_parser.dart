import 'dart:convert'; // Required at the top of your file for jsonDecode

final RegExp defMatchRegex = RegExp(r'^def\s+(?:(\w+)\s+)?"?([^"]+)"?$');
final RegExp variantStringRegex = RegExp(r'^string\s+(\w+)$');
final RegExp attrMatchRegex = RegExp(r'^(?:uniform\s+)?(\w+(?:\[\])?)\s+(.+)$');

enum SpecType {
  attribute(1),
  prim(6),
  relationship(8);

  final int value;
  const SpecType(this.value);
}

class USDAParser {

  Map<String, dynamic> parseText(String text) {
    // Preprocess: strip comments and normalize multiline values
    text = _preprocess(text);

    final Map<String, dynamic> root = {};
    final List<String> lines = text.split('\n');

    String? stringVar; // Renamed 'string' to 'stringVar' as 'string' is a keyword concept
    Map<String, dynamic> target = root;
    final List<Map<String, dynamic>> stack = [root];

    final RegExp numCheck = RegExp(r'^[\d.]+$');

    for (final line in lines) {
      if (line.contains('=')) {
        // Find the first '=' that's not inside quotes
        final int eqIdx = _findAssignmentOperator(line);
        if (eqIdx == -1) {
          stringVar = line.trim();
          continue;
        }

        final String lhs = line.substring(0, eqIdx).trim();
        final String rhs = line.substring(eqIdx + 1).trim();

        if (rhs.endsWith('{')) {
          final Map<String, dynamic> group = {};
          stack.add(group);
          target[lhs] = group;
          target = group;
        } else if (rhs.endsWith('(')) {
          // see #28631
          final String values = rhs.substring(0, rhs.length - 1);
          target[lhs] = values;
          
          final Map<String, dynamic> meta = {};
          stack.add(meta);
          target = meta;
        } else {
          target[lhs] = rhs;
        }
      } else if (line.contains(':') && !line.contains('=')) {
        // Handle dictionary entries like "0: [(...)...]" for timeSamples
        final int colonIdx = line.indexOf(':');
        final String key = line.substring(0, colonIdx).trim();
        final String value = line.substring(colonIdx + 1).trim();

        // Only process if key looks like a number (timeSamples frame)
        if (numCheck.hasMatch(key)) {
          target[key] = value;
        }
      } else if (line.endsWith('{')) {
        final String currentTrimmed = line.substring(0, line.length - 1).trim();
        stringVar = currentTrimmed.isNotEmpty ? currentTrimmed : stringVar;
        
        if (stringVar != null) {
          final Map<String, dynamic> group = target[stringVar] is Map<String, dynamic> 
              ? target[stringVar] as Map<String, dynamic> 
              : {};
          stack.add(group);
          target[stringVar] = group;
          target = group;
        }
      } else if (line.endsWith('}')) {
        stack.removeLast();
        if (stack.isEmpty) continue;
        target = stack.last;
      } else if (line.endsWith('(')) {
        final Map<String, dynamic> meta = {};
        stack.add(meta);
        
        final String currentSplit = line.split('(')[0].trim();
        stringVar = currentSplit.isNotEmpty ? currentSplit : stringVar;
        
        if (stringVar != null) {
          target[stringVar] = meta;
        }
        target = meta;
      } else if (line.endsWith(')')) {
        stack.removeLast();
        target = stack.last;
      } else if (line.trim().isNotEmpty) {
        stringVar = line.trim();
      }
    }

    return root;
  }

  String _preprocess(String text) {
    // Remove block comments /* ... */
    text = _stripBlockComments(text);

    // Collapse triple-quoted strings into single lines
    text = _collapseTripleQuotedStrings(text);

    // Remove line comments # ... (but preserve #usda header)
    // Only remove # comments that aren't at the start of a line or after whitespace
    final List<String> lines = text.split('\n');
    final List<String> processed = [];

    bool inMultilineValue = false;
    int bracketDepth = 0;
    int parenDepth = 0;
    String accumulated = '';

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Strip inline comments (but not inside strings)
      line = _stripInlineComment(line);

      final String trimmed = line.trim();

      if (inMultilineValue) {
        // Continue accumulating multiline value
        accumulated += ' $trimmed';

        // Update depths
        // Split into characters to iterate safely
        for (final String ch in trimmed.split('')) {
          if (ch == '[') {
            bracketDepth++;
          } else if (ch == ']') {
            bracketDepth--;
          } else if (ch == '(' && bracketDepth > 0) {
            parenDepth++;
          } else if (ch == ')' && bracketDepth > 0) {
            parenDepth--;
          }
        }

        // Check if multiline value is complete
        if (bracketDepth == 0 && parenDepth == 0) {
          processed.add(accumulated);
          accumulated = '';
          inMultilineValue = false;
        }
      } else {
        // Check if this line starts a multiline array value
        // Look for patterns like "attr = [" or "attr = @path@[" without closing ]
        if (trimmed.contains('=')) {
          final int eqIdx = _findAssignmentOperator(trimmed);
          if (eqIdx != -1) {
            final String rhs = trimmed.substring(eqIdx + 1).trim();

            // Count brackets in the value part
            int openBrackets = 0;
            int closeBrackets = 0;
            for (final String ch in rhs.split('')) {
              if (ch == '[') {
                openBrackets++;
              } else if (ch == ']') {
                closeBrackets++;
              }
            }

            if (openBrackets > closeBrackets) {
              // Multiline array detected
              inMultilineValue = true;
              bracketDepth = openBrackets - closeBrackets;
              parenDepth = 0;
              accumulated = trimmed;
              continue;
            }
          }
        }

        processed.add(trimmed);
      }
    }

    return processed.join('\n');
  }

  String _stripBlockComments(String text) {
    // Iteratively remove /* ... */ comments without regex backtracking
    final StringBuffer result = StringBuffer();
    int i = 0;

    while (i < text.length) {
      // Check for block comment start
      if (i + 1 < text.length && text.substring(i, i + 1) == '/' && text.substring(i + 1, i + 2) == '*') {
        // Find the closing */
        int j = i + 2;
        while (j < text.length) {
          if (j + 1 < text.length && text.substring(j, j + 1) == '*' && text.substring(j + 1, j + 2) == '/') {
            // Found closing, skip past it
            j += 2;
            break;
          }
          j++;
        }
        // Move past the comment (or to end if unclosed)
        i = j;
      } else {
        result.write(text.substring(i, i + 1));
        i++;
      }
    }

    return result.toString();
  }

  String _collapseTripleQuotedStrings(String text) {
    final StringBuffer result = StringBuffer();
    int i = 0;

    while (i < text.length) {
      if (i + 2 < text.length) {
        final String triple = text.substring(i, i + 3);
        if (triple == "'''" || triple == '"""') {
          final String quoteChar = triple;
          result.write(quoteChar);
          i += 3;

          while (i < text.length) {
            if (i + 2 < text.length && text.substring(i, i + 3) == quoteChar) {
              result.write(quoteChar);
              i += 3;
              break;
            } else {
              final String char = text.substring(i, i + 1);
              if (char == '\n') {
                result.write(r'\n'); // Using raw string literal to match the JS escape behavior
              } else if (char != '\r') {
                result.write(char);
              }
              i++;
            }
          }
          continue;
        }
      }
      result.write(text.substring(i, i + 1));
      i++;
    }

    return result.toString();
  }

  String _stripInlineComment(String line) {
    // Don't strip if line starts with #usda
    if (line.trim().startsWith('#usda')) return line;

    // Find # that's not inside a string
    bool inString = false;
    String? stringChar;
    bool escaped = false;

    for (int i = 0; i < line.length; i++) {
      final String ch = line.substring(i, i + 1);

      if (escaped) {
        escaped = false;
        continue;
      }

      if (ch == '\\') {
        escaped = true;
        continue;
      }

      if (!inString && (ch == '"' || ch == "'")) {
        inString = true;
        stringChar = ch;
      } else if (inString && ch == stringChar) {
        inString = false;
        stringChar = null;
      } else if (!inString && ch == '#') {
        // Found comment start outside of string
        return line.substring(0, i).trimRight();
      }
    }

    return line;
  }

  int _findAssignmentOperator(String line) {
    // Find the first '=' that's not inside quotes
    bool inString = false;
    String? stringChar;
    bool escaped = false;

    for (int i = 0; i < line.length; i++) {
      final String ch = line.substring(i, i + 1);

      if (escaped) {
        escaped = false;
        continue;
      }

      if (ch == '\\') {
        escaped = true;
        continue;
      }

      if (!inString && (ch == '"' || ch == "'")) {
        inString = true;
        stringChar = ch;
      } else if (inString && ch == stringChar) {
        inString = false;
        stringChar = null;
      } else if (!inString && ch == '=') {
        return i;
      }
    }

    return -1;
  }

  /// Parse USDA text and return raw spec data in specsByPath format.
  /// Used by USDComposer for unified scene composition.
  Map<String, dynamic> parseData(String text) {
    final Map<String, dynamic> root = parseText(text);
    final Map<String, Map<String, dynamic>> specsByPath = {};

    // Parse root metadata
    final Map<String, dynamic> rootFields = {};
    if (root.containsKey('#usda 1.0')) {
      final dynamic header = root['#usda 1.0'];
      
      // Safety check to ensure header is a map before accessing keys
      if (header is Map<String, dynamic>) {
        if (header.containsKey('upAxis')) {
          rootFields['upAxis'] = header['upAxis'].toString().replaceAll('"', '');
        }
        if (header.containsKey('defaultPrim')) {
          rootFields['defaultPrim'] = header['defaultPrim'].toString().replaceAll('"', '');
        }
        if (header.containsKey('metersPerUnit')) {
          rootFields['metersPerUnit'] = double.tryParse(header['metersPerUnit'].toString()) ?? 0.0;
        }
        if (header.containsKey('framesPerSecond')) {
          rootFields['framesPerSecond'] = double.tryParse(header['framesPerSecond'].toString()) ?? 0.0;
        }
        if (header.containsKey('timeCodesPerSecond')) {
          rootFields['timeCodesPerSecond'] = double.tryParse(header['timeCodesPerSecond'].toString()) ?? 0.0;
        }
      }
    }

    specsByPath['/'] = {
      'specType': SpecType.prim.index,
      'fields': rootFields,
    };

    // Walk the tree and build specsByPath
    void walkTree(Map<String, dynamic> data, String parentPath) {
      final List<String> primChildren = [];
      
      for (final String key in data.keys) {
        // Skip metadata
        if (key == '#usda 1.0') continue;
        if (key == 'variants') continue;

        // Check for primitive definitions
        // Matches both 'def TypeName "name"' and 'def "name"' (no type)
        final RegExpMatch? defMatch = defMatchRegex.firstMatch(key);
        if (defMatch != null) {
          final String typeName = defMatch.group(1) ?? '';
          final String name = defMatch.group(2) ?? '';
          final String path = parentPath == '/' ? '/$name' : '$parentPath/$name';
          
          primChildren.add(name);
          
          final Map<String, dynamic> primFields = {'typeName': typeName};
          final dynamic primData = data[key];

          if (primData is Map<String, dynamic>) {
            // Extract attributes and relationships from this prim
            _extractPrimData(primData, path, primFields, specsByPath);
            
            specsByPath[path] = {
              'specType': SpecType.prim.index,
              'fields': primFields,
            };

            // Recurse into children
            walkTree(primData, path);
          }
        }
      }

      // Add primChildren to parent spec
      if (primChildren.isNotEmpty && specsByPath.containsKey(parentPath)) {
        specsByPath[parentPath]?['fields']?['primChildren'] = primChildren;
      }
    }

    walkTree(root, '/');

    // Fallback: infer elementSize for primvars:skel:jointIndices/jointWeights
    // when not explicitly declared in the USDA text
    _inferSkelElementSize(specsByPath);

    return {'specsByPath': specsByPath};
  }

  void _inferSkelElementSize(Map<String, Map<String, dynamic>> specsByPath) {
    // For each mesh prim with primvars:skel:jointIndices/jointWeights but no
    // elementSize, infer it from the data: elementSize = array.length / numVertices.
    for (final String path in specsByPath.keys) {
      final Map<String, dynamic>? spec = specsByPath[path];
      if (spec == null) continue;

      final dynamic fields = spec['fields'];
      if (spec['specType'] != SpecType.prim.index || 
          fields == null || 
          fields['typeName'] != 'Mesh') {
        continue;
      }

      final Map<String, dynamic>? pointsSpec = specsByPath['$path.points'];
      if (pointsSpec == null) continue;

      final dynamic pointsFields = pointsSpec['fields'];
      if (pointsFields == null || pointsFields['default'] == null) continue;

      final dynamic defaultPoints = pointsFields['default'];
      if (defaultPoints is! List) continue;

      final double numVertices = defaultPoints.length / 3;
      if (numVertices == 0) continue;

      _inferElementSize(specsByPath['$path.primvars:skel:jointIndices'], numVertices);
      _inferElementSize(specsByPath['$path.primvars:skel:jointWeights'], numVertices);
    }
  }

  void _inferElementSize(Map<String, dynamic>? attrSpec, double numVertices) {
    if (attrSpec == null) return;
    
    final dynamic fields = attrSpec['fields'];
    if (fields == null || fields['elementSize'] != null || fields['default'] == null) {
      return;
    }

    final dynamic defaultVal = fields['default'];
    if (defaultVal is! List) return;

    final int len = defaultVal.length;
    if (len > 0 && numVertices > 0 && len % numVertices == 0) {
      fields['elementSize'] = len ~/ numVertices; // Uses integer division (~/) instead of double division
    }
  }

  void _extractPrimData(
    Map<String, dynamic>? data,
    String path,
    Map<String, dynamic> primFields,
    Map<String, Map<String, dynamic>> specsByPath  
  ) {
    if (data == null) return;

    for (final String key in data.keys) {
      // Skip nested defs (handled by walkTree)
      if (key.startsWith('def ')) continue;

      if (key == 'prepend references') {
        primFields['references'] = [data[key]];
        continue;
      }

      if (key == 'payload') {
        primFields['payload'] = data[key];
        continue;
      }

      if (key == 'variants') {
        final Map<String, String> variantSelection = {};
        final dynamic variants = data[key];

        if (variants is Map<String, dynamic>) {
          for (final String vKey in variants.keys) {
            final RegExpMatch? match = variantStringRegex.firstMatch(vKey);
            if (match != null) {
              final String variantSetName = match.group(1) ?? '';
              final String variantValue = variants[vKey].toString().replaceAll('"', '');
              variantSelection[variantSetName] = variantValue;
            }
          }
        }

        if (variantSelection.isNotEmpty) {
          primFields['variantSelection'] = variantSelection;
        }
        continue;
      }

      if (key.startsWith('rel ')) {
        final String relName = key.substring(4);
        final String relPath = '$path.$relName';
        final String target = data[key].toString().replaceAll(RegExp(r'[<>]'), '');
        
        specsByPath[relPath] = {
          'specType': SpecType.relationship.index, // Assuming your unified enum
          'fields': {
            'targetPaths': [target]
          }
        };
        continue;
      }

      // Handle xformOpOrder
      if (key.contains('xformOpOrder')) {
        final List<String> ops = data[key]
            .toString()
            .replaceAll(RegExp(r'[\[\]]'), '')
            .split(',')
            .map((s) => s.trim().replaceAll('"', ''))
            .toList();
        primFields['xformOpOrder'] = ops;
        continue;
      }

      // Handle typed attributes
      // Format: [qualifier] type attrName (e.g., "uniform token[] joints", "float3 position")
      final RegExpMatch? attrMatch = attrMatchRegex.firstMatch(key);
      if (attrMatch != null) {
        final String valueType = attrMatch.group(1) ?? '';
        final String attrName = attrMatch.group(2) ?? '';
        final dynamic rawValue = data[key];

        // Handle connection attributes (e.g., "inputs:normal.connect = </path>")
        if (attrName.endsWith('.connect')) {
          final String baseAttrName = attrName.substring(0, attrName.length - 8); // Remove '.connect'
          final String attrPath = '$path.$baseAttrName';
          
          // Parse connection path - extract from <path> format
          String connPath = rawValue.toString().trim();
          if (connPath.startsWith('<')) connPath = connPath.substring(1);
          if (connPath.endsWith('>')) connPath = connPath.substring(0, connPath.length - 1);

          // Get or create the attribute spec
          if (!specsByPath.containsKey(attrPath)) {
            specsByPath[attrPath] = {
              'specType': SpecType.attribute.index,
              'fields': <String, dynamic>{'typeName': valueType}
            };
          }
          
          final Map<String, dynamic>? fields = specsByPath[attrPath]?['fields'] as Map<String, dynamic>?;
          if (fields != null) {
            fields['connectionPaths'] = [connPath];
          }
          continue;
        }

        // Handle timeSamples attributes specially
        if (attrName.endsWith('.timeSamples') && rawValue is Map<String, dynamic>) {
          final String baseAttrName = attrName.substring(0, attrName.length - 12); // Remove '.timeSamples'
          final String attrPath = '$path.$baseAttrName';
          
          // Parse timeSamples dictionary into times and values arrays
          final List<double> times = [];
          final List<dynamic> values = [];

          for (final String frameKey in rawValue.keys) {
            final double? frame = double.tryParse(frameKey);
            if (frame == null) continue;
            
            times.add(frame);
            values.add(_parseAttributeValue(valueType, rawValue[frameKey]));
          }

          // Sort by time using a structured helper map list
          final List<Map<String, dynamic>> combined = List.generate(
            times.length,
            (i) => {'t': times[i], 'v': values[i]},
          );
          combined.sort((a, b) => (a['t'] as double).compareTo(b['t'] as double));

          specsByPath[attrPath] = {
            'specType': SpecType.attribute.index,
            'fields': {
              'timeSamples': {
                'times': combined.map((s) => s['t'] as double).toList(),
                'values': combined.map((s) => s['v']).toList()
              },
              'typeName': valueType
            }
          };
        } else {
          // Parse value based on type
          final dynamic parsedValue = _parseAttributeValue(valueType, rawValue);

          // Store as attribute spec, preserving any existing fields
          // (e.g. connectionPaths set by an earlier `.connect` form)
          final String attrPath = '$path.$attrName';
          
          if (specsByPath.containsKey(attrPath)) {
            final Map<String, dynamic>? fields = specsByPath[attrPath]?['fields'] as Map<String, dynamic>?;
            if (fields != null) {
              fields['default'] = parsedValue;
              fields['typeName'] = valueType;
            }
          } else {
            specsByPath[attrPath] = {
              'specType': SpecType.attribute.index,
              'fields': {'default': parsedValue, 'typeName': valueType}
            };
          }
        }
      }
    }
  }

  dynamic _parseAttributeValue(String valueType, dynamic rawValue) {
    if (rawValue == null) return null;
    final String str = rawValue.toString().trim();

    // Array types
    if (valueType.endsWith('[]')) {
      List<dynamic> result;

      // Parse JSON-like arrays
      try {
        // Handle arrays with parentheses like [(1,2,3), (4,5,6)]
        // Remove trailing comma (valid in USDA but not JSON)
        String cleaned = str.replaceAll('(', '[').replaceAll(')', ']');
        if (cleaned.endsWith(',')) {
          cleaned = cleaned.substring(0, cleaned.length - 1);
        }
        
        final dynamic parsed = jsonDecode(cleaned);
        
        // Flatten nested arrays for types like point3f[]
        if (parsed is List && parsed.isNotEmpty && parsed[0] is List) {
          result = parsed.expand((element) => element as List).toList();
        } else if (parsed is List) {
          result = parsed;
        } else {
          result = [parsed];
        }
      } catch (e) {
        // Try simple array parsing
        final String cleaned = str.replaceAll(RegExp(r'[\[\]]'), '');
        result = cleaned.split(',').map((s) {
          final String trimmed = s.trim();
          final double? numVal = double.tryParse(trimmed);
          return numVal ?? trimmed.replaceAll('"', '');
        }).toList();
      }

      // reorder (w, x, y, z) to (x, y, z, w)
      if (valueType.startsWith('quat')) {
        for (int i = 0; i < result.length; i += 4) {
          if (i + 3 < result.length) {
            final dynamic w = result[i];
            result[i] = result[i + 1];
            result[i + 1] = result[i + 2];
            result[i + 2] = result[i + 3];
            result[i + 3] = w;
          }
        }
      }
      return result;
    }

    // Vector types (double3, float3, point3f, etc.)
    if (valueType.contains('3') || valueType.contains('2') || valueType.contains('4')) {
      // Parse (x, y, z) format
      final String cleaned = str.replaceAll(RegExp(r'[()]'), '');
      final List<double> values = cleaned
          .split(',')
          .map((s) => double.tryParse(s.trim()) ?? 0.0)
          .toList();
      return values;
    }

    // Quaternion types (quatf, quatd, quath)
    // Text format is (w, x, y, z), convert to (x, y, z, w)
    if (valueType.startsWith('quat')) {
      final String cleaned = str.replaceAll(RegExp(r'[()]'), '');
      final List<double> values = cleaned
          .split(',')
          .map((s) => double.tryParse(s.trim()) ?? 0.0)
          .toList();
      if (values.length >= 4) {
        return [values[1], values[2], values[3], values[0]];
      }
      return values;
    }

    // Matrix types
    if (valueType.contains('matrix')) {
      final String cleaned = str.replaceAll(RegExp(r'[()]'), '');
      final List<double> values = cleaned
          .split(',')
          .map((s) => double.tryParse(s.trim()) ?? 0.0)
          .toList();
      return values;
    }

    // Scalar numeric types
    if (valueType == 'float' || valueType == 'double' || valueType == 'int') {
      return double.tryParse(str) ?? 0.0;
    }

    // String/token types
    if (valueType == 'string' || valueType == 'token') {
      return _parseString(str);
    }

    // Asset path
    if (valueType == 'asset') {
      return str.replaceAll('@', '').replaceAll('"', '');
    }

    // Default: return as string with quotes removed
    return _parseString(str);
  }

  String _parseString(String str) {
    // Remove surrounding quotes
    if ((str.startsWith('"') && str.endsWith('"')) || 
        (str.startsWith("'") && str.endsWith("'"))) {
      str = str.substring(1, str.length - 1);
    }

    // Handle escape sequences
    final StringBuffer result = StringBuffer();
    int i = 0;

    while (i < str.length) {
      final String current = str.substring(i, i + 1);

      if (current == '\\' && i + 1 < str.length) {
        final String next = str.substring(i + 1, i + 2);
        switch (next) {
          case 'n':
            result.write('\n');
            break;
          case 't':
            result.write('\t');
            break;
          case 'r':
            result.write('\r');
            break;
          case '\\':
            result.write('\\');
            break;
          case '"':
            result.write('"');
            break;
          case "'":
            result.write("'");
            break;
          default:
            result.write(next);
            break;
        }
        i += 2;
      } else {
        result.write(current);
        i++;
      }
    }

    return result.toString();
  }
}