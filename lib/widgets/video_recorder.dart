import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_questions/model/question.dart';

class VideoRecorder extends StatefulWidget {
  final Question question;

  VideoRecorder({this.question});

  @override
  _VideoRecorderState createState() {
    return _VideoRecorderState();
  }
}

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

class _VideoRecorderState extends State<VideoRecorder>
    with WidgetsBindingObserver {
  CameraController controller;
  String imagePath;
  String videoPath;
  VideoPlayerController videoController;
  VoidCallback videoPlayerListener;
  bool enableAudio = true;
  List<CameraDescription> cameras = [];

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

  Widget _getBody() {
    Column column = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _surfaceCameraView(),
        _captureControlRowWidget(),
        _toggleAudioWidget(),
        _toggleCameraSelector(),
        _finishButton(context)
      ],
    );
    return column;
  }

  Widget _finishButton(BuildContext ctx) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity),
      child: RaisedButton(
        padding: EdgeInsets.all(20.0),
        color: Colors.blue,
        child: Text('Finish'),
        onPressed: () {
          if (videoPath != null) Navigator.pop(ctx, videoPath);
        },
      ),
    );
  }

  Widget _toggleCameraSelector() {
    return Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[_cameraTogglesRowWidget(), _thumbnailWidget()],
        ));
  }

  Widget _surfaceCameraView() {
    var widget1 = Expanded(
      child: Container(
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
      ),
    );

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
        IconButton(
            icon: const Icon(Icons.camera_alt),
            color: Colors.blue,
            onPressed: controller != null &&
                    controller.value.isInitialized &&
                    !controller.value.isRecordingVideo
                ? onTakePictureButtonPressed
                : null),
        IconButton(
            icon: Icon(Icons.videocam),
            color: Colors.blue,
            onPressed: controller != null &&
                    controller.value.isInitialized &&
                    !controller.value.isRecordingVideo
                ? onVideoRecordButtonPressed
                : null),
        IconButton(
          icon: controller != null && controller.value.isRecordingPaused
              ? Icon(Icons.play_arrow)
              : Icon(Icons.pause),
          color: Colors.blue,
          onPressed: controller != null &&
                  controller.value.isInitialized &&
                  controller.value.isRecordingVideo
              ? (controller != null && controller.value.isRecordingVideo
                  ? onResumeButtonPressed
                  : onPauseButtonPressed)
              : null,
        ),
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

  /// Toggle recording audio
  Widget _toggleAudioWidget() {
    return Padding(
        padding: const EdgeInsets.only(left: 25),
        child: Row(
          children: <Widget>[
            Text('Enable Audio:'),
            Switch(
              value: enableAudio,
              onChanged: (bool value) {
                enableAudio = value;
                if (controller != null) {
                  onNewCameraSelected(controller.description);
                }
              },
            )
          ],
        ));
  }

  /// Selector of front Camera and main Camera
  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    if (cameras.isEmpty) {
      return const Text('No camera found');
    } else {
      for (CameraDescription cameraDescription in cameras) {
        toggles.add(SizedBox(
            width: 90.0,
            child: RadioListTile<CameraDescription>(
                title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
                groupValue: controller?.description,
                value: cameraDescription,
                onChanged:
                    controller != null && controller.value.isRecordingVideo
                        ? null
                        : onNewCameraSelected)));
      }
    }
    return Row(children: toggles);
  }

  /// Display the thumbnail of the captured image or video
  Widget _thumbnailWidget() {
    return Expanded(
        child: Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          videoController == null && imagePath == null
              ? Container()
              : SizedBox(
                  width: 64.0,
                  height: 64.0,
                  child: (videoController == null)
                      ? Image.file(File(imagePath))
                      : Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.pink)),
                          child: Center(
                              child: AspectRatio(
                            child: VideoPlayer(videoController),
                            aspectRatio: videoController.value.size != null
                                ? videoController.value.aspectRatio
                                : 1.0,
                          )),
                        ))
        ],
      ),
    ));
  }

  /// Take Picture
  void onTakePictureButtonPressed() {
    takePicture().then((String filePath) {
      if (mounted) {
        setState(() {
          imagePath = filePath;
          videoController?.dispose();
          videoController = null;
        });
        if (filePath != null) showInSnackBar('Picture saved to $filePath');
      }
    });
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

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) setState(() {});
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording resumed');
    });
  }

  void showInSnackBar(String message) {
    if (message != null)
      _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
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

  /// Takes Picture
  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/video_recorder';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    return filePath;
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

    await _startVideoPlayer();
  }

  Future<void> pauseVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.pauseVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.resumeVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _startVideoPlayer() async {
    final VideoPlayerController vcontroller =
        VideoPlayerController.file(File(videoPath));
    videoPlayerListener = () {
      if (videoController != null && videoController.value.size != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) setState(() {});
        videoController.removeListener(videoPlayerListener);
      }
    };
    vcontroller.addListener(videoPlayerListener);
    await vcontroller.setLooping(true);
    await vcontroller.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        imagePath = null;
        videoController = vcontroller;
      });
    }
    await vcontroller.play();
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