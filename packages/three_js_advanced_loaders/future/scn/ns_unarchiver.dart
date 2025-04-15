import 'dart:typed_data';
import 'dart:math' as math;
import 'binary_reader_old.dart';
import 'package:three_js_core/three_js_core.dart';

final Map<String,dynamic> _classForKey = {};
const _loadingSymbol = Symbol('loading');

class _UID {
  late NsUnarchiver _unarchiver;
  late int _value; 

  _UID(NsUnarchiver unarchiver, int value) {
    _unarchiver = unarchiver;
   _value = value;
  }

  int get value => _value;
  NsUnarchiver get obj => _unarchiver._parsedObj[r'$objects'][_value];
}

class NsUnarchiver{
  NsUnarchiver([Uint8List? data, Map? options]){
    options ??= {};

    if(data != null){
      _reader = BinaryReader(data, true, 'utf8');//String.fromCharCodes(data);
      _checkHeader(data);
      _parsedObj = _parseBPlist();
    }
  }

  late BinaryReader _reader;
  late int _offsetSize;
  late int _objCount;
  List<int> _offsetArray = [];
  dynamic _parsedObj;
  String? _filePath;
  Map<int,dynamic> _dataObj = {};
  bool _requiresSecureCoding = false;
  dynamic delegate;
  Map<int,List?> _resolveFunctions = {};
  dynamic _refObj;
  bool _decodingFinished = false;

  NsUnarchiver copy() {
    final coder = NsUnarchiver();
    coder._requiresSecureCoding = _requiresSecureCoding;
    coder.delegate = delegate;
    coder._reader = _reader;
    coder._offsetSize = _offsetSize;
    coder._objCount = _objCount;
    coder._offsetArray = _offsetArray;
    coder._parsedObj = _parsedObj;
    coder._dataObj = _dataObj;
    coder._resolveFunctions = _resolveFunctions;
    coder._filePath = _filePath;
    coder._refObj = _refObj;
    coder._decodingFinished = _decodingFinished;
    return coder;
  }

  static unarchiveObjectWithData(data, [String? path, Map? options]) {
    options ??= {};
    final unarchiver = NsUnarchiver(data, options);
    unarchiver._filePath = path;
    print(unarchiver._parsedObj);
    final topObjIndex = unarchiver._parsedObj[r'$top']['root'];
    return unarchiver._parseClassAt(topObjIndex);
  }

  bool _checkHeader(Uint8List text) {
    final header = String.fromCharCodes(text.sublist(0,8));
    if(header != 'bplist00'){
      console.warning('unsupported file format: $header');
      return false;
    }
    return true;
  }

  _parseBPlist() {
    final reader = _reader;
    // read basic info
    reader.seek(-26);
    final dataLen = reader.length;
    final intSize = reader.readUnsignedByte();
    _offsetSize = reader.readUnsignedByte();
    _objCount = reader.readUnsignedLongLong();
    final topIndex = reader.readUnsignedLongLong();
    final tablePos = reader.readUnsignedLongLong();

    print('dataLen: $dataLen');
    print('intSize: $intSize');
    print('offsetSize: $_offsetSize');
    print('objCount: $_objCount');
    print('topIndex: $topIndex');
    print('tablePos: $tablePos');

    _offsetArray = [];
    int pos = tablePos;
    reader.seek(pos);
    final objCount = _objCount;
    for(int i=0; i<objCount; i++){
      final offset = reader.readInteger(intSize);
      _offsetArray.add(offset);
    }

    return _parseObjAtIndex(topIndex);
  }

  _parseObjAtIndex(index) {
    return _parseObj(_offsetArray.isEmpty?null:_offsetArray[index]);
  }

