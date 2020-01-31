import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  VideoPlayerWidget({@required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: _controller.value.initialized
            ? AspectRatio(
                aspectRatio: 1,
                //child: VideoPlayer(_controller),
                child: Stack(
                  children: <Widget>[
                    VideoPlayer(_controller),
                    Center(
                      child: _controller.value.isPlaying
                          ? IconButton(
                              icon: Icon(
                                Icons.pause,
                                color: Colors.white,
                              ),
                              onPressed: () => pauseVideo(),
                            )
                          : IconButton(
                              icon: Icon(Icons.play_arrow, color: Colors.white),
                              onPressed: () => playVideo(),
                            ),
                    ),
                  ],
                ),
              )
            : Container(),
      ),
    );
  }

  void playVideo() {
    if (widget.videoUrl == null) {
      return;
    }
    if (_controller.value.initialized && !_controller.value.isPlaying) {
      setState(() {
        _controller.play();
      });
    }
  }

  void pauseVideo() {
    if (widget.videoUrl == null) {
      return;
    }
    if (_controller.value.initialized && _controller.value.isPlaying) {
      _controller.pause();
    }
  }
}
