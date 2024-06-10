import 'dart:typed_data';
import 'dart:math' as math;
import 'package:three_js_advanced_loaders/scn/binary_reader.dart';
import 'package:three_js_core/three_js_core.dart';

class NsUnarchiver{
  Uint8List data;
  NsUnarchiver(Uint8List? data, [Map? options]){
    options ??= {};

    if(data != null){
      _reader = BinaryReader(data, true, 'utf8');//String.fromCharCodes(data);
      _checkHeader(_reader);
      _parsedObj = _parseBPlist();
    }
  }

  BinaryReader _reader;
  int _offsetSize;
  int _objCount;
  List<int> _offsetArray;
  dynamic _parsedObj;
  String _filePath;
  List _dataObj;
  bool _requiresSecureCoding = false;
  dynamic delegate;
  _decodingFailurePolicy;
  _resolveFunctions;
  _refObj;
  _decodingFinished;

  NsUnarchiver copy() {
    final coder = NsUnarchiver();
    coder._requiresSecureCoding = _requiresSecureCoding;
    coder.delegate = delegate;
    coder._decodingFailurePolicy = _decodingFailurePolicy;
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
    final topObjIndex = unarchiver._parsedObj.$top.root.value;
    return unarchiver._parseClassAt(topObjIndex);
  }

  bool _checkHeader(BinaryReader text) {
    final header = text.readString(8);
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

    //console.log('dataLen: ${dataLen}')
    //console.log('intSize: ${intSize}')
    //console.log('offsetSize: ${this._offsetSize}')
    //console.log('objCount: ${this._objCount}')
    //console.log('topIndex: ${topIndex}')
    //console.log('tablePos: ${tablePos}')

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
    return _parseObj(_offsetArray[index]);
  }

  _parseObj([int? offset, bool signed = false]) {
    final reader = _reader;
    if(offset != null){
      reader.seek(offset);
    }
    final type = reader.readUnsignedByte();
    final type1 = type & 0xF0;
    final type2 = type & 0x0F;
    //console.log('parseObj: type: ${type1} ${type2}')
    if(type1 == 0x00){
      // null, boolean
      if(type2 == 0){
        //console.log('   type: null')
        return null;
      }else if(type2 == 8){
        //console.log('   type: boolean')
        return false;
      }else if(type2 == 9){
        //console.log('   type: boolean')
        return true;
      }
    }else if(type1 == 0x10){
      // Int
      final int len = math.pow(2, type2).toInt();
      //console.log('   type: integer ' + len)
      return reader.readInteger(len, signed);
    }else if(type1 == 0x20){
      // Float
      final len = math.pow(2, type2);
      if(len == 4){
        //console.log('   type: float')
        return reader.readFloat();
      }else if(len == 8){
        //console.log('   type: double')
        return reader.readDouble();
      }
      throw('unsupported float size: $len');
    }else if(type1 == 0x30){
      // Date
      //console.log('   type: Date')
    }else if(type1 == 0x40){
      // Data
      final count = this._getDataSize(type2);
      //console.log('   type: Data: length: ${count}')
      return reader.readData(count);
    }else if(type1 == 0x50){
      // ASCII
      final count = this._getDataSize(type2);
      //console.log('   type: ascii ' + count)
      return reader.readString(count, 'ascii');
    }else if(type1 == 0x60){
      // UTF-16
      final count = this._getDataSize(type2);
      //console.log('   type: UTF-16 ' + count)
      return reader.readString(count, 'utf16be'); // Big Endian might not be supported...
    }else if(type1 == 0x80){
      // UID
      final uid = reader.readInteger(type2 + 1, false);
      //console.log('   type: UID: ' + uid)
      return _UID(this, uid);
    }
    else if(type1 == 0xA0){
      // Array
      final count = this._getDataSize(type2);
      //console.log('   type: array: ' + count)
      final arrIndex = [];
      for(int i=0; i<count; i++){
        arrIndex.add(reader.readInteger(_offsetSize, false));
      }
      final arr = arrIndex.map((index) => _parseObjAtIndex(index));
      //console.log('***arr.length: ${arr.length}')
      return arr;
    }
    else if(type1 == 0xC0){
      // Set
      final count = this._getDataSize(type2);
      final setIndex = [];
      for(int i=0; i<count; i++){
        setIndex.add(reader.readInteger(_offsetSize, false));
      }
      final arr = setIndex.map((index) => _parseObjAtIndex(index));
      return Set(arr);
    }
    else if(type1 == 0xD0){
      // Dictionary
      //console.log('   type: dictionary')
      final count = this._getDataSize(type2);
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
        //console.log('key: ' + key)
        final val = _parseObjAtIndex(valueIndex[i]);
        //console.log('val: ' + val)
        result[key] = val;
      }
      return result;
    }

    throw('unknown data type: $type');
  }

  _parseClassAt(index) {
    final obj = this._parsedObj.$objects[index]
    if(this._dataObj[index] === _loadingSymbol){
      // it seems to be a reference loop; return Promise
      return new Promise((resolve, reject) => {
        if(typeof this._resolveFunctions[index] === 'undefined'){
          this._resolveFunctions[index] = []
        }
        this._resolveFunctions[index].push(resolve)
      })
    }else if(typeof this._dataObj[index] !== 'undefined'){
      return this._dataObj[index]
    }
    this._dataObj[index] = _loadingSymbol
    final data = this._parseClass(obj)
    this._dataObj[index] = data
    if(Array.isArray(this._resolveFunctions[index])){
      this._resolveFunctions[index].forEach((resolve) => {
        resolve(data)
      })
      delete this._resolveFunctions[index]
    }
    return data
  }

  _parseClass(obj) {
    final className = obj.$class.obj.$classname;
    //console.log(`parseClass ${className}`)
    final classObj = NsUnarchiver.classForClassName(className);
    if(classObj){
      final unarchiver = this.copy();
      unarchiver._refObj = obj;
      return classObj.initWithCoder(unarchiver);
    }
    return null
  }
}