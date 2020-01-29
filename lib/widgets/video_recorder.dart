import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/*
  * Global Values
  */
StreamController<int> _controller = StreamController<int>();
Stream _recorderStream = _controller.stream;
bool _isRecordingVideo = false;

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class VideoRecorder extends StatefulWidget {
  Function onVideoRecorded;
  GlobalKey<ScaffoldState> videoKey = GlobalKey<ScaffoldState>();
  VideoRecorderController recorderController;

  VideoRecorder({this.onVideoRecorded, this.videoKey, this.recorderController});

  @override
  _VideoRecorderState createState() {
    return _VideoRecorderState();
  }
}

class _VideoRecorderState extends State<VideoRecorder>
    with WidgetsBindingObserver {
  CameraController controller;
  String imagePath;
  String videoPath;
  VoidCallback videoPlayerListener;
  bool enableAudio = true;
  List<CameraDescription> cameras = [];
  int selectedCameraIdx = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _initCameras().then((_) {
      if (cameras.isNotEmpty) {
        onNewCameraSelected(cameras[0]);
      }
      setState(() {});
      WidgetsBinding.instance.addObserver(this);
    });

    if (widget.recorderController != null) {
      _recorderStream.listen((value) {
        onRecorderControllerChangeState(value);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed && controller != null) {
      onNewCameraSelected(controller.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: _scaffoldKey, child: _getBody());
  }

  void onRecorderControllerChangeState(int state) {
    if (state == VideoRecorderController.RECORD) {
      onVideoRecordButtonPressed();
    } else if (state == VideoRecorderController.STOP) {
      onStopButtonPressed();
    }
  }

  Widget _getBody() {
    Column column = Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        _surfaceCameraView(),
      ],
    );
    return column;
  }

  Widget _surfaceCameraView() {
    var container = Container(
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Center(
          child: _cameraPreviewWidget(),
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
            width: 3.0,
            color: controller != null && controller.value.isRecordingVideo
                ? Colors.redAccent
                : Colors.grey),
      ),
    );
    return container;
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
            color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w900),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  /// Display the control bar with buttons to take pictures and record videos
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        _cameraTogglesRowWidget(),
        IconButton(
            icon: Icon(Icons.videocam),
            color: Colors.blue,
            onPressed: controller != null &&
                    controller.value.isInitialized &&
                    !controller.value.isRecordingVideo
                ? onVideoRecordButtonPressed
                : null),
        IconButton(
            icon: const Icon(Icons.stop),
            color: Colors.red,
            onPressed: controller != null &&
                    controller.value.isInitialized &&
                    controller.value.isRecordingVideo
                ? onStopButtonPressed
                : null)
      ],
    );
  }

  /// Selector of front Camera and main Camera
  Widget _cameraTogglesRowWidget() {
    if (cameras == null || cameras.isEmpty) {
      return Spacer();
    }

    CameraDescription selectedCamera = cameras[selectedCameraIdx];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    Widget body = Align(
      alignment: Alignment.centerLeft,
      child: FlatButton.icon(
        onPressed: () => _onSwitchCamera(),
        icon: Icon(getCameraLensIcon(lensDirection)),
        label: Text(
            '${lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1)}'),
      ),
    );

    return body;
  }

  /// Record Video
  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String filePath) {
      if (mounted) setState(() {});
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }

  void showInSnackBar(String message) {
    if (message != null)
      widget.videoKey.currentState
          .showSnackBar(SnackBar(content: Text(message)));
  }

  void _onSwitchCamera() {
    selectedCameraIdx = selectedCameraIdx == 1 ? 0 : 1;
    CameraDescription cameraDescription = cameras[selectedCameraIdx];
    onNewCameraSelected(cameraDescription);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) await controller.dispose();

    controller = CameraController(cameraDescription, ResolutionPreset.medium,
        enableAudio: enableAudio);

    // If the controller is updated then update the UI
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  /// Starts Recording Video
  Future<String> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    if (controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      videoPath = filePath;
      await controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    _isRecordingVideo = true;
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    if (videoPath != null &&
        videoPath.isNotEmpty &&
        widget.onVideoRecorded != null) {
      _isRecordingVideo = false;
      widget.onVideoRecorded(videoPath);
    }
  }

  Future<void> _initCameras() async {
    cameras = await availableCameras();
  }

  /// Prints camera exception log
  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

class VideoRecorderController {
  static final int RECORD = 1;
  static final int STOP = 2;

  void startRecording() {
    _controller.add(RECORD);
  }

  void stopRecording() {
    _controller.add(STOP);
  }

  bool isRecording() {
    return _isRecordingVideo;
  }
}
