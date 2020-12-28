import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart' hide DownloadTask;
import 'package:in_app_download/downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Downloader(),
      child: MaterialApp(home: MainChild()),
    );
  }
}

class MainChild extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RaisedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyHome(),
              ),
            );
          },
          child: Text("Go"),
        ),
      ),
    );
  }
}

class DownloadWithDIO extends StatefulWidget {
  @override
  _DownloadWithDIOState createState() => _DownloadWithDIOState();
}

class _DownloadWithDIOState extends State<DownloadWithDIO> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ListTile(
                        title: Text(e.outputFilename),
                        subtitle: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_displayStatus(e.status)),
                                Text(((e.progress ?? 0) / 100).toString()),
                              ],
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 500),
                              child: LinearProgressIndicator(
                                value: (e.progress ?? 0) / 100,
                                backgroundColor: Colors.black12,
                              ),
                            )
                          ],
                        ),
                        trailing: IconButton(
                          icon: e.status == DownloadTaskStatus.running
                              ? Icon(
                                  Icons.pause,
                                  color: Colors.red,
                                )
                              : e.status == DownloadTaskStatus.enqueued
                                  ? Icon(
                                      Icons.history,
                                      color: Colors.red,
                                    )
                                  : e.status == DownloadTaskStatus.paused
                                      ? Icon(
                                          Icons.play_arrow,
                                          color: Colors.red,
                                        )
                                      : e.status == DownloadTaskStatus.failed
                                          ? Icon(
                                              Icons.refresh,
                                              color: Colors.red,
                                            )
                                          : e.status ==
                                                  DownloadTaskStatus.undefined
                                              ? Icon(
                                                  Icons.device_unknown,
                                                  color: Colors.red,
                                                )
                                              : e.status ==
                                                      DownloadTaskStatus
                                                          .complete
                                                  ? Icon(
                                                      Icons.open_in_browser,
                                                      color: Colors.red,
                                                    )
                                                  : Container(),
                          onPressed: () {
                            handleActionButton(e);
                          },
                        )));
        ],
      ),
    );
  }
}

class DownloadWithFlutterDownloader extends StatefulWidget {
  @override
  _DownloadWithFlutterDownloaderState createState() =>
      _DownloadWithFlutterDownloaderState();
}

class _DownloadWithFlutterDownloaderState
    extends State<DownloadWithFlutterDownloader> {
  Downloader downloader = Downloader();
  List<DownloadTask> _tasks = [
    DownloadTask(
        url:
            "https://drive.google.com/uc?export=download&id=1SguriTZ5tAGUL3-ZbdTt7a8fglBS3Lk3",
        outputFilename: "testvideo"),
  ];

  @override
  void initState() {
    Permission.storage.request().then((value) {
      if (!value.isGranted) {
        print('Permission not granted!');
        openAppSettings();
        return;
      } else {
        downloader.init();
        _tasks.forEach((element) {
          downloader.addTask(element);
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    downloader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void handleActionButton(DownloadTask task) {
      if (task.status == DownloadTaskStatus.undefined) {
      } else if (task.status == DownloadTaskStatus.running) {
        downloader.pause(task);
      } else if (task.status == DownloadTaskStatus.paused) {
        downloader.resume(task);
      } else if (task.status == DownloadTaskStatus.enqueued) {
        downloader.cancel(task);
      } else if (task.status == DownloadTaskStatus.failed) {
        downloader.addTask(task);
      } else if (task.status == DownloadTaskStatus.canceled) {
        downloader.addTask(task);
      } else if (task.status == DownloadTaskStatus.complete) {
        downloader.open(task);
      }
    }

    String _displayStatus(DownloadTaskStatus status) {
      if (status == null) return "";
      if (status == DownloadTaskStatus.undefined) {
        return "Unknown";
      } else if (status == DownloadTaskStatus.running) {
        return "Downloading";
      } else if (status == DownloadTaskStatus.paused) {
        return "Paused";
      } else if (status == DownloadTaskStatus.enqueued) {
        return "Pending";
      } else if (status == DownloadTaskStatus.failed) {
        return "Failed";
      } else if (status == DownloadTaskStatus.canceled) {
        return "Cancelled";
      } else if (status == DownloadTaskStatus.complete) {
        return "Completed";
      }
      return "Error";
    }

    return Scaffold(
        appBar: AppBar(),
        body: StreamBuilder<List<DownloadTask>>(
          initialData: [],
          stream: downloader.tasks.stream,
          builder: (context, snapshot) {
            if (!downloader.hasTasks) {
              return Center(
                child: Text("No download task found"),
              );
            }
            return ListView(
                shrinkWrap: true,
                children: snapshot.data
                    .map((e) => ListTile(
                        title: Text(e.outputFilename),
                        subtitle: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_displayStatus(e.status)),
                                Text(((e.progress ?? 0) / 100).toString()),
                              ],
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 500),
                              child: LinearProgressIndicator(
                                value: (e.progress ?? 0) / 100,
                                backgroundColor: Colors.black12,
                              ),
                            )
                          ],
                        ),
                        trailing: IconButton(
                          icon: e.status == DownloadTaskStatus.running
                              ? Icon(
                                  Icons.pause,
                                  color: Colors.red,
                                )
                              : e.status == DownloadTaskStatus.enqueued
                                  ? Icon(
                                      Icons.history,
                                      color: Colors.red,
                                    )
                                  : e.status == DownloadTaskStatus.paused
                                      ? Icon(
                                          Icons.play_arrow,
                                          color: Colors.red,
                                        )
                                      : e.status == DownloadTaskStatus.failed
                                          ? Icon(
                                              Icons.refresh,
                                              color: Colors.red,
                                            )
                                          : e.status ==
                                                  DownloadTaskStatus.undefined
                                              ? Icon(
                                                  Icons.device_unknown,
                                                  color: Colors.red,
                                                )
                                              : e.status ==
                                                      DownloadTaskStatus
                                                          .complete
                                                  ? Icon(
                                                      Icons.open_in_browser,
                                                      color: Colors.red,
                                                    )
                                                  : Container(),
                          onPressed: () {
                            handleActionButton(e);
                          },
                        )))
                    .toList());
          },
        ));
  }
}
