import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:three_js_core/three_js_core.dart';

class GetFilePicker{
  static Future<FilePickerResult?> pickFiles(List<String> extensions) async {
    try {
      FilePickerResult? paths = (await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        onFileLoading: (FilePickerStatus status) => console.info(status),
        allowedExtensions: extensions,
        allowCompression: false,
        withData: true
      ));
      return paths;
    } 
    on PlatformException catch (e) {
      console.error('Unsupported operation Pick: $e');
    } 
    catch (e) {
      console.error('Pick: $e');
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
      console.error('Unsupported operation Clear: $e');
    } 
    catch (e) {
      console.error('Clear: $e');
    } 
    return false;
  }

  static Future<String?> saveFile(String fileName, String fileType) async {
    String? path = '';
    try {
      path = await FilePicker.platform.saveFile(
        fileName: '$fileName.$fileType',
        type: FileType.custom,
        allowedExtensions: [fileType]
      );
    } 
    on PlatformException catch (e) {
      console.error('Unsupported operation Select: $e');
    } 
    catch (e) {
      console.error('Select: $e');
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
      console.error('Unsupported operation Select: $e');
    } 
    catch (e) {
      console.error('Select: $e');
    }
    return '';
  }
}