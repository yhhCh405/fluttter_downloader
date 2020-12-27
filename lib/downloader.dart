import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_downloader/src/models.dart' as dldrModels;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class Downloader extends ChangeNotifier {
  ReceivePort _port = ReceivePort();
  static const String _PORTNAME = "downloader_send_port";

  BehaviorSubject<List<DownloadTask>> tasks = BehaviorSubject.seeded([]);

  bool get hasTasks => this.tasks.value != null && this.tasks.value.length > 0;

  void init() {
    bool _registeredPort =
        IsolateNameServer.registerPortWithName(_port.sendPort, _PORTNAME);
    if (!_registeredPort) {
      _unRegisterPort();
      init();
      return;
    }
    _port.listen((dynamic d) {
      String id = d[0];
      DownloadTaskStatus status = d[1];
      int progress = d[2];

      List<DownloadTask> _dt = tasks.value;
      _dt.forEach((e) {
        if (e.taskId == id) {
          e.status = status;
          e.progress = progress;
        }
      });
      tasks.add(_dt);
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  void _unRegisterPort() {
    IsolateNameServer.removePortNameMapping(_PORTNAME);
  }

  void discard() {
    _unRegisterPort();
    tasks.close();
  }

  static void downloadCallback(id, status, progress) {
    final SendPort _sendPort = IsolateNameServer.lookupPortByName(_PORTNAME);
    _sendPort.send([id, status, progress]);
  }

  Future<void> addTask(DownloadTask task, {bool forced = false}) async {
    if (!forced) {
      if (this.tasks != null && this.tasks.value.contains(task)) {
        retry(task);
        return;
      }
    }
    await task._createTask();
    List<DownloadTask> _dt = this.tasks.value;
    _dt.add(task);
    this.tasks.add(_dt);
  }

  Future<void> loadAllTask() async {
    List<dldrModels.DownloadTask> _t = await FlutterDownloader.loadTasks();
    this.tasks.add(_t.map((e) => DownloadTask.fromDldrModel(e)).toList());
    notifyListeners();
  }

  Future<void> pause(DownloadTask task) async {
    await FlutterDownloader.pause(taskId: task.taskId);
  }

  Future<String> resume(DownloadTask task) async {
    return await FlutterDownloader.resume(taskId: task.taskId);
  }

  Future<void> cancel(DownloadTask task) async {
    await FlutterDownloader.cancel(taskId: task.taskId);
  }

  Future<void> cancelAll() async {
    await FlutterDownloader.cancelAll();
  }

  Future<void> retry(DownloadTask task) async {
    await FlutterDownloader.retry(taskId: task.taskId);
  }

  Future<void> remove(DownloadTask task) async {
    await FlutterDownloader.remove(taskId: task.taskId);
  }

  Future<void> open(DownloadTask task) async {
    await FlutterDownloader.open(taskId: task.taskId);
  }
}

class DownloadTask {
  String url;
  String _taskId;
  DownloadTaskStatus status;
  int progress;
  int timeCreated;

  /// Must call createTask() first
  String get taskId => this._taskId;
  String outputFilename;
  String outputDir;

  DownloadTask({@required this.url, this.outputDir, this.outputFilename}) {
    if (this.outputFilename == null) {
      this.outputFilename = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> _createTask({
    Map<String, String> headers,
    bool showNotification = true,
  }) async {
    if (this.outputDir == null) {
      Directory _d = await getExternalStorageDirectory();
      this.outputDir = _d.path + "/yhh/";
    }
    bool direxist = Directory(outputDir).existsSync();
    if (!direxist) {
      await Directory(this.outputDir).create(recursive: true);
    }

    this._taskId = await FlutterDownloader.enqueue(
        url: this.url,
        savedDir: outputDir,
        fileName: outputFilename,
        headers: headers,
        showNotification: showNotification,
        openFileFromNotification: true,
        requiresStorageNotLow: true);
  }

  DownloadTask.fromDldrModel(dldrModels.DownloadTask dtask) {
    this._taskId = dtask.taskId;
    this.status = dtask.status;
    this.progress = dtask.progress;
    this.url = dtask.url;
    this.outputFilename = dtask.filename;
    this.outputDir = dtask.savedDir;
    this.timeCreated = dtask.timeCreated;
  }
}
