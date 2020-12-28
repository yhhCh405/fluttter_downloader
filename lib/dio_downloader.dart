// Test Dio download
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DioDownloader {
  String outputDir;

  Future<void> _createOutputDir() async {
    if (this.outputDir == null) {
      Directory _d = await getExternalStorageDirectory();
      this.outputDir = _d.path + "/yhh/";
    }
    bool direxist = Directory(outputDir).existsSync();
    if (!direxist) {
      await Directory(this.outputDir).create(recursive: true);
    }
  }

  Future<void> download(String url, {String outputFileName}) async {
    outputFileName ??= DateTime.now().millisecondsSinceEpoch.toString();
    _createOutputDir();
    String _saveFileWithPath;
    if(outputDir.endsWith("/")){
      _saveFileWithPath = outputDir + 
    }
    Dio dio = Dio();
    await dio.download(url, outputDir + ,
        options: Options(
            headers: {HttpHeaders.acceptEncodingHeader: "*"}), // disable gzip
        onReceiveProgress: (received, total) {
      if (total != -1) {
        print((received / total * 100).toStringAsFixed(0) + "%");
      }
    });
  }
}
