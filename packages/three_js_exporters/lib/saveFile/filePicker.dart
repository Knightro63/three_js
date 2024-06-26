import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class GetFilePicker{
  static Future<FilePickerResult?> pickFiles(List<String> extensions) async {
    try {
      FilePickerResult? _paths = (await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        onFileLoading: (FilePickerStatus status) => print(status),
        allowedExtensions: extensions,
        allowCompression: false,
        withData: true
      ));
      return _paths;
    } 
    on PlatformException catch (e) {
      print('Unsupported operation Pick:' + e.toString());
    } 
    catch (e) {
      print('Pick: '+e.toString());
    }
    return null;
  }

  static Future<bool> clearCachedFiles() async {
    try {
      await FilePicker.platform.clearTemporaryFiles().then((value){
        return value;
      });
    } 
    on PlatformException catch (e) {
      print('Unsupported operation Clear:' + e.toString());
    } 
    catch (e) {
      print('Clear: '+e.toString());
    } 
    return false;
  }

  static Future<String?> saveFile(String fileName, String fileType) async {
    String? path = '';
    try {
      path = await FilePicker.platform.saveFile(
        fileName: fileName+'.'+fileType,
        type: FileType.custom,
        allowedExtensions: [fileType]
      );
    } 
    on PlatformException catch (e) {
      print('Unsupported operation Select:' + e.toString());
    } 
    catch (e) {
      print('Select: '+e.toString());
    }
    return path;
  }

  static Future<String> selectFolder() async {
    try {
      await FilePicker.platform.getDirectoryPath().then((value){
        return value;
      });
    } 
    on PlatformException catch (e) {
      print('Unsupported operation Select:' + e.toString());
    } 
    catch (e) {
      print('Select: '+e.toString());
    }
    return '';
  }
}