  _parseObj([int? offset, bool signed = false]) {
    final reader = _reader;
    if(offset != null){
      reader.seek(offset);
    }
    final type = reader.readUnsignedByte();
    final type1 = type & 0xF0;
    final type2 = type & 0x0F;
    //print('parseObj: type: ${type1} ${type2}')
    if(type1 == 0x00){
      // null, boolean
      if(type2 == 0){
        //print('   type: null')
        return null;
      }else if(type2 == 8){
        //print('   type: boolean')
        return false;
      }else if(type2 == 9){
        //print('   type: boolean')
        return true;
      }
    }else if(type1 == 0x10){
      // Int
      final int len = math.pow(2, type2).toInt();
      //print('   type: integer ' + len)
      return reader.readInteger(len, signed);
    }else if(type1 == 0x20){
      // Float
      final len = math.pow(2, type2);
      if(len == 4){
        //print('   type: float')
        return reader.readFloat();
      }else if(len == 8){
        //print('   type: double')
        return reader.readDouble();
      }
      throw('unsupported float size: $len');
    }else if(type1 == 0x30){
      // Date
      //print('   type: Date')
    }else if(type1 == 0x40){
      // Data
      final count = _getDataSize(type2);
      //print('   type: Data: length: ${count}')
      return reader.readData(count);
    }else if(type1 == 0x50){
      // ASCII
      final count = _getDataSize(type2);
      //print('   type: ascii ' + count)
      return reader.readString(count, 'ascii');
    }else if(type1 == 0x60){
      // UTF-16
      final count = _getDataSize(type2);
      //print('   type: UTF-16 ' + count)
      return reader.readString(count, 'utf16be'); // Big Endian might not be supported...
    }else if(type1 == 0x80){
      // UID
      final uid = reader.readInteger(type2 + 1, false);
      //print('   type: UID: ' + uid)
      return _UID(this, uid);
    }
    else if(type1 == 0xA0){
      // Array
      final count = _getDataSize(type2);
      //print('   type: array: ' + count)
      final arrIndex = [];
      for(int i=0; i<count; i++){
        arrIndex.add(reader.readInteger(_offsetSize, false));
      }
      final arr = arrIndex.map((index) => _parseObjAtIndex(index));
      //print('***arr.length: ${arr.length}')
      return arr;
    }
    else if(type1 == 0xC0){
      // Set
      final count = _getDataSize(type2);
      final setIndex = [];
      for(int i=0; i<count; i++){
        setIndex.add(reader.readInteger(_offsetSize, false));
      }
      final arr = setIndex.map((index) => _parseObjAtIndex(index));
      return arr;
    }
    else if(type1 == 0xD0){
      // Dictionary
      //print('   type: dictionary')
      final count = _getDataSize(type2);
      final keyIndex = [];
      final valueIndex = [];
      for(int i=0; i<count; i++){
        keyIndex.add(reader.readInteger(_offsetSize, false));
      }
      for(int i=0; i<count; i++){
        valueIndex.add(reader.readInteger(_offsetSize, false));
      }
      final result = {};
      for(int i=0; i<count; i++){
        final key = _parseObjAtIndex(keyIndex[i]);
        //print('key: ' + key)
        final val = _parseObjAtIndex(valueIndex[i]);
        //print('val: ' + val)
        result[key] = val;
      }
      return result;
    }

    throw('unknown data type: $type');
  }

  int _getDataSize(int type2) {
    int count = 0;
    if(type2 != 0x0F){
      count = type2;
    }else{
      count = _parseObj(null, false);
    }
    return count;
  }

  _parseClassAt(index) async {
    final obj = _parsedObj[r'$objects'][index];
    if(_dataObj[index] == _loadingSymbol){
      // it seems to be a reference loop; return Promise
      return ((resolve, reject){
        if(_resolveFunctions[index] == null){
          _resolveFunctions[index] = [];
        }
        _resolveFunctions[index]?.add(resolve);
      });
    }
    else if(_dataObj[index] != null){
      return _dataObj[index];
    }
    _dataObj[index] = _loadingSymbol;
    final data = _parseClass(obj);
    _dataObj[index] = data;
    if(_resolveFunctions[index] != null && _resolveFunctions[index]!.isNotEmpty){
      _resolveFunctions[index]?.forEach((resolve){
        resolve(data);
      });
      _resolveFunctions[index] = null;
    }
    return data;
  }

  dynamic _parseClass(obj) {
    final className = obj[r'$class'].obj[r'$classname'];
    //print(`parseClass ${className}`)
    final classObj = NsUnarchiver.classForClassName(className);
    if(classObj != null){
      final unarchiver = copy();
      unarchiver._refObj = obj;
      return classObj.initWithCoder(unarchiver);
    }
    return null;
  }

  static void setClassForClassName(cls, String codedName) {
    _classForKey[codedName] =  cls;
  }

  static dynamic classForClassName(codedName) {
    final classObj = _classForKey[codedName];
    if(classObj != null){
      return classObj;
    }
    //return _ClassList.get(codedName);
  }
}