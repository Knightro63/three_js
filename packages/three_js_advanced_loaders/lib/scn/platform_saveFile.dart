import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'filePicker.dart';
import 'package:path_provider/path_provider.dart' as pp;

class SaveFile{
  static Future<void> saveBytes({
    required String printName,
    required String fileType,
    required Uint8List bytes,
    String? path,
  }) async {

    if(Platform.isMacOS || Platform.isWindows || Platform.isLinux || Platform.isFuchsia){
      path = await GetFilePicker.saveFile(printName, fileType);
    }
    else if(path == null && (Platform.isAndroid || Platform.isIOS)){
      final appDocDir = await pp.getApplicationDocumentsDirectory();
      path = '${appDocDir.path}/$printName.$fileType';
    }
    else{
      path = '$path/$printName.$fileType';
    }

    await File(path!).writeAsBytes(bytes);
    print('Save file to $path ...');
  }

  static Future<void> saveString({
    required String printName,
    required String fileType,
    required String data,
    String? path,
  }) async {
    if(Platform.isMacOS || Platform.isWindows || Platform.isLinux || Platform.isFuchsia){
      path = await GetFilePicker.saveFile(printName, fileType);
    }
    else if(path == null && (Platform.isAndroid || Platform.isIOS)){
      final appDocDir = await pp.getApplicationDocumentsDirectory();
      path = '${appDocDir.path}/$printName.$fileType';
    }
    else{
      path = '$path/$printName.$fileType';
    }

    await File(path!).writeAsString(data);
    print('Save file to $path ...');
  }
}